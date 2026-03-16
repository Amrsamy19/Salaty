import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';

// Brand palette
const _bg     = Color(0xFF061026);
const _bg2    = Color(0xFF0D1B3E);
const _gold   = Color(0xFFC5A35E);
const _faint  = Color(0x33C5A35E);
const _cream  = Color(0xFFE2D1A8);
const _slate  = Color(0xFF64748B);

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  final _locationStreamController = FlutterQiblah.qiblahStream;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('اتجاه القبلة',
            style: TextStyle(fontWeight: FontWeight.bold, color: _cream)),
        centerTitle: true,
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _gold),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bg, _bg2, _bg],
          ),
        ),
        child: StreamBuilder(
          stream: _locationStreamController,
          builder: (context, AsyncSnapshot<QiblahDirection> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: _gold));
            }

            if (snapshot.hasError) {
              return Center(
                  child: Text('خطأ: ${snapshot.error}',
                      style: const TextStyle(color: _cream)));
            }

            final qiblahDirection = snapshot.data!;
            final qiblahAngle = qiblahDirection.qiblah;

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Degree badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: _faint,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: _gold.withOpacity(0.35)),
                    ),
                    child: Text(
                      '${qiblahAngle.toStringAsFixed(1)}° من الشمال',
                      style: const TextStyle(
                          color: _gold, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Compass
                  SizedBox(
                    width: 300,
                    height: 300,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer ring
                        Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _gold.withOpacity(0.25), width: 2),
                            color: _bg2.withOpacity(0.6),
                          ),
                          child: CustomPaint(
                            painter: BrandCompassPainter(),
                          ),
                        ),
                        // North label
                        Positioned(
                          top: 12,
                          child: Text('N',
                              style: TextStyle(
                                  color: _cream.withOpacity(0.4),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                        ),
                        // North indicator (device heading)
                        Transform.rotate(
                          angle: (qiblahDirection.direction * (math.pi / 180) * -1),
                          child: Icon(Icons.arrow_upward,
                              color: _cream.withOpacity(0.2), size: 200),
                        ),
                        // Qibla needle (gold)
                        Transform.rotate(
                          angle: (qiblahAngle * (math.pi / 180) * -1),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Kaaba icon at tip
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _gold,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.mosque,
                                    color: _bg, size: 20),
                              ),
                              Container(
                                width: 4,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [_gold, Colors.transparent],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Center dot
                        Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'أدر الهاتف حتى تتجه الإبرة الذهبية نحو القبلة',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _slate, fontSize: 15),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class BrandCompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Tick marks
    final tickPaint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 360; i += 10) {
      final angle = i * (math.pi / 180);
      final isMajor = i % 30 == 0;
      tickPaint.color =
          isMajor ? const Color(0xFFC5A35E).withOpacity(0.6) : const Color(0xFFE2D1A8).withOpacity(0.15);
      final tickLen = isMajor ? 14.0 : 7.0;
      final start = Offset(
        center.dx + (radius - tickLen) * math.cos(angle),
        center.dy + (radius - tickLen) * math.sin(angle),
      );
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(start, end, tickPaint);
    }

    // Inner glow ring
    final glowPaint = Paint()
      ..color = const Color(0xFFC5A35E).withOpacity(0.06)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.85, glowPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
