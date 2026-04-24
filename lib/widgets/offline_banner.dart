import 'package:flutter/material.dart';
import '../utils/constants.dart';

class OfflineBanner extends StatelessWidget {
  final bool isOffline;

  const OfflineBanner({Key? key, required this.isOffline}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: AppColors.warningOrange,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, color: AppColors.white, size: 16),
          SizedBox(width: 8),
          Text(
            'Offline Mode - Using Cached Services',
            style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
