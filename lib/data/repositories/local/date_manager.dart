import 'package:intl/intl.dart' as Intl;

class DateManager {
  static Intl.DateFormat formatter = Intl.DateFormat();
  static Intl.DateFormat dayFormatter = Intl.DateFormat("DD");
  static Intl.DateFormat hourFormatter = Intl.DateFormat("HH:MM");

  static String getFullDate() {
    return formatter.format(DateTime.now());
  }
  
  static String getCurrentHour() {
    return formatter.format(DateTime.now());
  }
  
  static String getCurrentDay() {
    return formatter.format(DateTime.now());
  }
}