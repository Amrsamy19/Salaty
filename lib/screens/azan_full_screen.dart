import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AzanFullScreen extends StatefulWidget {
  final VoidCallback onDismiss;
  final String prayerName;

  const AzanFullScreen({
    super.key,
    required this.onDismiss,
    this.prayerName = "الصلاة",
  });

  @override
  State<AzanFullScreen> createState() => _AzanFullScreenState();
}

class _AzanFullScreenState extends State<AzanFullScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF040B1A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Gradient & Pattern
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF061533),
                  Color(0xFF040B1A),
                ],
              ),
            ),
          ),
          
          // Subtle Mosque Overlay (Simulation)
          Center(
            child: Opacity(
              opacity: 0.05,
              child: Icon(Icons.mosque, size: MediaQuery.of(context).size.width, color: Colors.white),
            ),
          ),

          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Pulsing Icon
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                      border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                    ),
                    child: const Icon(
                      Icons.notifications_active,
                      size: 100,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                ),
                
                const SizedBox(height: 48),
                
                Text(
                  "حان الآن موعد",
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    color: Colors.white70,
                    letterSpacing: 2,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  widget.prayerName,
                  style: GoogleFonts.cairo(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFD4AF37),
                    shadows: [
                      const Shadow(
                        blurRadius: 20,
                        color: Color(0x66D4AF37),
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Slide to Dismiss (Simulation via simple button for now)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                  child: SizedBox(
                    width: double.infinity,
                    height: 80,
                    child: ElevatedButton(
                      onPressed: widget.onDismiss,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: const Color(0xFF040B1A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        elevation: 8,
                      ),
                      child: Text(
                        "إيقاف الأذان",
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
