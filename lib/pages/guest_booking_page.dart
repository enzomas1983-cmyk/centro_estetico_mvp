import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/booking_rules.dart';
import 'package:intl/intl.dart';

class GuestBookingPage extends StatefulWidget {
  final String businessId;
  const GuestBookingPage({super.key, required this.businessId});

  @override
  State<GuestBookingPage> createState() => _GuestBookingPageState();
}

class _GuestBookingPageState extends State<GuestBookingPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> services = [];
  Map<String, int> durationMap = {};
  String? selectedServiceId;
  DateTime selectedDate = DateTime.now();
  List<DateTime> availableSlots = [];
  DateTime? selectedSlot;
  bool isLoading = true;

  final nameController = TextEditingController();
  final surnameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    surnameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // build: 20260608
    loadServices();
  }

  Future<void> loadServices() async {
    try {
      final data = await supabase
          .from('services')
          .select()
          .eq('business_id', widget.businessId)
          .order('name');
      if (!mounted) return;
      setState(() {
        services = List<Map<String, dynamic>>.from(data);
        durationMap = {
          for (final s in data)
            s['id'].toString(): (s['duration_minutes'] is int)
                ? s['duration_minutes']
                : int.tryParse('${s['duration_minutes']}') ?? 30
        };
      });
    } catch (e) {
      debugPrint("LOAD SERVICES ERROR => $e");
      if (!mounted) return;
      // ✅ mostra errore solo se i servizi sono effettivamente vuoti
      if (services.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Errore nel caricamento dei servizi"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> loadAvailableSlots() async {
    if (selectedServiceId == null) return;
    final service = services.firstWhere(
          (s) => s['id'].toString() == selectedServiceId,
      orElse: () => {},
    );
    final durationMinutes = (service['duration_minutes'] is int)
        ? service['duration_minutes']
        : int.tryParse('${service['duration_minutes']}') ?? 30;
    final dayStartLocal = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 8);
    final dayEndLocal = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20);
    final dayStartUtc = dayStartLocal.toUtc();
    final dayEndUtc = dayEndLocal.toUtc();
    try {
      final data = await supabase
          .from('appointments')
          .select('start_time,end_time,status')
          .eq('business_id', widget.businessId)
          .neq('status', 'cancelled')
          .lt('start_time', dayEndUtc.toIso8601String())
          .gt('end_time', dayStartUtc.toIso8601String());
      final booked = List<Map<String, dynamic>>.from(data).map((a) {
        return _Interval(
          DateTime.parse(a['start_time']).toUtc(),
          DateTime.parse(a['end_time']).toUtc(),
        );
      }).toList();
      final List<DateTime> slots = [];
      const step = Duration(minutes: 15);
      DateTime cursor = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 8);
      while (true) {
        final startLocal = cursor;
        final endLocal = startLocal.add(Duration(minutes: durationMinutes));
        if (endLocal.isAfter(dayEndLocal)) break;
        final blocked = BookingRules.isBlocked(start: startLocal, end: endLocal);
        if (blocked) {
          cursor = cursor.add(step);
          continue;
        }
        bool occupied = false;
        for (final b in booked) {
          final overlap = startLocal.toUtc().isBefore(b.end) && endLocal.toUtc().isAfter(b.start);
          if (overlap) {
            occupied = true;
            break;
          }
        }
        if (!occupied) slots.add(startLocal);
        cursor = cursor.add(step);
      }
      if (!mounted) return;
      setState(() {
        availableSlots = slots;
        selectedSlot = null;
      });
    } catch (e) {
      debugPrint("LOAD SLOTS ERROR => $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Errore nel caricamento degli slot"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> createBooking() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || selectedServiceId == null || selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Compila tutti i campi e seleziona un orario"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => isLoading = true);
    try {
      final localStart = selectedSlot!;
      final startUtc = localStart.toUtc();
      final duration = durationMap[selectedServiceId!] ?? 30;
      final endUtc = startUtc.add(Duration(minutes: duration));
      final blocked = BookingRules.isBlocked(start: startUtc.toLocal(), end: endUtc.toLocal());
      if (blocked) {
        final reason = BookingRules.reason(start: startUtc.toLocal(), end: endUtc.toLocal());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(reason ?? "Slot non disponibile"), backgroundColor: Colors.red),
        );
        return;
      }
      final existing = await supabase
          .from('customers')
          .select()
          .eq('phone', phoneController.text.trim())
          .eq('business_id', widget.businessId)
          .maybeSingle();
      String customerId;
      if (existing != null) {
        customerId = existing['id'];
        await supabase.from('customers').update({
          'name': nameController.text.trim(),
          'surname': surnameController.text.trim(),
          'email': emailController.text.trim(),
        }).eq('id', customerId);
      } else {
        final created = await supabase.from('customers').insert({
          'name': nameController.text.trim(),
          'surname': surnameController.text.trim(),
          'phone': phoneController.text.trim(),
          'email': emailController.text.trim(),
          'business_id': widget.businessId,
        }).select().single();
        customerId = created['id'];
      }
      final appointment = await supabase.from('appointments').insert({
        'business_id': widget.businessId,
        'customer_id': customerId,
        'service_id': selectedServiceId,
        'start_time': startUtc.toIso8601String(),
        'end_time': endUtc.toIso8601String(),
        'status': 'scheduled',
      }).select().single();

      final email = emailController.text.trim();

      if (email.isNotEmpty) {
        await supabase.functions.invoke(
          'send-booking-email',
          body: {'appointment_id': appointment['id']},
        );
      }

      if (!mounted) return;

      // ✅ messaggio con email se presente, senza se assente
      final confirmMessage = email.isNotEmpty
          ? "Prenotazione confermata! ✅\nEmail di conferma inviata a $email"
          : "Prenotazione confermata! ✅";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
          content: Text(confirmMessage),
        ),
      );

      setState(() {
        selectedSlot = null;
        availableSlots = [];
        selectedServiceId = null;
      });
      nameController.clear();
      surnameController.clear();
      phoneController.clear();
      emailController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceSelected = selectedServiceId != null;
    Map<String, dynamic>? selectedService;
    try {
      selectedService = services.firstWhere((s) => s['id'].toString() == selectedServiceId);
    } catch (_) {
      selectedService = null;
    }
    final selectedServiceName = selectedService?['name']?.toString() ?? '';
    final selectedServiceDuration = selectedService?['duration_minutes']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text("Prenota online")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // SERVIZIO
              DropdownButtonFormField<String>(
                //value: selectedServiceId,
                decoration: const InputDecoration(labelText: "Seleziona servizio"),
                items: services.map((s) => DropdownMenuItem(
                  value: s['id'].toString(),
                  child: Text(s['name']),
                )).toList(),
                onChanged: (v) async {
                  setState(() => selectedServiceId = v);
                  await loadAvailableSlots();
                },
              ),

              // PREVIEW SERVIZIO
              if (selectedServiceId != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.pink.shade200),
                  ),
                  child: Column(
                    children: [
                      const Text("Stai prenotando per",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 12),
                      Text(selectedServiceName,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text("Durata: $selectedServiceDuration minuti",
                          style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                ),
              ],

              // DATA
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: const Text("Seleziona data"),
                onPressed: serviceSelected ? () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDate: selectedDate,
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                    await loadAvailableSlots();
                  }
                } : null,
              ),

              // FORM DATI — sempre visibile
              const SizedBox(height: 24),
              const Text("I tuoi dati",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameController,
                validator: (v) => v == null || v.trim().isEmpty ? "Campo obbligatorio" : null,
                decoration: const InputDecoration(labelText: "Nome *"),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: surnameController,
                validator: (v) => v == null || v.trim().isEmpty ? "Campo obbligatorio" : null,
                decoration: const InputDecoration(labelText: "Cognome *"),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.trim().isEmpty ? "Campo obbligatorio" : null,
                decoration: const InputDecoration(labelText: "Telefono *"),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null; // email opzionale
                  final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
                  if (!emailRegex.hasMatch(v.trim())) {
                    return "Formato email non valido (es. nome@dominio.it)";
                  }
                  return null;
                },

              ),

              // SLOT DISPONIBILI
              if (availableSlots.isNotEmpty) ...[
                const SizedBox(height: 20),
                if (availableSlots.where((s) => s.hour < 13).isNotEmpty) ...[
                  const Row(children: [
                    Icon(Icons.wb_sunny, size: 18, color: Colors.orange),
                    SizedBox(width: 6),
                    Text("Mattina", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ]),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableSlots.where((s) => s.hour < 13).map((slot) {
                      final selected = selectedSlot != null && selectedSlot!.isAtSameMomentAs(slot);
                      final label = "${slot.hour.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')}";
                      return ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (_) => setState(() => selectedSlot = slot),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                if (availableSlots.where((s) => s.hour >= 14).isNotEmpty) ...[
                  const Row(children: [
                    Icon(Icons.nights_stay, size: 18, color: Colors.indigo),
                    SizedBox(width: 6),
                    Text("Pomeriggio", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ]),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableSlots.where((s) => s.hour >= 14).map((slot) {
                      final selected = selectedSlot != null && selectedSlot!.isAtSameMomentAs(slot);
                      final label = "${slot.hour.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')}";
                      return ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (_) => setState(() => selectedSlot = slot),
                      );
                    }).toList(),
                  ),
                ],
              ],

              if (availableSlots.isEmpty && serviceSelected) ...[
                const SizedBox(height: 20),
                const Text("Nessun orario disponibile per questa data",
                    style: TextStyle(color: Colors.grey)),
              ],

              // RECAP E PULSANTE
              if (selectedSlot != null) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Riepilogo prenotazione",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      Row(children: [
                        const Icon(Icons.spa, size: 18, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(selectedServiceName, style: const TextStyle(fontSize: 15)),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.calendar_today, size: 18, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(DateFormat('dd MMMM yyyy', 'it_IT').format(selectedDate),
                            style: const TextStyle(fontSize: 15)),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.access_time, size: 18, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          "${selectedSlot!.hour.toString().padLeft(2, '0')}:${selectedSlot!.minute.toString().padLeft(2, '0')}",
                          style: const TextStyle(fontSize: 15),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.timer, size: 18, color: Colors.green),
                        const SizedBox(width: 8),
                        Text("Durata: $selectedServiceDuration minuti",
                            style: const TextStyle(fontSize: 15)),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : createBooking,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Conferma prenotazione"),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Interval {
  final DateTime start;
  final DateTime end;
  const _Interval(this.start, this.end);
}