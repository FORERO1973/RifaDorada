import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    if (auth.organizacionId != null) {
      final users = await auth.getUsersInOrg(auth.organizacionId!);
      if (mounted) setState(() { _users = users; _isLoading = false; });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Usuarios', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: () => _showCreateVendedorDialog(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      const Text('No hay usuarios en tu organización'),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateVendedorDialog(context),
                        icon: const Icon(Icons.person_add_rounded),
                        label: const Text('Crear Vendedor'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) => _buildUserCard(_users[index]),
                ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final esAdmin = user.rol == UserRol.orgAdmin;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: (esAdmin ? AppTheme.primaryColor : Colors.orange).withValues(alpha: 0.2),
              child: Text(
                user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : '?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: esAdmin ? AppTheme.primaryColor : Colors.orange,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(user.email, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (esAdmin ? AppTheme.primaryColor : Colors.orange).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      esAdmin ? 'ADMIN' : 'VENDEDOR',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: esAdmin ? AppTheme.primaryColor : Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
            if (!esAdmin) ...[
              Switch(
                value: user.activo,
                onChanged: (val) => _toggleUserStatus(user, val),
                activeThumbColor: AppTheme.secondaryColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _toggleUserStatus(UserModel user, bool active) async {
    final auth = context.read<AuthProvider>();
    await auth.toggleUserActive(user.uid, active);
    await _loadUsers();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(active ? '✅ Usuario activado' : '⛔ Usuario desactivado'),
          backgroundColor: active ? AppTheme.secondaryColor : Colors.orange,
        ),
      );
    }
  }

  void _showCreateVendedorDialog(BuildContext context) {
    final nombreCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Crear Vendedor'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña temporal', prefixIcon: Icon(Icons.lock)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (nombreCtrl.text.isEmpty || emailCtrl.text.isEmpty || passCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Completa todos los campos')),
                  );
                  return;
                }
                setState(() => isLoading = true);
                final auth = context.read<AuthProvider>();
                final success = await auth.createVendedor(
                  nombre: nombreCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  password: passCtrl.text,
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  if (success) {
                    await _loadUsers();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Vendedor creado exitosamente'), backgroundColor: AppTheme.secondaryColor),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('⚠️ Error al crear vendedor'), backgroundColor: Colors.orange),
                    );
                  }
                }
              },
              child: const Text('CREAR'),
            ),
          ],
        ),
      ),
    );
  }
}
