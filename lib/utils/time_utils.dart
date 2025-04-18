import 'package:flutter/material.dart';

int timeOfDayToMinutes(TimeOfDay time) {
  return time.hour * 60 + time.minute;
}

int scheduleDuration(TimeOfDay start, TimeOfDay end) {
  int startMinutes = timeOfDayToMinutes(start);
  int endMinutes = timeOfDayToMinutes(end);

  return endMinutes - startMinutes;
}
