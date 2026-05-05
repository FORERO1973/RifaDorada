import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../models/participante.dart';
import '../models/rifa.dart';
import '../utils/web_helper.dart';

class TicketScreen extends StatefulWidget {
  final Participante participante;
  final Rifa rifa;

  const TicketScreen({
    super.key,
    required this.participante,
    required this.rifa,
  });

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Digital'),
        actions: [
          IconButton(
            icon: Icon(kIsWeb ? Icons.download_rounded : Icons.share_outlined),
            onPressed: _shareTicket,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Screenshot(
              controller: _screenshotController,
              child: _buildTicket(context),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _shareTicket,
                icon: Icon(
                  kIsWeb ? Icons.download_rounded : Icons.share_rounded,
                ),
                label: Text(kIsWeb ? 'DESCARGAR TICKET' : 'COMPARTIR TICKET'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              kIsWeb
                  ? 'Descarga el ticket para enviarlo manualmente por WhatsApp.'
                  : 'Puedes compartir este ticket con el cliente por WhatsApp o redes sociales.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicket(BuildContext context) {
    final isPaid = widget.participante.estadoPago == EstadoPago.pagado;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header del Ticket
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppTheme.goldGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.rifa.organizacion != null)
                      Text(
                        widget.rifa.organizacion!.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          color: Colors.black54,
                          letterSpacing: 1,
                        ),
                      ),
                    Text(
                      'TICKET DE RIFA',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 2,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#${widget.participante.id.substring(widget.participante.id.length - 6).toUpperCase()}',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.stars_rounded, color: Colors.black, size: 40),
              ],
            ),
          ),

          // Contenido del Ticket
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  widget.rifa.nombre.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                _buildInfoRow('PARTICIPANTE', widget.participante.nombre),
                const Divider(height: 32, color: Colors.white10),
                _buildInfoRow('WHATSAPP', widget.participante.whatsapp),
                const Divider(height: 32, color: Colors.white10),
                _buildInfoRow('CIUDAD', widget.participante.ciudad),
                const SizedBox(height: 32),

                // Números Seleccionados
                Text(
                  'NÚMEROS ASIGNADOS',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    letterSpacing: 1,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                if (widget.participante.numeros.isEmpty)
                  const Text('Ninguno', style: TextStyle(color: Colors.white54))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: widget.participante.numeros
                        .map(
                          (n) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            child: Text(
                              n,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 32),

                // Estado de Pago y Valor
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          AppConstants.formatCurrencyCOP(
                            widget.participante.numeros.length *
                                widget.rifa.precioNumero,
                          ),
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? AppTheme.secondaryColor
                            : AppTheme.errorColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPaid ? 'PAGADO' : 'PENDIENTE',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // QR Simulado y Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sorteo:',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          widget.rifa.loteria ?? 'Lotería por definir',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.qr_code_2_rounded,
                      size: 60,
                      color: Colors.white54,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Pie del ticket con diseño de "corte"
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(22),
                bottomRight: Radius.circular(22),
              ),
            ),
            child: Column(
              children: [
                if (widget.rifa.responsable != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'RESPONSABLE: ${widget.rifa.responsable} ${widget.rifa.contactoResponsable != null ? "(${widget.rifa.contactoResponsable})" : ""}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                Text(
                  'GRACIAS POR PARTICIPAR EN RIFADORADA',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    letterSpacing: 2,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            letterSpacing: 1,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Future<void> _shareTicket() async {
    try {
      final Uint8List? image = await _screenshotController.capture();
      if (image == null) return;

      if (kIsWeb) {
        downloadBytes(image, 'ticket_${widget.participante.id}.png');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ticket descargado correctamente')),
          );
        }
      } else {
        final directory = await getTemporaryDirectory();
        final imagePath = await File(
          '${directory.path}/ticket_${widget.participante.id}.png',
        ).create();
        await imagePath.writeAsBytes(image);

        await Share.shareXFiles(
          [XFile(imagePath.path)],
          text:
              '¡Hola! Aquí tienes tu ticket para la rifa ${widget.rifa.nombre}. ¡Mucha suerte!',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al procesar ticket: $e')));
      }
    }
  }
}
