import 'package:flutter/material.dart';
import '../models/emergency_service.dart';
import '../utils/constants.dart';
import '../services/sms_service.dart';

class ServiceCard extends StatelessWidget {
  final EmergencyService service;
  final VoidCallback onDirectionsPressed;
  final _smsService = SmsService();

  ServiceCard({Key? key, required this.service, required this.onDirectionsPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    service.name,
                    style: AppTextStyles.subheader,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (service.distance != null)
                  Text(
                    '${(service.distance! / 1000).toStringAsFixed(1)} km',
                    style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              service.address ?? 'Address not available',
              style: AppTextStyles.body.copyWith(color: Colors.grey[700], fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (service.phoneNumber != null)
                  ElevatedButton.icon(
                    onPressed: () => _smsService.callNumber(service.phoneNumber!),
                    icon: const Icon(Icons.call),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: onDirectionsPressed,
                  icon: const Icon(Icons.directions),
                  label: const Text('Directions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: AppColors.white,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
