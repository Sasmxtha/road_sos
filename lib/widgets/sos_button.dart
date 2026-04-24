import 'package:flutter/material.dart';
import '../utils/constants.dart';

class SosButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SosButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          color: AppColors.primaryRed,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryRed.withOpacity(0.5),
              spreadRadius: 10,
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'SOS',
            style: AppTextStyles.sosButton,
          ),
        ),
      ),
    );
  }
}
