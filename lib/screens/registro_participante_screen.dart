import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/rifa_provider.dart';
import '../providers/auth_provider.dart';
import '../models/rifa.dart';
import '../models/participante.dart';
import 'ticket_screen.dart';
import 'imagen_estado_screen.dart';

class RegistroParticipanteScreen extends StatefulWidget {
  const RegistroParticipanteScreen({super.key});

  @override
  State<RegistroParticipanteScreen> createState() =>
      _RegistroParticipanteScreenState();
}

class _RegistroParticipanteScreenState
    extends State<RegistroParticipanteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _documentoController = TextEditingController();
  final _notasController = TextEditingController();
  final _ciudadSearchController = TextEditingController();
  String _ciudadSeleccionada = AppConstants.ciudadesColombia.first;
  bool _isPickingContact = false;
  bool _enviarWhatsApp = true;
  String _citySearchQuery = '';

  Future<void> _pickContact() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La búsqueda de contactos no está disponible en la web')),
      );
      return;
    }

    try {
      final permission = await Permission.contacts.request();
      if (permission.isGranted) {
        setState(() => _isPickingContact = true);
        final contact = await FlutterContacts.openExternalPick();
        setState(() => _isPickingContact = false);

        if (contact != null) {
          final fullContact = await FlutterContacts.getContact(contact.id);
          if (fullContact != null) {
            setState(() {
              _nombreController.text = fullContact.displayName;
              if (fullContact.phones.isNotEmpty) {
                String phone = fullContact.phones.first.number
                    .replaceAll(RegExp(r'\s+'), '')
                    .replaceAll(RegExp(r'[^\d+]'), '');
                
                if (phone.startsWith('+57')) {
                  phone = phone.substring(3);
                } else if (phone.startsWith('57') && phone.length > 10) {
                  phone = phone.substring(2);
                }
                
                _whatsappController.text = phone;
              }
            });
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permiso de contactos denegado')),
          );
        }
      }
    } catch (e) {
      setState(() => _isPickingContact = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al acceder a contactos: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _whatsappController.dispose();
    _documentoController.dispose();
    _notasController.dispose();
    _ciudadSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RifaProvider>();
    final rifa = provider.rifaSeleccionada;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Participante'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSelectionSummary(provider),
            const SizedBox(height: 20),
            _buildContactButton(),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _nombreController,
              label: 'Nombre Completo',
              icon: Icons.person_outline_rounded,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese su nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _whatsappController,
              label: 'WhatsApp',
              icon: Icons.phone_android_rounded,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese su número de WhatsApp';
                }
                if (value.length < 10) {
                  return 'Ingrese un número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildCitySelector(),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _documentoController,
              label: 'Documento (opcional)',
              icon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _notasController,
              label: 'Notas (opcional)',
              icon: Icons.note_add_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            _buildWhatsAppToggle(),
            const SizedBox(height: 20),
            _buildTotalSection(provider, rifa!),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: provider.isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: provider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline_rounded),
                        SizedBox(width: 10),
                        Text('CONFIRMAR REGISTRO', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ],
                    ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ciudad',
          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showCityPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_city_rounded, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _ciudadSeleccionada,
                    style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textPrimary),
                  ),
                ),
                const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.primaryColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final filtered = AppConstants.ciudadesColombia.where((c) {
            if (_citySearchQuery.isEmpty) return true;
            return c.toLowerCase().contains(_citySearchQuery.toLowerCase());
          }).toList();

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _ciudadSearchController,
                        onChanged: (v) => setModalState(() => _citySearchQuery = v),
                        decoration: InputDecoration(
                          hintText: 'Buscar ciudad...',
                          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor),
                          suffixIcon: _citySearchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    _ciudadSearchController.clear();
                                    setModalState(() => _citySearchQuery = '');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final city = filtered[i];
                      final isSelected = city == _ciudadSeleccionada;
                      return ListTile(
                        leading: Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.location_on_outlined,
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                        ),
                        title: Text(city, style: GoogleFonts.outfit(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                        )),
                        onTap: () {
                          setState(() => _ciudadSeleccionada = city);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectionSummary(RifaProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.confirmation_number_rounded, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'NÚMEROS SELECCIONADOS',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: provider.numerosSeleccionados.map((val) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  val,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.backgroundColor,
                    fontSize: 13,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton() {
    return OutlinedButton.icon(
      onPressed: _isPickingContact ? null : _pickContact,
      icon: _isPickingContact 
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.contact_phone_rounded),
      label: const Text('BUSCAR EN MIS CONTACTOS'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: AppTheme.primaryColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildWhatsAppToggle() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chat_rounded, color: Colors.green, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enviar WhatsApp automático',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.green.shade700,
                  ),
                ),
                Text(
                  'Enviar confirmación al participante',
                  style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _enviarWhatsApp,
            onChanged: (v) => setState(() => _enviarWhatsApp = v),
            activeThumbColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator,
    );
  }

  Widget _buildTotalSection(RifaProvider provider, Rifa rifa) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.goldGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL A PAGAR',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: AppTheme.backgroundColor.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppConstants.formatCurrencyCOP(provider.totalSeleccion),
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.backgroundColor,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.payments_rounded,
              color: AppTheme.primaryColor,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<RifaProvider>();
    final rifa = provider.rifaSeleccionada;
    final numerosSeleccionados = provider.numerosSeleccionados.toList();

    try {
      final auth = context.read<AuthProvider>();
      final id = await provider.registrarParticipante(
        nombre: _nombreController.text.trim(),
        whatsapp: _whatsappController.text.trim(),
        ciudad: _ciudadSeleccionada,
        documento: _documentoController.text.trim().isEmpty
            ? null
            : _documentoController.text.trim(),
        creadoPorNombre: auth.currentUser?.nombre,
      );

      if (mounted) {
        final participante = Participante(
          id: id,
          rifaId: rifa?.id ?? '',
          nombre: _nombreController.text.trim(),
          whatsapp: _whatsappController.text.trim(),
          ciudad: _ciudadSeleccionada,
          documento: _documentoController.text.trim().isEmpty ? null : _documentoController.text.trim(),
          numeros: numerosSeleccionados,
          estadoPago: EstadoPago.pendiente,
          fechaRegistro: DateTime.now(),
          totalPagado: 0,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Registro exitoso. Generando ticket...'),
            backgroundColor: AppTheme.secondaryColor,
            duration: Duration(seconds: 1),
          ),
        );

        // Push TicketScreen on top (don't pop yet, or mounted becomes false)
        final ticketOk = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => TicketScreen(
              participante: participante,
              rifa: rifa!,
              autoSend: _enviarWhatsApp,
              autoPopAfterSend: true,
            ),
          ),
        );

        // After ticket auto-sends & pops, push ImagenEstadoScreen
        if (ticketOk == true && mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ImagenEstadoScreen(
                autoUpload: true,
                autoPopAfterMs: 1500,
              ),
            ),
          );
        }

        // Now pop RegistroParticipanteScreen → back to SelectorNumerosScreen
        if (mounted) Navigator.pop(context);
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
    }
  }
}
