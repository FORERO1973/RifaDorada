import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../models/rifa.dart';

class RifaCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceColor.withValues(alpha: 0.9),
            AppTheme.backgroundColor.withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderImage(context),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 16),
                    _buildDescription(context),
                    const SizedBox(height: 24),
                    _buildFooter(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderImage(BuildContext context) {
    return Container(
      height: 8,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.goldGradient,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                rifa.nombre,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onEdit != null || onDelete != null)
              Row(
                children: [
                  if (onEdit != null)
                    _buildIconButton(
                      icon: Icons.edit_rounded,
                      color: Colors.blue,
                      onTap: onEdit!,
                    ),
                  if (onDelete != null)
                    _buildIconButton(
                      icon: Icons.delete_rounded,
                      color: AppTheme.errorColor,
                      onTap: onDelete!,
                    ),
                  const SizedBox(width: 8),
                ],
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: rifa.activa
                    ? AppTheme.secondaryColor.withValues(alpha: 0.1)
                    : AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: rifa.activa ? AppTheme.secondaryColor.withValues(alpha: 0.3) : AppTheme.errorColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: rifa.activa ? AppTheme.secondaryColor : AppTheme.errorColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (rifa.activa ? AppTheme.secondaryColor : AppTheme.errorColor).withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    rifa.activa ? 'ACTIVA' : 'CERRADA',
                    style: TextStyle(
                      color: rifa.activa ? AppTheme.secondaryColor : AppTheme.errorColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }


  Widget _buildDescription(BuildContext context) {
    if (rifa.descripcion.isEmpty && !showDetails && rifa.loteria == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rifa.descripcion.isNotEmpty)
          Text(
            rifa.descripcion,
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
            if (rifa.loteria != null)
              _buildTag(
                icon: Icons.account_balance_rounded,
                text: rifa.loteria!,
              ),
            if (rifa.diaSorteo != null)
              _buildTag(
                icon: Icons.calendar_today_rounded,
                text: rifa.fechaSorteo != null 
                    ? '${rifa.diaSorteo} ${DateFormat('dd MMM', 'es').format(rifa.fechaSorteo!)}'
                    : rifa.diaSorteo!,
              ),

            _buildTag(
              icon: Icons.style_rounded,
              text: rifa.tipoRifa,
            ),
            _buildTag(
              icon: Icons.tag_rounded,
              text: '${rifa.cantidadNumeros} números',
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
              AppConstants.formatCurrencyCOP(rifa.precioNumero),
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