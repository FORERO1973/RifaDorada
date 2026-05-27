import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../models/rifa.dart';

class PremiumRaffleCard extends StatefulWidget {
  final Rifa rifa;
  final int vendidos;
  final int total;
  final VoidCallback onTap;
  final int animationDelay;

  const PremiumRaffleCard({
    super.key,
    required this.rifa,
    required this.vendidos,
    required this.total,
    required this.onTap,
    this.animationDelay = 0,
  });

  @override
  State<PremiumRaffleCard> createState() => _PremiumRaffleCardState();
}

class _PremiumRaffleCardState extends State<PremiumRaffleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final progreso = widget.total > 0 ? widget.vendidos / widget.total : 0.0;
    final isNew = DateTime.now().difference(widget.rifa.fechaCreacion).inDays <= 2;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          transform: _isHovered
              ? Matrix4.translationValues(0, -4, 0)
              : Matrix4.identity(),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppTheme.cardColor,
              border: Border.all(
                color: _isHovered
                    ? AppTheme.primaryColor.withValues(alpha: 0.3)
                    : AppTheme.primaryColor.withValues(alpha: 0.08),
                width: _isHovered ? 1.5 : 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: _isHovered ? 0.4 : 0.25,
                  ),
                  blurRadius: _isHovered ? 25 : 15,
                  offset: Offset(0, _isHovered ? 12 : 8),
                ),
                if (_isHovered)
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardImage(isNew),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCardHeader(),
                        const SizedBox(height: 12),
                        _buildCardDescription(),
                        const SizedBox(height: 16),
                        _buildCardFooter(),
                        const SizedBox(height: 12),
                        _buildProgress(progreso),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(
              duration: 500.ms,
              delay: Duration(milliseconds: widget.animationDelay),
            )
            .slideY(
              begin: 0.3,
              end: 0,
              duration: 500.ms,
              delay: Duration(milliseconds: widget.animationDelay),
              curve: Curves.easeOutCubic,
            ),
      ),
    );
  }

  Widget _buildCardImage(bool isNew) {
    final hasImage = widget.rifa.imagenes.isNotEmpty;

    return Stack(
      children: [
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: AppTheme.goldGradient,
          ),
          child: hasImage
              ? _buildImageWidget(widget.rifa.imagenes.first)
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.celebration_rounded,
                        size: 40,
                        color: AppTheme.backgroundColor.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            size: 12,
                            color: AppTheme.backgroundColor.withValues(alpha: 0.25),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'RIFA DORADA',
                            style: GoogleFonts.outfit(
                              color: AppTheme.backgroundColor.withValues(alpha: 0.25),
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.stars_rounded,
                            size: 12,
                            color: AppTheme.backgroundColor.withValues(alpha: 0.25),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.75),
                ],
                stops: const [0.3, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          top: 10,
          left: 10,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.5),
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
                    const SizedBox(width: 4),
                    Text(
                      'ACTIVA',
                      style: GoogleFonts.outfit(
                        color: AppTheme.secondaryColor,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              if (isNew) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withValues(alpha: 0.9),
                        const Color(0xFFFFA000).withValues(alpha: 0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome_rounded, size: 10, color: AppTheme.backgroundColor),
                      const SizedBox(width: 3),
                      Text(
                        'NUEVA',
                        style: GoogleFonts.outfit(
                          color: AppTheme.backgroundColor,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.rifa.tipoRifa.toUpperCase(),
              style: GoogleFonts.outfit(
                color: AppTheme.primaryColor,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        if (widget.rifa.fechaSorteo != null)
          Positioned(
            bottom: 10,
            right: 10,
            child: _buildCountdownBadge(widget.rifa.fechaSorteo!),
          ),
        if (widget.rifa.loteria != null)
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_rounded, size: 10, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    widget.rifa.loteria!,
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageWidget(String path) {
    if (path.isEmpty) {
      return const Center(child: Icon(Icons.broken_image));
    }

    if (path.startsWith('http') || path.startsWith('blob:')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Center(child: Icon(Icons.broken_image, color: Colors.white24)),
      );
    }

    if (path.startsWith('data:image/')) {
      return const Center(
        child: Icon(Icons.image_rounded, color: Colors.white54, size: 40),
      );
    }

    return const Center(child: Icon(Icons.broken_image, color: Colors.white24));
  }

  Widget _buildCountdownBadge(DateTime fechaSorteo) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final now = DateTime.now();
        final diff = fechaSorteo.difference(now);

        if (diff.isNegative) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'FINALIZADA',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                fontSize: 8,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          );
        }

        final days = diff.inDays;
        final hours = diff.inHours % 24;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined, color: AppTheme.primaryColor, size: 10),
              const SizedBox(width: 4),
              Text(
                '$days d ${hours}h',
                style: GoogleFonts.outfit(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.rifa.nombre.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        if (widget.rifa.organizacion != null) ...[
          const SizedBox(height: 3),
          Text(
            widget.rifa.organizacion!,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCardDescription() {
    if (widget.rifa.descripcion.isEmpty) return const SizedBox.shrink();

    return Text(
      widget.rifa.descripcion,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.outfit(
        fontSize: 12,
        color: AppTheme.textSecondary,
        height: 1.4,
      ),
    );
  }

  Widget _buildCardFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VALOR POR NÚMERO',
              style: GoogleFonts.outfit(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: AppTheme.textSecondary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              AppConstants.formatCurrencyCOP(widget.rifa.precioNumero),
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppTheme.goldGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_forward_rounded,
            color: AppTheme.backgroundColor,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildProgress(double progreso) {
    final porcentaje = (progreso * 100).toInt();
    Color progressColor;
    if (progreso > 0.8) {
      progressColor = AppTheme.secondaryColor;
    } else if (progreso > 0.5) {
      progressColor = AppTheme.primaryColor;
    } else {
      progressColor = AppTheme.primaryDark;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${widget.vendidos}/${widget.total} vendidos',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              '$porcentaje%',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: progressColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progreso.clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: AppTheme.dividerColor.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
      ],
    );
  }
}

class RaffleCardSkeleton extends StatelessWidget {
  const RaffleCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            width: double.infinity,
            color: AppTheme.surfaceColor,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _skeletonBox(width: 120, height: 16),
                const SizedBox(height: 8),
                _skeletonBox(width: 80, height: 10),
                const SizedBox(height: 16),
                _skeletonBox(width: double.infinity, height: 12),
                const SizedBox(height: 6),
                _skeletonBox(width: double.infinity * 0.7, height: 12),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _skeletonBox(width: 80, height: 30),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _skeletonBox(width: double.infinity, height: 5),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .shimmer(duration: 1.5.seconds, color: AppTheme.surfaceColor.withValues(alpha: 0.5));
  }

  Widget _skeletonBox({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
