import 'dart:io';
import 'package:flutter/material.dart';

/// Check if device has real network connectivity
Future<bool> hasInternetConnection() async {
  try {
    final result = await InternetAddress.lookup('google.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } on SocketException catch (_) {
    return false;
  }
}

/// Format a distance in meters to a human readable string
String formatDistance(double meters) {
  if (meters < 1000) {
    return '${meters.toStringAsFixed(0)} m';
  } else {
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}

/// Show a quick SnackBar message
void showMessage(BuildContext context, String message,
    {Color backgroundColor = Colors.black87, int durationSeconds = 3}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      duration: Duration(seconds: durationSeconds),
    ),
  );
}

/// Graceful permission denied handler
void showPermissionDeniedDialog(BuildContext context, String permissionName) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('$permissionName Permission Required'),
      content: Text(
          'RoadSoS needs $permissionName permission to function properly. '
          'Please grant it in your device settings.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
