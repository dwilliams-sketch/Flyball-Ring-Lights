import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../services/ring_audio_service.dart';
import '../../services/ring_clock_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fault_button.dart';
import '../../widgets/flyball_lamp.dart';

class RingScreen extends StatefulWidget {
  const RingScreen({super.key});

  @override
  State<RingScreen> createState() => _RingScreenState();
}

class _RingScreenState extends State<RingScreen> {
  final clock = RingClockController();
  final audio = RingAudioService();

  final blue = List<bool>.filled(4, false);
  final red = List<bool>.filled(4, false);

  bool soundOn = true;
  double volume = .65;

  @override
  void initState() {
    super.initState();
    clock.onCue = _cue;
    clock.addListener(_refresh);
    _enter();
  }

  Future<void> _enter() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await WakelockPlus.enable();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _cue(LightPhase phase) async {
    audio.enabled = soundOn;
    audio.volume = volume;

    if (phase == LightPhase.red1 ||
        phase == LightPhase.red2 ||
        phase == LightPhase.red3) {
      await audio.redCue();
    } else if (phase == LightPhase.green) {
      await audio.greenCue();
    }
  }

  void _reset() {
    setState(() {
      for (var i = 0; i < 4; i++) {
        blue[i] = false;
        red[i] = false;
      }
    });
    clock.reset();
  }

