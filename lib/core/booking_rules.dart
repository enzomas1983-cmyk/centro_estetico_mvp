
/*class BookingRules {
  static const int openingHour = 8;
  static const int closingHour = 20;

  static const int lunchStartHour = 13;
  static const int lunchEndHour = 14;

  static bool isBlocked({
    required DateTime start,
    required DateTime end,
  }) {
    final s = start.toLocal();
    final e = end.toLocal();

    final now = DateTime.now();

    // =========================
    // 1. PASSATO (PRO SLOT CHECK)
    // =========================
    if (!e.isAfter(now)) {
      return true;
    }

    // =========================
    // 2. DOMENICA
    // =========================
    if (s.weekday == DateTime.sunday) {
      return true;
    }

    // =========================
    // 3. ORARI LAVORATIVI (STRICT)
    // =========================
    final dayStart = DateTime(s.year, s.month, s.day, openingHour);
    final dayEnd = DateTime(s.year, s.month, s.day, closingHour);

    if (s.isBefore(dayStart) || e.isAfter(dayEnd)) {
      return true;
    }

    // =========================
    // 4. PAUSA PRANZO (OVERLAP PRO CHECK)
    // =========================
    final lunchStart = DateTime(s.year, s.month, s.day, lunchStartHour);
    final lunchEnd = DateTime(s.year, s.month, s.day, lunchEndHour);

    final overlapsLunch =
        s.isBefore(lunchEnd) && e.isAfter(lunchStart);

    if (overlapsLunch) {
      return true;
    }

    return false;
  }

  static String? reason({
    required DateTime start,
    required DateTime end,
  }) {
    final s = start.toLocal();
    final e = end.toLocal();
    final now = DateTime.now();

    if (!e.isAfter(now)) {
      return "Non puoi prenotare per una data passata";
    }

    if (s.weekday == DateTime.sunday) {
      return "Domenica non lavorativa";
    }

    final dayStart = DateTime(s.year, s.month, s.day, openingHour);
    final dayEnd = DateTime(s.year, s.month, s.day, closingHour);

    if (s.isBefore(dayStart)) {
      return "Il centro apre alle 08:00";
    }

    if (e.isAfter(dayEnd)) {
      return "Il centro chiude alle 20:00";
    }

    final lunchStart = DateTime(s.year, s.month, s.day, lunchStartHour);
    final lunchEnd = DateTime(s.year, s.month, s.day, lunchEndHour);

    if (s.isBefore(lunchEnd) && e.isAfter(lunchStart)) {
      return "Pausa pranzo 13:00 - 14:00";
    }

    return null;
  }

  // =========================
  // SLOT VALIDATION (PRO LEVEL)
  // =========================
  static bool isSlotValid({
    required DateTime start,
    required int durationMinutes,
  }) {
    final end = start.add(Duration(minutes: durationMinutes));
    return !isBlocked(start: start, end: end);
  }
}*/



class BookingRules {
  // Costanti orari
  static const int openingHour = 8;
  static const int closingHour = 20;
  static const int lunchStartHour = 13;
  static const int lunchStartMinute = 0;
  static const int lunchEndHour = 14;
  static const int lunchEndMinute = 0;

  // ✅ reason() è l'unica fonte di verità
  static String? reason({
    required DateTime start,
    required DateTime end,
  }) {
    final s = start.toLocal();
    final e = end.toLocal();
    final now = DateTime.now();

    if (!e.isAfter(now)) {
      return "Non puoi prenotare per una data passata";
    }

    if (s.weekday == DateTime.sunday) {
      return "Domenica non lavorativa";
    }

    final dayStart = DateTime(s.year, s.month, s.day, openingHour);
    final dayEnd = DateTime(s.year, s.month, s.day, closingHour);

    if (s.isBefore(dayStart)) {
      return "Il centro apre alle 08:00";
    }

    if (e.isAfter(dayEnd)) {
      return "Il centro chiude alle 20:00";
    }

    final lunchStart = DateTime(s.year, s.month, s.day, lunchStartHour, lunchStartMinute);
    final lunchEnd = DateTime(s.year, s.month, s.day, lunchEndHour, lunchEndMinute);

    if (s.isBefore(lunchEnd) && e.isAfter(lunchStart)) {
      return "Pausa pranzo 13:00 - 14:00";
    }

    return null;
  }

  // ✅ isBlocked è ora un wrapper di reason
  static bool isBlocked({
    required DateTime start,
    required DateTime end,
  }) {
    return reason(start: start, end: end) != null;
  }

  // ✅ isSlotValid invariato
  static bool isSlotValid({
    required DateTime start,
    required int durationMinutes,
  }) {
    final end = start.add(Duration(minutes: durationMinutes));
    return !isBlocked(start: start, end: end);
  }

  // ✅ Metodi spostati da pro_calendar_page.dart
  static bool isSunday(DateTime date) =>
      date.weekday == DateTime.sunday;

  static bool isLunchBreak(DateTime date) {
    final minutes = date.hour * 60 + date.minute;
    return minutes >= (lunchStartHour * 60 + lunchStartMinute) &&
        minutes < (lunchEndHour * 60 + lunchEndMinute);
  }

  static bool isPastSlot(DateTime date) {
    final now = DateTime.now();
    return date.isBefore(
      DateTime(now.year, now.month, now.day, now.hour, now.minute),
    );
  }

  static bool isBlockedSlot(DateTime date) =>
      isPastSlot(date) || isSunday(date) || isLunchBreak(date);
}