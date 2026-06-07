import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_model.dart';

class AuthService {

  final supabase = Supabase.instance.client;

  // LOGIN
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final res = await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    return res;
  }

  // LOGOUT
  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  // USER
  User? get currentUser {
    return supabase.auth.currentUser;
  }

  // PROFILE
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
}