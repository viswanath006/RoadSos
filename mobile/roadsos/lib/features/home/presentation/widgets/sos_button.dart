import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class SosButton extends StatefulWidget {
  const SosButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulsing ring 2
            Container(
              width: 240 + (_pulse.value * 30),
              height: 240 + (_pulse.value * 30),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.sosRed.withOpacity((1 - _pulse.value) * 0.15),
              ),
            ),
            // Outer pulsing ring 1
            Container(
              width: 200 + (_pulse.value * 25),
              height: 200 + (_pulse.value * 25),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.sosRed.withOpacity((1 - _pulse.value) * 0.3),
              ),
            ),
            // Main Button Container
            GestureDetector(
              onTap: widget.onPressed,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFF5252),
                      AppTheme.sosRed,
                      Color(0xFFB71C1C),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.sosRed.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                        height: 1.0,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'TAP FOR HELP',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
