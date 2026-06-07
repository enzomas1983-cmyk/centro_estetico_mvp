// #### al momento non è attiva ####

import 'package:flutter/material.dart';
//import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PublicLandingPage extends StatefulWidget {

  final String slug;

  const PublicLandingPage({
    super.key,
    required this.slug,
  });

  @override
  State<PublicLandingPage> createState() =>
      _PublicLandingPageState();
}

class _PublicLandingPageState
    extends State<PublicLandingPage> {

  Map<String, dynamic>? business;

  @override
  void initState() {
    super.initState();
    loadBusiness();
  }

  Future<void> loadBusiness() async {

    debugPrint("📡 CHIAMO SUPABASE con slug: ${widget.slug}");
    final response = await Supabase.instance.client
        .from('businesses')
        .select()
        .eq('slug', widget.slug)
        .maybeSingle();

    debugPrint("📦 RISPOSTA SUPABASE: $response");
    setState(() {
      business = response;
    });
  }

  @override
  Widget build(BuildContext context) {

    debugPrint("🔥 LANDING APERTA - slug: ${widget.slug}");
    debugPrint("🖥️ BUILD LANDING - business = $business");


    if (business == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final color = business!['primary_color'] ?? '#41B13D';

    return Scaffold(

      backgroundColor: Color(
        int.parse(
          color.replaceFirst('#', '0xff'),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(

          padding: const EdgeInsets.all(24),

          child: Column(

            children: [

              const SizedBox(height: 40),

              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.store,
                  size: 50,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                business!['name'] ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                business!['address'] ?? '',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 40),

              buildButton(
                title: 'PRENOTA ONLINE',
                icon: Icons.calendar_month,
                onTap: () {

                  Navigator.pushNamed(
                    context,
                    '/book/${business!['id']}',
                  );
                },
              ),

              buildButton(
                title: 'CHIAMA',
                icon: Icons.phone,
                onTap: () {},
              ),

              buildButton(
                title: 'INSTAGRAM',
                icon: Icons.camera_alt,
                onTap: () {},
              ),

              buildButton(
                title: 'FACEBOOK',
                icon: Icons.facebook,
                onTap: () {},
              ),

              const SizedBox(height: 40),

              const Text(
                'Powered by YourApp',
                style: TextStyle(
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),

      child: Material(
        color: Colors.white,

        borderRadius: BorderRadius.circular(24),

        child: InkWell(
          borderRadius: BorderRadius.circular(24),

          onTap: onTap,

          child: Container(

            padding: const EdgeInsets.symmetric(
              vertical: 22,
              horizontal: 20,
            ),

            child: Row(
              children: [

                Icon(icon),

                const SizedBox(width: 20),

                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,

                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}