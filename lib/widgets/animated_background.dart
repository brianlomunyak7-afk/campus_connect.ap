import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _particleController;
  late Animation<double> _gradientAnimation;
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Gradient animation
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _gradientAnimation = CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    );

    // Particle animation
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Generate particles
    for (int i = 0; i < 18; i++) {
      _particles.add(Particle(random: _random));
    }

    _particleController.addListener(() {
      setState(() {
        for (var p in _particles) {
          p.update();
        }
      });
    });
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _gradientAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Animated gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(
                      const Color(0xFF1A237E), // deep blue
                      const Color(0xFF0D47A1), // medium blue
                      _gradientAnimation.value,
                    )!,
                    Color.lerp(
                      const Color(0xFF1565C0), // blue
                      const Color(0xFF0288D1), // light blue
                      _gradientAnimation.value,
                    )!,
                    Color.lerp(
                      const Color(0xFF00BCD4), // cyan
                      const Color(0xFF1DE9B6), // teal
                      _gradientAnimation.value,
                    )!,
                  ],
                ),
              ),
            ),

            // Floating particles
            CustomPaint(
              painter: ParticlePainter(particles: _particles),
              child: const SizedBox.expand(),
            ),

            // Glowing orbs
            Positioned(
              top: -80,
              right: -60,
              child: AnimatedBuilder(
                animation: _gradientAnimation,
                builder: (context, _) => Transform.scale(
                  scale: 0.9 + (_gradientAnimation.value * 0.2),
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: -100,
              left: -60,
              child: AnimatedBuilder(
                animation: _gradientAnimation,
                builder: (context, _) => Transform.scale(
                  scale: 1.0 - (_gradientAnimation.value * 0.15),
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFF59E0B).withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Your actual screen content on top
            widget.child,
          ],
        );
      },
    );
  }
}

// Particle model
class Particle {
  late double x, y, size, speed, opacity;
  late double directionX, directionY;
  final Random random;

  Particle({required this.random}) {
    reset();
  }

  void reset() {
    x = random.nextDouble();
    y = random.nextDouble();
    size = random.nextDouble() * 6 + 2;
    speed = random.nextDouble() * 0.003 + 0.001;
    opacity = random.nextDouble() * 0.5 + 0.1;
    directionX = (random.nextDouble() - 0.5) * 0.002;
    directionY = -speed;
  }

  void update() {
    x += directionX;
    y += directionY;
    if (y < -0.05 || x < -0.05 || x > 1.05) reset();
  }
}

// Custom painter for particles
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(p.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}
