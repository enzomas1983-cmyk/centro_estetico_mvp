/*import 'package:flutter/material.dart';
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

  /*@override
  void initState() {
    super.initState();
    // build: 20260608
    loadServices();
  }*/

  @override
  void initState() {
    super.initState();
    if (widget.businessId.isEmpty) return; // ✅ evita query con id vuoto
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
}*/



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

  // ── Design tokens ──────────────────────────────────────────────
  static const _maxWidth        = 420.0;
  static const _pageBg          = Color(0xFFF0F2F5);
  static const _cardBg          = Color(0xFFFFFFFF);
  static const _cardBorder      = Color(0xFFDDE2EA);
  static const _navy            = Color(0xFF1C2130);
  static const _blue            = Color(0xFF3B6FD4);
  static const _blueLight       = Color(0xFFEEF3FC);
  static const _textPrimary     = Color(0xFF1C2130);
  static const _textSecondary   = Color(0xFF3D4A63);
  static const _textMuted       = Color(0xFF7A8599);
  static const _textHint        = Color(0xFFAAB2C2);
  static const _chipBg          = Color(0xFFF0F2F5);
  static const _green           = Color(0xFF2D8A4E);
  static const _borderRadius    = BorderRadius.all(Radius.circular(16));
  static const _borderRadiusMd  = BorderRadius.all(Radius.circular(12));
  static const _borderRadiusSm  = BorderRadius.all(Radius.circular(8));
  // ───────────────────────────────────────────────────────────────

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
    if (widget.businessId.isEmpty) return;
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

    final dayStartLocal =
    DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 8);
    final dayEndLocal =
    DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 20);
    final dayStartUtc = dayStartLocal.toUtc();
    final dayEndUtc   = dayEndLocal.toUtc();

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

      final now = DateTime.now();
      final List<DateTime> slots = [];
      const step = Duration(minutes: 15);
      DateTime cursor =
      DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 8);

      while (true) {
        final startLocal = cursor;
        final endLocal   = startLocal.add(Duration(minutes: durationMinutes));
        if (endLocal.isAfter(dayEndLocal)) break;

        // Filtro orari già passati
        if (startLocal.isBefore(now)) {
          cursor = cursor.add(step);
          continue;
        }

        final blocked = BookingRules.isBlocked(start: startLocal, end: endLocal);
        if (blocked) {
          cursor = cursor.add(step);
          continue;
        }

        bool occupied = false;
        for (final b in booked) {
          final overlap = startLocal.toUtc().isBefore(b.end) &&
              endLocal.toUtc().isAfter(b.start);
          if (overlap) { occupied = true; break; }
        }
        if (!occupied) slots.add(startLocal);
        cursor = cursor.add(step);
      }

      if (!mounted) return;
      setState(() { availableSlots = slots; selectedSlot = null; });
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
      final startUtc   = localStart.toUtc();
      final duration   = durationMap[selectedServiceId!] ?? 30;
      final endUtc     = startUtc.add(Duration(minutes: duration));

      final blocked = BookingRules.isBlocked(
          start: startUtc.toLocal(), end: endUtc.toLocal());
      if (blocked) {
        final reason = BookingRules.reason(
            start: startUtc.toLocal(), end: endUtc.toLocal());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(reason ?? "Slot non disponibile"),
              backgroundColor: Colors.red),
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
          'name':    nameController.text.trim(),
          'surname': surnameController.text.trim(),
          'email':   emailController.text.trim(),
        }).eq('id', customerId);
      } else {
        final created = await supabase.from('customers').insert({
          'name':        nameController.text.trim(),
          'surname':     surnameController.text.trim(),
          'phone':       phoneController.text.trim(),
          'email':       emailController.text.trim(),
          'business_id': widget.businessId,
        }).select().single();
        customerId = created['id'];
      }

      final appointment = await supabase.from('appointments').insert({
        'business_id': widget.businessId,
        'customer_id': customerId,
        'service_id':  selectedServiceId,
        'start_time':  startUtc.toIso8601String(),
        'end_time':    endUtc.toIso8601String(),
        'status':      'scheduled',
      }).select().single();

      final email = emailController.text.trim();
      if (email.isNotEmpty) {
        await supabase.functions.invoke(
          'send-booking-email',
          body: {'appointment_id': appointment['id']},
        );
      }

      if (!mounted) return;

      final confirmMessage = email.isNotEmpty
          ? "Prenotazione confermata! ✅\nEmail di conferma inviata a $email"
          : "Prenotazione confermata! ✅";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _green,
          duration: const Duration(seconds: 5),
          content: Text(confirmMessage),
        ),
      );

      setState(() {
        selectedSlot      = null;
        availableSlots    = [];
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

  // ── Helpers ─────────────────────────────────────────────────────

  String _formatSlot(DateTime slot) =>
      "${slot.hour.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')}";

  InputDecoration _inputDecoration(String label, String tag) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _textHint, fontSize: 14),
      suffixText: tag,
      suffixStyle: const TextStyle(
          color: _textHint, fontSize: 10, fontWeight: FontWeight.w700,
          letterSpacing: 0.6),
      filled: true,
      fillColor: _cardBg,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
          borderRadius: _borderRadiusMd,
          borderSide: const BorderSide(color: _cardBorder, width: 1)),
      enabledBorder: OutlineInputBorder(
          borderRadius: _borderRadiusMd,
          borderSide: const BorderSide(color: _cardBorder, width: 1)),
      focusedBorder: OutlineInputBorder(
          borderRadius: _borderRadiusMd,
          borderSide: const BorderSide(color: _blue, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: _borderRadiusMd,
          borderSide: const BorderSide(color: Colors.red, width: 1)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: _borderRadiusMd,
          borderSide: const BorderSide(color: Colors.red, width: 1.5)),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _textMuted,
            letterSpacing: 0.8)),
  );

  Widget _slotSection({
    required IconData icon,
    required Color iconColor,
    required String label,
    required List<DateTime> slots,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: _borderRadius,
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary)),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: _blueLight,
                    borderRadius: BorderRadius.circular(99)),
                child: Text(
                  "${slots.length} disponibili",
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _blue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: slots.map((slot) {
              final sel = selectedSlot != null &&
                  selectedSlot!.isAtSameMomentAs(slot);
              return _SlotChip(
                label: _formatSlot(slot),
                selected: sel,
                onTap: () => setState(() => selectedSlot = slot),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? selectedService;
    try {
      selectedService =
          services.firstWhere((s) => s['id'].toString() == selectedServiceId);
    } catch (_) {
      selectedService = null;
    }
    final selectedServiceName =
        selectedService?['name']?.toString() ?? '';
    final selectedServiceDuration =
        selectedService?['duration_minutes']?.toString() ?? '';
    final serviceSelected = selectedServiceId != null;

    final morningSlots   = availableSlots.where((s) => s.hour < 13).toList();
    final afternoonSlots = availableSlots.where((s) => s.hour >= 14).toList();

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _pageBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _cardBorder),
        ),
        title: const Text(
          "Prenota online",
          style: TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
              letterSpacing: -0.2),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? const Center(
          child: CircularProgressIndicator(color: _blue))
          : Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ── SERVIZIO ─────────────────────────────
                  _sectionLabel("SERVIZIO"),
                  Container(
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: _borderRadius,
                      border: Border.all(color: _cardBorder),
                    ),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 14),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        value: selectedServiceId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        hint: const Text("Seleziona servizio",
                            style: TextStyle(
                                color: _textHint, fontSize: 14)),
                        style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                        icon: const Icon(Icons.keyboard_arrow_down,
                            color: _textHint),
                        items: services
                            .map((s) => DropdownMenuItem(
                          value: s['id'].toString(),
                          child: Text(s['name']),
                        ))
                            .toList(),
                        onChanged: (v) async {
                          setState(() => selectedServiceId = v);
                          await loadAvailableSlots();
                        },
                      ),
                    ),
                  ),

                  // ── PREVIEW SERVIZIO ─────────────────────
                  if (serviceSelected) ...[
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: _borderRadius,
                        border: Border.all(color: _cardBorder),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: _blueLight,
                          borderRadius: _borderRadiusMd,
                        ),
                        child: Column(
                          children: [
                            const Text("Stai prenotando",
                                style: TextStyle(
                                    fontSize: 11,
                                    color: _textMuted,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text(selectedServiceName,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: _textPrimary,
                                    letterSpacing: -0.3)),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.access_time,
                                    size: 12, color: _blue),
                                const SizedBox(width: 4),
                                Text(
                                    "$selectedServiceDuration minuti",
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: _blue,
                                        fontWeight:
                                        FontWeight.w500)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // ── DATA ─────────────────────────────────
                  const SizedBox(height: 16),
                  _sectionLabel("DATA"),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: serviceSelected
                          ? () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365)),
                          initialDate: selectedDate,
                        );
                        if (picked != null) {
                          setState(
                                  () => selectedDate = picked);
                          await loadAvailableSlots();
                        }
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _navy,
                        disabledBackgroundColor: _textHint,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: const Icon(Icons.calendar_today_outlined,
                          size: 15),
                      label: const Text("Seleziona data",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.1)),
                    ),
                  ),
                  if (serviceSelected) ...[
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        DateFormat('dd MMMM yyyy', 'it_IT')
                            .format(selectedDate),
                        style: const TextStyle(
                            fontSize: 12,
                            color: _blue,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],

                  // ── SLOT MATTINA ─────────────────────────
                  if (morningSlots.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _slotSection(
                      icon: Icons.wb_sunny_outlined,
                      iconColor: const Color(0xFFF59E0B),
                      label: "Mattina",
                      slots: morningSlots,
                    ),
                  ],

                  // ── SLOT POMERIGGIO ──────────────────────
                  if (afternoonSlots.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _slotSection(
                      icon: Icons.nights_stay_outlined,
                      iconColor: const Color(0xFF7C84F0),
                      label: "Pomeriggio",
                      slots: afternoonSlots,
                    ),
                  ],

                  if (availableSlots.isEmpty && serviceSelected) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: _borderRadius,
                        border: Border.all(color: _cardBorder),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy_outlined,
                              size: 16, color: _textHint),
                          SizedBox(width: 8),
                          Text(
                            "Nessun orario disponibile per questa data",
                            style: TextStyle(
                                color: _textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── FORM DATI ────────────────────────────
                  const SizedBox(height: 20),
                  _sectionLabel("I TUOI DATI"),
                  TextFormField(
                    controller: nameController,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? "Campo obbligatorio"
                        : null,
                    decoration: _inputDecoration("Nome *", "NOME"),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: surnameController,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? "Campo obbligatorio"
                        : null,
                    decoration:
                    _inputDecoration("Cognome *", "COGNOME"),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? "Campo obbligatorio"
                        : null,
                    decoration:
                    _inputDecoration("Telefono *", "TEL"),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(
                        "Email (opzionale)", "EMAIL"),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final emailRegex =
                      RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
                      if (!emailRegex.hasMatch(v.trim())) {
                        return "Formato email non valido";
                      }
                      return null;
                    },
                  ),

                  // ── RECAP ────────────────────────────────
                  if (selectedSlot != null) ...[
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: _borderRadius,
                      child: Column(
                        children: [
                          // Header scuro
                          Container(
                            width: double.infinity,
                            color: _navy,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: const [
                                Icon(Icons.check_circle_outline,
                                    size: 15,
                                    color: Color(0xFFAAB2C2)),
                                SizedBox(width: 8),
                                Text("Riepilogo prenotazione",
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        letterSpacing: -0.1)),
                              ],
                            ),
                          ),
                          // Body righe
                          Container(
                            decoration: BoxDecoration(
                              color: _cardBg,
                              border: Border.all(color: _cardBorder),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                            child: Column(
                              children: [
                                _RecapRow(
                                    icon: Icons.spa_outlined,
                                    label: "Servizio",
                                    value: selectedServiceName),
                                _RecapRow(
                                    icon: Icons.calendar_today_outlined,
                                    label: "Data",
                                    value: DateFormat(
                                        'dd MMM yyyy', 'it_IT')
                                        .format(selectedDate)),
                                _RecapRow(
                                    icon: Icons.access_time_outlined,
                                    label: "Orario",
                                    value: _formatSlot(selectedSlot!)),
                                _RecapRow(
                                    icon: Icons.hourglass_bottom_outlined,
                                    label: "Durata",
                                    value:
                                    "$selectedServiceDuration min",
                                    isLast: true),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : createBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: _borderRadiusMd,
                          ),
                        ),
                        icon: isLoading
                            ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2))
                            : const Icon(Icons.check, size: 16),
                        label: const Text(
                          "Conferma prenotazione",
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1),
                        ),
                      ),
                    ),
                  ],

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Chip orario ──────────────────────────────────────────────────────

class _SlotChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SlotChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const _blue  = Color(0xFF3B6FD4);
  static const _navy  = Color(0xFF1C2130);
  static const _chipBg = Color(0xFFF0F2F5);
  static const _border = Color(0xFFDDE2EA);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _blue : _chipBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? _blue : _border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFF3D4A63),
          ),
        ),
      ),
    );
  }
}

// ── Riga recap ───────────────────────────────────────────────────────

class _RecapRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _RecapRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  static const _blue          = Color(0xFF3B6FD4);
  static const _textSecondary = Color(0xFF3D4A63);
  static const _textPrimary   = Color(0xFF1C2130);
  static const _divider       = Color(0xFFF0F2F5);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 15, color: _blue),
              const SizedBox(width: 10),
              Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: _textSecondary)),
              const Spacer(),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary)),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, thickness: 1, color: _divider),
      ],
    );
  }
}

// ── Interval helper ──────────────────────────────────────────────────

class _Interval {
  final DateTime start;
  final DateTime end;
  const _Interval(this.start, this.end);
}




