import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';

/// A single floating particle with mutable position, speed, and size.
class _Particle {
  double x;
  double y;
  double speed;
  double radius;
  double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.radius,
    required this.opacity,
  });
}

class HeroSection extends StatefulWidget {
  final int activeRafflesCount;
  final VoidCallback onViewRaffles;

  const HeroSection({
    super.key,
    required this.activeRafflesCount,
    required this.onViewRaffles,
  });

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _particleController;
  late AnimationController _glowController;
  late AnimationController _ctaPulseController;

  late List<_Particle> _particles;
  final int _particleCount = 35;

  bool _isCtaHovered = false;

  @override
  void initState() {
    super.initState();

    // Background shimmer
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Particle animation – continuous loop
    _particleController = AnimationController(
      duration: const Duration(seconds: 1), // tick rate, not total duration
      vsync: this,
    )..repeat();

    // Title glow breathing
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    )..repeat(reverse: true);

    // CTA pulsating glow
    _ctaPulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // Initialise particles with random positions
    _initParticles();
  }

  void _initParticles() {
    final random = math.Random(42);
    _particles = List.generate(_particleCount, (_) {
      return _Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        speed: 0.0003 + random.nextDouble() * 0.0008, // normalised speed
        radius: 0.8 + random.nextDouble() * 2.0,
        opacity: 0.08 + random.nextDouble() * 0.18,
      );
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    _ctaPulseController.dispose();
    super.dispose();
  }

  // ── Layout helpers ──────────────────────────────────────────────────────
  bool _isTablet(double width) => width > 600 && width <= 1000;
  bool _isDesktop(double width) => width > 1000;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = _isDesktop(width);
    final isTablet = _isTablet(width);

    return Container(
      constraints: BoxConstraints(
        minHeight: isDesktop ? 420 : (isTablet ? 360 : 320),
        maxHeight: isDesktop ? 500 : (isTablet ? 420 : 380),
      ),
      child: Stack(
        children: [
          _buildBackground(),
          _buildAnimatedParticles(),
          _buildGradientOverlay(),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 80 : (isTablet ? 40 : 24),
                vertical: isDesktop ? 60 : (isTablet ? 40 : 32),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBadge(),
                  const SizedBox(height: 16),
                  _buildTitle(isDesktop, isTablet),
                  const SizedBox(height: 12),
                  _buildSubtitle(isDesktop, isTablet),
                  const SizedBox(height: 24),
                  _buildCTAButton(isDesktop),
                  if (widget.activeRafflesCount > 0) ...[
                    const SizedBox(height: 16),
                    _buildStatsRow(isDesktop),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Background ──────────────────────────────────────────────────────────
  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.08),
                AppTheme.backgroundColor,
                AppTheme.primaryColor.withValues(alpha: 0.04),
              ],
              stops: [
                _shimmerController.value * 0.3,
                0.5,
                0.5 + (_shimmerController.value * 0.5),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Animated Particles ──────────────────────────────────────────────────
  Widget _buildAnimatedParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        // Advance each particle upward every frame
        for (final p in _particles) {
          p.y -= p.speed;
          // Horizontal drift for organic feel
          p.x += math.sin(p.y * 12) * 0.0002;
          // Reset when above the viewport
          if (p.y < -0.02) {
            p.y = 1.02;
            p.x = math.Random().nextDouble();
          }
          // Wrap horizontal
          if (p.x < 0) p.x = 1.0;
          if (p.x > 1) p.x = 0.0;
        }
        return CustomPaint(
          painter: _AnimatedParticlePainter(particles: _particles),
          child: const SizedBox.expand(),
        );
      },
    );
  }

  // ── Gradient overlay ────────────────────────────────────────────────────
  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              AppTheme.backgroundColor.withValues(alpha: 0.3),
              AppTheme.backgroundColor.withValues(alpha: 0.8),
              AppTheme.backgroundColor,
            ],
            stops: const [0.0, 0.4, 0.7, 1.0],
          ),
        ),
      ),
    );
  }

  // ── Badge ───────────────────────────────────────────────────────────────
  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppTheme.secondaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${widget.activeRafflesCount} RIFA${widget.activeRafflesCount != 1 ? 'S' : ''} ACTIVA${widget.activeRafflesCount != 1 ? 'S' : ''}',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(
            begin: -0.3,
            end: 0,
            duration: 500.ms,
            curve: Curves.easeOutCubic);
  }

  // ── Title with pulsating glow ───────────────────────────────────────────
  Widget _buildTitle(bool isDesktop, bool isTablet) {
    final fontSize = isDesktop ? 48.0 : (isTablet ? 36.0 : 28.0);

    return Stack(
      children: [
        // Pulsating golden glow behind the title
        AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            final glowValue =
                Curves.easeInOut.transform(_glowController.value);
            return Positioned(
              left: -20,
              top: -10,
              child: Container(
                width: isDesktop ? 260 : (isTablet ? 200 : 160),
                height: isDesktop ? 260 : (isTablet ? 200 : 160),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryColor
                          .withValues(alpha: 0.06 + glowValue * 0.08),
                      AppTheme.primaryColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        // Title text
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Tu próxima ',
                style: GoogleFonts.outfit(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w300,
                  color: AppTheme.textPrimary,
                  height: 1.1,
                ),
              ),
              TextSpan(
                text: 'oportunidad',
                style: GoogleFonts.outfit(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                  height: 1.1,
                  shadows: [
                    Shadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
              TextSpan(
                text: '\nte está esperando',
                style: GoogleFonts.outfit(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w300,
                  color: AppTheme.textPrimary,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 200.ms)
        .slideY(
            begin: 0.2,
            end: 0,
            duration: 700.ms,
            curve: Curves.easeOutCubic)
        .then(delay: 300.ms)
        .shimmer(
          duration: 1800.ms,
          color: AppTheme.primaryColor.withValues(alpha: 0.12),
        );
  }

  // ── Subtitle ────────────────────────────────────────────────────────────
  Widget _buildSubtitle(bool isDesktop, bool isTablet) {
    return Text(
      'Selecciona tus números de la suerte y recibe tu ticket directamente por WhatsApp. ¡Fácil, rápido y seguro!',
      style: GoogleFonts.outfit(
        fontSize: isDesktop ? 18 : (isTablet ? 15 : 14),
        color: AppTheme.textSecondary,
        height: 1.5,
        fontWeight: FontWeight.w400,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 400.ms)
        .slideY(
            begin: 0.2,
            end: 0,
            duration: 600.ms,
            curve: Curves.easeOutCubic);
  }

  // ── CTA Button with scale on hover + pulsating glow ─────────────────────
  Widget _buildCTAButton(bool isDesktop) {
    return AnimatedBuilder(
      animation: _ctaPulseController,
      builder: (context, child) {
        final pulseValue =
            Curves.easeInOut.transform(_ctaPulseController.value);
        final glowAlpha = 0.30 + pulseValue * 0.25;
        final glowBlur = 18.0 + pulseValue * 14.0;

        return MouseRegion(
          onEnter: (_) => setState(() => _isCtaHovered = true),
          onExit: (_) => setState(() => _isCtaHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onViewRaffles,
            child: AnimatedScale(
              scale: _isCtaHovered ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 40 : 32,
                  vertical: isDesktop ? 18 : 14,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: glowAlpha),
                      blurRadius: glowBlur,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: AppTheme.primaryColor
                          .withValues(alpha: glowAlpha * 0.3),
                      blurRadius: glowBlur * 2,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'VER RIFAS DISPONIBLES',
                      style: GoogleFonts.outfit(
                        fontSize: isDesktop ? 16 : 14,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.backgroundColor,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded,
                        color: AppTheme.backgroundColor, size: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 600.ms)
        .slideY(
            begin: 0.3,
            end: 0,
            duration: 600.ms,
            curve: Curves.easeOutCubic)
        .then()
        .shimmer(
            duration: const Duration(seconds: 2),
            delay: const Duration(seconds: 1));
  }

  // ── Stats Row ───────────────────────────────────────────────────────────
  Widget _buildStatsRow(bool isDesktop) {
    return Row(
      children: [
        _buildStatItem(
          icon: Icons.emoji_events_rounded,
          label: 'Premios',
          value: 'Garantizados',
          isDesktop: isDesktop,
        ),
        const SizedBox(width: 24),
        _buildStatItem(
          icon: Icons.security_rounded,
          label: '100%',
          value: 'Seguro',
          isDesktop: isDesktop,
        ),
        const SizedBox(width: 24),
        _buildStatItem(
          icon: Icons.phone_android_rounded,
          label: 'Ticket',
          value: 'WhatsApp',
          isDesktop: isDesktop,
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 800.ms)
        .slideY(
            begin: 0.2,
            end: 0,
            duration: 600.ms,
            curve: Curves.easeOutCubic);
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDesktop,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              color: AppTheme.primaryColor, size: isDesktop ? 20 : 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: isDesktop ? 14 : 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: isDesktop ? 11 : 10,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Animated particle painter – repaints every frame via the controller.
// ═══════════════════════════════════════════════════════════════════════════
class _AnimatedParticlePainter extends CustomPainter {
  final List<_Particle> particles;

  _AnimatedParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = AppTheme.primaryColor.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedParticlePainter oldDelegate) => true;
}
