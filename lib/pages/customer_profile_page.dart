/*import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerProfilePage extends StatefulWidget {
  final String customerId;
  final String customerName;

  const CustomerProfilePage({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> appointments = [];
  Map<String, dynamic>? customer;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> showEditCustomerDialog() async {
    final nameController =
    TextEditingController(text: customer?['name'] ?? '');
    final surnameController =
    TextEditingController(text: customer?['surname'] ?? '');

    final emailController =
    TextEditingController(text: customer?['email'] ?? '');

    final phoneController =
    TextEditingController(text: customer?['phone'] ?? '');

    final notesController =
    TextEditingController(text: customer?['notes'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Modifica cliente"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Nome"),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Telefono"),
              ),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: "Note"),
              ),
              TextField(
                controller: surnameController,
                decoration: const InputDecoration(
                  labelText: "Cognome",
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
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
                await supabase.from('customers').update({
                  'name': nameController.text.trim(),
                  'surname': surnameController.text.trim(),
                  'email': emailController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'notes': notesController.text.trim(),
                }).eq('id', widget.customerId);

                if (mounted) {
                  Navigator.pop(context);
                  loadData();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Cliente aggiornato")),
                  );
                }
              },
              child: const Text("Salva"),
            ),
          ],
        );
      },
    );
  }

  Future<void> loadData() async {
    try {
      // 👤 CUSTOMER
      final customerData = await supabase
          .from('customers')
          .select()
          .eq('id', widget.customerId)
          .single();

      // 📅 APPOINTMENTS
      final appointmentsData = await supabase
          .from('appointments')
          .select('*, services(name)')
          .eq('customer_id', widget.customerId)
          .order('start_time', ascending: false);

      if (!mounted) return;
      setState(() {
        customer = customerData;
        appointments = List<Map<String, dynamic>>.from(appointmentsData);
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Errore load customer: $e");
      setState(() => isLoading = false);
    }
  }

  int get totalVisits => appointments.length;

  int calculateMonthlyFrequency() {
    final now = DateTime.now();

    return appointments.where((a) {
      final date = DateTime.parse(a['start_time']);
      return date.month == now.month && date.year == now.year;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customerName),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 👤 INFO CLIENTE
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text("Visite totali: $totalVisits"),
                  subtitle: Text(
                    "Questo mese: ${calculateMonthlyFrequency()}",
                  ),
                ),
              ),
            ),

            // 📞 INFO ANAGRAFICA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${customer?['name'] ?? ''} ${customer?['surname'] ?? ''}",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text("📞 ${customer?['phone'] ?? 'Nessun telefono'}"),

                  const SizedBox(height: 10),

                  Text(
                    "✉️ ${customer?['email'] ?? 'Nessuna email'}",
                  ),

                  const SizedBox(height: 10),

                  Text("📝 Note: ${customer?['notes'] ?? 'Nessuna nota'}"),

                  ElevatedButton.icon(
                    onPressed: showEditCustomerDialog,
                    icon: const Icon(Icons.edit),
                    label: const Text("Modifica cliente"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Appuntamenti",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // 📅 LISTA APPUNTAMENTI
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final a = appointments[index];
                final date = DateTime.parse(a['start_time']).toLocal();

                return ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(a['services']?['name'] ?? 'Servizio'),
                  /*subtitle: Text(
                    "${date.day}/${date.month}/${date.year} - ${date.hour}:00",
                  ),*/

                  subtitle: Text(
                    "${date.day}/${date.month}/${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}",
                  ),

                );
              },
            ),
          ],
        ),
      ),
    );
  }
}*/


