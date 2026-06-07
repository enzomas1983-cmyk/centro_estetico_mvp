/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 🔥 MANCAVA QUESTO
import '../providers/auth_provider.dart'; // 🔥 MANCAVA QUESTO
import '../pages/pro_calendar_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/login_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();

      await auth.loadProfile();

      if (auth.profile == null) {
        debugPrint("❌ PROFILE NULL DOPO LOAD");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return LoginPage();
    }

    if (auth.profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return const ProCalendarPage();
  }
}*/


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../pages/pro_calendar_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/login_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {

  @override
  void initState() {
    super.initState();
    // ✅ Non serve più chiamare loadProfile() manualmente qui —
    // AuthProvider.init() ascolta onAuthStateChange e lo chiama da solo.
    // Chiamarlo due volte causava un doppio fetch al primo avvio.
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = Supabase.instance.client.auth.currentUser;

    // 1️⃣ Nessuna sessione → login
    if (user == null) {
      return const LoginPage();
    }

    // 2️⃣ Sessione attiva ma profilo in caricamento → spinner
    if (auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 3️⃣ Caricamento finito ma profilo non trovato → errore
    if (auth.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text("Errore: ${auth.error}"),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.read<AuthProvider>().loadProfile(),
                child: const Text("Riprova"),
              ),
            ],
          ),
        ),
      );
    }

    // 4️⃣ Profilo caricato → app
    if (auth.hasProfile) {
      return const ProCalendarPage();
    }

    // 5️⃣ Fallback (profilo null senza errore — caso raro)
    return const LoginPage();
  }
}