import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../models/rifa.dart';
import '../providers/rifa_provider.dart';

class CrearRifaScreen extends StatefulWidget {
  const CrearRifaScreen({super.key});

  @override
  State<CrearRifaScreen> createState() => _CrearRifaScreenState();
}

class _CrearRifaScreenState extends State<CrearRifaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  final _organizacionController = TextEditingController();
  final _responsableController = TextEditingController();
  final _contactoController = TextEditingController();
  
  String _tipoRifa = '2 cifras';
  int _cantidadNumeros = 100;
  bool _isLoading = false;
  
  String? _loteriaSeleccionada;
  String? _diaSorteoSeleccionado;
  DateTime? _fechaSorteo;
  final List<String> _imagenes = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _precioController.addListener(_onPrecioChanged);
  }

  void _onPrecioChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _precioController.removeListener(_onPrecioChanged);
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _organizacionController.dispose();
    _responsableController.dispose();
    _contactoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nueva Rifa'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _nombreController,
              label: 'Nombre de la Rifa',
              hint: 'Ej: Rifa Navidad 2024',
              icon: Icons.celebration,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese el nombre de la rifa';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descripcionController,
              label: 'Descripción',
              hint: 'Describe los premios y condiciones',
              icon: Icons.description,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _organizacionController,
              label: 'Organización',
              hint: 'Ej: Inversiones Rueda',
              icon: Icons.business,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _responsableController,
                    label: 'Responsable',
                    hint: 'Nombre',
                    icon: Icons.person,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _contactoController,
                    label: 'Contacto',
                    hint: 'WhatsApp',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildLoteriasSection(),
            const SizedBox(height: 16),
            _buildDiaSorteoSection(),
            const SizedBox(height: 24),
            _buildImagenesSection(),
            const SizedBox(height: 24),
            _buildTipoRifaSelector(),
            const SizedBox(height: 16),
            _buildCantidadSelector(),
            const SizedBox(height: 24),
            _buildPrecioInput(),
            const SizedBox(height: 32),
            _buildPreview(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.2),
            AppTheme.primaryDark.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb,
            color: AppTheme.primaryColor,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consejo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Elige la cantidad de números según el premio. Más números = más opciones de venta.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildLoteriasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Lotería de Referencia',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _loteriaSeleccionada,
            decoration: const InputDecoration(
              labelText: 'Selecciona la lotería',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
            items: LoteriasColombia.principales.map((loteria) {
              return DropdownMenuItem(
                value: loteria,
                child: Text(loteria),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _loteriaSeleccionada = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDiaSorteoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.event, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Fecha del Sorteo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _selectFechaSorteo,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Row(
              children: [
                Icon(
                  _fechaSorteo != null ? Icons.check_circle : Icons.calendar_today,
                  color: _fechaSorteo != null ? AppTheme.secondaryColor : AppTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _fechaSorteo != null
                        ? '${_fechaSorteo!.day}/${_fechaSorteo!.month}/${_fechaSorteo!.year}'
                        : 'Selecciona la fecha del sorteo',
                    style: TextStyle(
                      color: _fechaSorteo != null ? AppTheme.textPrimary : AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Opcional: También puedes indicar el día de la semana',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: LoteriasColombia.diasSemana.map((dia) {
            final isSelected = _diaSorteoSeleccionado == dia;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _diaSorteoSeleccionado = isSelected ? null : dia;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
                  ),
                ),
                child: Text(
                  dia,
                  style: TextStyle(
                    color: isSelected ? AppTheme.backgroundColor : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _selectFechaSorteo() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSorteo ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: AppTheme.backgroundColor,
              surface: AppTheme.surfaceColor,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _fechaSorteo) {
      setState(() {
        _fechaSorteo = picked;
      });
    }
  }

  Widget _buildImagenesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.image, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Imágenes de la Rifa',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            Text(
              '${_imagenes.length}/5',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (_imagenes.isNotEmpty) ...[
          SizedBox(
            height: 180,
            child: PageView.builder(
              itemCount: _imagenes.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildImageWidget(_imagenes[index]),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _imagenes.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        if (index == 0)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Principal',
                                style: TextStyle(
                                  color: AppTheme.backgroundColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _imagenes.length > 5 ? 5 : _imagenes.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == 0 ? AppTheme.primaryColor : AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        Row(
          children: [
            Expanded(
              child: _buildImageButton(
                icon: Icons.camera_alt,
                label: 'Cámara',
                onTap: _imagenes.length >= 5 ? null : () => _pickImage(ImageSource.camera),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildImageButton(
                icon: Icons.photo_library,
                label: 'Galería',
                onTap: _imagenes.length >= 5 ? null : () => _pickImage(ImageSource.gallery),
              ),
            ),
          ],
        ),
        
        if (_imagenes.length >= 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Máximo 5 imágenes',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.errorColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: onTap != null ? AppTheme.surfaceColor : AppTheme.surfaceColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: onTap != null ? AppTheme.primaryColor : AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: onTap != null ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String imagePath) {
    if (kIsWeb) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppTheme.surfaceColor,
            child: const Icon(Icons.broken_image, size: 50, color: AppTheme.textSecondary),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
      );
    } else {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppTheme.surfaceColor,
            child: const Icon(Icons.broken_image, size: 50, color: AppTheme.textSecondary),
          );
        },
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _imagenes.add(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildTipoRifaSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Rifa',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTipoOption('2 cifras', '00-99'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTipoOption('3 cifras', '000-999'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTipoOption(String tipo, String rango) {
    final isSelected = _tipoRifa == tipo;
    return GestureDetector(
      onTap: () {
        setState(() {
          _tipoRifa = tipo;
          _cantidadNumeros = tipo == '3 cifras' ? 1000 : 100;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.numbers,
              color: isSelected ? AppTheme.backgroundColor : AppTheme.textPrimary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              tipo,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.backgroundColor : AppTheme.textPrimary,
              ),
            ),
            Text(
              rango,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppTheme.backgroundColor : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCantidadSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cantidad de Números',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.cantidadesNumeros.map((cantidad) {
            final isSelected = _cantidadNumeros == cantidad;
            return GestureDetector(
              onTap: () => setState(() => _cantidadNumeros = cantidad),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
                  ),
                ),
                child: Text(
                  '$cantidad',
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppTheme.backgroundColor : AppTheme.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPrecioInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Precio por Número',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _precioController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Precio en COP',
            hintText: 'Ej: 10000',
            prefixIcon: const Icon(Icons.attach_money),
            suffixText: 'COP',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ingrese el precio por número';
            }
            final precio = double.tryParse(value);
            if (precio == null || precio <= 0) {
              return 'Ingrese un precio válido';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Sugerencia: Entre \$${(_cantidadNumeros * 0.01).toStringAsFixed(0)} y \$${(_cantidadNumeros * 0.05).toStringAsFixed(0)} es un buen rango',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildPreview() {
    final precio = double.tryParse(_precioController.text) ?? 0;
    final ingresosPosibles = _cantidadNumeros * precio;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vista Previa',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildPreviewRow('Nombre', _nombreController.text.isEmpty ? 'Sin nombre' : _nombreController.text),
          if (_loteriaSeleccionada != null)
            _buildPreviewRow('Lotería', _loteriaSeleccionada!),
          if (_diaSorteoSeleccionado != null)
            _buildPreviewRow('Día', _diaSorteoSeleccionado!),
          _buildPreviewRow('Tipo', _tipoRifa),
          _buildPreviewRow('Números', '$_cantidadNumeros'),
          _buildPreviewRow('Precio', AppConstants.formatCurrencyCOP(precio)),
          if (_imagenes.isNotEmpty)
            _buildPreviewRow('Imágenes', '${_imagenes.length} adjunta(s)'),
          const Divider(color: AppTheme.dividerColor),
          _buildPreviewRow(
            'Ingresos potenciales',
            AppConstants.formatCurrencyCOP(ingresosPosibles),
            isHighlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: isHighlight
                ? Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  )
                : Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _submitForm,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.backgroundColor,
              ),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle),
                SizedBox(width: 8),
                Text('Crear Rifa'),
              ],
            ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<RifaProvider>();
      final rifa = Rifa(
        id: '',
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        precioNumero: double.parse(_precioController.text.trim()),
        cantidadNumeros: _cantidadNumeros,
        tipoRifa: _tipoRifa,
        fechaCreacion: DateTime.now(),
        fechaSorteo: _fechaSorteo,
        loteria: _loteriaSeleccionada,
        diaSorteo: _diaSorteoSeleccionado,
        imagenes: _imagenes,
        organizacion: _organizacionController.text.trim().isEmpty ? null : _organizacionController.text.trim(),
        responsable: _responsableController.text.trim().isEmpty ? null : _responsableController.text.trim(),
        contactoResponsable: _contactoController.text.trim().isEmpty ? null : _contactoController.text.trim(),
      );

      await provider.crearRifa(rifa);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Rifa creada exitosamente!'),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}