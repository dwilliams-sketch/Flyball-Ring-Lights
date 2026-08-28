import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CameraBetaController {
  Future<void> Function(int offsetMs)? _capture;

  Future<void> captureAtZero(int offsetMs) async {
    final fn = _capture;
    if (fn != null) await fn(offsetMs);
  }

  void _attach(Future<void> Function(int offsetMs) fn) => _capture = fn;
  void _detach() => _capture = null;
}

class CameraBetaPanel extends StatefulWidget {
  final CameraBetaController controller;
  final bool compact;

  const CameraBetaPanel({
    super.key,
    required this.controller,
    this.compact = false,
  });

  @override
  State<CameraBetaPanel> createState() => _CameraBetaPanelState();
}

class _CameraBetaPanelState extends State<CameraBetaPanel> {
  List<CameraDescription> cameras = const [];
  CameraDescription? blueCamera;
  CameraDescription? redCamera;
  CameraController? blueController;
  CameraController? redController;
  Uint8List? blueCapture;
  Uint8List? redCapture;
  int? captureOffsetMs;
  double blueLine = .5;
  double redLine = .5;
  bool loading = false;
  String message = 'Camera Beta is off.';

  @override
  void initState() {
    super.initState();
    widget.controller._attach(_captureAtZero);
  }

  @override
  void dispose() {
    widget.controller._detach();
    blueController?.dispose();
    redController?.dispose();
    super.dispose();
  }

  Future<void> _setup() async {
    if (!kIsWeb) {
      setState(() => message = 'Dual start-line Camera Beta is currently enabled on the hosted web display only.');
      return;
    }

    setState(() {
      loading = true;
      message = 'Requesting camera permission…';
    });

    try {
      final found = await availableCameras();
      if (found.length < 2) {
        setState(() {
          cameras = found;
          message = found.isEmpty
              ? 'No webcams were found. Check browser camera permission.'
              : 'Only one camera was found. Connect a second webcam, then press SET UP again.';
        });
        return;
      }

      cameras = found;
      blueCamera ??= found[0];
      redCamera ??= found[1];
      if (redCamera == blueCamera && found.length > 1) redCamera = found[1];
      await _initialiseControllers();
      if (mounted) {
        setState(() => message = 'Two-camera preview ready. Tap each preview to place the start/finish line.');
      }
    } on CameraException catch (e) {
      if (mounted) setState(() => message = 'Camera error: ${e.description ?? e.code}');
    } catch (e) {
      if (mounted) setState(() => message = 'Camera setup failed: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _initialiseControllers() async {
    await blueController?.dispose();
    await redController?.dispose();
    blueController = null;
    redController = null;

    final blue = blueCamera;
    final red = redCamera;
    if (blue == null || red == null) return;
    if (blue.name == red.name) {
      setState(() => message = 'Choose two different cameras.');
      return;
    }

    final bc = CameraController(
      blue,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    final rc = CameraController(
      red,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    blueController = bc;
    redController = rc;

    await Future.wait([bc.initialize(), rc.initialize()]);
    if (mounted) setState(() {});
  }

  Future<void> _changeCamera(String lane, String? name) async {
    final chosen = cameras.where((c) => c.name == name).firstOrNull;
    if (chosen == null) return;
    if (lane == 'blue') {
      blueCamera = chosen;
    } else {
      redCamera = chosen;
    }
    setState(() {
      loading = true;
      message = 'Changing cameras…';
    });
    try {
      await _initialiseControllers();
      if (mounted) setState(() => message = 'Camera preview ready.');
    } catch (e) {
      if (mounted) setState(() => message = 'Could not open both cameras: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _captureAtZero(int offsetMs) async {
    final bc = blueController;
    final rc = redController;
    if (bc == null || rc == null || !bc.value.isInitialized || !rc.value.isInitialized) return;

    try {
      final shots = await Future.wait([bc.takePicture(), rc.takePicture()]);
      final bytes = await Future.wait([shots[0].readAsBytes(), shots[1].readAsBytes()]);
      if (!mounted) return;
      setState(() {
        blueCapture = bytes[0];
        redCapture = bytes[1];
        captureOffsetMs = offsetMs;
        message = 'Zero capture saved locally on this display. Camera shutter latency is not calibrated.';
      });
    } catch (e) {
      if (mounted) setState(() => message = 'Zero capture failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = blueController?.value.isInitialized == true && redController?.value.isInitialized == true;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(widget.compact ? 6 : 10),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.videocam_outlined, size: 18, color: AppTheme.gold),
                const SizedBox(width: 6),
                const Text('START-LINE CAMERA BETA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                const Spacer(),
                if (captureOffsetMs != null)
                  Text(
                    'Capture requested ${captureOffsetMs! >= 0 ? '+' : ''}${(captureOffsetMs! / 1000).toStringAsFixed(3)}s',
                    style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
                  ),
                const SizedBox(width: 6),
                OutlinedButton.icon(
                  onPressed: loading ? null : _setup,
                  icon: const Icon(Icons.settings_input_component, size: 16),
                  label: Text(ready ? 'RE-SCAN' : 'SET UP'),
                ),
              ],
            ),
            if (cameras.length >= 2) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: _selector('Blue camera', blueCamera, (v) => _changeCamera('blue', v))),
                  const SizedBox(width: 8),
                  Expanded(child: _selector('Red camera', redCamera, (v) => _changeCamera('red', v))),
                ],
              ),
            ],
            const SizedBox(height: 6),
            if (ready)
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _cameraBox('BLUE', AppTheme.blueLane, blueController!, blueLine, (v) => setState(() => blueLine = v), blueCapture)),
                    const SizedBox(width: 8),
                    Expanded(child: _cameraBox('RED', AppTheme.redLane, redController!, redLine, (v) => setState(() => redLine = v), redCapture)),
                  ],
                ),
              )
            else
              Expanded(child: Center(child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textMuted)))),
            const SizedBox(height: 4),
            Text(message, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _selector(String label, CameraDescription? selected, ValueChanged<String?> changed) {
    return DropdownButtonFormField<String>(
      value: selected?.name,
      isDense: true,
      decoration: InputDecoration(labelText: label),
      items: cameras.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: changed,
    );
  }

  Widget _cameraBox(
    String lane,
    Color color,
    CameraController controller,
    double line,
    ValueChanged<double> onLine,
    Uint8List? captured,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          Text('$lane LANE', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10)),
          const SizedBox(height: 3),
          Expanded(
            child: GestureDetector(
              onTapDown: (details) {
                final next = (details.localPosition.dx / constraints.maxWidth).clamp(0.02, 0.98);
                onLine(next);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreview(controller),
                    Positioned(
                      left: constraints.maxWidth * line,
                      top: 0,
                      bottom: 0,
                      child: Container(width: 2, color: AppTheme.gold),
                    ),
                    Positioned(
                      left: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        color: Colors.black54,
                        child: const Text('Tap to move line', style: TextStyle(fontSize: 8)),
                      ),
                    ),
                    if (captured != null)
                      Positioned(
                        right: 4,
                        bottom: 4,
                        width: 72,
                        height: 46,
                        child: GestureDetector(
                          onTap: () => showDialog<void>(
                            context: context,
                            builder: (context) => Dialog(
                              child: InteractiveViewer(child: Image.memory(captured)),
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(border: Border.all(color: AppTheme.gold, width: 2)),
                            child: Image.memory(captured, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
