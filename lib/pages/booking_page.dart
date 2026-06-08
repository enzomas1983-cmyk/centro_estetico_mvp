import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/booking_rules.dart';

class BookingPage extends StatefulWidget {
  final String serviceId;
  final DateTime selectedDateTime;

  const BookingPage({
    super.key,
    required this.serviceId,
    required this.selectedDateTime,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final supabase = Supabase.instance.client;
  bool isLoading = false;
  // Aggiungi questa variabile in cima alla classe
  String? _businessId;

  String? selectedCustomerId;
  final List customers = [];
  Map<String, dynamic>? selectedCustomer;
  final TextEditingController nameController = TextEditingController();
  List customerAppointments = [];

  @override
  void initState() {
    super.initState();
    loadCustomers();
  }


  // ✅ Sostituisci loadCustomers() con questa versione
  Future<void> loadCustomers() async {
    try {
      // Recupera businessId dal servizio (necessario per filtrare i clienti)
      final service = await supabase
          .from('services')
          .select('business_id')
          .eq('id', widget.serviceId)
          .single();

      _businessId = service['business_id'];

      final data = await supabase
          .from('customers')
          .select()
          .eq('business_id', _businessId!);

      if (!mounted) return;

      setState(() {
        customers.clear();
        customers.addAll(List<Map<String, dynamic>>.from(data));
      });
    } catch (e) {
      debugPrint("LOAD CUSTOMERS ERROR => $e");
    }
  }

  Future<void> loadCustomerHistory(String customerId) async {
    final data = await supabase
        .from('appointments')
        .select('*, services(name, duration_minutes)')
        .eq('customer_id', customerId)
        .order('start_time', ascending: false);

    if (!mounted) return;
    setState(() {
      customerAppointments = data;
    });
  }

  /// 🚨 BLOCCO SOVRAPPOSIZIONI INTELLIGENTE

  // ✅ Il filtro overlap avviene sul DB, non in Dart
  Future<bool> isSlotBusy(
      DateTime newStart,
      DateTime newEnd,
      String businessId, {
        String? excludeId,
      }) async {
    var query = supabase
        .from('appointments')
        .select('id')
        .eq('business_id', businessId)
        .neq('status', 'cancelled')
        .lt('start_time', newEnd.toUtc().toIso8601String())
        .gt('end_time', newStart.toUtc().toIso8601String());

    final data = List<Map<String, dynamic>>.from(await query);

    // excludeId è sempre al massimo 1 record — ok filtrare in Dart
    if (excludeId != null) {
      return data.any((a) => a['id'] != excludeId);
    }

    return data.isNotEmpty;
  }

  Future<void> saveAppointment() async {
    if (isLoading) return;
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      if (selectedCustomerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Seleziona un cliente"),
            backgroundColor: Colors.orange,
          ),
        );
        return; // finally gestisce isLoading = false
      }

      // ✅ businessId già disponibile, nessuna query aggiuntiva
      if (_businessId == null) {
        throw Exception("Business non disponibile");
      }

      // ✅ Recupera solo la duration, non più business_id
      final service = await supabase
          .from('services')
          .select('duration_minutes')
          .eq('id', widget.serviceId)
          .single();

      final duration = service['duration_minutes'] is int
          ? service['duration_minutes']
          : int.tryParse(service['duration_minutes'].toString()) ?? 30;

      final startTime = widget.selectedDateTime.toLocal();
      final endTime = startTime.add(Duration(minutes: duration));

      final error = BookingRules.reason(start: startTime, end: endTime);
      if (error != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
        return; // finally gestisce isLoading = false
      }

      final busy = await isSlotBusy(startTime, endTime, _businessId!);
      if (busy) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Questo orario si sovrappone a un altro appuntamento"),
            backgroundColor: Colors.red,
          ),
        );
        return; // finally gestisce isLoading = false
      }

      await supabase.from('appointments').insert({
        'service_id': widget.serviceId,
        'customer_id': selectedCustomerId,
        'business_id': _businessId,
        'start_time': startTime.toUtc().toIso8601String(),
        'end_time': endTime.toUtc().toIso8601String(),
        'status': 'scheduled',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Appuntamento salvato")),
      );

      Navigator.pop(context, true);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Errore: $e")),
        );
      }
    } finally {
      // ✅ Un solo posto dove isLoading torna false — niente setState sparsi
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> showAddCustomerDialog() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Nuovo cliente"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: "Nome cliente",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annulla"),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;

                final response = await supabase
                    .from('customers')
                    .insert({'name': name})
                    .select()
                    .single();

                if (!mounted) return;
                setState(() {
                  customers.add(response);
                  selectedCustomerId = response['id'];
                });

                Navigator.pop(context);
              },
              child: const Text("Salva"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dt = widget.selectedDateTime;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nuovo appuntamento"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,

          children: [
            // =========================
            // CLIENTE HEADER
            // =========================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Cliente",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                TextButton.icon(
                  onPressed: showAddCustomerDialog,
                  icon: const Icon(Icons.add),
                  label: const Text("Nuovo"),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // =========================
            // DROPDOWN CLIENTI
            // =========================
            DropdownButtonFormField<String>(
              value: selectedCustomerId,

              items: customers.map<DropdownMenuItem<String>>((c) {
                return DropdownMenuItem(
                  value: c['id'],
                  child: Text(c['name']),
                );
              }).toList(),

              onChanged: (value) async {
                final customer = customers.cast<Map<String, dynamic>?>().firstWhere(
                      (c) => c?['id'] == value,
                  orElse: () => null,
                );

                if (!mounted) return;

                setState(() {
                  selectedCustomerId = value;
                  selectedCustomer = customer;
                });

                if (value != null) {
                  await loadCustomerHistory(value);
                }
              },

              decoration: const InputDecoration(
                labelText: "Cliente",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // =========================
            // ORARIO SELEZIONATO
            // =========================
            const Text(
              "Orario selezionato:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            Text(
                "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}"
            ),

            const SizedBox(height: 20),

            // =========================
            // SERVICE ID
            // =========================
            const Text(
              "Service ID:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            Text(widget.serviceId),

            const SizedBox(height: 30),

            // =========================
            // BUTTON
            // =========================
            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: () {
                  print("BUTTON CLICKED");
                  saveAppointment();
                },

                child: isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text("Salva appuntamento"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}