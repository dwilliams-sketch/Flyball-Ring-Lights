import 'dart:async';
import 'package:flutter/foundation.dart';

enum RingClockState { ready, countdown, racing, stopped }
enum LightPhase { none, red1, red2, red3, green }

class RingClockController extends ChangeNotifier {
  Timer? _ticker; DateTime? _zero; double _frozen=0; LightPhase _last=LightPhase.none;
  RingClockState state=RingClockState.ready; double seconds=-3; LightPhase phase=LightPhase.none;
  void Function(LightPhase)? onCue;
  void go(){ _ticker?.cancel(); _zero=DateTime.now().add(const Duration(seconds:3)); seconds=-3; phase=LightPhase.red1; state=RingClockState.countdown; _last=LightPhase.none; _cue(); _ticker=Timer.periodic(const Duration(milliseconds:10),(_)=>_tick()); notifyListeners(); }
  void _tick(){ final z=_zero; if(z==null)return; seconds=DateTime.now().difference(z).inMicroseconds/1000000.0; if(seconds>=60){seconds=60; stop(); return;} if(seconds < -2){phase=LightPhase.red1;state=RingClockState.countdown;} else if(seconds < -1){phase=LightPhase.red2;state=RingClockState.countdown;} else if(seconds < 0){phase=LightPhase.red3;state=RingClockState.countdown;} else {phase=LightPhase.green;state=RingClockState.racing;} _cue(); notifyListeners(); }
  void _cue(){ if(_last==phase)return; _last=phase; onCue?.call(phase); }
  void stop(){ if(state==RingClockState.ready||state==RingClockState.stopped)return; _ticker?.cancel(); _ticker=null; _frozen=seconds; state=RingClockState.stopped; notifyListeners(); }
  void reset(){ _ticker?.cancel(); _ticker=null; _zero=null; seconds=-3; _frozen=0; phase=LightPhase.none; _last=LightPhase.none; state=RingClockState.ready; notifyListeners(); }
  String get display { if(state==RingClockState.ready)return 'READY'; final v=state==RingClockState.stopped?_frozen:seconds; return '${v>0?'+':''}${v.toStringAsFixed(3)}'; }
  @override void dispose(){_ticker?.cancel();super.dispose();}
}
