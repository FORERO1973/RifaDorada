import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../config/theme.dart';
import '../config/constants.dart';
import '../models/rifa.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/rifa_provider.dart';

class CrearRifaScreen extends StatefulWidget {
  const CrearRifaScreen({super.key});

  @override
  State<CrearRifaScreen> createState() => _CrearRifaScreenState();
}

class _CrearRifaScreenState extends State<CrearRifaScreen> {
  final _formKeys = List.generate(4, (_) => GlobalKey<FormState>());
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  final _organizacionController = TextEditingController();
  final _responsableController = TextEditingController();
  final _contactoController = TextEditingController();
  
  int _currentStep = 0;
  String _tipoRifa = '2 cifras';
  int _cantidadNumeros = 100;
  bool _isLoading = false;
  
  String? _loteriaSeleccionada;
  String? _diaSorteoSeleccionado;
  DateTime? _fechaSorteo;
  final List<String> _imagenes = [];
  final ImagePicker _picker = ImagePicker();
  List<UserModel> _vendedores = [];
  final List<String> _selectedVendedores = [];
  bool _loadingVendedores = false;

  @override
  void initState() {
    super.initState();
    _precioController.addListener(_onPrecioChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadVendedores());
  }

  Future<void> _loadVendedores() async {
    final auth = context.read<AuthProvider>();
    final orgId = auth.organizacionId;
    if (orgId == null) return;
    setState(() => _loadingVendedores = true);
    try {
      final users = await auth.getUsersInOrg(orgId);
      setState(() {
        _vendedores = users.where((u) => u.rol == UserRol.vendedor && u.activo).toList();
      });
    } catch (_) {}
    setState(() => _loadingVendedores = false);
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

  void _nextStep() {
    if (_currentStep < 3) {
      if (_currentStep == 0 && !_formKeys[0].currentState!.validate()) return;
      if (_currentStep == 1 && !_formKeys[1].currentState!.validate()) return;
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nueva Rifa'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 4,
            backgroundColor: AppTheme.dividerColor,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            minHeight: 6,
          ),
        ),
      ),
      body: Form(
        key: _formKeys[_currentStep],
        child: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_currentStep == 0) _buildStep1InfoBasica(),
                  if (_currentStep == 1) _buildStep2Sorteo(),
                  if (_currentStep == 2) _buildStep3Estructura(),
                  if (_currentStep == 3) _buildStep4VendedoresYPreview(),
                  const SizedBox(height: 24),
                  _buildNavigationButtons(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Info', 'Sorteo', 'Estructura', 'Confirmar'];
    final icons = [Icons.info_outline_rounded, Icons.event_rounded, Icons.style_rounded, Icons.check_circle_outline_rounded];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: AppTheme.surfaceColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(4, (i) {
          final isActive = i == _currentStep;
          final isCompleted = i < _currentStep;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? AppTheme.primaryColor : (isCompleted ? AppTheme.secondaryColor : AppTheme.cardColor),
                  border: Border.all(
                    color: isActive || isCompleted ? Colors.transparent : AppTheme.dividerColor,
                    width: 2,
                  ),
                  boxShadow: isActive ? [
                    BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 8),
                  ] : [],
                ),
                child: Icon(
                  isCompleted ? Icons.check_rounded : icons[i],
                  color: isActive || isCompleted ? AppTheme.backgroundColor : AppTheme.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                steps[i],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive ? AppTheme.primaryColor : (isCompleted ? AppTheme.textPrimary : AppTheme.textSecondary),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStep1InfoBasica() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Información Básica', Icons.info_outline_rounded),
        const SizedBox(height: 16),
        _buildTextField(
          formKey: _formKeys[0],
          controller: _nombreController,
          label: 'Nombre de la Rifa',
          hint: 'Ej: Rifa Navidad 2024',
          icon: Icons.celebration_rounded,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Ingrese el nombre de la rifa';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          formKey: _formKeys[0],
          controller: _descripcionController,
          label: 'Descripción',
          hint: 'Describe los premios y condiciones',
          icon: Icons.description_rounded,
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          formKey: _formKeys[0],
          controller: _organizacionController,
          label: 'Organización',
          hint: 'Ej: Inversiones Rueda',
          icon: Icons.business_rounded,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                formKey: _formKeys[0],
                controller: _responsableController,
                label: 'Responsable',
                hint: 'Nombre',
                icon: Icons.person_rounded,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                formKey: _formKeys[0],
                controller: _contactoController,
                label: 'Contacto',
                hint: 'WhatsApp',
                icon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2Sorteo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Sorteo y Lotería', Icons.event_rounded),
        const SizedBox(height: 16),
        _buildLoteriasSection(),
        const SizedBox(height: 20),
        _buildDiaSorteoSection(),
      ],
    );
  }

