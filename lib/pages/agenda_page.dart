import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'booking_page.dart';
import 'customer_profile_page.dart';
import 'edit_appointment_page.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AgendaPage extends StatefulWidget {
  final String serviceId;

  const AgendaPage({
    super.key,
    required this.serviceId,
  });

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> appointments = [];

  final List<int> hours = List.generate(12, (index) => 9 + index);

  @override
  void initState() {
    super.initState();
    loadAppointments();
  }

  // ✅ Fix 1 — filtro business_id + duration_minutes nel select
  Future<void> loadAppointments() async {
    final profile = context.read<AuthProvider>().profile;
    final businessId = profile?.businessId;

    if (businessId == null) {
      debugPrint("❌ BUSINESS ID NULL in AgendaPage");
      return;
    }

    try {
      final data = await supabase
          .from('appointments')
          .select('*, customers(name), services(name, color, duration_minutes)')
          .eq('business_id', businessId)
          .order('start_time');

      if (!mounted) return;
      setState(() {
        appointments = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      debugPrint("LOAD APPOINTMENTS ERROR => $e");
    }
  }

  // ✅ Fix 2 — await + gestione errori
  Future<void> deleteAppointment(String id) async {
    try {
      await supabase
          .from('appointments')
          .delete()
          .eq('id', id);

      await loadAppointments(); // ✅ await aggiunto

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Appuntamento eliminato")),
      );
    } catch (e) {
      debugPrint("DELETE ERROR => $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Errore eliminazione: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ Fix 3 — overlap corretto con intervallo, non solo start_time esatto
  Future<bool> isSlotBusy(
      DateTime start,
      DateTime end, {
        String? excludeId,
      }) async {
    var query = supabase
        .from('appointments')
        .select('id')
        .lt('start_time', end.toUtc().toIso8601String())
        .gt('end_time', start.toUtc().toIso8601String())
        .neq('status', 'cancelled');

    final data = List<Map<String, dynamic>>.from(await query);

    if (excludeId != null) {
      return data.any((a) => a['id'] != excludeId);
    }

    return data.isNotEmpty;
  }

  // ✅ Fix 4 — rimosso client_name inesistente, date in UTC
  Future<void> updateAppointment(
      String id,
      DateTime startTime,
      int durationMinutes,
      ) async {
    final endTime = startTime.add(Duration(minutes: durationMinutes));

    final busy = await isSlotBusy(
      startTime,
      endTime,
      excludeId: id,
    );

    if (busy) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Orario già occupato"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await supabase.from('appointments').update({
        'start_time': startTime.toUtc().toIso8601String(), // ✅ UTC
        'end_time': endTime.toUtc().toIso8601String(),     // ✅ UTC
      }).eq('id', id);

      await loadAppointments();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Appuntamento aggiornato")),
      );
    } catch (e) {
      debugPrint("UPDATE ERROR => $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Errore aggiornamento: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ Fix 5 — getServiceColor dal DB invece di hardcoded
  Color getServiceColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return Colors.grey[200]!;
    try {
      final buffer = StringBuffer();
      if (hexColor.length == 6 || hexColor.length == 7) buffer.write('ff');
      buffer.write(hexColor.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16)).withOpacity(0.3);
    } catch (_) {
      return Colors.grey[200]!;
    }
  }

  Map<String, dynamic>? getAppointmentForHour(DateTime day, int hour) {
    final start = DateTime(day.year, day.month, day.day, hour);
    final end = start.add(const Duration(hours: 1));

    for (final a in appointments) {
      final raw = a['start_time'];
      if (raw == null) continue;
      final time = DateTime.tryParse(raw.toString())?.toLocal();
      if (time == null) continue;
      if (time.isAfter(start) && time.isBefore(end)) return a;
    }

    return null;
  }

  void showAppointmentOptions(Map<String, dynamic> appointment) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Apri cliente"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomerProfilePage(
                      customerId: appointment['customer_id'],
                      customerName:
                      appointment['customers']?['name'] ?? 'Cliente',
                    ),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Modifica appuntamento"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditAppointmentPage(
                      appointmentId: appointment['id'].toString(),
                      initialDate: DateTime.parse(appointment['start_time']),
                      businessId: context.read<AuthProvider>().profile?.businessId ?? '',
                      durationMinutes:
                      appointment['services']?['duration_minutes'] as int? ?? 30,
                    ),
                  ),
                ).then((_) => loadAppointments());
              },
            ),

            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                "Elimina",
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(context);
                await deleteAppointment(appointment['id'].toString());
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text("Agenda giornaliera")),
      body: ListView.builder(
        itemCount: hours.length,
        itemBuilder: (context, index) {
          final hour = hours[index];
          final appointment = getAppointmentForHour(today, hour);
          final isBusy = appointment != null;

          return ListTile(
            leading: isBusy
                ? Container(
              width: 6,
              height: double.infinity,
              // ✅ Colore dal DB
              color: getServiceColor(
                appointment['services']?['color'],
              ),
            )
                : null,

            title: Text("${hour.toString().padLeft(2, '0')}:00"),

            subtitle: isBusy
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment['customers']?['name'] ?? 'Cliente',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  appointment['services']?['name'] ?? 'Servizio',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            )
                : const Text("Libero"),

            tileColor: isBusy ? Colors.red[50] : Colors.green[50],

            onTap: () {
              final selectedDateTime = DateTime(
                today.year,
                today.month,
                today.day,
                hour,
              );

              if (!isBusy) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingPage(
                      selectedDateTime: selectedDateTime,
                      serviceId: widget.serviceId,
                    ),
                  ),
                ).then((_) => loadAppointments());
                return;
              }

              showAppointmentOptions(appointment);
            },
          );
        },
      ),
    );
  }
}

