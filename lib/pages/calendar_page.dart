import 'package:flutter/material.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final List<Map<String, dynamic>> appointments = [
    {
      "title": "Cliente A",
      "hour": 10,
      "duration": 1,
      "color": Colors.blue,
    },
    {
      "title": "Cliente B",
      "hour": 12,
      "duration": 2,
      "color": Colors.green,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendario"),
      ),
      body: ListView.builder(
        itemCount: 13, // 8-20
        itemBuilder: (context, index) {
          final hour = index + 8;

          final dayAppointments = appointments
              .where((a) => a["hour"] == hour)
              .toList();

          return Container(
            height: 80,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text("$hour:00"),
                ),

                Expanded(
                  child: Stack(
                    children: dayAppointments.map((a) {

                      final customer = a['customers']?['name'];
                      final service = a['services']?['name'];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: a["color"],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          customer != null && service != null
                              ? "$customer - $service"
                              : a["title"] ?? "Appuntamento",
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}