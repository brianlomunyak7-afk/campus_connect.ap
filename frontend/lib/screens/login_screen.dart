import 'forgot_password_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_storage.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8001/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        // ✅ Login successful
        final data = jsonDecode(response.body);
        final token = data['access_token'];

        // Save token for later use
       await AuthStorage.saveToken(token, data['username'] ?? '');

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else if (response.statusCode == 401) {
        // ❌ Wrong password or email
        _showError('Wrong email or password. Try again!');
      } else {
        _showError('Something went wrong. Please try again.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Cannot connect to server. Is the backend running?');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [
          // Background grid pattern
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
                        _buildLoginCard(),
                      ],
                    )
                  : Column(
                      children: [
                        _buildMascot(),
                        const SizedBox(height: 30),
                        _buildLoginCard(),
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
                  // Glow container around mascot
                  Container(
                    width: 200,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E676)
                              .withOpacity(_glowAnimation.value * 0.5),
                          blurRadius: 60,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                    child: CustomPaint(
                      painter: MascotPainter(
                        eyeScale: _eyeAnimation.value,
                        glowValue: _glowAnimation.value,
                      ),
                      size: const Size(200, 220),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Glow shadow under mascot
                  AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, _) => Container(
                      width: 100,
                      height: 14,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E676)
                                .withOpacity(_glowAnimation.value * 0.6),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                        color: const Color(0xFF00E676)
                            .withOpacity(_glowAnimation.value * 0.3),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your campus awaits 🎓',
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

  Widget _buildLoginCard() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, _) {
        return Container(
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF00E676)
                  .withOpacity(_glowAnimation.value * 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E676)
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
                'Login',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sign in to your account',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 28),

              // Email
              _buildField(
                controller: _emailController,
                label: 'Email',
                hint: 'Enter your email',
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 16),

              // Password
              _buildField(
                controller: _passwordController,
                label: 'Password',
                hint: 'Enter your password',
                icon: Icons.lock_outline,
                isPassword: true,
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Login button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                    shadowColor:
                        const Color(0xFF00E676).withOpacity(0.5),
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
                          'Login',
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
                    "Don't have an account? ",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen()),
                    ),
                    child: const Text(
                      'Register',
                      style: TextStyle(
                        color: Color(0xFF00E676),
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
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
            prefixIcon:
                Icon(icon, color: const Color(0xFF00E676), size: 20),
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
                  color: Color(0xFF00E676), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// Mascot painter — animated lamp character
class MascotPainter extends CustomPainter {
  final double eyeScale;
  final double glowValue;

  MascotPainter({required this.eyeScale, required this.glowValue});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Body glow
    final glowPaint = Paint()
      ..color = const Color(0xFF00E676).withOpacity(glowValue * 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset(cx, cy - 10), 75, glowPaint);

    // Lamp shade (triangle-ish top)
    final shadePaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.fill;

    final shadePath = Path();
    shadePath.moveTo(cx - 65, cy + 10);
    shadePath.lineTo(cx + 65, cy + 10);
    shadePath.lineTo(cx + 45, cy - 60);
    shadePath.quadraticBezierTo(cx, cy - 90, cx - 45, cy - 60);
    shadePath.close();
    canvas.drawPath(shadePath, shadePaint);

    // Shade highlight
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

    // Face area (lighter circle)
    final facePaint = Paint()..color = const Color(0xFF66BB6A);
    canvas.drawCircle(Offset(cx, cy - 10), 42, facePaint);

    // Eyes
    final eyePaint = Paint()..color = Colors.white;
    final eyeHeight = 10.0 * eyeScale;

    // Left eye
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx - 14, cy - 12),
          width: 12,
          height: eyeHeight),
      eyePaint,
    );
    // Right eye
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx + 14, cy - 12),
          width: 12,
          height: eyeHeight),
      eyePaint,
    );

    // Pupils
    if (eyeScale > 0.3) {
      final pupilPaint = Paint()..color = const Color(0xFF1B5E20);
      canvas.drawCircle(Offset(cx - 14, cy - 12), 4, pupilPaint);
      canvas.drawCircle(Offset(cx + 14, cy - 12), 4, pupilPaint);
    }

    // Smile
    final smilePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final smilePath = Path();
    smilePath.moveTo(cx - 14, cy + 8);
    smilePath.quadraticBezierTo(cx, cy + 22, cx + 14, cy + 8);
    canvas.drawPath(smilePath, smilePaint);

    // Tongue
    final tonguePaint = Paint()..color = const Color(0xFFE57373);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + 16), width: 14, height: 9),
      tonguePaint,
    );

    // Lamp neck
    final neckPaint = Paint()
      ..color = const Color(0xFF9E9E9E)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(cx, cy + 10), Offset(cx, cy + 60), neckPaint);

    // Base
    final basePaint = Paint()..color = const Color(0xFF757575);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, cy + 70), width: 70, height: 18),
        const Radius.circular(9),
      ),
      basePaint,
    );

    // Base glow
    final baseGlowPaint = Paint()
      ..color =
          const Color(0xFF00E676).withOpacity(glowValue * 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + 78), width: 80, height: 12),
      baseGlowPaint,
    );

    // Light beam from lamp
    final beamPaint = Paint()
      ..color =
          const Color(0xFF00E676).withOpacity(glowValue * 0.12)
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
  bool shouldRepaint(MascotPainter old) =>
      old.eyeScale != eyeScale || old.glowValue != glowValue;
}

// Background grid painter
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
