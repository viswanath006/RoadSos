import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class BreakdownScreen extends StatelessWidget {
  const BreakdownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Breakdown Assistance'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.car_repair,
              size: 72,
              color: Colors.orange.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            const Text(
              'Breakdown Assistance',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Nearby towing, mechanics, and tire puncture centers will appear here in the next phase.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            Center(
              child: Chip(
                label: const Text('Coming Soon'),
                backgroundColor: Colors.orange.shade50,
                side: BorderSide(color: Colors.orange.shade200),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
