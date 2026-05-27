import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';

class FooterSection extends StatelessWidget {
  final VoidCallback? onGoToAdmin;
  final VoidCallback? onScrollToTop;
  final VoidCallback? onScrollToRaffles;
  final String? whatsappNumber;

  const FooterSection({
    super.key,
    this.onGoToAdmin,
    this.onScrollToTop,
    this.onScrollToRaffles,
    this.whatsappNumber,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1000;
    final isTablet = width > 600 && width <= 1000;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : (isTablet ? 40 : 24),
        vertical: isDesktop ? 60 : 40,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          top: BorderSide(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          isDesktop || isTablet
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildBrand()),
                    const SizedBox(width: 40),
                    Expanded(child: _buildQuickLinks()),
                    const SizedBox(width: 40),
                    Expanded(child: _buildContact()),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBrand(),
                    const SizedBox(height: 32),
                    _buildQuickLinks(),
                    const SizedBox(height: 32),
                    _buildContact(),
                  ],
                ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppTheme.dividerColor.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '© 2026 RifaDorada. Todos los derechos reservados.',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.textSecondary.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  'v1.0.0',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppTheme.textSecondary.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildBrand() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.confirmation_number_rounded,
                color: AppTheme.backgroundColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'RifaDorada',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 280,
          child: Text(
            'La plataforma más confiable para participar en rifas en Colombia. Transparencia, seguridad y emoción en cada sorteo.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildQuickLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ENLACES RÁPIDOS',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryColor,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        _buildLinkItem(Icons.home_rounded, 'Inicio', () {
          onScrollToTop?.call();
        }),
        _buildLinkItem(Icons.style_rounded, 'Rifas Activas', () {
          onScrollToRaffles?.call();
        }),
        _buildLinkItem(Icons.message_rounded, 'WhatsApp Directo', () {
          final number = whatsappNumber ?? '573001234567';
          final url = 'https://wa.me/$number';
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }),
        if (onGoToAdmin != null)
          _buildLinkItem(Icons.admin_panel_settings_rounded, 'Administración', onGoToAdmin!),
      ],
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 100.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildLinkItem(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONTACTO',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryColor,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        if (whatsappNumber != null)
          _buildContactItem(
            Icons.chat_rounded,
            'WhatsApp',
            whatsappNumber!,
            () {
              final url = 'https://wa.me/$whatsappNumber';
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
          ),
        _buildContactItem(
          Icons.schedule_rounded,
          'Horario',
          'Lun - Dom: 8am - 8pm',
          null,
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 200.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildContactItem(
    IconData icon,
    String label,
    String value,
    VoidCallback? onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppTheme.textSecondary.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      value,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
