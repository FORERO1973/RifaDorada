import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../models/app_config.dart';
import '../services/firebase_service.dart';
import '../widgets/logout_helper.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final _chatbotUrlController = TextEditingController();
  final _botApiKeyController = TextEditingController();
  bool _isTesting = false;
  String? _connectionStatus;
  bool? _connectionSuccess;

  String _botStatus = 'unknown';
  String? _botQrBase64;
  DateTime? _botLastCheck;
  Timer? _statusPollTimer;

  final _orgController = TextEditingController();
  final _respController = TextEditingController();
  final _telController = TextEditingController();
  final _emailController = TextEditingController();
  final _cuentaController = TextEditingController();
  String _metodoPago = 'nequi';
  bool _isSavingConfig = false;
  bool _isLoadingConfig = true;

  final Map<String, bool> _expandedSections = {
    'perfil': true,
    'apariencia': false,
    'chatbot': false,
    'datos': false,
    'region': false,
    'sistema': false,
    'cuenta': false,
  };

  @override
  void initState() {
    super.initState();
    _chatbotUrlController.text = AppConstants.chatbotUrl;
    _botApiKeyController.text = AppConstants.botApiKey;
    _loadAppConfig();
    _startStatusPolling();
  }

  @override
  void dispose() {
    _chatbotUrlController.dispose();
    _botApiKeyController.dispose();
    _orgController.dispose();
    _respController.dispose();
    _telController.dispose();
    _emailController.dispose();
    _cuentaController.dispose();
    _statusPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAppConfig() async {
    try {
      final auth = context.read<AuthProvider>();
      final config = await FirebaseService.instance.getAppConfig(organizacionId: auth.organizacionId);
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
      final auth = context.read<AuthProvider>();
      await FirebaseService.instance.updateAppConfig(config, organizacionId: auth.organizacionId);
      if (auth.organizacionId != null) {
        final org = auth.currentOrg?.copyWith(
          nombre: config.organizacion,
          telefono: config.telefono,
          email: config.email,
          metodoPago: config.metodoPago,
          numeroCuenta: config.numeroCuenta,
        );
        if (org != null) await auth.updateOrgConfig(org);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Datos guardados correctamente'), backgroundColor: AppTheme.secondaryColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Error al guardar: $e'), backgroundColor: Colors.orange),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingConfig = false);
    }
  }

  Future<void> _testChatbotConnection() async {
    setState(() { _isTesting = true; _connectionStatus = null; _connectionSuccess = null; });
    try {
      final url = _chatbotUrlController.text.trim();
      final cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
      final testUri = '$cleanUrl/v1/rifas';
      debugPrint('[CONFIG] Probando conexión a: $testUri');
      final apiKey = _botApiKeyController.text.trim();
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (apiKey.isNotEmpty) headers['X-API-Key'] = apiKey;
      final response = await http.get(Uri.parse(testUri), headers: headers).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        setState(() { _connectionSuccess = true; _connectionStatus = '✅ Conexión exitosa'; });
      } else {
        setState(() { _connectionSuccess = false; _connectionStatus = '❌ Error: Servidor respondió ${response.statusCode}'; });
      }
    } catch (e) {
      debugPrint('[CONFIG] Error de conexión: $e');
      setState(() { _connectionSuccess = false; _connectionStatus = '❌ $e'; });
    } finally {
      setState(() => _isTesting = false);
    }
  }

  Future<void> _saveChatbotUrl() async {
    final url = _chatbotUrlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa una URL válida')));
      return;
    }
    await AppConstants.setChatbotUrl(url);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ URL del chatbot actualizada'), backgroundColor: AppTheme.secondaryColor));
    }
  }

  Future<void> _saveBotApiKey() async {
    final key = _botApiKeyController.text.trim();
    await AppConstants.setBotApiKey(key);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ API Key guardada'), backgroundColor: AppTheme.secondaryColor));
    }
  }

  void _startStatusPolling() {
    _fetchBotStatus();
    _statusPollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchBotStatus());
  }

  Future<void> _fetchBotStatus() async {
    try {
      final baseUrl = AppConstants.chatbotUrl.trim();
      if (baseUrl.isEmpty) return;
      final cleanUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
      final response = await http.get(Uri.parse('$cleanUrl/v1/status')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _botStatus = data['status'] ?? 'unknown';
          _botQrBase64 = data['qr'];
          _botLastCheck = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _botStatus = 'disconnected';
          _botLastCheck = DateTime.now();
        });
      }
    }
  }

  void _showQrDialog() {
    if (_botQrBase64 == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.qr_code_rounded, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text('Escanea el QR', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Image.memory(
                base64Decode(_botQrBase64!.split(',').last),
                width: 250,
                height: 250,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Abre WhatsApp → Menú → Dispositivos vinculados',
              style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cerrar', style: GoogleFonts.outfit(color: AppTheme.primaryColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _toggleSection(String key) {
    setState(() => _expandedSections[key] = !(_expandedSections[key] ?? false));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildCollapsibleSection(
                    key: 'perfil',
                    title: 'Mi Perfil',
                    icon: Icons.person_rounded,
                    iconColor: AppTheme.primaryColor,
                    child: _buildUserInfo(context),
                  ),
                  const SizedBox(height: 12),
                  _buildCollapsibleSection(
                    key: 'apariencia',
                    title: 'Apariencia',
                    icon: Icons.palette_rounded,
                    iconColor: Colors.purple,
                    child: _buildThemeToggle(context),
                  ),
                  const SizedBox(height: 12),
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      if (!auth.esAdmin) return const SizedBox.shrink();
                      return Column(
                        children: [
                          _buildCollapsibleSection(
                            key: 'chatbot',
                            title: 'Chatbot WhatsApp',
                            icon: Icons.chat_rounded,
                            iconColor: Colors.green,
                            child: _buildChatbotSection(context),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    },
                  ),
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return _buildCollapsibleSection(
                        key: 'datos',
                        title: 'Datos del Negocio',
                        icon: Icons.business_rounded,
                        iconColor: Colors.blue,
                        child: _buildUserDataSection(context, readOnly: !auth.esAdmin),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildCollapsibleSection(
                    key: 'region',
                    title: 'Región',
                    icon: Icons.public_rounded,
                    iconColor: Colors.teal,
                    child: _buildRegionInfo(context),
                  ),
                  const SizedBox(height: 12),
                  _buildCollapsibleSection(
                    key: 'sistema',
                    title: 'Sistema',
                    icon: Icons.info_outline_rounded,
                    iconColor: Colors.cyan,
                    child: _buildAboutSection(context),
                  ),
                  const SizedBox(height: 12),
                  _buildCollapsibleSection(
                    key: 'cuenta',
                    title: 'Sesión',
                    icon: Icons.logout_rounded,
                    iconColor: AppTheme.errorColor,
                    child: _buildAccountSection(context),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required String key,
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    final isExpanded = _expandedSections[key] ?? false;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isExpanded ? iconColor.withValues(alpha: 0.3) : AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _toggleSection(key),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(Icons.expand_more_rounded, color: iconColor, size: 22),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.surfaceColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryColor.withValues(alpha: 0.08), AppTheme.surfaceColor],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 2),
                  ),
                  child: const Icon(Icons.tune_rounded, color: AppTheme.primaryColor, size: 28),
                ),
                const SizedBox(height: 10),
                Text(
                  'Configuración',
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                ),
                Text(
                  'v${AppConstants.appVersion}',
                  style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.currentUser;
        final org = auth.currentOrg;
        if (user == null) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                child: Text(
                  user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : 'U',
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.nombre, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(user.email, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (user.esAdmin ? AppTheme.primaryColor : Colors.orange).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        user.esAdmin ? 'ADMINISTRADOR' : 'VENDEDOR',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: user.esAdmin ? AppTheme.primaryColor : Colors.orange),
                      ),
                    ),
                    if (org != null) ...[
                      const SizedBox(height: 2),
                      Text(org.nombre, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatbotSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBotStatusIndicator(),
        const SizedBox(height: 16),
        Text('URL del Servidor', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 4),
        Text('Dirección del servidor del chatbot de WhatsApp', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textSecondary)),
        const SizedBox(height: 10),
        TextField(
          controller: _chatbotUrlController,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'http://192.168.200.107:3008',
            prefixIcon: const Icon(Icons.link_rounded, size: 18),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isTesting ? null : _testChatbotConnection,
                icon: _isTesting ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.wifi_find_rounded, size: 16),
                label: Text(_isTesting ? 'Probando...' : 'Probar'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _saveChatbotUrl,
                icon: const Icon(Icons.save_rounded, size: 16),
                label: const Text('Guardar'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ),
          ],
        ),
        if (_connectionStatus != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (_connectionSuccess == true ? Colors.green : Colors.red).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: (_connectionSuccess == true ? Colors.green : Colors.red).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(_connectionSuccess == true ? Icons.check_circle_rounded : Icons.error_rounded, color: _connectionSuccess == true ? Colors.green : Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_connectionStatus!, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text('API Key', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 4),
        Text('Clave para autenticar las llamadas al servidor del bot', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textSecondary)),
        const SizedBox(height: 10),
        TextField(
          controller: _botApiKeyController,
          obscureText: true,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Ingresa la API Key del bot',
            prefixIcon: const Icon(Icons.vpn_key_rounded, size: 18),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Spacer(),
            SizedBox(
              width: 160,
              child: ElevatedButton.icon(
                onPressed: _saveBotApiKey,
                icon: const Icon(Icons.save_rounded, size: 16),
                label: const Text('Guardar API Key'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBotStatusIndicator() {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String subText;

    switch (_botStatus) {
      case 'connected':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        statusText = 'Conectado';
        subText = _botLastCheck != null ? 'Actualizado ${_formatTime(_botLastCheck!)}' : 'En línea';
        break;
      case 'qr_pending':
        statusColor = Colors.orange;
        statusIcon = Icons.qr_code_rounded;
        statusText = 'Esperando QR';
        subText = 'Toca para escanear';
        break;
      case 'disconnected':
      default:
        statusColor = Colors.red;
        statusIcon = Icons.error_rounded;
        statusText = 'Desconectado';
        subText = _botLastCheck != null ? 'Última verificación ${_formatTime(_botLastCheck!)}' : 'Sin conexión';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Icon(statusIcon, color: statusColor, size: 28),
              if (_botStatus == 'connected')
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.5), blurRadius: 4)],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14, color: statusColor),
                ),
                Text(
                  subText,
                  style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          if (_botStatus == 'qr_pending')
            TextButton.icon(
              onPressed: _showQrDialog,
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
              label: const Text('Ver QR'),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            ),
          if (_botStatus == 'disconnected')
            IconButton(
              onPressed: _fetchBotStatus,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              tooltip: 'Reintentar',
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 5) return 'ahora';
    if (diff.inSeconds < 60) return 'hace ${diff.inSeconds}s';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}m';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildUserDataSection(BuildContext context, {bool readOnly = false}) {
    if (_isLoadingConfig) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.dividerColor)),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCompactField(_orgController, 'Organización', Icons.business_rounded, readOnly: readOnly),
        const SizedBox(height: 8),
        _buildCompactField(_respController, 'Responsable', Icons.person_rounded, readOnly: readOnly),
        const SizedBox(height: 8),
        _buildCompactField(_telController, 'Teléfono', Icons.phone_android_rounded, keyboardType: TextInputType.phone, readOnly: readOnly),
        const SizedBox(height: 8),
        _buildCompactField(_emailController, 'Email', Icons.email_rounded, keyboardType: TextInputType.emailAddress, readOnly: readOnly),
        const SizedBox(height: 8),
        _buildCompactField(_cuentaController, 'N° Cuenta', Icons.account_balance_wallet_rounded, keyboardType: TextInputType.number, readOnly: readOnly),
        const SizedBox(height: 10),
        Text('MÉTODO DE PAGO', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppTheme.textSecondary)),
        const SizedBox(height: 6),
        Row(children: [
          _buildPagoChip('Nequi', 'nequi', readOnly: readOnly),
          const SizedBox(width: 6),
          _buildPagoChip('Daviplata', 'daviplata', readOnly: readOnly),
          const SizedBox(width: 6),
          _buildPagoChip('Bancolombia', 'bancolombia', readOnly: readOnly),
        ]),
        if (!readOnly) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSavingConfig ? null : _saveAppConfig,
              icon: _isSavingConfig ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Icon(Icons.save_rounded, size: 14),
              label: Text(_isSavingConfig ? 'GUARDANDO...' : 'GUARDAR', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12)),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), minimumSize: const Size.fromHeight(36)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactField(TextEditingController ctrl, String label, IconData icon, {TextInputType? keyboardType, bool readOnly = false}) {
    return TextField(
      controller: ctrl,
      readOnly: readOnly,
      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 12),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(fontSize: 11),
        prefixIcon: Icon(icon, size: 18),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: readOnly,
        fillColor: readOnly ? AppTheme.surfaceColor : null,
      ),
    );
  }

  Widget _buildPagoChip(String label, String value, {bool readOnly = false}) {
    final selected = _metodoPago == value;
    return Expanded(
      child: GestureDetector(
        onTap: readOnly ? null : () => setState(() => _metodoPago = value),
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
              Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded, size: 14, color: selected ? AppTheme.primaryColor : AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 10, color: selected ? AppTheme.primaryColor : AppTheme.textSecondary)),
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => RotationTransition(turns: animation, child: child),
                child: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  key: ValueKey(themeProvider.isDarkMode),
                  color: AppTheme.primaryColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Modo Oscuro', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(themeProvider.isDarkMode ? 'Activado' : 'Desactivado', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              Switch.adaptive(
                value: themeProvider.isDarkMode,
                onChanged: (_) => themeProvider.toggleTheme(),
                activeThumbColor: AppTheme.primaryColor,
                activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.3),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRegionInfo(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.dividerColor)),
      child: Column(
        children: [
          _buildSettingsItem(icon: Icons.flag_rounded, iconColor: Colors.red.shade400, title: 'País', subtitle: 'Colombia'),
          const Divider(height: 1, indent: 56),
          _buildSettingsItem(icon: Icons.attach_money_rounded, iconColor: Colors.green.shade400, title: 'Moneda', subtitle: 'Peso Colombiano (COP)'),
          const Divider(height: 1, indent: 56),
          _buildSettingsItem(icon: Icons.schedule_rounded, iconColor: Colors.blue.shade400, title: 'Zona Horaria', subtitle: 'Bogotá (UTC-5)'),
          const Divider(height: 1, indent: 56),
          _buildSettingsItem(icon: Icons.phone_rounded, iconColor: Colors.purple.shade400, title: 'Código de País', subtitle: '+57', isLast: true),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    final isConnected = !FirebaseService.instance.useLocalData;
    return Container(
      decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.dividerColor)),
      child: Column(
        children: [
          _buildSettingsItem(icon: Icons.flutter_dash_rounded, iconColor: Colors.cyan.shade400, title: 'Desarrollado con', subtitle: 'Flutter & Firebase'),
          const Divider(height: 1, indent: 56),
          _buildSettingsItem(
            icon: isConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            iconColor: isConnected ? Colors.green.shade400 : Colors.orange.shade400,
            title: 'Estado de Firebase',
            subtitle: isConnected ? 'Conectado' : 'Modo local',
            trailing: Container(
              width: 8, height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: isConnected ? Colors.green : Colors.orange, boxShadow: [BoxShadow(color: (isConnected ? Colors.green : Colors.orange).withValues(alpha: 0.4), blurRadius: 6)]),
            ),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({required IconData icon, required Color iconColor, required String title, required String subtitle, Widget? trailing, bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(left: 14, right: 14, top: 12, bottom: isLast ? 12 : 12),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(subtitle, style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textSecondary)),
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
      decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.2))),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutDialog(context),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.errorColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.logout_rounded, color: AppTheme.errorColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cerrar Sesión', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.errorColor)),
                      Text('Salir del panel', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textSecondary)),
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
    showLogoutDialog(context);
  }
}
