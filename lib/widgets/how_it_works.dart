import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';

class HowItWorks extends StatelessWidget {
  const HowItWorks({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1000;
    final isTablet = width > 600 && width <= 1000;

    final steps = [
      _StepData(
        icon: Icons.style_rounded,
        number: '01',
        title: 'Elige tu Rifa',
        description: 'Explora las rifas disponibles y selecciona la que más te guste.',
      ),
      _StepData(
        icon: Icons.pin_rounded,
        number: '02',
        title: 'Selecciona tus Números',
        description: 'Escoge tus números de la suerte del grid interactivo.',
      ),
      _StepData(
        icon: Icons.mark_email_read_rounded,
        number: '03',
        title: 'Recibe tu Ticket',
        description: 'Completa tus datos y recibe tu ticket automáticamente por WhatsApp.',
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : (isTablet ? 40 : 24),
        vertical: isDesktop ? 60 : 40,
      ),
      child: Column(
        children: [
          Text(
            '¿CÓMO FUNCIONA?',
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
          Text(
            'Participar es muy fácil',
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
          isDesktop || isTablet
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: steps.asMap().entries.map((entry) {
                    final index = entry.key;
                    final step = entry.value;
                    return Expanded(
                      child: _buildStepCard(step, index, isDesktop),
                    );
                  }).toList(),
                )
              : Column(
                  children: steps.asMap().entries.map((entry) {
                    final index = entry.key;
                    final step = entry.value;
                    return _buildStepCard(step, index, false);
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildStepCard(_StepData step, int index, bool isDesktop) {
    return Padding(
      padding: EdgeInsets.only(
        right: isDesktop && index < 2 ? 20 : 0,
        bottom: isDesktop ? 0 : 16,
      ),
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 28 : 20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    step.icon,
                    color: AppTheme.backgroundColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  step.number,
                  style: GoogleFonts.outfit(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              step.title,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              step.description,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 500.ms, delay: Duration(milliseconds: 200 + (index * 150)))
          .slideY(begin: 0.3, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),
    );
  }
}

class _StepData {
  final IconData icon;
  final String number;
  final String title;
  final String description;

  _StepData({
    required this.icon,
    required this.number,
    required this.title,
    required this.description,
  });
}
