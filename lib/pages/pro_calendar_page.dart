import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../models/appointment_model.dart';
import '../providers/auth_provider.dart';
import 'create_appointment_page.dart';
import 'customer_list_page.dart';
import 'customer_profile_page.dart';
import 'login_page.dart';
import 'business_qr_page.dart';
import '../core/booking_rules.dart';
import 'dart:async';

class ProCalendarPage extends StatefulWidget {
  const ProCalendarPage({super.key});

  @override
  State<ProCalendarPage> createState() =>
      _ProCalendarPageState();
}

class _ProCalendarPageState
    extends State<ProCalendarPage> {

  // Aggiungi questa variabile di stato in cima alla classe
  String? _loadedBusinessId;

  // Aggiungi questa variabile in cima alla classe
  late List<TimeRegion> _specialRegions;

  // ✅ Fix race condition realtime
  bool _isLoadingAppointments = false;

  // Aggiungi in cima alla classe
  Timer? _refreshTimer;

  final supabase = Supabase.instance.client;

  final CalendarController _calendarController =
  CalendarController();

  List<AppointmentModel> _appointments = [];

  late AppointmentDataSource _calendarDataSource;

  RealtimeChannel? _channel;

  CalendarView _view = CalendarView.week;

  DateTime _focusedDay = DateTime.now();

  // =========================================================
  // INIT
  // =========================================================

  /*@override
  void initState() {
    super.initState();

    _calendarDataSource =
        AppointmentDataSource(_appointments);

    _calendarController.view = _view;
    _calendarController.displayDate = _focusedDay;

    subscribeRealtime();
  }*/

  /*@override
  void initState() {
    super.initState();

    // ✅ Calcolata una volta, mai più rieseguita
    _specialRegions = _getSpecialRegions();

    _calendarDataSource = AppointmentDataSource(_appointments);
    _calendarController.view = _view;
    _calendarController.displayDate = _focusedDay;
    subscribeRealtime();
  }*/

  @override
  void initState() {
    super.initState();
    _specialRegions = _getSpecialRegions();
    _calendarDataSource = AppointmentDataSource(_appointments);
    _calendarController.view = _view;
    _calendarController.displayDate = _focusedDay;
    subscribeRealtime();
    _startRefreshTimer(); // ✅ aggiunto
  }

// ✅ Refresh ogni 30 secondi come fallback
  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) {
        if (mounted) loadAppointments();
      },
    );
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _refreshTimer?.cancel(); // ✅ cancella il timer
    super.dispose();
  }

  /*@override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final profile =
        context.watch<AuthProvider>().profile;

    if (profile != null &&
        _appointments.isEmpty) {

      loadAppointments();
    }
  }*/

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final profile = context.watch<AuthProvider>().profile;

    // ✅ Ricarica solo se il businessId è cambiato (o è il primo caricamento)
    if (profile != null && profile.businessId != _loadedBusinessId) {
      _loadedBusinessId = profile.businessId;
      loadAppointments();
    }
  }

  /*@override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }*/


  // ✅ Versione corretta di _getSpecialRegions()
  List<TimeRegion> _getSpecialRegions() {
    final List<TimeRegion> regions = [];
    final now = DateTime.now();

    for (int i = -365; i < 365; i++) {
      final day = now.add(Duration(days: i));
      final isSunday = day.weekday == DateTime.sunday;
      final isPast = day.isBefore(DateTime(now.year, now.month, now.day));
      final isToday = day.year == now.year &&
          day.month == now.month &&
          day.day == now.day;

      // ✅ Domenica — priorità su tutto, passato o futuro
      if (isSunday) {
        regions.add(
          TimeRegion(
            startTime: DateTime(day.year, day.month, day.day, 0, 0),
            endTime: DateTime(day.year, day.month, day.day, 23, 59),
            color: Colors.yellow.withOpacity(0.3),
            enablePointerInteraction: false,
            text: 'CHIUSO',
          ),
        );
        continue; // ✅ salta le altre regioni per questo giorno
      }

      // ✅ Giorno passato (non domenica) — blocca tutto il giorno
      if (isPast) {
        regions.add(
          TimeRegion(
            startTime: DateTime(day.year, day.month, day.day, 0, 0),
            endTime: DateTime(day.year, day.month, day.day, 23, 59),
            color: Colors.grey.withOpacity(0.25),
            enablePointerInteraction: false,
            text: 'PASSATO',
          ),
        );
        continue; // ✅ salta pausa pranzo per giorni passati
      }

      // ✅ Oggi — blocca solo fino ad adesso
      if (isToday) {
        regions.add(
          TimeRegion(
            startTime: DateTime(day.year, day.month, day.day, 0, 0),
            endTime: now,
            color: Colors.grey.withOpacity(0.25),
            enablePointerInteraction: false,
            text: 'PASSATO',
          ),
        );
      }

      // ✅ Pausa pranzo — solo giorni futuri e oggi (non domenica, non passato)
      regions.add(
        TimeRegion(
          startTime: DateTime(day.year, day.month, day.day, 13, 0),
          endTime: DateTime(day.year, day.month, day.day, 14, 0),
          color: Colors.grey.withOpacity(0.3),
          enablePointerInteraction: false,
          text: 'Pausa pranzo',
        ),
      );
    }

    return regions;
  }


  /*List<TimeRegion> _getSpecialRegions() {

    final List<TimeRegion> regions = [];

    final now = DateTime.now();

    // prossimi 30 giorni
    for (int i = 0; i < 365; i++) {

      final day = now.add(Duration(days: i));

      final today = DateTime.now();

      final isToday =
              day.year == today.year &&
              day.month == today.month &&
              day.day == today.day;

      if (isToday) {

        regions.add(
          TimeRegion(
            startTime: DateTime(
              day.year,
              day.month,
              day.day,
              0,
              0,
            ),

            endTime: now, // ok: blocca fino ad adesso
            color: Colors.grey.withOpacity(0.25),
            enablePointerInteraction: false,
            text: 'PASSATO',
          ),
        );
      }


      //final day = now.add(Duration(days: i));

      // =========================
      // DOMENICA CHIUSO
      // =========================

      if (day.weekday == DateTime.sunday) {

        regions.add(
          TimeRegion(
            startTime: DateTime(
              day.year,
              day.month,
              day.day,
              0,
              0,
            ),

            endTime: DateTime(
              day.year,
              day.month,
              day.day,
              23,
              59,
            ),

            color: Colors.yellow.withOpacity(0.3),

            enablePointerInteraction: false,

            text: 'CHIUSO',
          ),
        );
      }

      // =========================
      // PAUSA PRANZO
      // =========================

      final isSunday = day.weekday == DateTime.sunday;

      if (!isSunday) {
        regions.add(
          TimeRegion(
            startTime: DateTime(
              day.year,
              day.month,
              day.day,
              13,
              0,
            ),
            endTime: DateTime(
              day.year,
              day.month,
              day.day,
              14,
              0,
            ),
            color: Colors.grey.withOpacity(0.3),
            enablePointerInteraction: false,
            text: 'Pausa pranzo',
          ),
        );
      }
    }

    return regions;
  }*/

  List<DateTime> _getBlockedDates() {
    final now = DateTime.now().toUtc();

    final List<DateTime> blocked = [];

    // blocchiamo solo la giornata corrente prima di "now"
    final dayStart = DateTime.utc(
      now.year,
      now.month,
      now.day,
      0,
      0,
    );

    for (int i = 0; i < 24; i++) {
      final slot = dayStart.add(Duration(minutes: i * 30));

      if (!slot.isAfter(now)) {
        blocked.add(slot);
      }
    }

    return blocked;
  }

  List<DateTime> _getPastDates() {
    final now = DateTime.now();

    final List<DateTime> days = [];

    // blocchiamo solo giorni passati (non ore future di oggi)
    for (int i = 0; i < 365; i++) {
      final d = now.subtract(Duration(days: i + 1));

      days.add(DateTime(d.year, d.month, d.day));
    }

    return days;
  }

  // =========================================================
  // LOAD APPOINTMENTS
  // =========================================================

  // ✅ FIX 3 — Guard per evitare query parallele
  //bool _isLoadingAppointments = false;

  Future<void> loadAppointments() async {
    // Se un fetch è già in corso, non ne avviamo un altro
    if (_isLoadingAppointments) return;

    final profile = context.read<AuthProvider>().profile;
    final businessId = profile?.businessId;

    if (businessId == null) {
      debugPrint("❌ BUSINESS ID NULL");
      return;
    }

    _isLoadingAppointments = true;

    try {
      final data = await supabase
          .from('appointments')
          .select('*, customers(name), services(name, color, duration_minutes)')
          .eq('business_id', businessId)
          .order('start_time');

      final result = (data as List)
          .map((e) => AppointmentModel.fromJson(e))
          .toList();

      debugPrint("APPOINTMENTS LOADED => ${result.length}");

      if (!mounted) return;

      setState(() {
        _appointments = result;
        _calendarDataSource = AppointmentDataSource(result);
      });
    } catch (e) {
      debugPrint("LOAD APPOINTMENTS ERROR => $e");
    } finally {
      _isLoadingAppointments = false;
    }
  }

