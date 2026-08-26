import 'package:audioplayers/audioplayers.dart';
class RingAudioService {
  final AudioPlayer _player=AudioPlayer();
  bool enabled=true; double volume=.65;
  Future<void> redCue() async { if(!enabled)return; await _player.stop(); await _player.setVolume(volume); await _player.play(AssetSource('audio/red_beep.wav')); }
  Future<void> greenCue() async { if(!enabled)return; await _player.stop(); await _player.setVolume(volume); await _player.play(AssetSource('audio/go_beep.wav')); }
  Future<void> dispose()=>_player.dispose();
}
