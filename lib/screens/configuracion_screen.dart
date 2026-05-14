import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/theme_provider.dart';
import '../models/app_config.dart';
import '../services/firebase_service.dart';
import 'login_screen.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final _chatbotUrlController = TextEditingController();
  bool _isTesting = false;
  String? _connectionStatus;
  bool? _connectionSuccess;

  final _orgController = TextEditingController();
  final _respController = TextEditingController();
  final _telController = TextEditingController();
  final _emailController = TextEditingController();
  final _cuentaController = TextEditingController();
  String _metodoPago = 'nequi';
  bool _isSavingConfig = false;
  bool _isLoadingConfig = true;

  @override
  void initState() {
    super.initState();
    _chatbotUrlController.text = AppConstants.chatbotUrl;
    _loadAppConfig();
  }

  @override
  void dispose() {
    _chatbotUrlController.dispose();
    _orgController.dispose();
    _respController.dispose();
    _telController.dispose();
    _emailController.dispose();
    _cuentaController.dispose();
    super.dispose();
  }

  Future<void> _loadAppConfig() async {
    try {
      final config = await FirebaseService.instance.getAppConfig();
      if (config != null && mounted) {
        setState(() {
          _orgController.text = config.organizacion;
          _respController.text = config.responsable;
          _telController.text = config.telefono;
          _emailController.text = config.email;
          _cuentaController.text = config.numeroCuenta;
          _metodoPago = config.metodoPago;
        });
      }
    } catch (e) {
      debugPrint('[CONFIG] Error loading app config: $e');
    } finally {
      if (mounted) setState(() => _isLoadingConfig = false);
    }
  }

  Future<void> _saveAppConfig() async {
    setState(() => _isSavingConfig = true);
    try {
      final config = AppConfig(
        organizacion: _orgController.text.trim(),
        responsable: _respController.text.trim(),
        telefono: _telController.text.trim(),
        email: _emailController.text.trim(),
        numeroCuenta: _cuentaController.text.trim(),
        metodoPago: _metodoPago,
      );
      await FirebaseService.instance.updateAppConfig(config);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Datos guardados correctamente'),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Error al guardar: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingConfig = false);
    }
  }

  Future<void> _testChatbotConnection() async {
    setState(() {
      _isTesting = true;
      _connectionStatus = null;
      _connectionSuccess = null;
    });

    try {
      final url = _chatbotUrlController.text.trim();
      final cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
      final testUri = '$cleanUrl/v1/rifas';
      debugPrint('[CONFIG] Probando conexión a: $testUri');

      final response = await http.get(Uri.parse(testUri))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        setState(() {
          _connectionSuccess = true;
          _connectionStatus = '✅ Conexión exitosa';
        });
      } else {
        setState(() {
          _connectionSuccess = false;
          _connectionStatus = '❌ Error: Servidor respondió ${response.statusCode}';
        });
      }
    } catch (e) {
      debugPrint('[CONFIG] Error de conexión: $e');
      setState(() {
        _connectionSuccess = false;
        _connectionStatus = '❌ $e';
      });
    } finally {
      setState(() => _isTesting = false);
    }
  }

  Future<void> _saveChatbotUrl() async {
    final url = _chatbotUrlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una URL válida')),
      );
      return;
    }
    await AppConstants.setChatbotUrl(url);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ URL del chatbot actualizada'),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'Apariencia', Icons.palette_rounded),
                  _buildThemeToggle(context),
                  const SizedBox(height: 28),
                  _buildSectionTitle(context, 'Chatbot WhatsApp', Icons.smart_toy_rounded),
                  _buildChatbotSection(context),
                  const SizedBox(height: 28),
                  _buildSectionTitle(context, 'Datos del Usuario', Icons.business_rounded),
                  _buildUserDataSection(context),
                  const SizedBox(height: 28),
                  _buildSectionTitle(context, 'Región', Icons.public_rounded),
                  _buildRegionInfo(context),
                  const SizedBox(height: 28),
                  _buildSectionTitle(context, 'Sistema', Icons.info_outline_rounded),
                  _buildAboutSection(context),
                  const SizedBox(height: 28),
                  _buildSectionTitle(context, 'Cuenta', Icons.person_outline_rounded),
                  _buildAccountSection(context),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.surfaceColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.08),
                AppTheme.surfaceColor,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    color: AppTheme.primaryColor,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Configuración',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'v${AppConstants.appVersion}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatbotSection(BuildContext context) {
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
          Text(
            'URL del Servidor',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Dirección del servidor del chatbot de WhatsApp',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _chatbotUrlController,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'http://192.168.1.100:3008',
              prefixIcon: const Icon(Icons.link_rounded, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isTesting ? null : _testChatbotConnection,
                  icon: _isTesting
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_find_rounded, size: 18),
                  label: Text(_isTesting ? 'Probando...' : 'Probar Conexión'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveChatbotUrl,
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Guardar'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_connectionStatus != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (_connectionSuccess == true
                        ? Colors.green
                        : Colors.red)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_connectionSuccess == true
                          ? Colors.green
                          : Colors.red)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _connectionSuccess == true
                        ? Icons.check_circle_rounded
                        : Icons.error_rounded,
                    color: _connectionSuccess == true ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _connectionStatus!,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserDataSection(BuildContext context) {
    if (_isLoadingConfig) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompactField(_orgController, 'Organización', Icons.business),
          const SizedBox(height: 8),
          _buildCompactField(_respController, 'Responsable', Icons.person),
          const SizedBox(height: 8),
          _buildCompactField(_telController, 'Teléfono', Icons.phone, TextInputType.phone),
          const SizedBox(height: 8),
          _buildCompactField(_emailController, 'Email', Icons.email, TextInputType.emailAddress),
          const SizedBox(height: 8),
          _buildCompactField(_cuentaController, 'N° Cuenta', Icons.account_balance, TextInputType.number),
          const SizedBox(height: 10),
          Text(
            'MÉTODO DE PAGO',
            style: GoogleFonts.outfit(
              fontSize: 10, fontWeight: FontWeight.w800,
              letterSpacing: 1.2, color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Row(children: [
            _buildPagoChip('Nequi', 'nequi'),
            const SizedBox(width: 6),
            _buildPagoChip('Daviplata', 'daviplata'),
            const SizedBox(width: 6),
            _buildPagoChip('Bancolombia', 'bancolombia'),
          ]),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSavingConfig ? null : _saveAppConfig,
              icon: _isSavingConfig
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.save_rounded, size: 16),
              label: Text(_isSavingConfig ? 'GUARDANDO...' : 'GUARDAR', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size.fromHeight(36),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactField(TextEditingController ctrl, String label, IconData icon, [TextInputType? kbType]) {
    return TextField(
      controller: ctrl,
      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
      keyboardType: kbType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(fontSize: 12),
        prefixIcon: Icon(icon, size: 18),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildPagoChip(String label, String value) {
    final selected = _metodoPago == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _metodoPago = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryColor.withValues(alpha: 0.15) : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? AppTheme.primaryColor : AppTheme.dividerColor, width: selected ? 2 : 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                size: 14, color: selected ? AppTheme.primaryColor : AppTheme.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 11, color: selected ? AppTheme.primaryColor : AppTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  RotationTransition(turns: animation, child: child),
              child: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                key: ValueKey(themeProvider.isDarkMode),
                color: AppTheme.primaryColor,
                size: 28,
              ),
            ),
            title: Text(
              'Modo Oscuro',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              themeProvider.isDarkMode ? 'Activado — Interfaz oscura' : 'Desactivado — Interfaz clara',
              style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary),
            ),
            trailing: Switch.adaptive(
              value: themeProvider.isDarkMode,
              onChanged: (_) => themeProvider.toggleTheme(),
              activeThumbColor: AppTheme.primaryColor,
              activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.3),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRegionInfo(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          _buildSettingsItem(
            icon: Icons.flag_rounded,
            iconColor: Colors.red.shade400,
            title: 'País',
            subtitle: 'Colombia 🇨🇴',
          ),
          const Divider(height: 1, indent: 72),
          _buildSettingsItem(
            icon: Icons.attach_money_rounded,
            iconColor: Colors.green.shade400,
            title: 'Moneda',
            subtitle: 'Peso Colombiano (COP)',
          ),
          const Divider(height: 1, indent: 72),
          _buildSettingsItem(
            icon: Icons.schedule_rounded,
            iconColor: Colors.blue.shade400,
            title: 'Zona Horaria',
            subtitle: 'Bogotá (UTC-5)',
          ),
          const Divider(height: 1, indent: 72),
          _buildSettingsItem(
            icon: Icons.phone_rounded,
            iconColor: Colors.purple.shade400,
            title: 'Código de País',
            subtitle: '+57',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    final isConnected = !FirebaseService.instance.useLocalData;
    
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          _buildSettingsItem(
            icon: Icons.flutter_dash_rounded,
            iconColor: Colors.cyan.shade400,
            title: 'Desarrollado con',
            subtitle: 'Flutter & Firebase',
          ),
          const Divider(height: 1, indent: 72),
          _buildSettingsItem(
            icon: isConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            iconColor: isConnected ? Colors.green.shade400 : Colors.orange.shade400,
            title: 'Estado de Firebase',
            subtitle: isConnected ? 'Conectado — Sincronización activa' : 'Modo local — Sin conexión',
            trailing: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isConnected ? Colors.green : Colors.orange,
                boxShadow: [
                  BoxShadow(
                    color: (isConnected ? Colors.green : Colors.orange).withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16,
        top: 14, bottom: isLast ? 14 : 14,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutDialog(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.logout_rounded, color: AppTheme.errorColor, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cerrar Sesión',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.errorColor,
                        ),
                      ),
                      Text(
                        'Salir del panel administrativo',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Está seguro de cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseService.instance.logout();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}