import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerProfilePage extends StatefulWidget {
  final String customerId;
  final String customerName;

  const CustomerProfilePage({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> appointments = [];
  Map<String, dynamic>? customer;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ── Validatori condivisi ─────────────────────────────────────

  String? _validateName(String? v, String fieldLabel) {
    if (v == null || v.trim().isEmpty) return "$fieldLabel obbligatorio";
    if (v.trim().length < 2) return "Minimo 2 caratteri";
    if (!RegExp(r"^[a-zA-ZàáâäãåèéêëìíîïòóôöùúûüÀÁÂÄÃÅÈÉÊËÌÍÎÏÒÓÔÖÙÚÛÜ '\-]+$")
        .hasMatch(v.trim())) return "Solo lettere e spazi";
    return null;
  }

  String? _validateEmail(String? v, {bool required = false}) {
    if (v == null || v.trim().isEmpty) {
      return required ? "Email obbligatoria" : null;
    }
    if (!RegExp(r"^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$")
        .hasMatch(v.trim())) return "Email non valida";
    return null;
  }

  String? _validatePhone(String? v, {bool required = false}) {
    if (v == null || v.trim().isEmpty) {
      return required ? "Telefono obbligatorio" : null;
    }
    final digits = v.trim().replaceAll(RegExp(r'\s+'), '');
    if (!RegExp(r'^[0-9]+$').hasMatch(digits)) return "Solo numeri";
    if (digits.length != 10) return "Inserisci 10 cifre (es. 3451234567)";
    return null;
  }

  // ── Edit dialog ──────────────────────────────────────────────

  Future<void> showEditCustomerDialog() async {
    final formKey = GlobalKey<FormState>();

    final nameController =
    TextEditingController(text: customer?['name'] ?? '');
    final surnameController =
    TextEditingController(text: customer?['surname'] ?? '');
    final emailController =
    TextEditingController(text: customer?['email'] ?? '');
    final phoneController =
    TextEditingController(text: customer?['phone'] ?? '');
    final notesController =
    TextEditingController(text: customer?['notes'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Modifica cliente"),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // NOME
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Nome *"),
                    validator: (v) => _validateName(v, "Nome"),
                  ),

                  const SizedBox(height: 8),

                  // COGNOME
                  TextFormField(
                    controller: surnameController,
                    decoration: const InputDecoration(labelText: "Cognome *"),
                    validator: (v) => _validateName(v, "Cognome"),
                  ),

                  const SizedBox(height: 8),

                  // EMAIL
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: "Email"),
                    validator: (v) => _validateEmail(v, required: false),
                  ),

                  const SizedBox(height: 8),

                  // TELEFONO
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: "Telefono"),
                    validator: (v) => _validatePhone(v, required: false),
                  ),

                  const SizedBox(height: 8),

                  // NOTE
                  TextFormField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: "Note"),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annulla"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                await supabase.from('customers').update({
                  'name':    nameController.text.trim(),
                  'surname': surnameController.text.trim(),
                  'email':   emailController.text.trim(),
                  'phone':   phoneController.text.trim(),
                  'notes':   notesController.text.trim(),
                }).eq('id', widget.customerId);

                if (!context.mounted) return;
                Navigator.pop(context);
                loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Cliente aggiornato")),
                );
              },
              child: const Text("Salva"),
            ),
          ],
        );
      },
    );
  }

  // ── Load ─────────────────────────────────────────────────────

  Future<void> loadData() async {
    try {
      final customerData = await supabase
          .from('customers')
          .select()
          .eq('id', widget.customerId)
          .single();

      final appointmentsData = await supabase
          .from('appointments')
          .select('*, services(name)')
          .eq('customer_id', widget.customerId)
          .order('start_time', ascending: false);

      if (!mounted) return;
      setState(() {
        customer     = customerData;
        appointments = List<Map<String, dynamic>>.from(appointmentsData);
        isLoading    = false;
      });
    } catch (e) {
      debugPrint("Errore load customer: $e");
      setState(() => isLoading = false);
    }
  }

  int get totalVisits => appointments.length;

  int calculateMonthlyFrequency() {
    final now = DateTime.now();
    return appointments.where((a) {
      final date = DateTime.parse(a['start_time']);
      return date.month == now.month && date.year == now.year;
    }).length;
  }

  // ── UI ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customerName),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // STATS
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text("Visite totali: $totalVisits"),
                  subtitle: Text(
                    "Questo mese: ${calculateMonthlyFrequency()}",
                  ),
                ),
              ),
            ),

            // ANAGRAFICA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${customer?['name'] ?? ''} ${customer?['surname'] ?? ''}",
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text("📞 ${customer?['phone'] ?? 'Nessun telefono'}"),
                  const SizedBox(height: 10),
                  Text("✉️ ${customer?['email'] ?? 'Nessuna email'}"),
                  const SizedBox(height: 10),
                  Text("📝 Note: ${customer?['notes'] ?? 'Nessuna nota'}"),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: showEditCustomerDialog,
                    icon: const Icon(Icons.edit),
                    label: const Text("Modifica cliente"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Appuntamenti",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            // LISTA APPUNTAMENTI
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final a    = appointments[index];
                final date =
                DateTime.parse(a['start_time']).toLocal();
                return ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(a['services']?['name'] ?? 'Servizio'),
                  subtitle: Text(
                    "${date.day}/${date.month}/${date.year} - "
                        "${date.hour.toString().padLeft(2, '0')}:"
                        "${date.minute.toString().padLeft(2, '0')}",
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