// ✅ showDateTimePicker invariato
Future<DateTime?> showDateTimePicker(
    BuildContext context,
    DateTime initialDate,
    ) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
  );

  if (date == null) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initialDate),
  );

  if (time == null) return null;

  return DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
}


/*import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'booking_page.dart';
import 'customer_profile_page.dart';
import 'edit_appointment_page.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AgendaPage extends StatefulWidget {
  final String serviceId;

  const AgendaPage({
    super.key,
    required this.serviceId,
  });

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> appointments = [];

  Color getServiceColor(String? serviceName) {
    switch (serviceName?.toLowerCase()) {
      case 'massaggio':
        return Colors.blue[100]!;
      case 'manicure':
        return Colors.pink[100]!;
      case 'pulizia viso':
        return Colors.purple[100]!;
      case 'laser':
        return Colors.orange[100]!;
      default:
        return Colors.grey[200]!;
    }
  }


  final List<int> hours = List.generate(12, (index) => 9 + index);

  @override
  void initState() {
    super.initState();
    loadAppointments();
  }

  Future<void> loadAppointments() async {
    final data = await supabase
        .from('appointments')
        .select('*, customers(name), services(name)')
        .order('start_time');

    if (!mounted) return;
    setState(() {
      appointments = List<Map<String, dynamic>>.from(data);
    });
  }

  Future<void> deleteAppointment(String id) async {
    await supabase
        .from('appointments')
        .delete()
        .eq('id', id);

    loadAppointments();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Appuntamento eliminato")),
      );
    }
  }

  void openEditDialog(Map<String, dynamic> appointment) {
    final TextEditingController nameController =
    TextEditingController(text: appointment['customers']?['name'] ?? '');

    DateTime selectedTime = DateTime.parse(appointment['start_time']);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Modifica appuntamento"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Cliente"),
                  ),

                  const SizedBox(height: 10),

                  TextButton(
                    onPressed: () async {
                      final picked = await showDateTimePicker(context, selectedTime);
                      if (picked != null) {
                        setStateDialog(() => selectedTime = picked);
                      }
                    },
                    child: Text(
                      "Orario: ${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}",
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Annulla"),
                ),

                ElevatedButton(
                  onPressed: () async {
                    await updateAppointment(
                      appointment['id'],
                      nameController.text,
                      selectedTime,
                    );

                    Navigator.pop(context);
                  },
                  child: const Text("Salva"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> isSlotBusy(DateTime dateTime, {String? excludeId}) async {
    final result = await supabase
        .from('appointments')
        .select('id')
        .eq('start_time', dateTime.toIso8601String());

    final list = List<Map<String, dynamic>>.from(result);

    if (excludeId != null) {
      return list.any((a) => a['id'] != excludeId);
    }

    return list.isNotEmpty;
  }

  Future<void> updateAppointment(
      String id,
      String clientName,
      DateTime startTime,
      ) async {
    // 🔒 1. controllo slot occupato (escludendo questo appuntamento)
    final busy = await isSlotBusy(
      startTime,
      excludeId: id,
    );

    if (busy) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ Orario già occupato"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 💾 2. update solo se libero
    await supabase.from('appointments').update({
      'start_time': startTime.toIso8601String(),
      'client_name': clientName,
    }).eq('id', id);

    // 🔄 3. refresh agenda
    await loadAppointments();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Appuntamento aggiornato")),
      );
    }
  }

  void showAppointmentDialog(Map<String, dynamic> appointment) {
    final customerName = appointment['customers']?['name'] ?? 'Cliente';
    final serviceName = appointment['services']?['name'] ?? 'Servizio';
    final time = DateTime.parse(appointment['start_time']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Dettaglio appuntamento"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Cliente: $customerName"),
            Text("Servizio: $serviceName"),
            Text("Orario: ${time.hour}:${time.minute.toString().padLeft(2, '0')}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Chiudi"),
          ),
          TextButton(
            onPressed: () async {
              await deleteAppointment(appointment['id']);
              Navigator.pop(context);
            },
            child: const Text("Elimina", style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openEditDialog(appointment);
            },
            child: const Text("Modifica"),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? getAppointmentForHour(DateTime day, int hour) {
    final start = DateTime(day.year, day.month, day.day, hour);
    final end = start.add(const Duration(hours: 1));

    for (final a in appointments) {
      final raw = a['start_time'];
      if (raw == null) continue;

      final time = DateTime.tryParse(raw.toString());
      if (time == null) continue;

      final isInSlot = time.isAfter(start) && time.isBefore(end);

      if (isInSlot) return a;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text("Agenda giornaliera")),
      body: ListView.builder(
        itemCount: hours.length,
        itemBuilder: (context, index) {
          final hour = hours[index];
          final appointment = getAppointmentForHour(today, hour);

          final isBusy = appointment != null;

          return ListTile(
            leading: isBusy
                ? Container(
              width: 6,
              height: double.infinity,
              color: getServiceColor(
                appointment!['services']?['name'],
              ),
            )
                : null,

            title: Text("${hour.toString().padLeft(2, '0')}:00"),

            subtitle: isBusy
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment!['customers']?['name'] ?? 'Cliente',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  appointment['services']?['name'] ?? 'Servizio',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            )
                : const Text("Libero"),

            tileColor: isBusy
                ? Colors.red[50]
                : Colors.green[50],

            onTap: () {
              final selectedDateTime = DateTime(
                today.year,
                today.month,
                today.day,
                hour,
              );

              // 🟢 SLOT LIBERO → NUOVO APPUNTAMENTO
              if (!isBusy) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingPage(
                      selectedDateTime: selectedDateTime,
                      serviceId: widget.serviceId,
                    ),
                  ),
                ).then((_) => loadAppointments());
                return;
              }

              // 🔴 SLOT OCCUPATO → MENU AZIONI
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Wrap(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text("Apri cliente"),
                        onTap: () {
                          Navigator.pop(context);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CustomerProfilePage(
                                customerId: appointment!['customer_id'],
                                customerName:
                                appointment['customers']?['name'] ?? 'Cliente',
                              ),
                            ),
                          );
                        },
                      ),

                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text("Modifica appuntamento"),
                        onTap: () {
                          Navigator.pop(context);

                          /*Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditAppointmentPage(

                                appointmentId:
                                appointment!['id'].toString(),

                                initialDate:
                                DateTime.parse(
                                  appointment['start_time'],
                                ),
                              ),
                            ),
                          ).then((_) => loadAppointments());*/

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditAppointmentPage(
                                appointmentId: appointment!['id'].toString(),
                                initialDate: DateTime.parse(appointment['start_time']),
                                // ✅ aggiunto
                                businessId: context.read<AuthProvider>().profile?.businessId ?? '',
                                // ✅ aggiunto
                                durationMinutes: appointment['services']?['duration_minutes'] as int? ?? 30,
                              ),
                            ),
                          ).then((_) => loadAppointments());

                        },
                      ),

                      ListTile(
                        leading: const Icon(Icons.delete, color: Colors.red),
                        title: const Text("Elimina"),
                        onTap: () async {
                          await supabase
                              .from('appointments')
                              .delete()
                              .eq('id', appointment!['id']);

                          Navigator.pop(context);
                          loadAppointments();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

Future<DateTime?> showDateTimePicker(
    BuildContext context,
    DateTime initialDate,
    ) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
  );

  if (date == null) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initialDate),
  );

  if (time == null) return null;

  return DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
}*/