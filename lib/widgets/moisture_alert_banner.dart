import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/sensor_data_provider.dart';

class MoistureAlertBanner extends StatelessWidget {
  const MoistureAlertBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SensorDataProvider>(
      builder: (context, provider, _) {
        final data = provider.sensorData;

        if (data == null || data.moistureLevel >= 30.0) {
          return const SizedBox.shrink();
        }

        return _AlertBanner(moistureLevel: data.moistureLevel);
      },
    );
  }
}

class _AlertBanner extends StatefulWidget {
  final double moistureLevel;

  const _AlertBanner({required this.moistureLevel});

  @override
  State<_AlertBanner> createState() => _AlertBannerState();
}

class _AlertBannerState extends State<_AlertBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) {
        setState(() => _dismissed = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          border: Border.all(color: const Color(0xFFFF5722), width: 1.5),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5722).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.water_drop_outlined,
                color: Color(0xFFFF5722),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚠️ Low Soil Moisture',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFFBF360C),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Current level: ${widget.moistureLevel.toStringAsFixed(1)}% (threshold: 30%). Please irrigate soon.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: Color(0xFFFF5722)),
              onPressed: _dismiss,
              tooltip: 'Dismiss',
            ),
          ],
        ),
      ),
    );
  }
}
