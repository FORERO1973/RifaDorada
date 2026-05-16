import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';

class AuthGuard extends StatelessWidget {
  final Widget? adminScreen;
  final Widget? vendedorScreen;
  final Widget? fallback;

  const AuthGuard({
    super.key,
    this.adminScreen,
    this.vendedorScreen,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.esAdmin && adminScreen != null) {
          return adminScreen!;
        }
        if (auth.esVendedor && vendedorScreen != null) {
          return vendedorScreen!;
        }
        return fallback ?? _buildNoAccess(context);
      },
    );
  }

  Widget _buildNoAccess(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline, size: 48, color: AppTheme.errorColor),
            ),
            const SizedBox(height: 24),
            const Text('Sin acceso', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 8),
            Text('No tienes permisos para ver esta sección', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class AdminOnly extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const AdminOnly({super.key, required this.child, this.fallback});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.esAdmin) return child;
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}
