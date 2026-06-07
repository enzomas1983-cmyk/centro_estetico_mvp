import 'package:flutter/material.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.error_outline, size: 80),
            SizedBox(height: 20),
            Text(
              "Pagina non trovata",
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}