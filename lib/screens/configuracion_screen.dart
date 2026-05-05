import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/theme_provider.dart';
import '../services/firebase_service.dart';
import 'login_screen.dart';

class ConfiguracionScreen extends StatelessWidget {
  const ConfiguracionScreen({super.key});

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
