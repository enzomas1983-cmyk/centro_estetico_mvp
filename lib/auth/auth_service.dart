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