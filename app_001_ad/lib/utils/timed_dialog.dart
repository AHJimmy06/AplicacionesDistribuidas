import 'dart:async';

import 'package:flutter/material.dart';

Future<T?> showTimedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) async {
  Timer? timer;

  try {
    return await showDialog<T>(
      context: context,
      builder: (dialogContext) {
        timer ??= Timer(const Duration(seconds: 4), () {
          if (dialogContext.mounted) Navigator.pop(dialogContext);
        });
        return builder(dialogContext);
      },
    );
  } finally {
    timer?.cancel();
  }
}
