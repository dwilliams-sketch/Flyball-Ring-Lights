import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../models/live_room.dart';
import '../../services/live_ring_service.dart';
import '../../services/ring_audio_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fault_button.dart';
import '../../widgets/flyball_lamp.dart';

enum _LivePhase { none, red1, red2, red3, green }

class LiveRingScreen extends StatefulWidget {
  final LiveRoomJoin join;

  const LiveRingScreen({
    super.key,
    required this.join,
  });

  @override
  State<LiveRingScreen> createState() => _LiveRingScreenState();
}

class _LiveRingScreenState extends State<LiveRingScreen> {
  final service = LiveRingService();
  final audio = RingAudioService();

  StreamSubscription<Map<String, dynamic>>? roomSub;
  StreamSubscription<bool>? connectedSub;
  Timer? ticker;

  Map<String, dynamic> room = {};
  bool connected = true;
  int serverOffset = 0;
  int elapsedMs = -3000;
  _LivePhase phase = _LivePhase.none;
  _LivePhase previousPhase = _LivePhase.none;
  bool firstPhaseSample = true;

  bool soundOn = false;
  double volume = .65;
  bool leaving = false;
  int autoStoppedGeneration = -1;

  final Map<String, bool> pendingFaults = {};

  @override
  void initState() {
    super.initState();

    // Main Display is the only role with sound on by default, reducing
    // multiple devices producing slightly separated beeps.
    soundOn = widget.join.isDisplay;

    _start();
  }

  Future<void> _start() async {
    if (!kIsWeb) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    await WakelockPlus.enable();

    serverOffset = await service.serverOffsetMs();

    connectedSub = service.connectedStream().listen((value) {
      if (mounted) setState(() => connected = value);
    });

    roomSub = service.roomStream(widget.join.roomId).listen(
      (value) {
        room = value;
        _reconcilePendingFaults();
        _recalculate();
      },
      onError: (Object error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Live ring connection: $error')),
        );
      },
    );

