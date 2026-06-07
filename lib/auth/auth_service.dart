import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  // ✅ signIn usa il campo supabase di classe
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final res = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return res;
  }

  // ✅ logout invariato
  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  // ✅ currentUser invariato
  User? get currentUser => supabase.auth.currentUser;

// ✅ getProfile() rimosso — duplicava AuthProvider.loadProfile()
}


/*import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class AuthService {

  final supabase = Supabase.instance.client;

  // LOGIN
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {

    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // LOGOUT
  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  // CURRENT USER
  User? get currentUser {
    return supabase.auth.currentUser;
  }

  // GET PROFILE
  Future<ProfileModel?> getProfile() async {

    final user = currentUser;

    if (user == null) return null;

    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) return null;

    return ProfileModel.fromJson(data);
  }
}*/