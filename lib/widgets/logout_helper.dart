import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

void showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Cerrar Sesión'),
      content: const Text('¿Estás seguro de cerrar sesión?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            context.read<AuthProvider>().logout();
            Navigator.pop(ctx);
          },
          child: const Text('Cerrar Sesión'),
        ),
      ],
    ),
  );
}
