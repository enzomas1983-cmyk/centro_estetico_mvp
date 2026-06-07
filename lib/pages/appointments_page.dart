import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final supabase = Supabase.instance.client;

  // ✅ Fix 2 — lista tipizzata
  List<Map<String, dynamic>> appointments = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadAppointments();
  }

  // ✅ Fix 1 — filtro business_id + gestione errori
  Future<void> loadAppointments() async {
    final profile = context.read<AuthProvider>().profile;
    final businessId = profile?.businessId;

    if (businessId == null) {
      debugPrint("❌ BUSINESS ID NULL in AppointmentsPage");
      return;
    }

    setState(() => isLoading = true);

    try {
      final data = await supabase
          .from('appointments')
          .select('*, services(name)')
          .eq('business_id', businessId)
          .order('start_time');

      if (!mounted) return;
      setState(() {
        appointments = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      debugPrint("LOAD APPOINTMENTS ERROR => $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Errore: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ✅ Fix 3 — formatDate usata nel build
  String formatDate(String date) {
    final dt = DateTime.parse(date).toLocal();
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Appuntamenti")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : appointments.isEmpty
          ? const Center(child: Text("Nessun appuntamento"))
          : ListView.builder(
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final a = appointments[index];
          return ListTile(
            title: Text(a['services']?['name'] ?? "Servizio"),
            // ✅ Fix 3 — formatDate usata
            subtitle: Text(formatDate(a['start_time'] ?? '')),
            trailing: const Icon(Icons.calendar_today),
          );
        },
      ),
    );
  }
}


/*import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final supabase = Supabase.instance.client;

  List appointments = [];

  @override
  void initState() {
    super.initState();
    loadAppointments();
  }


  Future<void> loadAppointments() async {
    final data = await supabase
        .from('appointments')
        .select('*, services(name)')
        .order('start_time');

    if (!mounted) return;
    setState(() => appointments = data);
  }

  String formatDate(String date) {
    final dt = DateTime.parse(date);
    return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Appuntamenti")),
      body: ListView.builder(
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final a = appointments[index];

          return ListTile(
            title: Text(a['services']?['name'] ?? "Servizio"),
            subtitle: Text(a['start_time'] ?? ''),
            trailing: const Icon(Icons.calendar_today),
          );
        },
      ),
    );
  }
}*/