    ticker = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _recalculate(),
    );
  }

  Map<String, dynamic> get _state {
    final raw = room['state'];
    return raw is Map<String, dynamic> ? raw : {};
  }

  Map<String, dynamic> get _roles {
    final raw = room['roles'];
    return raw is Map<String, dynamic> ? raw : {};
  }

  String get _status => (_state['status'] ?? 'ready').toString();

  int get _generation => (_state['generation'] as num?)?.toInt() ?? 0;

  int get _zeroAt => (_state['zeroAt'] as num?)?.toInt() ?? 0;

  int get _stoppedAt => (_state['stoppedAt'] as num?)?.toInt() ?? 0;

  void _recalculate() {
    if (!mounted) return;

    final status = _status;
    final zeroAt = _zeroAt;
    int nextElapsed = -3000;

    if (status == 'ready' || zeroAt <= 0) {
      nextElapsed = -3000;
    } else if (status == 'stopped' && _stoppedAt > 0) {
      nextElapsed = _stoppedAt - zeroAt;
    } else {
      final serverNow =
          DateTime.now().millisecondsSinceEpoch + serverOffset;
      nextElapsed = serverNow - zeroAt;
    }

    if (nextElapsed > 60000) nextElapsed = 60000;

    final nextPhase = _phaseFor(status, nextElapsed);

    if (nextPhase != phase) {
      previousPhase = phase;
      phase = nextPhase;

      if (!firstPhaseSample) {
        _playCue(nextPhase);
      } else {
        firstPhaseSample = false;
      }
    }

    elapsedMs = nextElapsed;

    if (widget.join.isHost &&
        status != 'ready' &&
        status != 'stopped' &&
        status != 'ended' &&
        elapsedMs >= 60000 &&
        autoStoppedGeneration != _generation) {
      autoStoppedGeneration = _generation;
      service.stop(widget.join.roomId);
    }

    setState(() {});
  }

  _LivePhase _phaseFor(String status, int elapsed) {
    if (status == 'ready' || status == 'ended') {
      return _LivePhase.none;
    }

    if (elapsed < -3000) return _LivePhase.none;
    if (elapsed < -2000) return _LivePhase.red1;
    if (elapsed < -1000) return _LivePhase.red2;
    if (elapsed < 0) return _LivePhase.red3;
    return _LivePhase.green;
  }

  Future<void> _playCue(_LivePhase p) async {
    audio.enabled = soundOn;
    audio.volume = volume;

    if (p == _LivePhase.red1 ||
        p == _LivePhase.red2 ||
        p == _LivePhase.red3) {
      await audio.redCue();
    } else if (p == _LivePhase.green) {
      await audio.greenCue();
    }
  }

  String _faultKey(String lane, int number) => '$lane-$number';

  bool _serverFault(String lane, int number) {
    final raw = _state[lane == 'blue' ? 'blueFaults' : 'redFaults'];
    if (raw is! Map) return false;
    return raw[number.toString()] == true;
  }

  bool _fault(String lane, int number) {
    final key = _faultKey(lane, number);

    // If a tap is waiting for the room stream to confirm, keep showing the
    // user's requested state instead of falling back to stale network data.
    if (pendingFaults.containsKey(key)) {
      return pendingFaults[key]!;
    }

    return _serverFault(lane, number);
  }

  void _reconcilePendingFaults() {
    if (pendingFaults.isEmpty) return;

    final confirmed = <String>[];

    for (final entry in pendingFaults.entries) {
      final parts = entry.key.split('-');
      if (parts.length != 2) continue;

      final lane = parts[0];
      final number = int.tryParse(parts[1]);
      if (number == null) continue;

      if (_serverFault(lane, number) == entry.value) {
        confirmed.add(entry.key);
      }
    }

    for (final key in confirmed) {
      pendingFaults.remove(key);
    }
  }

  Future<void> _changeFault(String lane, int number) async {
    final key = _faultKey(lane, number);
    final next = !_fault(lane, number);

    // Update instantly. Keep this local state until the Firebase room stream
    // actually confirms the same value. There is deliberately no 120 ms timer.
    setState(() => pendingFaults[key] = next);

    try {
      await service.setFault(
        roomId: widget.join.roomId,
        lane: lane,
        dogNumber: number,
        active: next,
      );

      // Normally the room stream confirms almost immediately. If it has
      // already arrived by the time setFault returns, reconcile now too.
      if (mounted) {
        setState(_reconcilePendingFaults);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => pendingFaults.remove(key));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not change $lane fault $number: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  Future<void> _resetRoom() async {
    // RESET is authoritative. Remove any local pending fault display first,
    // then let the room stream supply the clean false values.
    setState(pendingFaults.clear);

    try {
      await service.reset(widget.join.roomId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not reset ring: $e')),
      );
    }
  }

  bool _roleOnline(String role) {
    final raw = _roles[role];
    if (raw is! Map) return false;
    return raw['online'] == true;
  }

  int get _viewerCount {
    final raw = _roles['viewers'];
    if (raw is! Map) return 0;

    var count = 0;
    for (final value in raw.values) {
      if (value is Map && value['online'] == true) count++;
    }
    return count;
  }

  String get _timerText {
    if (_status == 'ready') return 'READY';

    final sign = elapsedMs < 0 ? '-' : '+';
    final absolute = elapsedMs.abs();
    final seconds = absolute ~/ 1000;
    final millis = absolute % 1000;

    return '$sign${seconds.toString()}.'
        '${millis.toString().padLeft(3, '0')}';
  }

  Future<void> _leave({bool end = false}) async {
    if (leaving) return;
    leaving = true;

    try {
      if (end && widget.join.isHost) {
        await service.endRoom(widget.join);
      } else {
        await service.leaveRoom(widget.join);
      }
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<bool> _confirmLeave() async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          widget.join.isHost ? 'Leave the live ring?' : 'Leave ring?',
        ),
        content: Text(
          widget.join.isHost
              ? 'You can leave without ending the room, or end the room '
                  'for everyone.'
              : 'You can rejoin later while the room is still active.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('STAY'),
          ),
          if (widget.join.isHost)
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
                _leave(end: true);
              },
              child: const Text('END FOR EVERYONE'),
            ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, false);
              _leave();
            },
            child: const Text('LEAVE'),
          ),
        ],
      ),
    );

    return answer ?? false;
  }

  @override
  void dispose() {
    ticker?.cancel();
    roomSub?.cancel();
    connectedSub?.cancel();
    audio.dispose();
    WakelockPlus.disable();

    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_status == 'ended') {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flag, size: 60),
                const SizedBox(height: 14),
                const Text(
                  'THIS LIVE RING HAS ENDED',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _leave(),
                  child: const Text('LEAVE RING'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 420;
              final veryCompact = constraints.maxHeight < 330;

              return Column(
                children: [
                  _topBar(
                    compact: compact,
                    veryCompact: veryCompact,
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 6 : 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 25,
                            child: _faultLane(
                              lane: 'blue',
                              title: 'BLUE',
                              color: AppTheme.blueLane,
                              canTap: widget.join.isHost,
                              compact: compact,
                            ),
                          ),
                          SizedBox(width: compact ? 5 : 10),
                          Expanded(
                            flex: 50,
                            child: _tower(
                              compact: compact,
                              veryCompact: veryCompact,
                            ),
                          ),
                          SizedBox(width: compact ? 5 : 10),
                          Expanded(
                            flex: 25,
                            child: _faultLane(
                              lane: 'red',
                              title: 'RED',
                              color: AppTheme.redLane,
                              canTap:
                                  widget.join.isRed || widget.join.isHost,
                              compact: compact,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.join.isHost || widget.join.isRed)
                    _controls(
                      compact: compact,
                      veryCompact: veryCompact,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _topBar({
    required bool compact,
    required bool veryCompact,
  }) {
    final roleLabel = switch (widget.join.role) {
      'host' => 'BLUE / HOST',
      'red' => 'RED LANE',
      'display' => 'MAIN DISPLAY',
      _ => 'VIEWER',
    };

    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 5 : 9,
        2,
        compact ? 5 : 9,
        2,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Leave ring',
            visualDensity: VisualDensity.compact,
            onPressed: _confirmLeave,
            icon: const Icon(Icons.close),
          ),
          if (!veryCompact) ...[
            Text(
              roleLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppTheme.surface2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${widget.join.token} · ${widget.join.code}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: compact ? 10 : 12,
                color: AppTheme.gold,
              ),
            ),
          ),
          const Spacer(),
          if (!veryCompact)
            _presence(
              compact: compact,
            ),
          SizedBox(width: compact ? 3 : 8),
          Icon(
            connected
                ? Icons.cloud_done_outlined
                : Icons.cloud_off_outlined,
            size: compact ? 18 : 21,
            color: connected ? AppTheme.green : AppTheme.redLane,
          ),
          IconButton(
            tooltip: soundOn ? 'Sound on' : 'Sound off',
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() {
              soundOn = !soundOn;
              audio.enabled = soundOn;
            }),
            icon: Icon(
              soundOn
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color: soundOn ? AppTheme.gold : Colors.white38,
              size: compact ? 19 : 22,
            ),
          ),
          SizedBox(
            width: compact ? 70 : 105,
            child: Slider(
              value: volume,
              min: 0,
              max: 1,
              onChanged: soundOn
                  ? (value) => setState(() {
                        volume = value;
                        audio.volume = value;
                      })
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _presence({required bool compact}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dot('B', _roleOnline('host'), AppTheme.blueLane),
        _dot('R', _roleOnline('red'), AppTheme.redLane),
        _dot('D', _roleOnline('display'), AppTheme.gold),
        Container(
          margin: const EdgeInsets.only(left: 4),
          child: Text(
            'V $_viewerCount',
            style: TextStyle(
              fontSize: compact ? 9 : 10,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _dot(String label, bool online, Color color) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.circle,
              size: 8,
              color: online ? color : Colors.white24,
            ),
            const SizedBox(width: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );

  Widget _faultLane({
    required String lane,
    required String title,
    required Color color,
    required bool canTap,
    required bool compact,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) => Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$title LANE',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  fontSize: compact ? 12 : 14,
                ),
              ),
              SizedBox(height: compact ? 4 : 7),
              for (var i = 1; i <= 4; i++) ...[
                FaultButton(
                  dogNumber: i,
                  laneColor: color,
                  active: _fault(lane, i),
                  width: compact ? 60 : 76,
                  height: compact ? 40 : 52,
                  fontSize: compact ? 17 : 22,
                  onTap: canTap
                      ? () => _changeFault(lane, i)
                      : () {},
                ),
                if (i != 4)
                  SizedBox(height: compact ? 4 : 7),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tower({
    required bool compact,
    required bool veryCompact,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final targetLamp = compact ? 58.0 : 80.0;
        final gap = compact ? 4.0 : 7.0;

        return Column(
          children: [
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: EdgeInsets.all(compact ? 5 : 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E131B),
                      borderRadius:
                          BorderRadius.circular(compact ? 18 : 26),
                      border: Border.all(
                        color: AppTheme.border,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FlyballLamp(
                          color: const Color(0xFFE54242),
                          active: phase == _LivePhase.red1,
                          size: targetLamp,
                        ),
                        SizedBox(height: gap),
                        FlyballLamp(
                          color: const Color(0xFFE54242),
                          active: phase == _LivePhase.red2,
                          size: targetLamp,
                        ),
                        SizedBox(height: gap),
                        FlyballLamp(
                          color: const Color(0xFFE54242),
                          active: phase == _LivePhase.red3,
                          size: targetLamp,
                        ),
                        SizedBox(height: gap),
                        FlyballLamp(
                          color: AppTheme.green,
                          active: phase == _LivePhase.green,
                          size: targetLamp,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: compact ? 44 : 58,
              width: double.infinity,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _timerText,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: veryCompact ? 40 : compact ? 50 : 66,
                      fontWeight: FontWeight.w900,
                      fontFeatures: const [
                        FontFeature.tabularFigures(),
                      ],
                      color: _status == 'stopped'
                          ? AppTheme.gold
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _controls({
    required bool compact,
    required bool veryCompact,
  }) {
    final active =
        _status != 'ready' && _status != 'stopped' && _status != 'ended';

    if (widget.join.isRed) {
      return SizedBox(
        height: compact ? 54 : 70,
        child: Padding(
          padding: EdgeInsets.all(compact ? 5 : 8),
          child: SizedBox.expand(
            child: FilledButton.icon(
              onPressed: active
                  ? () => service.stop(widget.join.roomId)
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.redLane,
              ),
              icon: const Icon(Icons.stop_rounded),
              label: const Text('EMERGENCY STOP'),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: compact ? 54 : 70,
      child: Padding(
        padding: EdgeInsets.all(compact ? 5 : 8),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: active
                    ? null
                    : () => service.go(widget.join.roomId),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.green,
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('GO'),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: FilledButton.icon(
                onPressed: active
                    ? () => service.stop(widget.join.roomId)
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.redLane,
                ),
                icon: const Icon(Icons.stop_rounded),
                label: const Text('STOP'),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: FilledButton.icon(
                onPressed: _resetRoom,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.surface2,
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('RESET'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
