import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'customer_profile_page.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> customers = [];

  bool isLoading = false;

  //String? businessId;

  @override
  void initState() {
    super.initState();

    final profile = context.read<AuthProvider>().profile;

    final bizId = profile?.businessId;

    if (bizId == null) {
      debugPrint("BUSINESS ID NULL in CustomerListPage");
      return;
    }

    loadCustomers();
  }

  // ---------------- LOAD ----------------

  Future<void> loadCustomers() async {
    final profile = context.read<AuthProvider>().profile;

    final businessId = profile?.businessId;

    if (businessId == null) {
      debugPrint("Business ID nullo");
      return;
    }

    final response = await supabase
        .from('customers')
        .select()
        .eq('business_id', businessId);

    setState(() {
      customers = List<Map<String, dynamic>>.from(response);
    });
  }

  // ---------------- ADD ----------------

  Future<void> showAddCustomerDialog() async {
    final nameController = TextEditingController();
    final surnameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Center(
                      child: Text(
                        "Nuovo cliente",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Nome *",
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: surnameController,
                      decoration: const InputDecoration(
                        labelText: "Cognome *",
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "Email *",
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Telefono",
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Note",
                      ),
                    ),

                    const SizedBox(height: 20),

                    const SizedBox(height: 24),

                    Row(
                      children: [

                        // ❌ ANNULLA
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text("Annulla"),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // ✅ SALVA
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),

                            child: const Text("Salva cliente"),

                            onPressed: () async {

                              final name = nameController.text.trim();
                              final surname = surnameController.text.trim();
                              final email = emailController.text.trim();
                              final phone = phoneController.text.trim();
                              final notes = notesController.text.trim();

                              // 🔴 VALIDAZIONE OBBLIGATORIA
                              if (name.isEmpty || surname.isEmpty || email.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Nome, cognome ed email sono obbligatori"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              // 🔵 VALIDAZIONE EMAIL
                              final emailRegex = RegExp(
                                r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
                              );

                              if (!emailRegex.hasMatch(email)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Email non valida"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              try {
                                final profile = context.read<AuthProvider>().profile;
                                final businessId = profile?.businessId;

                                if (businessId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Business non valido"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                // continua logica...

                                await supabase.from('customers').insert({
                                  'name': name,
                                  'surname': surname,
                                  'email': email,
                                  'phone': phone,
                                  'notes': notes,
                                  'business_id': businessId,
                                });

                                if (!mounted) return;

                                Navigator.pop(context);

                                await loadCustomers();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Cliente creato con successo"),
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
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------- DELETE ----------------

  Future<void> deleteCustomer(String id) async {
    try {
      final profile = context.read<AuthProvider>().profile;
      final businessId = profile?.businessId;

      if (businessId == null) {
        debugPrint("Business ID nullo");
        return;
      }

      await supabase
          .from('customers')
          .delete()
          .eq('id', id)
          .eq('business_id', businessId);

    } catch (e) {
      debugPrint("DELETE ERROR => $e");
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Clienti"),
        /*actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: showAddCustomerDialog,
          ),
        ],*/

        actions: [

          Padding(
            padding: const EdgeInsets.only(right: 12),

            child: ElevatedButton.icon(

              onPressed: showAddCustomerDialog,

              icon: const Icon(
                Icons.person_add_alt_1,
                size: 18,
              ),

              label: const Text("Nuovo cliente"),

              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],

      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : customers.isEmpty
          ? const Center(child: Text("Nessun cliente"))
          : ListView.builder(
        itemCount: customers.length,
        itemBuilder: (context, index) {
          final customer = customers[index];

          return ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),

            title: Text(
              "${customer['name'] ?? ''} ${customer['surname'] ?? ''}",
            ),

            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer['phone'] ?? ''),
                Text(customer['email'] ?? ''),
              ],
            ),

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CustomerProfilePage(
                    customerId: customer['id'],
                    customerName: customer['name'],
                  ),
                ),
              );
            },

            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),

              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Elimina cliente"),
                    content: const Text(
                      "Sei sicuro di voler eliminare questo cliente?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, false),
                        child: const Text("Annulla"),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(context, true),
                        child: const Text("Elimina"),
                      ),
                    ],
                  ),
                );

                if (confirm != true) return;

                await deleteCustomer(customer['id'].toString());

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Cliente eliminato"),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}