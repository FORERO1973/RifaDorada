import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/rifa_provider.dart';
import '../models/rifa.dart';
import '../utils/web_helper.dart';

class ImagenEstadoScreen extends StatefulWidget {
  final bool autoUpload;
  final int autoPopAfterMs;

  const ImagenEstadoScreen({
    super.key,
    this.autoUpload = false,
    this.autoPopAfterMs = 0,
  });

  @override
  State<ImagenEstadoScreen> createState() => _ImagenEstadoScreenState();
}

class _ImagenEstadoScreenState extends State<ImagenEstadoScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RifaProvider>();
      final rifa = provider.rifaSeleccionada;
      if (rifa != null) {
        provider.loadNumeros(rifa.id);
        if (widget.autoUpload) _uploadToBot(rifa);
      }
    });
  }

  Future<void> _uploadToBot(Rifa rifa) async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subir al Bot solo está disponible en dispositivos móviles')),
        );
      }
      return;
    }

    setState(() => _isUploading = true);
    try {
      final image = await _screenshotController.capture();
      if (image == null) throw Exception('No se pudo capturar la imagen');

      final base64 = base64Encode(image);
      final url = Uri.parse('${AppConstants.chatbotApi}/status-image');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', if (AppConstants.botApiKey.isNotEmpty) 'X-API-Key': AppConstants.botApiKey},
        body: jsonEncode({
          'rifaId': rifa.id,
          'imageBase64': base64,
        }),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Estado de números actualizado en el Bot'),
              backgroundColor: Colors.green,
            ),
          );
          if (widget.autoPopAfterMs > 0) {
            await Future.delayed(Duration(milliseconds: widget.autoPopAfterMs));
            if (mounted) Navigator.pop(context);
          }
        } else {
          final msg = jsonDecode(response.body)['message'] ?? 'Error desconocido';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $msg'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

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
            IconButton(
              icon: _isUploading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.cloud_upload_rounded),
              onPressed: _isUploading ? null : () => _uploadToBot(rifa),
              tooltip: 'Subir al Bot',
            ),
            IconButton(
              icon: _isSharing 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.share_rounded),
              onPressed: _isSharing ? null : () => _shareImage(rifa),
              tooltip: 'Compartir Imagen',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Screenshot(
          controller: _screenshotController,
          child: Container(
            padding: const EdgeInsets.all(12),
            color: AppTheme.backgroundColor,
            child: Column(
            children: [
              if (rifa.imagenes.isNotEmpty)
                _buildPrizeImages(rifa.imagenes),
              if (rifa.imagenes.isNotEmpty)
                const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      rifa.nombre,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppConstants.formatCurrencyCOP(rifa.precioNumero),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
                    ),
                    if (rifa.infoLoterias.isNotEmpty || rifa.fechaSorteo != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (rifa.infoLoterias.isNotEmpty)
                            Text(
                              rifa.infoLoterias,
                              style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                            ),
                          if (rifa.infoLoterias.isNotEmpty && rifa.fechaSorteo != null)
                            Text(' · ', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                          if (rifa.fechaSorteo != null)
                            Text(
                              'Sorteo: ${DateFormat('dd/MM/yy').format(rifa.fechaSorteo!)}',
                              style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: rifa.tipoRifa == '3 cifras' ? 8 : 10,
                  crossAxisSpacing: 3,
                  mainAxisSpacing: 3,
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
                    backgroundColor = AppTheme.numeroDisponible;
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      numero,
                      style: TextStyle(
                        fontSize: rifa.tipoRifa == '3 cifras' ? 7 : 9,
                        fontWeight: FontWeight.w900,
                        color: isReserved ? AppTheme.backgroundColor : Colors.white,
                      ),
                    ),
                  );
                },
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
      ),
    ),
  );
}

  Widget _buildPrizeImages(List<String> imagenes) {
    final images = imagenes.take(2).toList();
    return SizedBox(
      height: 120,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: images.length == 1
            ? _buildImageWidget(images[0])
            : Row(
                children: [
                  Expanded(child: _buildImageWidget(images[0])),
                  const SizedBox(width: 4),
                  Expanded(child: _buildImageWidget(images[1])),
                ],
              ),
      ),
    );
  }

  Widget _buildImageWidget(String path) {
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox());
    }
    if (path.startsWith('data:image/')) {
      final base64 = path.contains('base64,') ? path.split('base64,')[1] : path;
      return Image.memory(base64Decode(base64), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox());
    }
    if (!kIsWeb) {
      return Image.file(File(path), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox());
    }
    return const SizedBox();
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
      ],
    );
  }
}
