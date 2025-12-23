import 'package:flutter/material.dart';

enum SnackBarType { success, error, warning, info }

/// AppDialogs provides reusable dialog functions
class AppDialogs {
  /// Shows a snackbar with the specified type
  static void showSnackBar(
    BuildContext context,
    String message, {
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    final colors = {
      SnackBarType.success: Colors.green,
      SnackBarType.error: Colors.red,
      SnackBarType.warning: Colors.orange,
      SnackBarType.info: Colors.blue,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: colors[type],
      ),
    );
  }

  /// Shows an error dialog
  static void showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onOk,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onOk?.call();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Shows a confirmation dialog
  static void showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onCancel?.call();
              },
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm.call();
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  /// Shows a loading dialog
  static void showLoadingDialog(
    BuildContext context, {
    String message = 'Loading...',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(message),
            ],
          ),
        );
      },
    );
  }

  /// Dismisses the current dialog
  static void dismiss(BuildContext context) {
    Navigator.of(context).pop();
  }
}
