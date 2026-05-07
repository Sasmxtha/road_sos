import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

class SosButton extends StatefulWidget {
  final VoidCallback onPressed;
  final VoidCallback? onWhatsAppPressed;

  const SosButton({
    Key? key,
    required this.onPressed,
    this.onWhatsAppPressed,
  }) : super(key: key);

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late AnimationController _pressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _pressAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // Continuous pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Ripple animation
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    // Press scale animation
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _pressAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    setState(() => _isPressed = true);
    _pressController.forward();
    HapticFeedback.mediumImpact();
  }

  void _handleTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  void _handleTap() {
    HapticFeedback.heavyImpact();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main SOS button with animations
        SizedBox(
          width: 260,
          height: 260,
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulseAnimation, _rippleAnimation, _pressAnimation]),
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ripple rings
                  ...List.generate(3, (index) {
                    final delay = index * 0.33;
                    final progress = (_rippleAnimation.value + delay) % 1.0;
                    return Container(
                      width: 200 + (progress * 80),
                      height: 200 + (progress * 80),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryRed.withOpacity(
                            (1.0 - progress) * 0.3,
                          ),
                          width: 2,
                        ),
                      ),
                    );
                  }),

                  // Glow effect
                  Container(
                    width: 210 * _pulseAnimation.value,
                    height: 210 * _pulseAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryRed.withOpacity(
                            _isPressed ? 0.6 : 0.35,
                          ),
                          spreadRadius: _isPressed ? 15 : 8,
                          blurRadius: _isPressed ? 40 : 25,
                        ),
                      ],
                    ),
                  ),

                  // Main button
                  Transform.scale(
                    scale: _pressAnimation.value * _pulseAnimation.value,
                    child: GestureDetector(
                      onTapDown: _handleTapDown,
                      onTapUp: _handleTapUp,
                      onTapCancel: _handleTapCancel,
                      onTap: _handleTap,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            center: Alignment(-0.2, -0.3),
                            radius: 0.8,
                            colors: [
                              Color(0xFFFF6F60),
                              Color(0xFFE53935),
                              Color(0xFFB71C1C),
                            ],
                            stops: [0.0, 0.5, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryRed.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.emergency_share,
                              color: Colors.white,
                              size: 36,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'SOS',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 6,
                                shadows: [
                                  Shadow(
                                    color: Colors.black38,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'TAP FOR HELP',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withOpacity(0.8),
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        // Quick action buttons below SOS
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildQuickAction(
              icon: Icons.sms,
              label: 'SMS',
              color: AppColors.accentBlue,
              onTap: widget.onPressed,
            ),
            const SizedBox(width: 16),
            if (widget.onWhatsAppPressed != null) ...[
              _buildQuickAction(
                icon: Icons.chat,
                label: 'WhatsApp',
                color: AppColors.accentGreen,
                onTap: widget.onWhatsAppPressed!,
              ),
              const SizedBox(width: 16),
            ],
            _buildQuickAction(
              icon: Icons.call,
              label: 'Call 112',
              color: AppColors.accentOrange,
              onTap: () async {
                final uri = Uri(scheme: 'tel', path: '112');
                // url_launcher is already imported in the parent
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
