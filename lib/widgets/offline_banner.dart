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
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentOrange.withOpacity(0.15),
            AppColors.accentOrange.withOpacity(0.08),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.accentOrange.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, color: AppColors.accentOrange, size: 16),
          const SizedBox(width: 8),
          Text(
            'Offline Mode — Using Cached Services',
            style: TextStyle(
              color: AppColors.accentOrange,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
