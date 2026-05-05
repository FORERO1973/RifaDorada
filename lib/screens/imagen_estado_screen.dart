import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../config/theme.dart';
import '../providers/rifa_provider.dart';
import '../models/rifa.dart';
import '../utils/web_helper.dart';

class ImagenEstadoScreen extends StatefulWidget {
  const ImagenEstadoScreen({super.key});

  @override
  State<ImagenEstadoScreen> createState() => _ImagenEstadoScreenState();
}

class _ImagenEstadoScreenState extends State<ImagenEstadoScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

  Future<void> _shareImage(Rifa rifa) async {
    if (rifa.tipoRifa != '2 cifras') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La función de compartir imagen solo está disponible para rifas de 2 cifras')),
      );
      return;
    }

    setState(() => _isSharing = true);

    try {
      final image = await _screenshotController.capture();
      
      if (image != null) {
        if (kIsWeb) {
          // En Web descargamos la imagen usando el helper
          final fileName = 'estado_rifa_${rifa.nombre.replaceAll(' ', '_')}.png';
          downloadBytes(image, fileName);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Imagen descargada exitosamente')),
            );
          }
        } else {
          // En móvil compartimos
          final directory = await getTemporaryDirectory();
          final imagePath = '${directory.path}/estado_rifa.png';
          final file = File(imagePath);
          await file.writeAsBytes(image);
          
          await Share.shareXFiles(
            [XFile(imagePath)],
            text: 'Estado de la rifa: ${rifa.nombre}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al compartir imagen: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RifaProvider>();
    final rifa = provider.rifaSeleccionada;

    if (rifa == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Estado de Números')),
        body: const Center(child: Text('No hay rifa seleccionada')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estado de Números'),
        actions: [
          if (rifa.tipoRifa == '2 cifras')
            IconButton(
              icon: _isSharing 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.share_rounded),
              onPressed: _isSharing ? null : () => _shareImage(rifa),
              tooltip: 'Compartir Imagen',
            ),
        ],
      ),
      body: Screenshot(
        controller: _screenshotController,
        child: Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.backgroundColor, // Asegurar fondo sólido para la captura
          child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    rifa.nombre,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem('Disponible', AppTheme.numeroDisponible),
                      const SizedBox(width: 8),
                      _buildLegendItem('Reservado', AppTheme.numeroReservado),
                      const SizedBox(width: 8),
                      _buildLegendItem('Pagado', AppTheme.numeroPagado),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(), // Para que se capture completa
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: rifa.tipoRifa == '3 cifras' ? 8 : 10,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: rifa.cantidadNumeros,
                itemBuilder: (context, index) {
                  final numero = index.toString().padLeft(
                    rifa.tipoRifa == '3 cifras' ? 3 : 2,
                    '0',
                  );

                  final numObj = provider.numeros[numero];
                  final isReserved = numObj?.estaReservado ?? false;
                  final isPaid = numObj?.estaPagado ?? false;

                  Color backgroundColor;
                  if (isPaid) {
                    backgroundColor = AppTheme.numeroPagado;
                  } else if (isReserved) {
                    backgroundColor = AppTheme.numeroReservado;
                  } else {
                    backgroundColor = Colors.green.shade900.withValues(alpha: 0.8);
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      numero,
                      style: TextStyle(
                        fontSize: rifa.tipoRifa == '3 cifras' ? 9 : 12,
                        fontWeight: FontWeight.w900,
                        color: isReserved ? AppTheme.backgroundColor : Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
