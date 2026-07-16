import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Firefly> _fireflies = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..addListener(() {
        _updateFireflies();
      })..repeat();

    _generateFireflies();
  }

  void _generateFireflies() {
    final random = math.Random();
    for (int i = 0; i < 20; i++) {
      _fireflies.add(Firefly(
        x: random.nextDouble(),
        y: random.nextDouble(),
        radius: random.nextDouble() * 3 + 1.5,
        speedX: (random.nextDouble() - 0.5) * 0.0015,
        speedY: (random.nextDouble() - 0.5) * 0.0015,
        maxOpacity: random.nextDouble() * 0.5 + 0.2,
      ));
    }
  }

  void _updateFireflies() {
    if (!mounted) return;
    setState(() {
      for (var f in _fireflies) {
        f.x += f.speedX;
        f.y += f.speedY;

        // Bounce/Wrap boundaries
        if (f.x < 0 || f.x > 1) f.speedX *= -1;
        if (f.y < 0 || f.y > 1) f.speedY *= -1;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final gradientColors = isDark
        ? [
            theme.colorScheme.background,
            theme.colorScheme.primary.withOpacity(0.08),
            theme.colorScheme.background,
          ]
        : [
            const Color(0xFFF0F2FD),
            theme.colorScheme.primary.withOpacity(0.05),
            const Color(0xFFF8F9FE),
          ];

    return Stack(
      children: [
        // Smooth shifting background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
        ),
        
        // Floating Firefly Embers
        CustomPaint(
          painter: FireflyPainter(
            fireflies: _fireflies,
            color: theme.colorScheme.primary.withOpacity(0.6),
          ),
          child: Container(),
        ),

        // Foreground content
        widget.child,
      ],
    );
  }
}

class Firefly {
  double x;
  double y;
  double radius;
  double speedX;
  double speedY;
  double maxOpacity;
  double currentOpacity = 0.0;

  Firefly({
    required this.x,
    required this.y,
    required this.radius,
    required this.speedX,
    required this.speedY,
    required this.maxOpacity,
  });
}

class FireflyPainter extends CustomPainter {
  final List<Firefly> fireflies;
  final Color color;

  FireflyPainter({required this.fireflies, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    for (var f in fireflies) {
      final pulse = (math.sin(f.x * 2 * math.pi) + 1.0) / 2.0;
      paint.color = color.withOpacity(f.maxOpacity * pulse);
      
      canvas.drawCircle(
        Offset(f.x * size.width, f.y * size.height),
        f.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