// ✅ FIX 3 — Realtime riusa loadAppointments() invece di duplicare la query
  /*void subscribeRealtime() {
    _channel = supabase
        .channel('appointments-realtime')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'appointments',
      callback: (payload) async {
        if (!mounted) return;
        // Nessuna query duplicata, nessuna race condition
        await loadAppointments();
      },
    )
        .subscribe();
  }*/


  void subscribeRealtime() {
    final businessId = context.read<AuthProvider>().profile?.businessId;
    if (businessId == null) return;

    _channel = supabase
        .channel('appointments-$businessId') // ✅ canale univoco per business
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'appointments',
      callback: (payload) async {
        if (!mounted) return;
        await loadAppointments(); // ✅ già filtra per business_id internamente
      },
    )
        .subscribe();
  }

  /*Future<void> loadAppointments() async {
    final profile = context.read<AuthProvider>().profile;

    final businessId = profile?.businessId;

    if (businessId == null) {
      debugPrint("Business ID nullo");
      return;
    }

    final String? currentBusinessId =
        context.read<AuthProvider>().profile?.businessId;

    if (currentBusinessId == null) {
      debugPrint("❌ BUSINESS ID NULL");
      return;
    }

    final data = await supabase
        .from('appointments')
        .select('*, customers(name), services(name, color, duration_minutes)')
        .eq('business_id', currentBusinessId)
        .order('start_time');

    final result = (data as List)
        .map((e) => AppointmentModel.fromJson(e))
        .toList();

    debugPrint("APPOINTMENTS LOADED => ${result.length}");

    if (!mounted) return;

    setState(() {
      _appointments = result;
      _calendarDataSource = AppointmentDataSource(result);
    });
  }

  // =========================================================
  // REALTIME
  // =========================================================

  void subscribeRealtime() {
    _channel = supabase
        .channel('appointments-realtime')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'appointments',
      callback: (payload) async {
        if (!mounted) return;

        final data = await supabase
            .from('appointments')
            .select('*, customers(name), services(name, color, duration_minutes)')
            .eq('business_id', context.read<AuthProvider>().profile!.businessId!)
            .order('start_time');

        final result = (data as List)
            .map((e) => AppointmentModel.fromJson(e))
            .toList();

        setState(() {
          _appointments = result;
          _calendarDataSource = AppointmentDataSource(result);
        });
      },
    )
        .subscribe();
  }*/




  // =========================================================
  // DELETE
  // =========================================================

  Future<void> deleteAppointment(String id) async {
    try {
      debugPrint("DELETE START => $id");

      await supabase
          .from('appointments')
          .delete()
          .eq('id', id);

      debugPrint("DELETE DONE");

      if (!mounted) return;

      await Future.delayed(Duration(milliseconds: 100)); // 👈 importante

      await loadAppointments();
    } catch (e) {
      debugPrint("DELETE ERROR => $e");
    }
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> logout() async {

    final confirm =
    await showDialog<bool>(
      context: context,

      builder: (_) => AlertDialog(

        title: const Text(
          "Conferma logout",
        ),

        content: const Text(
          "Vuoi davvero uscire?",
        ),

        actions: [

          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),

            child: const Text("Annulla"),
          ),

          ElevatedButton(
            style:
            ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),

            onPressed: () =>
                Navigator.pop(context, true),

            child: const Text("Esci"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await supabase.auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,

      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),

          (route) => false,
    );
  }

  // =========================================================
  // ROLE LABEL
  // =========================================================

  String _getRoleLabel(String? role) {

    switch (role) {

      case 'admin':
        return 'Admin 👑';

      case 'operator':
        return 'Operatore 💼';

      default:
        return 'Utente';
    }
  }

  // =========================================================
  // VIEW BUTTON
  // =========================================================

  Widget _buildViewButton(
      String label,
      CalendarView view,
      ) {

    final isSelected = _view == view;

    return Expanded(
      child: GestureDetector(

        onTap: () {

          if (!mounted) return;

          setState(() {

            _view = view;

            _calendarController.view =
                view;
          });
        },

        child: AnimatedContainer(

          duration:
          const Duration(milliseconds: 200),

          padding:
          const EdgeInsets.symmetric(
            vertical: 10,
          ),

          decoration: BoxDecoration(

            color: isSelected
                ? Colors.white
                : Colors.transparent,

            borderRadius:
            BorderRadius.circular(10),

            boxShadow: isSelected
                ? [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
              )
            ]
                : [],
          ),

          child: Center(
            child: Text(

              label,

              style: TextStyle(
                fontWeight:
                FontWeight.w600,

                color: isSelected
                    ? Colors.black
                    : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {

    final authProvider =
    context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(

          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            const Text(
              "CENTRO ESTETICO MVP",
              style:
              TextStyle(fontSize: 16),

            ),

            Text(
              "Ciao ${_getRoleLabel(authProvider.profile?.role)}",

              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),

        actions: [

          // =================================================
          // QR
          // =================================================

          /*IconButton(

            icon: const Icon(Icons.qr_code),

            tooltip: "QR Prenotazioni",

            onPressed: () {

              final profile =
                  context.read<AuthProvider>()
                      .profile;

              if (profile == null) {

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Profilo non caricato",
                    ),
                  ),
                );

                return;
              }

              Navigator.push(

                context,

                MaterialPageRoute(



                  builder: (_) =>
                      BusinessQrPage(
                        businessId:
                        profile.businessId,
                      ),


                ),
              );
            },
          ),*/

          IconButton(
            icon: const Icon(Icons.qr_code),
            tooltip: "QR Prenotazioni",
            onPressed: () {
              final profile = context.read<AuthProvider>().profile;

              if (profile == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Profilo non caricato")),
                );
                return;
              }

              // ✅ Check aggiunto per businessId nullable
              if (profile.businessId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Business non disponibile")),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BusinessQrPage(
                    businessId: profile.businessId!, // ✅ ! sicuro — verificato sopra
                  ),
                ),
              );
            },
          ),

          // =================================================
          // VIEW SWITCH
          // =================================================

          IconButton(

            icon: Icon(

              _view == CalendarView.week
                  ? Icons.calendar_view_month
                  : Icons.view_week,
            ),

            onPressed: () {

              if (!mounted) return;

              setState(() {

                _view =
                _view == CalendarView.week
                    ? CalendarView.month
                    : CalendarView.week;

                _calendarController.view =
                    _view;
              });
            },
          ),

          // =================================================
          // TODAY
          // =================================================

          IconButton(

            icon: const Icon(Icons.today),
            tooltip: "Vai a oggi",
            onPressed: () {

              if (!mounted) return;

              setState(() {

                _focusedDay = DateTime.now();

                _calendarController
                    .displayDate =
                    _focusedDay;
              });

              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                  content: Text("Vista oggi"),
                ),
              );
            },
          ),

          // =================================================
          // CUSTOMERS
          // =================================================

          IconButton(

            icon: const Icon(Icons.people),
            tooltip: "Clienti",

            onPressed: () {

              Navigator.push(

                context,

                MaterialPageRoute(
                  builder: (_) =>
                  const CustomerListPage(),
                ),
              );
            },
          ),

          // =================================================
          // LOGOUT
          // =================================================

          TextButton.icon(
            onPressed: logout,
            icon: const Icon(Icons.logout),
            label: const Text("Logout"),
          )
        ],
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: Column(

        children: [

          // =================================================
          // HEADER
          // =================================================

          Container(

            padding:
            const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),

            color: const Color(0xFFF1F5F9),

            child: Row(

              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,

              children: [

                IconButton(

                  icon:
                  const Icon(Icons.chevron_left),

                  onPressed: () {

                    if (!mounted) return;

                    setState(() {

                      _focusedDay =
                          _focusedDay.subtract(
                            const Duration(days: 7),
                          );

                      _calendarController
                          .displayDate =
                          _focusedDay;
                    });
                  },
                ),

                Text(

                  DateFormat(
                    'MMMM yyyy',
                    'it_IT',
                  ).format(_focusedDay),

                  style: const TextStyle(
                    fontWeight:
                    FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                IconButton(

                  icon:
                  const Icon(Icons.chevron_right),

                  onPressed: () {

                    if (!mounted) return;

                    setState(() {

                      _focusedDay =
                          _focusedDay.add(
                            const Duration(days: 7),
                          );

                      _calendarController
                          .displayDate =
                          _focusedDay;
                    });
                  },
                ),
              ],
            ),
          ),

          // =================================================
          // VIEW BUTTONS
          // =================================================

          Container(

            margin: const EdgeInsets.all(10),

            padding: const EdgeInsets.all(4),

            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius:
              BorderRadius.circular(12),
            ),

            child: Row(
              children: [

                _buildViewButton(
                  "Giorno",
                  CalendarView.day,
                ),

                _buildViewButton(
                  "Settimana",
                  CalendarView.week,
                ),

                _buildViewButton(
                  "Mese",
                  CalendarView.month,
                ),
              ],
            ),
          ),

          // =================================================
          // CALENDAR
          // =================================================

          Expanded(

            child: SfCalendar(

              key: ValueKey(_appointments.map((e) => e.id).join('-')),

              //key: ValueKey(_appointments.length),
              //timeZone: 'UTC',

              //specialRegions: _getSpecialRegions(),
              // ✅ Dopo
              specialRegions: _specialRegions,

              cellBorderColor: Colors.grey.shade300,

              monthCellBuilder: (context, details) {

                final date = details.date;

                /*final isSunday = _isSunday(date);
                final isLunch = _isLunchBreak(date);
                final isPast = _isPastSlot(date);*/

                // ✅ Dopo
                final isSunday = BookingRules.isSunday(date);
                final isLunch = BookingRules.isLunchBreak(date);
                final isPast = BookingRules.isPastSlot(date);

                Color bgColor = Colors.white;
                Color textColor = Colors.black;

                // =========================
                // DOMENICA
                // =========================

                if (isSunday) {
                  bgColor = Colors.yellow.shade200;
                }

                // =========================
                // PAUSA PRANZO
                // =========================

                else if (isLunch) {
                  bgColor = Colors.grey.shade300;
                  textColor = Colors.grey.shade700;
                }

                // =========================
                // PASSATO
                // =========================

                else if (isPast) {
                  bgColor = Colors.grey.shade400;
                  textColor = Colors.white;
                }

                return Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                  ),

                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },

              blackoutDates: _getPastDates(),
              blackoutDatesTextStyle: const TextStyle(
                color: Colors.grey,
              ),


              //key: ValueKey(_appointments.length),

              controller: _calendarController,

              view: _view,

              initialDisplayDate:
              _focusedDay,

              dataSource: _calendarDataSource,

              timeSlotViewSettings: const TimeSlotViewSettings(
                startHour: 8,
                endHour: 20,

                timeFormat: 'HH:mm',

                timeInterval: Duration(minutes: 30),

                timeIntervalHeight: 60,
              ),

              // =================================================
              // TAP
              // =================================================

              onTap: (details) async {

                // =============================================
                // SLOT LIBERO ### OK ####
                // =============================================

                if (details.targetElement == CalendarElement.calendarCell) {

                  final selectedDate = details.date;

                  if (selectedDate == null) {
                    return;
                  }

                    // =========================
                    // BLOCCO DATE PASSATE
                    // =========================

                  if (!selectedDate.isAfter(DateTime.now())) {

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Non puoi prenotare per una data passata",
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );

                    return;
                  }


                  //final localSelectedDate = selectedDate!;

                  final date = details.date;

                  if (date == null) return;

// 🔥 NORMALIZZAZIONE UNICA (STANDARD SISTEMA)
                  final normalizedDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedDate.hour,
                    selectedDate.minute,
                  );


                  // =========================
                  // SLOT BLOCCATI
                  // =========================




                  /*final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateAppointmentPage(
                        //selectedDateTime: localSelectedDate,

                        selectedDateTime: normalizedDateTime,
                      ),
                    ),
                  );*/


                  final profile = context.read<AuthProvider>().profile;

                  if (profile?.businessId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Business non disponibile"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateAppointmentPage(
                        selectedDateTime: normalizedDateTime,
                        businessId: profile!.businessId!,
                        isGuest: false,
                      ),
                    ),
                  );


                  if (result == true) {

                    await loadAppointments();

                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Prenotazione effettuata correttamente"),
                        backgroundColor: Colors.green,
                      ),
                    );



                  }

                  return;
                }

                // =============================================
                // TAP APPOINTMENT
                // =============================================

                if (details.targetElement ==
                    CalendarElement.appointment) {

                  final Appointment appt =
                      details.appointments!.first;

                  final model = _appointments.firstWhere(
                        (a) => a.id.toString() == appt.id.toString(),
                  );

                  showModalBottomSheet(

                    context: context,

                    builder: (_) => Padding(

                      padding:
                      const EdgeInsets.all(20),

                      child: Column(

                        mainAxisSize:
                        MainAxisSize.min,

                        crossAxisAlignment:
                        CrossAxisAlignment.start,

                        children: [

                          Text(

                            model.customerName,

                            style:
                            const TextStyle(
                              fontSize: 20,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            "Servizio: ${model.serviceName}",
                          ),

                          const SizedBox(height: 20),

                          // ===================================
                          // CUSTOMER PROFILE
                          // ===================================

                          ElevatedButton(

                            onPressed: () {

                              Navigator.pop(context);

                              Navigator.push(

                                context,

                                MaterialPageRoute(

                                  builder: (_) =>
                                      CustomerProfilePage(
                                        customerId:
                                        model.customerId,

                                        customerName:
                                        model.customerName,
                                      ),
                                ),
                              );
                            },

                            child: const Text(
                              "Scheda cliente",
                            ),
                          ),

                          // ===================================
                          // DELETE
                          // ===================================



                          ElevatedButton.icon(

                            style:
                            ElevatedButton.styleFrom(
                              backgroundColor:
                              Colors.red,
                            ),

                            icon:
                            const Icon(Icons.delete),

                            label:
                            const Text("Elimina"),

                            onPressed: () async {

                              final confirm =
                              await showDialog<bool>(

                                context: context,

                                builder: (_) =>
                                    AlertDialog(

                                      title: const Text(
                                        "Conferma eliminazione",
                                      ),

                                      content:
                                      const Text(
                                        "Sei sicuro di voler eliminare questo appuntamento?",
                                      ),

                                      actions: [

                                        TextButton(

                                          onPressed: () =>
                                              Navigator.pop(
                                                context,
                                                false,
                                              ),

                                          child:
                                          const Text(
                                            "Annulla",
                                          ),
                                        ),

                                        ElevatedButton(

                                          style:
                                          ElevatedButton.styleFrom(
                                            backgroundColor:
                                            Colors.red,
                                          ),

                                          onPressed: () =>
                                              Navigator.pop(
                                                context,
                                                true,
                                              ),

                                          child:
                                          const Text(
                                            "Elimina",
                                          ),
                                        ),
                                      ],
                                    ),
                              );

                              if (confirm != true) {
                                return;
                              }

                              await deleteAppointment(
                                model.id,
                              );

                              if (!mounted) return;

                              Navigator.pop(context);

                              await loadAppointments();

                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Appuntamento eliminato",
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// DATA SOURCE
// ===========================================================

class AppointmentDataSource extends CalendarDataSource {
  AppointmentDataSource(List<AppointmentModel> source) {

    final now = DateTime.now().toUtc();

    appointments = source.map((e) {

      debugPrint("========== MAP APPOINTMENT ==========");
      debugPrint("DB START     => ${e.startTime}");
      debugPrint("IS UTC       => ${e.startTime.isUtc}");
      debugPrint("LOCAL VIEW   => ${e.startTime.toLocal()}");
      debugPrint("UTC VIEW     => ${e.startTime.toUtc()}");
      debugPrint("====================================");

      final isPast = e.endTime.isBefore(now);

      return Appointment(
        id: e.id,

        /*startTime: e.startTime.toUtc(),
        endTime: e.endTime.toUtc(),*/

        // risolta anomalia GUEST
        startTime: e.startTime.toLocal(),
        endTime: e.endTime.toLocal(),

        subject: '👤 ${e.customerName} | 💆 ${e.serviceName}',

        color: isPast
            ? _fromHex(e.serviceColor).withOpacity(0.4)
            : _fromHex(e.serviceColor),
      );
    }).toList();
  }

  Color _fromHex(String? hex) {
    if (hex == null || hex.isEmpty) {
      return Colors.blueGrey;
    }

    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) {
      buffer.write('ff');
    }

    buffer.write(hex.replaceFirst('#', ''));

    return Color(int.parse(buffer.toString(), radix: 16));
  }
}


/*bool _isSunday(DateTime date) {
  return date.weekday == DateTime.sunday;
}

bool _isLunchBreak(DateTime date) {
  final minutes = date.hour * 60 + date.minute;

  return minutes >= (13 * 60) &&
      minutes < (14 * 60);
}

bool _isPastSlot(DateTime date) {

  final now = DateTime.now();

  return date.isBefore(
    DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    ),
  );
}

bool _isBlockedSlot(DateTime date) {
  return
    _isPastSlot(date) ||
        _isSunday(date) ||
        _isLunchBreak(date);
}*/