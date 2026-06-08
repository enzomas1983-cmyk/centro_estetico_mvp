import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'booking_page.dart';
import 'agenda_page.dart';
import 'calendar_page.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final supabase = Supabase.instance.client;

  // ✅ Fix 3 — lista tipizzata
  List<Map<String, dynamic>> services = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadServices();
  }

  // ✅ Fix 1 — filtro business_id + gestione errori
  Future<void> loadServices() async {
    final profile = context.read<AuthProvider>().profile;
    final businessId = profile?.businessId;

    if (businessId == null) {
      debugPrint("❌ BUSINESS ID NULL in ServicesPage");
      return;
    }

    setState(() => isLoading = true);

    try {
      final data = await supabase
          .from('services')
          .select()
          .eq('business_id', businessId)
          .order('name');

      if (!mounted) return;
      setState(() {
        services = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      debugPrint("LOAD SERVICES ERROR => $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Errore: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // ✅ Fix 2 — debugPrint al posto di print()
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Servizi"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CalendarPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : services.isEmpty
          ? const Center(child: Text("Nessun servizio disponibile"))
          : ListView.builder(
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return ListTile(
            title: Text(service['name'] ?? ''),
            subtitle: Text(
              "${service['duration_minutes'] ?? '-'} min",
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AgendaPage(
                    serviceId: service['id'],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}