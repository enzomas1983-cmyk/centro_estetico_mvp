class CustomerStats {
  // ✅ Classe statica — nessuna istanza necessaria
  CustomerStats._(); // costruttore privato

  // ✅ totalVisits al posto di calculateFrequency ridondante
  static int totalVisits(
      List<Map<String, dynamic>> appointments,
      ) =>
      appointments.length;

  // ✅ Lista tipizzata
  static int monthlyFrequency(
      List<Map<String, dynamic>> appointments,
      ) {
    final now = DateTime.now();
    return appointments.where((a) {
      final date = DateTime.parse(a['start_time']);
      return date.month == now.month && date.year == now.year;
    }).length;
  }
}