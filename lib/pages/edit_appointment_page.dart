import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../core/booking_rules.dart';

class EditAppointmentPage extends StatefulWidget {
  final String appointmentId;
  final DateTime initialDate;
  final String businessId; // ✅ aggiunto
  final int durationMinutes; // ✅ aggiunto

  const EditAppointmentPage({
    super.key,
    required this.appointmentId,
    required this.initialDate,
    required this.businessId,
    required this.durationMinutes,
  });

  @override
  State<EditAppointmentPage> createState() =>
      _EditAppointmentPageState();
}

class _EditAppointmentPageState
    extends State<EditAppointmentPage> {

  final supabase = Supabase.instance.client;
  late DateTime selectedDate;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
  }

  Future<bool> isTimeSlotBusy({
    required DateTime start,
    required DateTime end,
    required String excludeId,
  }) async {
    final data = await supabase
        .from('appointments')
        .select('id')
        .eq('business_id', widget.businessId) // ✅ filtro business
        .lt('start_time', end.toUtc().toIso8601String())
        .gt('end_time', start.toUtc().toIso8601String())
        .neq('id', excludeId)
        .neq('status', 'cancelled');

    return data.isNotEmpty;
  }

  Future<void> updateAppointment() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final newStart = selectedDate;
      final newEnd = selectedDate.add(
        Duration(minutes: widget.durationMinutes), // ✅ durata reale
      );

      // ✅ Validazione BookingRules
      final error = BookingRules.reason(start: newStart, end: newEnd);
      if (error != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
        return;
      }

      final busy = await isTimeSlotBusy(
        start: newStart,
        end: newEnd,
        excludeId: widget.appointmentId,
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

      await supabase.from('appointments').update({
        'start_time': newStart.toUtc().toIso8601String(), // ✅ UTC
        'end_time': newEnd.toUtc().toIso8601String(),     // ✅ UTC
      }).eq('id', widget.appointmentId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Appuntamento aggiornato")),
      );

      Navigator.pop(context, true);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore: $e"), backgroundColor: Colors.red),
      );
    } finally {
      // ✅ Un solo posto dove isLoading torna false
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifica appuntamento"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              title: const Text("Data e ora appuntamento"),
              // ✅ Data formattata
              subtitle: Text(
                DateFormat('dd/MM/yyyy HH:mm').format(selectedDate.toLocal()),
              ),
              trailing: const Icon(Icons.edit),
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (pickedDate == null) return;

                final pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(selectedDate),
                );
                if (pickedTime == null) return;

                if (!mounted) return;
                setState(() {
                  selectedDate = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );
                });
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : updateAppointment,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Salva modifiche"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}