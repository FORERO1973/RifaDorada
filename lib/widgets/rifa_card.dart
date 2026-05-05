import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../models/rifa.dart';

class RifaCard extends StatefulWidget {
  final Rifa rifa;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showDetails;

  const RifaCard({
    super.key,
    required this.rifa,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showDetails = false,
  });

  @override
  State<RifaCard> createState() => _RifaCardState();
}

class _RifaCardState extends State<RifaCard> with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: AppTheme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              blurRadius: 2,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: GestureDetector(
            onTapDown: (_) => _pressController.forward(),
            onTapUp: (_) {
              _pressController.reverse();
              widget.onTap?.call();
            },
            onTapCancel: () => _pressController.reverse(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageHeader(context),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.rifa.nombre.toUpperCase(),
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                if (widget.rifa.organizacion != null)
                                  Text(
                                    widget.rifa.organizacion!,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (widget.onEdit != null || widget.onDelete != null)
                            _buildAdminActions(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDescription(context),
                      const Divider(height: 32, color: AppTheme.dividerColor),
                      _buildFooter(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageHeader(BuildContext context) {
    final hasImage = widget.rifa.imagenes.isNotEmpty;

    return Stack(
      children: [
        Container(
          height: 160,
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
                        size: 48,
                        color: AppTheme.backgroundColor.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            size: 14,
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
                            size: 14,
                            color: AppTheme.backgroundColor.withValues(alpha: 0.25),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
        // Overlay Gradient
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
                stops: const [0.4, 1.0],
              ),
            ),
          ),
        ),
        // Status Badge
        Positioned(
          top: 12,
          left: 12,
          child: _buildStatusBadge(),
        ),
        // Type badge
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              widget.rifa.tipoRifa,
              style: GoogleFonts.outfit(
                color: AppTheme.primaryColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        // Prize Badge (if any)
        if (widget.rifa.numeroGanador != null)
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_rounded, size: 16, color: AppTheme.backgroundColor),
                  const SizedBox(width: 4),
                  Text(
                    'GANADOR: ${widget.rifa.numeroGanador}',
                    style: const TextStyle(
                      color: AppTheme.backgroundColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Bottom info overlay
        if (widget.rifa.loteria != null)
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_rounded, size: 12, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    widget.rifa.loteria!,
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 11,
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
    if (path.isEmpty) return const Center(child: Icon(Icons.broken_image));

    if (path.startsWith('http') || path.startsWith('blob:')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.white24)),
      );
    }
    
    if (kIsWeb) {
      // En Web, si no es una URL/Blob, no podemos cargarla como File
      return const Center(child: Icon(Icons.broken_image, color: Colors.white24));
    }

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.white24)),
    );
  }

  Widget _buildStatusBadge() {
    final color = widget.rifa.activa ? AppTheme.secondaryColor : AppTheme.errorColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            widget.rifa.activa ? 'ACTIVA' : 'CERRADA',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.onEdit != null)
          _buildCircleButton(icon: Icons.edit_rounded, color: Colors.blue, onTap: widget.onEdit!),
        if (widget.onDelete != null)
          _buildCircleButton(icon: Icons.delete_outline_rounded, color: AppTheme.errorColor, onTap: widget.onDelete!),
      ],
    );
  }

  Widget _buildCircleButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Material(
        color: Colors.white.withValues(alpha: 0.05),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }


  Widget _buildDescription(BuildContext context) {
    if (widget.rifa.descripcion.isEmpty && !widget.showDetails && widget.rifa.loteria == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.rifa.descripcion.isNotEmpty)
          Text(
            widget.rifa.descripcion,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (widget.rifa.diaSorteo != null)
              _buildTag(
                icon: Icons.calendar_today_rounded,
                text: widget.rifa.fechaSorteo != null 
                    ? '${widget.rifa.diaSorteo} ${DateFormat('dd MMM', 'es').format(widget.rifa.fechaSorteo!)}'
                    : widget.rifa.diaSorteo!,
              ),

            _buildTag(
              icon: Icons.tag_rounded,
              text: '${widget.rifa.cantidadNumeros} números',
            ),

          ],
        ),
      ],
    );
  }

  Widget _buildTag({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VALOR DEL NÚMERO',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                letterSpacing: 1,
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppConstants.formatCurrencyCOP(widget.rifa.precioNumero),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppTheme.goldGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.backgroundColor,
            size: 32,
          ),
        ),
      ],
    );
  }

}