  @override
  void dispose() {
    clock.removeListener(_refresh);
    clock.dispose();
    audio.dispose();
    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;
            final width = constraints.maxWidth;

            // Phone landscape can be surprisingly shallow once Android's
            // navigation/status areas are removed. Everything below scales
            // from the ACTUAL usable height rather than fixed pixel sizes.
            final veryCompact = height < 330;
            final compact = height < 430;

            final topHeight =
                (height * .105).clamp(34.0, compact ? 42.0 : 48.0);
            final controlsHeight =
                (height * .17).clamp(52.0, compact ? 62.0 : 72.0);

            return Column(
              children: [
                SizedBox(
                  height: topHeight,
                  child: _topBar(
                    context,
                    compact: compact,
                    veryCompact: veryCompact,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 7 : 12,
                      1,
                      compact ? 7 : 12,
                      1,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: width < 700 ? 27 : 24,
                          child: _faultColumn(
                            title: 'BLUE',
                            color: AppTheme.blueLane,
                            values: blue,
                            compact: compact,
                            onTap: (i) => setState(
                              () => blue[i] = !blue[i],
                            ),
                          ),
                        ),
                        SizedBox(width: compact ? 5 : 10),
                        Expanded(
                          flex: width < 700 ? 46 : 52,
                          child: _lightTower(
                            compact: compact,
                            veryCompact: veryCompact,
                          ),
                        ),
                        SizedBox(width: compact ? 5 : 10),
                        Expanded(
                          flex: width < 700 ? 27 : 24,
                          child: _faultColumn(
                            title: 'RED',
                            color: AppTheme.redLane,
                            values: red,
                            compact: compact,
                            onTap: (i) => setState(
                              () => red[i] = !red[i],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: controlsHeight,
                  child: _controls(
                    compact: compact,
                    veryCompact: veryCompact,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _topBar(
    BuildContext context, {
    required bool compact,
    required bool veryCompact,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Leave ring',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              size: veryCompact ? 20 : 23,
            ),
          ),
          if (!veryCompact)
            Text(
              compact ? 'LOCAL · REV 0.2A' : 'LOCAL RING · REV 0.2A',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w800,
                letterSpacing: .7,
                fontSize: compact ? 10 : 12,
              ),
            ),
          const Spacer(),
          IconButton(
            tooltip: soundOn ? 'Sound on' : 'Sound off',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            onPressed: () => setState(() {
              soundOn = !soundOn;
              audio.enabled = soundOn;
            }),
            icon: Icon(
              soundOn
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              size: veryCompact ? 20 : 23,
              color: soundOn ? AppTheme.gold : Colors.white38,
            ),
          ),
          SizedBox(
            width: veryCompact ? 78 : compact ? 100 : 130,
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

  Widget _faultColumn({
    required String title,
    required Color color,
    required List<bool> values,
    required bool compact,
    required void Function(int index) onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final buttonHeight = compact ? 42.0 : 52.0;
        final buttonWidth = compact ? 62.0 : 76.0;
        final gap = compact ? 4.0 : 7.0;
        final fontSize = compact ? 18.0 : 22.0;

        return Center(
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
                    letterSpacing: 1.1,
                    fontSize: compact ? 12 : 14,
                  ),
                ),
                SizedBox(height: compact ? 4 : 6),
                for (var i = 0; i < 4; i++) ...[
                  FaultButton(
                    dogNumber: i + 1,
                    laneColor: color,
                    active: values[i],
                    width: buttonWidth,
                    height: buttonHeight,
                    fontSize: fontSize,
                    onTap: () => onTap(i),
                  ),
                  if (i != 3) SizedBox(height: gap),
                ],
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _lightTower({
    required bool compact,
    required bool veryCompact,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;

        final timerHeight =
            (h * .18).clamp(30.0, compact ? 44.0 : 58.0);
        final timerGap = compact ? 1.0 : 4.0;
        final lampAreaHeight =
            (h - timerHeight - timerGap).clamp(60.0, h);

        final targetLampSize = compact ? 58.0 : 78.0;
        final lampGap = compact ? 4.0 : 7.0;
        final towerPadding = compact ? 5.0 : 8.0;

        return Column(
          children: [
            SizedBox(
              height: lampAreaHeight,
              width: double.infinity,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: EdgeInsets.all(towerPadding),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E131B),
                      borderRadius:
                          BorderRadius.circular(compact ? 18 : 26),
                      border: Border.all(
                        color: AppTheme.border,
                        width: compact ? 1.2 : 1.8,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FlyballLamp(
                          color: const Color(0xFFE54242),
                          active: clock.phase == LightPhase.red1,
                          size: targetLampSize,
                        ),
                        SizedBox(height: lampGap),
                        FlyballLamp(
                          color: const Color(0xFFE54242),
                          active: clock.phase == LightPhase.red2,
                          size: targetLampSize,
                        ),
                        SizedBox(height: lampGap),
                        FlyballLamp(
                          color: const Color(0xFFE54242),
                          active: clock.phase == LightPhase.red3,
                          size: targetLampSize,
                        ),
                        SizedBox(height: lampGap),
                        FlyballLamp(
                          color: AppTheme.green,
                          active: clock.phase == LightPhase.green,
                          size: targetLampSize,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: timerGap),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    clock.display,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: veryCompact ? 42 : compact ? 52 : 66,
                      fontWeight: FontWeight.w900,
                      fontFeatures: const [
                        FontFeature.tabularFigures(),
                      ],
                      letterSpacing: compact ? .8 : 1.8,
                      color: clock.state == RingClockState.stopped
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
    final running = clock.state == RingClockState.countdown ||
        clock.state == RingClockState.racing;

    return Container(
      color: const Color(0xFF0C1016),
      padding: EdgeInsets.fromLTRB(
        compact ? 8 : 14,
        compact ? 5 : 8,
        compact ? 8 : 14,
        compact ? 5 : 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: _button(
              label: 'GO',
              icon: Icons.play_arrow_rounded,
              color: AppTheme.green,
              foreground: Colors.black,
              compact: compact,
              veryCompact: veryCompact,
              onPressed: running ? null : clock.go,
            ),
          ),
          SizedBox(width: compact ? 6 : 10),
          Expanded(
            child: _button(
              label: 'STOP',
              icon: Icons.stop_rounded,
              color: AppTheme.redLane,
              foreground: Colors.white,
              compact: compact,
              veryCompact: veryCompact,
              onPressed: running ? clock.stop : null,
            ),
          ),
          SizedBox(width: compact ? 6 : 10),
          Expanded(
            child: _button(
              label: 'RESET',
              icon: Icons.refresh_rounded,
              color: AppTheme.surface2,
              foreground: Colors.white,
              compact: compact,
              veryCompact: veryCompact,
              onPressed: _reset,
            ),
          ),
        ],
      ),
    );
  }

  Widget _button({
    required String label,
    required IconData icon,
    required Color color,
    required Color foreground,
    required bool compact,
    required bool veryCompact,
    required VoidCallback? onPressed,
  }) {
    return SizedBox.expand(
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: veryCompact ? 19 : compact ? 22 : 26,
        ),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: veryCompact ? 13 : compact ? 16 : 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: foreground,
          disabledBackgroundColor: color.withValues(alpha: .18),
          disabledForegroundColor:
              foreground.withValues(alpha: .35),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 5 : 10,
            vertical: 2,
          ),
        ),
      ),
    );
  }
}
