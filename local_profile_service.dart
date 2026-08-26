import 'package:shared_preferences/shared_preferences.dart';
import '../models/local_profile.dart';

class LocalProfileService {
  static const _name='prototype_name', _email='prototype_email', _club='prototype_club';
  Future<void> save(LocalProfile p) async { final s=await SharedPreferences.getInstance(); await s.setString(_name,p.displayName); await s.setString(_email,p.email); await s.setString(_club,p.clubName); }
  Future<LocalProfile?> load() async { final s=await SharedPreferences.getInstance(); final n=s.getString(_name), e=s.getString(_email), c=s.getString(_club); if(n==null||e==null||c==null)return null; return LocalProfile(displayName:n,email:e,clubName:c); }
  Future<void> clear() async { final s=await SharedPreferences.getInstance(); await s.remove(_name); await s.remove(_email); await s.remove(_club); }
}
