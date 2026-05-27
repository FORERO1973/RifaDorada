import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../models/rifa.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/rifa_provider.dart';

class EditRifaDialog extends StatefulWidget {
  final Rifa rifa;
  final RifaProvider provider;

  const EditRifaDialog({super.key, required this.rifa, required this.provider});

  @override
  State<EditRifaDialog> createState() => _EditRifaDialogState();
}

class _EditRifaDialogState extends State<EditRifaDialog> {
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _precioController;
  final _picker = ImagePicker();
  late List<String> _editImages;
  bool _saving = false;
  String? _selectedLoteria;
  String? _selectedDia;
  DateTime? _selectedFecha;
  List<UserModel> _vendedores = [];
  late List<String> _selectedVendedores;
  bool _loadingVendedores = true;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.rifa.nombre);
    _descripcionController = TextEditingController(text: widget.rifa.descripcion);
    _precioController = TextEditingController(text: widget.rifa.precioNumero.toStringAsFixed(0));
    _editImages = List.from(widget.rifa.imagenes);
    _selectedLoteria = widget.rifa.loteria;
    _selectedDia = widget.rifa.diaSorteo;
    _selectedFecha = widget.rifa.fechaSorteo;
    _selectedVendedores = List.from(widget.rifa.vendedoresAsignados);
    _loadVendedores();
  }

  Future<void> _loadVendedores() async {
    final auth = context.read<AuthProvider>();
    if (!auth.esAdmin) {
      _loadingVendedores = false;
      return;
    }
    try {
      final orgId = auth.organizacionId;
      if (orgId != null) {
        final users = await auth.getUsersInOrg(orgId);
        if (mounted) {
          setState(() {
            _vendedores = users.where((u) => u.esVendedor && u.activo).toList();
            _loadingVendedores = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loadingVendedores = false);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      List<String> finalImages = List.from(_editImages);
      final localPaths = finalImages.where((p) =>
          !p.startsWith('http') && !p.startsWith('data:') && !p.startsWith('blob:') && !kIsWeb).toList();
      if (localPaths.isNotEmpty) {
        try {
          final uri = Uri.parse('${AppConstants.chatbotApi}/upload-images');
          final base64List = <String>[];
          for (final path in localPaths) {
            final bytes = await File(path).readAsBytes();
            base64List.add(base64Encode(bytes));
          }
          final response = await http.post(uri,
              headers: {'Content-Type': 'application/json', if (AppConstants.botApiKey.isNotEmpty) 'X-API-Key': AppConstants.botApiKey},
              body: jsonEncode({'images': base64List}));
          if (response.statusCode == 200) {
            final urls = List<String>.from(jsonDecode(response.body)['urls']);
            int urlIdx = 0;
            finalImages = finalImages.map((p) {
              if (localPaths.contains(p)) return urls[urlIdx++];
              return p;
            }).toList();
          }
        } catch (_) {
          finalImages = finalImages.map((p) {
            if (localPaths.contains(p)) {
              return 'data:image/jpeg;base64,${base64Encode(File(p).readAsBytesSync())}';
            }
            return p;
          }).toList();
        }
      }
      final precio = double.tryParse(_precioController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? widget.rifa.precioNumero;
      final updatedRifa = widget.rifa.copyWith(
        nombre: _nombreController.text,
        descripcion: _descripcionController.text,
        precioNumero: precio,
        loteria: _selectedLoteria,
        diaSorteo: _selectedDia,
        fechaSorteo: _selectedFecha,
        imagenes: finalImages,
        vendedoresAsignados: _selectedVendedores,
      );
      await widget.provider.actualizarRifa(updatedRifa);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rifa actualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final isAdmin = auth.esAdmin;

    return AlertDialog(
      title: const Text('Editar Rifa'),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nombreController,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Nombre',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descripcionController,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Descripción',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _precioController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Precio (COP)',
                hintText: '0',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedLoteria,
              isExpanded: true,
              style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Lotería',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              items: LoteriasColombia.principales
                  .map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (val) => setState(() => _selectedLoteria = val),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedDia,
              isExpanded: true,
              style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Día de Sorteo',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              items: LoteriasColombia.diasSemana
                  .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (val) => setState(() => _selectedDia = val),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedFecha ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _selectedFecha = picked);
              },
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(
                _selectedFecha != null
                    ? 'Sorteo: ${DateFormat('dd/MM/yyyy').format(_selectedFecha!)}'
                    : 'Seleccionar fecha',
                style: const TextStyle(fontSize: 12),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.surfaceColor,
                foregroundColor: AppTheme.textPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: AppTheme.dividerColor),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Imágenes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            if (_editImages.isNotEmpty)
              SizedBox(
                height: 60,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ..._editImages.map((img) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Stack(
                          children: [
                            _buildThumbnail(img, 60),
                            Positioned(
                              top: 0, right: 0,
                              child: GestureDetector(
                                onTap: () => setState(() => _editImages.remove(img)),
                                child: Container(
                                  decoration: BoxDecoration(color: AppTheme.errorColor, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                      if (_editImages.length < 5)
                        GestureDetector(
                          onTap: () async {
                            final image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 80);
                            if (image != null) setState(() => _editImages.add(image.path));
                          },
                          child: Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.dividerColor),
                            ),
                            child: Icon(Icons.add_photo_alternate_outlined, color: AppTheme.textSecondary, size: 24),
                          ),
                        ),
                    ],
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: () async {
                  final image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 80);
                  if (image != null) setState(() => _editImages.add(image.path));
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.dividerColor, style: BorderStyle.solid),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, color: AppTheme.textSecondary, size: 18),
                      const SizedBox(width: 6),
                      Text('Agregar imágenes', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ),
            if (isAdmin) ...[
              const SizedBox(height: 16),
              Text('Asignar Vendedores',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              if (_loadingVendedores)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                      child:
                          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                )
              else if (_vendedores.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('No hay vendedores activos en tu organización',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                )
              else
                ..._vendedores.map((v) => CheckboxListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: EdgeInsets.zero,
                      title: Text(v.nombre, style: const TextStyle(fontSize: 13)),
                      subtitle: Text(v.email, style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                      value: _selectedVendedores.contains(v.uid),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedVendedores.add(v.uid);
                          } else {
                            _selectedVendedores.remove(v.uid);
                          }
                        });
                      },
                    )),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(fontSize: 13)),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildThumbnail(String path, double size) {
    Widget child;
    if (path.startsWith('http') || path.startsWith('blob:')) {
      child = Image.network(path, fit: BoxFit.cover, width: size, height: size);
    } else if (path.startsWith('data:image/')) {
      final b64 = path.contains('base64,') ? path.split('base64,')[1] : path;
      child = Image.memory(base64Decode(b64), fit: BoxFit.cover, width: size, height: size);
    } else {
      child = Image.file(File(path), fit: BoxFit.cover, width: size, height: size);
    }
    return ClipRRect(borderRadius: BorderRadius.circular(8), child: child);
  }
}
