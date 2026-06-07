/*import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_model.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;

  ProfileModel? _profile;
  ProfileModel? get profile => _profile;

  bool isLoading = false;

  bool get hasProfile => _profile != null;

  // ---------------- INIT (CALL FROM MAIN) ----------------

  void init() {
    supabase.auth.onAuthStateChange.listen((data) {

      final session = data.session;

      debugPrint(
        "AUTH STATE CHANGE => ${data.event}",
      );

      if (session != null) {
        loadProfile();
      } else {
        _profile = null;
        notifyListeners();
      }
    });
  }

  // ---------------- LOAD PROFILE ----------------

  Future<void> loadProfile() async {
    try {
      final user = supabase.auth.currentUser;

      debugPrint("USER => $user");

      if (user == null) {
        debugPrint("❌ USER NULL");
        return;
      }

      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      debugPrint("PROFILE RAW => $data");

      if (data == null) {
        debugPrint("❌ PROFILE NON TROVATO");
        return;
      }

      _profile = ProfileModel.fromJson(
        Map<String, dynamic>.from(data),
      );

      debugPrint("✔ PROFILE SET => $_profile");

      notifyListeners();
    } catch (e) {
      debugPrint("LOAD PROFILE ERROR => $e");
    }
  }

  // ---------------- ROLE CHECK ----------------

  bool get isAdmin {
    return _profile?.role == 'admin';
  }

  bool get isOperator {
    return _profile?.role == 'operator';
  }
}*/


import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;

  ProfileModel? _profile;
  ProfileModel? get profile => _profile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool get hasProfile => _profile != null;
  bool get isAdmin => _profile?.role == 'admin';
  bool get isOperator => _profile?.role == 'operator';

  // ✅ FIX 1 — StreamSubscription salvata per poter fare cancel()
  StreamSubscription<AuthState>? _authSub;

  void init() {
    _authSub = supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      debugPrint("AUTH STATE CHANGE => ${data.event}");

      if (session != null) {
        loadProfile();
      } else {
        _profile = null;
        notifyListeners();
      }
    });
  }

  Future<void> loadProfile() async {
    // ✅ FIX 2 — isLoading usato correttamente
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        debugPrint("❌ USER NULL");
        return;
      }

      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        debugPrint("❌ PROFILE NON TROVATO");
        return;
      }

      _profile = ProfileModel.fromJson(Map<String, dynamic>.from(data));
      debugPrint("✔ PROFILE SET => $_profile");

    } catch (e) {
      // ✅ FIX 2b — errore esposto alla UI, non solo in console
      _error = e.toString();
      debugPrint("LOAD PROFILE ERROR => $e");
    } finally {
      // ✅ isLoading sempre rimesso a false, anche in caso di errore
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ FIX 1 — cancel() del subscription per evitare memory leak
  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}