  Widget _buildStep3Estructura() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Detalles y Estructura', Icons.style_rounded),
        const SizedBox(height: 16),
        _buildImagenesSection(),
        const SizedBox(height: 24),
        _buildTipoRifaSelector(),
        const SizedBox(height: 16),
        _buildCantidadSelector(),
        const SizedBox(height: 16),
        _buildPrecioInput(),
      ],
    );
  }

  Widget _buildStep4VendedoresYPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Asignar Vendedores', Icons.people_alt_rounded),
        const SizedBox(height: 12),
        _buildVendedoresSectionCompact(),
        const SizedBox(height: 24),
        _buildSectionTitle('Vista Previa', Icons.visibility_rounded),
        const SizedBox(height: 12),
        _buildPreview(),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required GlobalKey<FormState> formKey,
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator,
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _prevStep,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Atrás'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          flex: _currentStep == 0 ? 1 : 2,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : (_currentStep == 3 ? _submitForm : _nextStep),
            icon: _isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(_currentStep == 3 ? Icons.check_rounded : Icons.arrow_forward_rounded),
            label: Text(_currentStep == 3 ? 'CREAR RIFA' : 'SIGUIENTE'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoteriasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on_rounded, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 8),
            Text('Lotería de Referencia', style: Theme.of(context).textTheme.titleMedium),
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
              return DropdownMenuItem(value: loteria, child: Text(loteria));
            }).toList(),
            onChanged: (value) => setState(() => _loteriaSeleccionada = value),
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
            const Icon(Icons.calendar_month_rounded, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 8),
            Text('Fecha del Sorteo', style: Theme.of(context).textTheme.titleMedium),
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
                  _fechaSorteo != null ? Icons.check_circle_rounded : Icons.calendar_today_rounded,
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
                const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.textSecondary),
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
      setState(() => _fechaSorteo = picked);
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
                const Icon(Icons.image_rounded, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text('Imágenes de la Rifa', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            Text('${_imagenes.length}/5', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 12),
        if (_imagenes.isNotEmpty) ...[
          SizedBox(
            height: 160,
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
                            onTap: () => setState(() => _imagenes.removeAt(index)),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
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
                icon: Icons.camera_alt_rounded,
                label: 'Cámara',
                onTap: _imagenes.length >= 5 ? null : () => _pickImage(ImageSource.camera),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildImageButton(
                icon: Icons.photo_library_rounded,
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.errorColor),
            ),
          ),
      ],
    );
  }

  Widget _buildImageButton({required IconData icon, required String label, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: onTap != null ? AppTheme.surfaceColor : AppTheme.surfaceColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: onTap != null ? AppTheme.primaryColor : AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: onTap != null ? AppTheme.textPrimary : AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String imagePath) {
    Widget imageWidget;
    if (kIsWeb || imagePath.startsWith('http') || imagePath.startsWith('blob:')) {
      imageWidget = Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: AppTheme.surfaceColor, child: const Icon(Icons.broken_image_rounded, size: 50, color: AppTheme.textSecondary)),
      );
    } else if (imagePath.startsWith('data:image/')) {
      final base64 = imagePath.contains('base64,') ? imagePath.split('base64,')[1] : imagePath;
      imageWidget = Image.memory(
        base64Decode(base64),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: AppTheme.surfaceColor, child: const Icon(Icons.broken_image_rounded, size: 50, color: AppTheme.textSecondary)),
      );
    } else {
      imageWidget = Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: AppTheme.surfaceColor, child: const Icon(Icons.broken_image_rounded, size: 50, color: AppTheme.textSecondary)),
      );
    }
    return imageWidget;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 80);
      if (image != null) {
        setState(() => _imagenes.add(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  Widget _buildTipoRifaSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tipo de Rifa', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTipoOption('2 cifras', '00-99')),
            const SizedBox(width: 12),
            Expanded(child: _buildTipoOption('3 cifras', '000-999')),
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
          border: Border.all(color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor, width: 2),
        ),
        child: Column(
          children: [
            Icon(Icons.numbers_rounded, color: isSelected ? AppTheme.backgroundColor : AppTheme.textPrimary, size: 32),
            const SizedBox(height: 8),
            Text(tipo, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? AppTheme.backgroundColor : AppTheme.textPrimary)),
            Text(rango, style: TextStyle(fontSize: 12, color: isSelected ? AppTheme.backgroundColor : AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildCantidadSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cantidad de Números', style: Theme.of(context).textTheme.titleMedium),
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
                  border: Border.all(color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor),
                ),
                child: Text('$cantidad', style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? AppTheme.backgroundColor : AppTheme.textPrimary)),
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
        Text('Precio por Número', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        TextFormField(
          controller: _precioController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Precio en COP',
            hintText: 'Ej: 10000',
            prefixIcon: const Icon(Icons.attach_money_rounded),
            suffixText: 'COP',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Ingrese el precio por número';
            final precio = double.tryParse(value);
            if (precio == null || precio <= 0) return 'Ingrese un precio válido';
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

  Widget _buildVendedoresSectionCompact() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: _loadingVendedores
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          : _vendedores.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('No hay vendedores activos en tu organización', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                )
              : Column(
                  children: _vendedores.map((v) => CheckboxListTile(
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
                  )).toList(),
                ),
    );
  }

  Widget _buildPreview() {
    final precio = double.tryParse(_precioController.text) ?? 0;
    final ingresosPosibles = _cantidadNumeros * precio;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withValues(alpha: 0.1), AppTheme.primaryColor.withValues(alpha: 0.03)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPreviewRow('Nombre', _nombreController.text.isEmpty ? 'Sin nombre' : _nombreController.text),
          if (_loteriaSeleccionada != null) _buildPreviewRow('Lotería', _loteriaSeleccionada!),
          if (_diaSorteoSeleccionado != null) _buildPreviewRow('Día', _diaSorteoSeleccionado!),
          _buildPreviewRow('Tipo', _tipoRifa),
          _buildPreviewRow('Números', '$_cantidadNumeros'),
          _buildPreviewRow('Precio', AppConstants.formatCurrencyCOP(precio)),
          if (_imagenes.isNotEmpty) _buildPreviewRow('Imágenes', '${_imagenes.length} adjunta(s)'),
          const Divider(color: AppTheme.dividerColor),
          _buildPreviewRow('Ingresos potenciales', AppConstants.formatCurrencyCOP(ingresosPosibles), isHighlight: true),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: isHighlight
                ? Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)
                : Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_currentStep == 3 && !_formKeys[3].currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      List<String> imageUrls = List.from(_imagenes);

      if (_imagenes.isNotEmpty) {
        try {
          imageUrls = await _uploadImages(_imagenes);
        } catch (e) {
          debugPrint('[UPLOAD FALLBACK] Bot no disponible, usando base64: $e');
          final List<String> base64Images = [];
          for (final path in _imagenes) {
            if (kIsWeb) {
              base64Images.add(path);
            } else {
              final bytes = await File(path).readAsBytes();
              final b64 = base64Encode(bytes);
              base64Images.add('data:image/jpeg;base64,$b64');
            }
          }
          imageUrls = base64Images;
        }
      }

      if (!mounted) return;

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
        imagenes: imageUrls,
        organizacion: _organizacionController.text.trim().isEmpty ? null : _organizacionController.text.trim(),
        responsable: _responsableController.text.trim().isEmpty ? null : _responsableController.text.trim(),
        contactoResponsable: _contactoController.text.trim().isEmpty ? null : _contactoController.text.trim(),
        vendedoresAsignados: _selectedVendedores,
      );

      await provider.crearRifa(rifa);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Rifa creada exitosamente!'), backgroundColor: AppTheme.secondaryColor),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<String>> _uploadImages(List<String> localPaths) async {
    final uri = Uri.parse('${AppConstants.chatbotApi}/upload-images');
    final imagesBase64 = <String>[];
    for (final path in localPaths) {
      if (kIsWeb) {
        imagesBase64.add(path);
      } else {
        final bytes = await File(path).readAsBytes();
        imagesBase64.add(base64Encode(bytes));
      }
    }
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'images': imagesBase64}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['urls']);
    }
    throw Exception('Error al subir imágenes: ${response.statusCode}');
  }
}
