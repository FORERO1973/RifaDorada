import 'package:flutter/material.dart';
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
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle(context, 'Apariencia'),
          _buildThemeToggle(context),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Región'),
          _buildRegionInfo(context),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Acerca de'),
          _buildAboutSection(context),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Cuenta'),
          _buildAccountSection(context),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Card(
          child: ListTile(
            leading: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: AppTheme.primaryColor,
            ),
            title: const Text('Modo Oscuro'),
            subtitle: Text(
              themeProvider.isDarkMode ? 'Activado' : 'Desactivado',
            ),
            trailing: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (_) => themeProvider.toggleTheme(),
              activeThumbColor: AppTheme.primaryColor,
            ),
          ),
        );
      },
    );
  }

  Widget _buildRegionInfo(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(
              Icons.location_on,
              color: AppTheme.primaryColor,
            ),
            title: const Text('País'),
            subtitle: const Text('Colombia'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(
              Icons.attach_money,
              color: AppTheme.primaryColor,
            ),
            title: const Text('Moneda'),
            subtitle: const Text('Peso Colombiano (COP)'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(
              Icons.access_time,
              color: AppTheme.primaryColor,
            ),
            title: const Text('Zona Horaria'),
            subtitle: const Text('Bogotá (UTC-5)'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.phone, color: AppTheme.primaryColor),
            title: const Text('Código de País'),
            subtitle: const Text('+57'),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info, color: AppTheme.primaryColor),
            title: const Text('Versión'),
            subtitle: Text(AppConstants.appVersion),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.code, color: AppTheme.primaryColor),
            title: const Text('Desarrollado con'),
            subtitle: const Text('Flutter & Firebase'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.cloud, color: AppTheme.primaryColor),
            title: const Text('Estado de Firebase'),
            subtitle: Text(
              FirebaseService.instance.useLocalData
                  ? 'Modo local (sin conexión)'
                  : 'Conectado',
            ),
            trailing: Icon(
              FirebaseService.instance.useLocalData
                  ? Icons.cloud_off
                  : Icons.cloud_done,
              color: FirebaseService.instance.useLocalData
                  ? Colors.orange
                  : AppTheme.secondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.logout, color: AppTheme.errorColor),
        title: const Text('Cerrar Sesión'),
        onTap: () => _showLogoutDialog(context),
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
