import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerService {
  final SupabaseClient supabase;

  CustomerService(this.supabase);

  // ✅ Ritorna String invece di int — UUID è sempre String
  // ✅ Cerca per phone coerentemente con public_booking_page.dart
  Future<String> getOrCreateCustomer({
    required String name,
    required String surname,
    required String email,
    required String phone,
    required String businessId,
  }) async {
    // Cerca prima per telefono — criterio principale
    final existing = await supabase
        .from('customers')
        .select()
        .eq('business_id', businessId)
        .eq('phone', phone)
        .maybeSingle();

    if (existing != null) {
      // ✅ Aggiorna i dati se il cliente esiste già
      await supabase.from('customers').update({
        'name': name,
        'surname': surname,
        'email': email,
      }).eq('id', existing['id']);

      return existing['id'].toString();
    }

    final newCustomer = await supabase.from('customers').insert({
      'name': name,
      'surname': surname,
      'email': email,
      'phone': phone,
      'business_id': businessId,
    }).select().single();

    return newCustomer['id'].toString();
  }
}


/*import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerService {
  final SupabaseClient supabase;

  CustomerService(this.supabase);

  Future<int> getOrCreateCustomer({
    required String name,
    required String surname,
    required String email,
    required String phone,
    required String businessId,
  }) async {

    final existing = await supabase
        .from('customers')
        .select()
        .eq('business_id', businessId)
        .eq('email', email)
        .maybeSingle();

    if (existing != null) {
      return existing['id'];
    }

    final newCustomer = await supabase.from('customers').insert({
      'name': name,
      'surname': surname,
      'email': email,
      'phone': phone,
      'business_id': businessId,
    }).select().single();

    return newCustomer['id'];
  }
}*/