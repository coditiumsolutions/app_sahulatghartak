import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Shows a date picker matching platform convention: a spinning wheel
/// [CupertinoDatePicker] sheet on iOS, the standard Material calendar
/// everywhere else.
Future<DateTime?> showPlatformDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  if (!Platform.isIOS) {
    return showDatePicker(context: context, initialDate: initialDate, firstDate: firstDate, lastDate: lastDate);
  }
  return _showCupertinoPickerSheet<DateTime>(
    context,
    initial: initialDate,
    builder: (context, selected) => CupertinoDatePicker(
      mode: CupertinoDatePickerMode.date,
      initialDateTime: initialDate,
      minimumDate: firstDate,
      maximumDate: lastDate,
      onDateTimeChanged: (value) => selected.value = value,
    ),
  );
}

/// Shows a time picker matching platform convention: a spinning wheel
/// [CupertinoDatePicker] (time mode) sheet on iOS, the standard Material
/// clock dial everywhere else.
Future<TimeOfDay?> showPlatformTimePicker(
  BuildContext context, {
  required TimeOfDay initialTime,
}) async {
  if (!Platform.isIOS) {
    return showTimePicker(context: context, initialTime: initialTime);
  }
  final now = DateTime.now();
  final initialDateTime = DateTime(now.year, now.month, now.day, initialTime.hour, initialTime.minute);
  final picked = await _showCupertinoPickerSheet<DateTime>(
    context,
    initial: initialDateTime,
    builder: (context, selected) => CupertinoDatePicker(
      mode: CupertinoDatePickerMode.time,
      initialDateTime: initialDateTime,
      use24hFormat: false,
      onDateTimeChanged: (value) => selected.value = value,
    ),
  );
  if (picked == null) return null;
  return TimeOfDay.fromDateTime(picked);
}

Future<T?> _showCupertinoPickerSheet<T>(
  BuildContext context, {
  required T initial,
  required Widget Function(BuildContext context, ValueNotifier<T> selected) builder,
}) {
  final selected = ValueNotifier<T>(initial);
  return showCupertinoModalPopup<T>(
    context: context,
    builder: (context) => Container(
      height: 260,
      color: CupertinoColors.systemBackground.resolveFrom(context),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onPressed: () => Navigator.of(context).pop(selected.value),
                    child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Expanded(child: builder(context, selected)),
          ],
        ),
      ),
    ),
  );
}
