import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  late AnimationController _floatController;
  late AnimationController _glowController;
  late AnimationController _eyeController;
  late Animation<double> _floatAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _eyeAnimation;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _eyeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _floatAnimation = Tween<double>(begin: -12, end: 12).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _eyeAnimation = Tween<double>(begin: 1.0, end: 0.1).animate(
      CurvedAnimation(parent: _eyeController, curve: Curves.easeInOut),
    );

    // Blink every 3 seconds
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return false;
      await _eyeController.forward();
      await _eyeController.reverse();
      return true;
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _glowController.dispose();
    _eyeController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [
          CustomPaint(
            painter: GridPainter(),
            size: Size.infinite,
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: isWide
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildMascot(),
                        const SizedBox(width: 60),
                        _buildRegisterCard(),
                      ],
                    )
                  : Column(
                      children: [
                        _buildMascot(),
                        const SizedBox(height: 30),
                        _buildRegisterCard(),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMascot() {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 200,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B)
                              .withOpacity(_glowAnimation.value * 0.5),
                          blurRadius: 60,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                    child: CustomPaint(
                      painter: RegisterMascotPainter(
                        eyeScale: _eyeAnimation.value,
                        glowValue: _glowAnimation.value,
                      ),
                      size: const Size(200, 220),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, _) => Container(
                      width: 100,
                      height: 14,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B)
                                .withOpacity(_glowAnimation.value * 0.6),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                        color: const Color(0xFFF59E0B)
                            .withOpacity(_glowAnimation.value * 0.3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Join Campus!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your account today 🚀',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRegisterCard() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, _) {
        return Container(
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFF59E0B)
                  .withOpacity(_glowAnimation.value * 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B)
                    .withOpacity(_glowAnimation.value * 0.15),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Register',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Create your campus account',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 28),

              _buildField(
                controller: _usernameController,
                label: 'Username',
                hint: 'Enter your username',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              _buildField(
                controller: _emailController,
                label: 'Email',
                hint: 'Enter your email',
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 16),

              _buildField(
                controller: _passwordController,
                label: 'Password',
                hint: 'Enter your password',
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                    shadowColor:
                        const Color(0xFFF59E0B).withOpacity(0.5),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: Color(0xFFF59E0B),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword ? _obscurePassword : false,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: Colors.white.withOpacity(0.25)),
            prefixIcon:
                Icon(icon, color: const Color(0xFFF59E0B), size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.white38,
                      size: 20,
                    ),
                    onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword),
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFF1F2937),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFFF59E0B), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// Same grid background
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(GridPainter _) => false;
}

// Register mascot — same lamp but AMBER/GOLD glow instead of green
class RegisterMascotPainter extends CustomPainter {
  final double eyeScale;
  final double glowValue;

  RegisterMascotPainter({required this.eyeScale, required this.glowValue});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final glowPaint = Paint()
      ..color = const Color(0xFFF59E0B).withOpacity(glowValue * 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset(cx, cy - 10), 75, glowPaint);

    final shadePaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;
    final shadePath = Path();
    shadePath.moveTo(cx - 65, cy + 10);
    shadePath.lineTo(cx + 65, cy + 10);
    shadePath.lineTo(cx + 45, cy - 60);
    shadePath.quadraticBezierTo(cx, cy - 90, cx - 45, cy - 60);
    shadePath.close();
    canvas.drawPath(shadePath, shadePaint);

    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    final highlightPath = Path();
    highlightPath.moveTo(cx - 30, cy + 5);
    highlightPath.lineTo(cx + 10, cy + 5);
    highlightPath.lineTo(cx, cy - 50);
    highlightPath.quadraticBezierTo(cx - 20, cy - 60, cx - 40, cy - 40);
    highlightPath.close();
    canvas.drawPath(highlightPath, highlightPaint);

    final facePaint = Paint()..color = const Color(0xFFFFB300);
    canvas.drawCircle(Offset(cx, cy - 10), 42, facePaint);

    final eyePaint = Paint()..color = Colors.white;
    final eyeHeight = 10.0 * eyeScale;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx - 14, cy - 12), width: 12, height: eyeHeight),
      eyePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx + 14, cy - 12), width: 12, height: eyeHeight),
      eyePaint,
    );

    if (eyeScale > 0.3) {
      final pupilPaint = Paint()..color = const Color(0xFF5D4037);
      canvas.drawCircle(Offset(cx - 14, cy - 12), 4, pupilPaint);
      canvas.drawCircle(Offset(cx + 14, cy - 12), 4, pupilPaint);
    }

    final smilePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final smilePath = Path();
    smilePath.moveTo(cx - 14, cy + 8);
    smilePath.quadraticBezierTo(cx, cy + 22, cx + 14, cy + 8);
    canvas.drawPath(smilePath, smilePaint);

    final tonguePaint = Paint()..color = const Color(0xFFE57373);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 16), width: 14, height: 9),
      tonguePaint,
    );

    final neckPaint = Paint()
      ..color = const Color(0xFF9E9E9E)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx, cy + 10), Offset(cx, cy + 60), neckPaint);

    final basePaint = Paint()..color = const Color(0xFF757575);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, cy + 70), width: 70, height: 18),
        const Radius.circular(9),
      ),
      basePaint,
    );

    final baseGlowPaint = Paint()
      ..color = const Color(0xFFF59E0B).withOpacity(glowValue * 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 78), width: 80, height: 12),
      baseGlowPaint,
    );

    final beamPaint = Paint()
      ..color = const Color(0xFFF59E0B).withOpacity(glowValue * 0.12)
      ..style = PaintingStyle.fill;
    final beamPath = Path();
    beamPath.moveTo(cx - 20, cy + 10);
    beamPath.lineTo(cx + 20, cy + 10);
    beamPath.lineTo(cx + 90, cy + 80);
    beamPath.lineTo(cx - 90, cy + 80);
    beamPath.close();
    canvas.drawPath(beamPath, beamPaint);
  }

  @override
  bool shouldRepaint(RegisterMascotPainter old) =>
      old.eyeScale != eyeScale || old.glowValue != glowValue;
}
