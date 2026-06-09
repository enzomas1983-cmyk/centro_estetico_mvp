import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:intl/intl.dart';
import '../core/booking_rules.dart';

class CreateAppointmentPage extends StatefulWidget {
  final DateTime selectedDateTime;
  final bool isGuest;
  final String businessId;

  const CreateAppointmentPage({
    super.key,
    required this.selectedDateTime,
    required this.businessId,
    this.isGuest = false,
  });

  @override
  State<CreateAppointmentPage> createState() =>
      _CreateAppointmentPageState();
}

class _CreateAppointmentPageState
    extends State<CreateAppointmentPage> {

  String? _emailError;

  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> services = [];

  String? selectedService;

  bool isLoading = false;

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  // =========================================================
  // CUSTOMER SEARCH
  // =========================================================

  final TextEditingController customerSearchController =
  TextEditingController();

  final TextEditingController newNameController =
  TextEditingController();

  final TextEditingController newSurnameController =
  TextEditingController();

  final TextEditingController newPhoneController =
  TextEditingController();

  final TextEditingController newEmailController =
  TextEditingController();

  final TextEditingController newNotesController =
  TextEditingController();

  List<Map<String, dynamic>> customerResults = [];

  Map<String, dynamic>? selectedCustomer;

  bool showCustomerResults = false;

  bool showCustomerForm = false;

  bool isCreatingCustomer = false;

  bool showCreateCustomerForm = false;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    customerSearchController.dispose();
    newNameController.dispose();
    newSurnameController.dispose();
    newPhoneController.dispose();
    newEmailController.dispose();
    newNotesController.dispose();
    super.dispose();
  }



  // =========================================================
  // QUICK CREATE CUSTOMER
  // =========================================================

  Future<Map<String, dynamic>> createQuickCustomer(
      String input,
      ) async {

    final profile =
        context.read<AuthProvider>().profile;

    final businessId = widget.businessId;

    if (businessId == null) {
      throw Exception("businessId nullo");
    }

    final parts = input.trim().split(" ");

    final name =
    parts.isNotEmpty ? parts.first : input;

    final surname =
    parts.length > 1
        ? parts.sublist(1).join(" ")
        : "";

    // ==========================================
    // ANTI DUPLICATO
    // ==========================================

    if (businessId.isEmpty) {
      throw Exception("businessId mancante (customer lookup)");
    }

    final existing = await supabase
        .from('customers')
        .select()
        .eq('business_id', businessId)
        .ilike('name', name)
        .ilike('surname', surname)
        .maybeSingle();

    if (existing != null) {
      return existing;
    }

    // ==========================================
    // CREATE
    // ==========================================

    final response = await supabase
        .from('customers')
        .insert({
      'name': name,
      'surname': surname,
      'business_id': businessId,
    })
        .select()
        .single();

    return response;
  }

  // modificato il    07.06.2026

  // ✅ Passa il testo già digitato al bottom sheet
  void openCreateCustomerSheet() {
    // Splitta quello che ha scritto in nome e cognome
    final parts = customerSearchController.text.trim().split(' ');
    final preName = parts.isNotEmpty ? parts.first : '';
    final preSurname = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    // ✅ Pre-compila i controller con il testo già digitato
    newNameController.text = preName;
    newSurnameController.text = preSurname;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: _buildCustomerForm(),
          ),
        );
      },
    );
  }

  Widget _buildCustomerForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        const Text(
          "Nuovo cliente",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        TextField(
          controller: newNameController,
          decoration: const InputDecoration(labelText: "Nome *"),
        ),

        TextField(
          controller: newSurnameController,
          decoration: const InputDecoration(labelText: "Cognome *"),
        ),

        TextFormField(
          controller: newEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: "Email *",
            errorText: _emailError,
          ),
          onChanged: (v) {
            final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
            setState(() {
              _emailError = v.trim().isEmpty
                  ? null
                  : !emailRegex.hasMatch(v.trim())
                  ? "Formato email non valido (es. nome@dominio.it)"
                  : null;
            });
          },
        ),

        TextField(
          controller: newPhoneController,
          decoration: const InputDecoration(labelText: "Telefono"),
        ),

        TextField(
          controller: newNotesController,
          decoration: const InputDecoration(labelText: "Note"),
          maxLines: 2,
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveCustomerFromSheet,
            child: const Text("Salva cliente"),
          ),
        ),
      ],
    );
  }

  Future<void> _saveCustomerFromSheet() async {

    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    final email = newEmailController.text.trim();

    if (email.isNotEmpty && !emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Formato email non valido (es. nome@dominio.it)"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newNameController.text.trim().isEmpty ||
        newSurnameController.text.trim().isEmpty ||
        newEmailController.text.trim().isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Nome, cognome e email obbligatori"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final profile = context.read<AuthProvider>().profile;
      final businessId = widget.businessId;

      final created = await supabase.from('customers').insert({
        'name': newNameController.text.trim(),
        'surname': newSurnameController.text.trim(),
        'email': newEmailController.text.trim(),
        'phone': newPhoneController.text.trim(),
        'notes': newNotesController.text.trim(),
        'business_id': businessId,
      }).select().single();

      setState(() {
        selectedCustomer = created;
        customerSearchController.text =
        "${created['name']} ${created['surname']}";
      });

      Navigator.pop(context); // chiude bottom sheet

      newNameController.clear();
      newSurnameController.clear();
      newEmailController.clear();
      newPhoneController.clear();
      newNotesController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cliente creato"),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Errore: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // SEARCH CUSTOMERS
  // =========================================================

  Future<void> searchCustomers(String value) async {

    final profile =
        context.read<AuthProvider>().profile;

    final businessId = widget.businessId;

    if (businessId == null) {
      return;
    }

    if (value.isEmpty) {

      setState(() {
        customerResults = [];
        showCustomerResults = false;
      });

      return;
    }

    final response = await supabase
        .from('customers')
        .select(
      'id, name, surname, phone',
    )
        .eq('business_id', businessId)
        .or(
        'name.ilike.%$value%,'
            'surname.ilike.%$value%,'
            'phone.ilike.%$value%'
    )
        .limit(6);

    setState(() {

      customerResults =
      List<Map<String, dynamic>>.from(response);

      showCustomerResults = true;
    });
  }

  // =========================================================
  // LOAD DATA
  // =========================================================

  /*Future<void> loadData() async {

    try {

      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception("Utente non autenticato");
      }

      final profile = await supabase
          .from('profiles')
          .select('business_id')
          .eq('id', user.id)
          .single();

      final businessId = widget.businessId;

      final List<Map<String, dynamic>> s =
      List<Map<String, dynamic>>.from(
        await supabase
            .from('services')
            .select(
          'id, name, color, duration_minutes',
        )
            .eq('business_id', businessId)
            .order('name'),
      );

      if (!mounted) return;

      setState(() {

        final Map<String,
            Map<String, dynamic>> unique = {};

        for (final item in s) {
          unique[item['name']] = item;
        }

        services = unique.values.toList();
      });

    } catch (e) {

      debugPrint("LOAD ERROR => $e");
    }
  }*/

  Future<void> loadData() async {
    try {
      // ✅ businessId già disponibile da widget, nessuna query a profiles
      final businessId = widget.businessId;

      if (businessId.isEmpty) {
        throw Exception("businessId mancante");
      }

      final List<Map<String, dynamic>> s =
      List<Map<String, dynamic>>.from(
        await supabase
            .from('services')
            .select('id, name, color, duration_minutes')
            .eq('business_id', businessId)
            .order('name'),
      );

      if (!mounted) return;

      setState(() {
        // deduplicazione per nome — invariata
        final Map<String, Map<String, dynamic>> unique = {};
        for (final item in s) {
          unique[item['name']] = item;
        }
        services = unique.values.toList();
      });

    } catch (e) {
      debugPrint("LOAD ERROR => $e");
    }
  }

  // =========================================================
  // HELPERS
  // =========================================================

  String _getCustomerName() {

    if (selectedCustomer == null) {
      return '-';
    }

    return
      "${selectedCustomer!['name']} "
          "${selectedCustomer!['surname'] ?? ''}";
  }

  String _getServiceName() {

    final s = services.firstWhere(
          (e) =>
      e['id'].toString() ==
          selectedService,
      orElse: () => {},
    );

    return s['name'] ?? '-';
  }

  String get activeBusinessId {
    return widget.businessId;
  }

  String _formatDate() {

    final d = widget.selectedDateTime;

    return
      "${d.day}/${d.month}/${d.year} "
          "alle "
          "${d.hour}:${d.minute.toString().padLeft(2, '0')}";
  }

  // =========================================================
  // SAVE APPOINTMENT
  // =========================================================

  Future<void> save() async {

    // ==========================================
    // VALIDATION
    // ==========================================

    if (selectedCustomer == null) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
          Text("Seleziona un cliente"),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    if (selectedService == null) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
          Text("Seleziona un servizio"),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    setState(() => isLoading = true);

    try {

      final user =
          supabase.auth.currentUser;

      if (user == null) {
        throw Exception(
          "Utente non autenticato",
        );
      }

      final start =
          widget.selectedDateTime;

      final serviceList =
      services.where(
            (s) =>
        s['id'].toString() ==
            selectedService,
      ).toList();

      if (serviceList.isEmpty) {
        throw Exception(
          "Servizio non trovato",
        );
      }

      final service =
          serviceList.first;

      final duration =
          (service['duration_minutes']
          as int?) ??
              30;

      final end = start.add(
        Duration(minutes: duration),
      );

      debugPrint("==============");
      debugPrint("BOOKING CHECK");
      debugPrint("START => $start");
      debugPrint("END => $end");
      debugPrint("DURATION => $duration");
      debugPrint("==============");

      final blocked = BookingRules.isBlocked(
        start: start,
        end: end,
      );

      if (blocked) {

        final reason = BookingRules.reason(
          start: start,
          end: end,
        );

        debugPrint("BOOKING BLOCKED => $reason");

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              reason ?? "Slot non disponibile",
            ),
            backgroundColor: Colors.red,
          ),
        );

        setState(() => isLoading = false);

        return;
      }

      final profile =
          context.read<AuthProvider>()
              .profile;

      final businessId = widget.businessId;

      // ==========================================
      // INSERT APPOINTMENT
      // ==========================================

      debugPrint("🔥 CREATE APPOINTMENT PAGE ACTIVE");
      debugPrint("GUEST BUSINESS ID => ${widget.businessId}");

      final inserted = await supabase
          .from('appointments')
          .insert({

        'user_id': user.id,

        'business_id': businessId,

        'customer_id':
        selectedCustomer!['id'],

        'service_id':
        selectedService,

        /*'start_time':
        start.toIso8601String(),

        'end_time':
        end.toIso8601String(),*/

        'start_time': start.toUtc().toIso8601String(),

        'end_time': end.toUtc().toIso8601String(),


        'status': 'scheduled',

      })
          .select()
          .single();

      // ==========================================
      // EMAIL
      // ==========================================

      /*final customerData =
      await supabase
          .from('customers')
          .select('email,name')
          .eq(
        'id',
        selectedCustomer!['id'],
      )
          .single();

      final customerEmail =
          customerData['email'] ?? '';

      await supabase.functions.invoke(
        'send-booking-email',
        body: {
          'appointment_id':
          inserted['id'],
        },
      );*/

      // ✅ Dopo — invocata solo se c'è un'email
      final customerData = await supabase
          .from('customers')
          .select('email, name')
          .eq('id', selectedCustomer!['id'])
          .single();

      final customerEmail = (customerData['email'] as String?)?.trim() ?? '';

      if (customerEmail.isNotEmpty) {
        await supabase.functions.invoke(
          'send-booking-email',
          body: {'appointment_id': inserted['id']},
        );
      }

      // ==========================================
      // SUCCESS
      // ==========================================

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          backgroundColor: Colors.green,
          content: Text(

            customerEmail.isNotEmpty
                ? "Appuntamento creato. Mail inviata a $customerEmail"
                : "Appuntamento creato correttamente",
          ),
        ),
      );

      Navigator.pop(context, true);

    } catch (e) {

      debugPrint(
        "INSERT ERROR => $e",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content: Text("Errore: $e"),
          backgroundColor: Colors.red,
        ),
      );

    } finally {

      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "Nuovo appuntamento",
        ),
      ),

        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ======================================
            // CUSTOMER SEARCH
            // ======================================

            TextField(

              controller:
              customerSearchController,

              decoration:
              const InputDecoration(
                labelText: "Cliente",
                prefixIcon:
                Icon(Icons.person_search),
              ),

              onChanged: (value) async {

                setState(() {
                  selectedCustomer = null;
                });

                await searchCustomers(value);
              },
            ),

            // ======================================
            // RESULTS
            // ======================================

            if (showCustomerResults)

              Container(

                constraints:
                const BoxConstraints(
                  maxHeight: 220,
                ),

                child: ListView.builder(

                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),

                  itemCount:
                  customerResults.length,

                  itemBuilder:
                      (context, index) {

                    final c =
                    customerResults[index];

                    return ListTile(

                      leading:
                      const Icon(Icons.person),

                      title: Text(
                        "${c['name']} "
                            "${c['surname']}",
                      ),

                      subtitle:
                      Text(c['phone'] ?? ''),

                      onTap: () {

                        setState(() {

                          selectedCustomer = c;

                          showCreateCustomerForm = false;

                          showCustomerResults = false;

                          customerSearchController.text =
                          "${c['name']} ${c['surname']}";
                        });
                      },
                    );
                  },
                ),
              ),

            // ======================================
            // QUICK CREATE
            // ======================================

            if (customerSearchController.text.length > 2 &&
                customerResults.isEmpty &&
                selectedCustomer == null &&
                !showCreateCustomerForm)


              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Crea nuovo cliente"),
                onPressed: openCreateCustomerSheet,
              ),



            const SizedBox(height: 20),

            // ======================================
            // HEADER
            // ======================================


            const SizedBox(height: 10),

            // ======================================
            // SERVICE
            // ======================================

            DropdownButtonFormField<String>(

              value: selectedService,

              items: services.map((s) {

                return DropdownMenuItem(

                  value:
                  s['id'].toString(),

                  child:
                  Text(s['name'] ?? ''),
                );

              }).toList(),

              onChanged: (v) {

                setState(() {
                  selectedService = v;
                });
              },

              decoration:
              const InputDecoration(
                labelText: "Servizio",
              ),
            ),

            // ======================================
            // PREVIEW
            // ======================================

            Container(

              margin:
              const EdgeInsets.only(top: 20),

              padding:
              const EdgeInsets.all(12),

              decoration: BoxDecoration(
                color:
                const Color(0xFFF1F5F9),

                borderRadius:
                BorderRadius.circular(12),
              ),

              child: Column(

                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  const Text(
                    "Preview appuntamento",
                    style: TextStyle(
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Cliente: ${_getCustomerName()}",
                  ),

                  Text(
                    "Servizio: ${_getServiceName()}",
                  ),

                  Text(
                    "Data: ${_formatDate()}",
                  ),
                ],
              ),
            ),

            //const Spacer(),

            // ======================================
            // SAVE
            // ======================================

            SizedBox(

              width: double.infinity,

              child: ElevatedButton(

                onPressed:
                isLoading ? null : save,

                child: isLoading

                    ? const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                )

                    : const Text(
                  "Salva appuntamento",
                ),
              ),
            ),
          ],
            ),
          ),
        ),
    );
  }
}