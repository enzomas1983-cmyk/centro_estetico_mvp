import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class CancelBookingPage extends StatefulWidget {
  final String appointmentId;

  const CancelBookingPage({
    super.key,
    required this.appointmentId,
  });

  @override
  State<CancelBookingPage> createState() => _CancelBookingPageState();
}

class _CancelBookingPageState extends State<CancelBookingPage> {
  final supabase = Supabase.instance.client;

  bool isLoading = false;
  bool isCancelled = false;
  bool isAlreadyCancelled = false;
  Map<String, dynamic>? appointment;

  @override
  void initState() {
    super.initState();
    loadAppointment();
  }

  Future<void> loadAppointment() async {

    if (widget.appointmentId.isEmpty) return; // ✅ aggiungi questa riga

    setState(() => isLoading = true);
    try {
      final data = await supabase
          .from('appointments')
          .select('*, services(name), customers(name, surname)')
          .eq('id', widget.appointmentId)
          .single();

      if (!mounted) return;
      setState(() {
        appointment = data;
        isAlreadyCancelled = data['status'] == 'cancelled';
      });
    } catch (e) {
      debugPrint("LOAD APPOINTMENT ERROR => $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }


  Future<void> cancelAppointment() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase.functions.invoke(
        'cancel-appointment',
        body: {'appointment_id': widget.appointmentId},
      );

      debugPrint("CANCEL RESPONSE => ${response.data}");

      // ✅ gestisci sia Map che String
      final raw = response.data;
      final data = raw is String ? jsonDecode(raw) : raw as Map;

      if (data['error'] == 'already_cancelled') {
        if (!mounted) return;
        setState(() => isAlreadyCancelled = true);
        return;
      }

      if (data['success'] == true) {
        if (!mounted) return;
        setState(() => isCancelled = true);
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Errore nella cancellazione"), backgroundColor: Colors.red),
      );

    } catch (e) {
      debugPrint("CANCEL ERROR => $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  /*Future<void> cancelAppointment() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase.functions.invoke(
        'cancel-appointment',
        body: {'appointment_id': widget.appointmentId},
      );

      debugPrint("CANCEL RESPONSE => ${response.data}");

      final data = response.data;

      if (data is Map) {
        if (data['error'] == 'already_cancelled') {
          if (!mounted) return;
          setState(() => isAlreadyCancelled = true);
          return;
        }
        if (data['success'] == true) {
          if (!mounted) return;
          setState(() => isCancelled = true);
          return;
        }
      }

      // fallback errore generico
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Errore nella cancellazione"), backgroundColor: Colors.red),
      );

    } catch (e) {
      debugPrint("CANCEL ERROR => $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }*/


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Annulla prenotazione")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(24),
        child: isCancelled
            ? _buildSuccess()
            : isAlreadyCancelled
            ? _buildAlreadyCancelled()
            : _buildConfirm(),
      ),
    );
  }

  Widget _buildConfirm() {
    final startTime = appointment?['start_time'] != null
        ? DateTime.parse(appointment!['start_time']).toLocal()
        : null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.warning_amber, size: 64, color: Colors.orange),
        const SizedBox(height: 24),
        const Text(
          "Vuoi annullare questa prenotazione?",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        if (appointment != null) ...[
          Text(
            "Servizio: ${appointment!['services']?['name'] ?? '-'}",
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (startTime != null)
            Text(
              "Data: ${startTime.day}/${startTime.month}/${startTime.year} "
                  "alle ${startTime.hour.toString().padLeft(2, '0')}:"
                  "${startTime.minute.toString().padLeft(2, '0')}",
              style: const TextStyle(fontSize: 16),
            ),
        ],
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: isLoading ? null : cancelAppointment,
            child: const Text(
              "Annulla prenotazione",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.check_circle, size: 64, color: Colors.green),
        SizedBox(height: 24),
        Text(
          "Prenotazione annullata",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12),
        Text(
          "La tua prenotazione è stata annullata con successo.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildAlreadyCancelled() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.info_outline, size: 64, color: Colors.grey),
        SizedBox(height: 24),
        Text(
          "Prenotazione già annullata",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12),
        Text(
          "Questa prenotazione risulta già annullata.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}