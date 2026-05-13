import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/theme_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _chatbotUrlController.text = AppConstants.chatbotUrl;
  }

  @override
  void dispose() {
    _chatbotUrlController.dispose();
    super.dispose();
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
      final response = await http.get(Uri.parse('$cleanUrl/v1/rifas'))
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
      setState(() {
        _connectionSuccess = false;
        _connectionStatus = '❌ No se pudo conectar: ${e.toString().substring(0, e.toString().length > 80 ? 80 : e.toString().length)}';
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
