import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';

class TrustSection extends StatefulWidget {
  const TrustSection({super.key});

  @override
  State<TrustSection> createState() => _TrustSectionState();
}

class _TrustSectionState extends State<TrustSection> {
  int _hoveredIndex = -1;

  static final List<_TrustCardData> _cards = [
    _TrustCardData(
      icon: Icons.shield_rounded,
      title: '100% Seguro',
      description:
          'Tus datos protegidos y transacciones verificadas en todo momento.',
    ),
    _TrustCardData(
      icon: Icons.visibility_rounded,
      title: 'Totalmente Transparente',
      description:
          'Cada número vendido se actualiza en tiempo real para todos los participantes.',
    ),
    _TrustCardData(
      icon: Icons.flash_on_rounded,
      title: 'Ticket Inmediato',
      description:
          'Recibe tu comprobante al instante por WhatsApp con todos los detalles.',
    ),
    _TrustCardData(
      icon: Icons.support_agent_rounded,
      title: 'Soporte Dedicado',
      description:
          'Estamos disponibles para ayudarte en cada paso del proceso.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1000;
    final isTablet = width > 600 && width <= 1000;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : (isTablet ? 40 : 24),
        vertical: isDesktop ? 60 : 40,
      ),
      child: Column(
        children: [
          // ── Section title ──
          Text(
            '¿POR QUÉ RIFADORADA?',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
              letterSpacing: 3,
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.2, end: 0),

          const SizedBox(height: 8),

          // ── Subtitle ──
          Text(
            'Tu confianza es nuestra prioridad',
            style: GoogleFonts.outfit(
              fontSize: isDesktop ? 32 : (isTablet ? 26 : 22),
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms)
              .slideY(begin: 0.2, end: 0),

          const SizedBox(height: 40),

          // ── Card grid ──
          _buildCardGrid(isDesktop, isTablet),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Responsive grid builder
  // ─────────────────────────────────────────────
  Widget _buildCardGrid(bool isDesktop, bool isTablet) {
    if (isDesktop) {
      // 4 columns
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _cards.asMap().entries.map((entry) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: entry.key < 3 ? 16 : 0,
              ),
              child: _buildCard(entry.value, entry.key),
            ),
          );
        }).toList(),
      );
    }

    if (isTablet) {
      // 2 columns × 2 rows
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildCard(_cards[0], 0),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _buildCard(_cards[1], 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildCard(_cards[2], 2),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _buildCard(_cards[3], 3),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Mobile – single column
    return Column(
      children: _cards.asMap().entries.map((entry) {
        return Padding(
          padding: EdgeInsets.only(bottom: entry.key < 3 ? 16 : 0),
          child: _buildCard(entry.value, entry.key),
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────
  // Individual trust card
  // ─────────────────────────────────────────────
  Widget _buildCard(_TrustCardData card, int index) {
    final isHovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      cursor: SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, isHovered ? -6 : 0, 0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardColor.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryColor
                .withValues(alpha: isHovered ? 0.25 : 0.10),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor
                  .withValues(alpha: isHovered ? 0.12 : 0.04),
              blurRadius: isHovered ? 28 : 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon circle with gold gradient
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                card.icon,
                color: AppTheme.backgroundColor,
                size: 24,
              ),
            ),

            const SizedBox(height: 18),

            // Title
            Text(
              card.title,
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            // Description
            Text(
              card.description,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: 500.ms,
          delay: Duration(milliseconds: 200 + (index * 120)),
        )
        .slideY(
          begin: 0.25,
          end: 0,
          duration: 500.ms,
          delay: Duration(milliseconds: 200 + (index * 120)),
          curve: Curves.easeOutCubic,
        );
  }
}

// ─────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────
class _TrustCardData {
  final IconData icon;
  final String title;
  final String description;

  const _TrustCardData({
    required this.icon,
    required this.title,
    required this.description,
  });
}
