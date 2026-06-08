
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/app_config.dart';

class BusinessQrPage extends StatelessWidget {
  final String businessId;

  const BusinessQrPage({
    super.key,
    required this.businessId,
  });

  SupabaseClient get supabase => Supabase.instance.client;

  // ✅ slug rimosso — non veniva usato nell'URL
  // ✅ publicUrl da AppConfig
  String get publicUrl => AppConfig.bookingUrl(businessId);

  Future<void> printQr(String link) async {
    final doc = pw.Document();

    final qr = QrPainter(
      data: link,
      version: QrVersions.auto,
      gapless: true,
    );

    final image = await qr.toImageData(600);
    if (image == null) return;

    doc.addPage(
      pw.Page(
        build: (_) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                "Prenota online",
                style: const pw.TextStyle(fontSize: 24),
              ),
              pw.SizedBox(height: 20),
              pw.Image(pw.MemoryImage(image.buffer.asUint8List())),
              pw.SizedBox(height: 20),
              pw.Text(link),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
    );
  }

  // ✅ Invio email con feedback utente
  Future<void> sendQrEmail(BuildContext context) async {
    try {
      await supabase.functions.invoke(
        'send-qr-email',
        body: {
          'business_id': businessId,
          'link': publicUrl,
        },
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Email inviata con successo"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Errore invio email: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("QR Prenotazioni"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // ✅ FutureBuilder rimosso — publicUrl è ora sincrono
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Scansiona per prenotare",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: QrImageView(
                    data: publicUrl,
                    version: QrVersions.auto,
                    size: 250,
                  ),
                ),

                const SizedBox(height: 30),

                SelectableText(
                  publicUrl,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 24),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text("Copia"),
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: publicUrl),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Link copiato")),
                          );
                        }
                      },
                    ),

                    OutlinedButton.icon(
                      icon: const Icon(Icons.email, size: 18),
                      label: const Text("Email"),
                      // ✅ feedback utente
                      onPressed: () => sendQrEmail(context),
                    ),

                    OutlinedButton.icon(
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text("Stampa"),
                      onPressed: () => printQr(publicUrl),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}