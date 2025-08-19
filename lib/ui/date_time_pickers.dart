import 'package:flutter/material.dart';

Future<DateTime?> pickDate({
  required BuildContext context,
  DateTime? initial,
  DateTime? first,
  DateTime? last,
}) async {
  final now = DateTime.now();
  final picked = await showDatePicker(
    context: context,
    initialDate: initial ?? now,
    firstDate: first ?? DateTime(now.year - 1),
    lastDate: last ?? DateTime(now.year + 2),
  );
  return picked;
}

Future<TimeOfDay?> pickTime({
  required BuildContext context,
  TimeOfDay? initial,
}) async {
  return showTimePicker(
    context: context,
    initialTime: initial ?? TimeOfDay.now(),
  );
}
