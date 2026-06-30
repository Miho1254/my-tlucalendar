import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final plugin = DeviceCalendarPlugin();
  
  final calendarsResult = await plugin.retrieveCalendars();
  if (calendarsResult.isSuccess && calendarsResult.data != null) {
    for (final c in calendarsResult.data!) {
      if (c.name == 'TLU Calendar') {
        final result = await plugin.deleteCalendar(c.id!);
        if (result.isSuccess) {
          print('Successfully deleted calendar: ${c.id}');
        } else {
          print('Failed to delete calendar: ${c.id}');
        }
      }
    }
  } else {
    print('Failed to retrieve calendars.');
  }
}
