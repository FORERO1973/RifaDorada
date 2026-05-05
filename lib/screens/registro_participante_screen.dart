import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/rifa_provider.dart';
import '../models/rifa.dart';
import '../models/participante.dart';
import 'ticket_screen.dart';

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
  String _ciudadSeleccionada = AppConstants.ciudadesColombia.first;
  bool _isPickingContact = false;

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
          // Obtener detalles completos del contacto seleccionado
          final fullContact = await FlutterContacts.getContact(contact.id);
          if (fullContact != null) {
            setState(() {
              _nombreController.text = fullContact.displayName;
              if (fullContact.phones.isNotEmpty) {
                // Limpiar el número de espacios y caracteres especiales
                String phone = fullContact.phones.first.number
                    .replaceAll(RegExp(r'\s+'), '')
                    .replaceAll(RegExp(r'[^\d+]'), '');
                
                // Si el número empieza por +57, quitarlo o ajustarlo según necesidad
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RifaProvider>();
    final rifa = provider.rifaSeleccionada;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Participante')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSelectionSummary(provider),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _isPickingContact ? null : _pickContact,
              icon: _isPickingContact 
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.contact_phone_rounded),
              label: const Text('BUSCAR EN MIS CONTACTOS'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppTheme.primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _nombreController,
              label: 'Nombre Completo',
              icon: Icons.person,
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
              icon: Icons.phone,
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
            DropdownButtonFormField<String>(
              initialValue: _ciudadSeleccionada,
              decoration: InputDecoration(
                labelText: 'Ciudad',
                prefixIcon: const Icon(Icons.location_city),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: AppConstants.ciudadesColombia.map((ciudad) {
                return DropdownMenuItem(value: ciudad, child: Text(ciudad));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _ciudadSeleccionada = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _documentoController,
              label: 'Documento (opcional)',
              icon: Icons.badge,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            _buildTotalSection(provider, rifa!),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: provider.isLoading ? null : _submitForm,
              child: provider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirmar Registro'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionSummary(RifaProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NÚMEROS SELECCIONADOS',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: provider.numerosSeleccionados.map((val) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  val,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.backgroundColor,
                  ),
                ),
              );
            }).toList(),
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
      ),
      validator: validator,
    );
  }

  Widget _buildTotalSection(RifaProvider provider, Rifa rifa) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppTheme.goldGradient,
        borderRadius: BorderRadius.circular(32),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: AppTheme.backgroundColor.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppConstants.formatCurrencyCOP(provider.totalSeleccion),
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.backgroundColor,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.payments_rounded,
              color: AppTheme.primaryColor,
              size: 32,
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
    final totalSeleccion = provider.totalSeleccion;

    try {
      final id = await provider.registrarParticipante(
        nombre: _nombreController.text.trim(),
        whatsapp: _whatsappController.text.trim(),
        ciudad: _ciudadSeleccionada,
        documento: _documentoController.text.trim().isEmpty
            ? null
            : _documentoController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Registro exitoso!'),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );

        final message = AppConstants.generateWhatsAppMessage(
          nombre: _nombreController.text.trim(),
          numeros: numerosSeleccionados,
          total: totalSeleccion,
          nombreRifa: rifa?.nombre ?? '',
        );
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

        _showWhatsAppDialog(message, _whatsappController.text.trim(), participante, rifa!);
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

  void _showWhatsAppDialog(String message, String whatsapp, Participante participante, Rifa rifa) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registro Completado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Desea enviar la confirmación por WhatsApp?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(message, style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TicketScreen(participante: participante, rifa: rifa),
                ),
              );
            },
            child: const Text('VER TICKET'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Más tarde'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final phone = AppConstants.formatPhoneNumber(whatsapp);
              final url = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.send),
            label: const Text('Enviar'),
          ),
        ],
      ),
    );
  }
}
