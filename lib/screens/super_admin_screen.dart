import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../models/organizacion.dart';
import 'stats_screen.dart';
import 'configuracion_screen.dart';

class SuperAdminNavigationScreen extends StatefulWidget {
  const SuperAdminNavigationScreen({super.key});

  @override
  State<SuperAdminNavigationScreen> createState() => _SuperAdminNavigationScreenState();
}

class _SuperAdminNavigationScreenState extends State<SuperAdminNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0
          ? AppBar(
              title: const Text('Panel SuperAdmin',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Cerrar Sesión',
                  onPressed: () => _showLogoutDialog(context),
                ),
              ],
            )
          : (_currentIndex == 1
              ? AppBar(
                  title: const Text('Organizaciones',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Nueva Organización',
                      onPressed: () => _showCrearOrgDialog(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout),
                      tooltip: 'Cerrar Sesión',
                      onPressed: () => _showLogoutDialog(context),
                    ),
                  ],
                )
              : null),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _SuperAdminDashboard(),
          _OrganizacionesScreen(),
          StatsScreen(),
          ConfiguracionScreen(),
        ],
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 5)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.dashboard_rounded, Icons.dashboard_rounded, 'Dashboard', 0),
              _navItem(Icons.business_outlined, Icons.business_rounded, 'Org\'s', 1),
              _navItem(Icons.analytics_outlined, Icons.analytics_rounded, 'Stats', 2),
              _navItem(Icons.settings_outlined, Icons.settings_rounded, 'Ajustes', 3),
              GestureDetector(
                onTap: () => _showLogoutDialog(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.logout, size: 20, color: AppTheme.errorColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, IconData activeIcon, String label, int index) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? activeIcon : icon, size: 20, color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            ],
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  void _showCrearOrgDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final orgController = TextEditingController();
    final nitController = TextEditingController();
    final emailController = TextEditingController();
    final adminNameController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Nueva Organización'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: orgController,
                    decoration: const InputDecoration(labelText: 'Nombre de la Organización *', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.isEmpty) ? 'Obligatorio' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nitController,
                    decoration: const InputDecoration(labelText: 'NIT (opcional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email del Admin *', border: OutlineInputBorder()),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || v.isEmpty) ? 'Obligatorio' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: adminNameController,
                    decoration: const InputDecoration(labelText: 'Nombre del Admin *', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.isEmpty) ? 'Obligatorio' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Contraseña Temporal *',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => obscure = !obscure),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Obligatorio';
                      if (v.length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirmar Contraseña *', border: OutlineInputBorder()),
                    validator: (v) => (v != passwordController.text) ? 'No coinciden' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final auth = context.read<AuthProvider>();
                final org = await auth.crearOrganizacion(
                  nombreOrg: orgController.text.trim(),
                  emailAdmin: emailController.text.trim(),
                  nombreAdmin: adminNameController.text.trim(),
                  passwordTemp: passwordController.text,
                  nit: nitController.text.trim().isNotEmpty ? nitController.text.trim() : null,
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (org != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Organización "${org.nombre}" creada. Admin: ${emailController.text.trim()}'),
                      backgroundColor: AppTheme.secondaryColor,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('⚠️ Error al crear organización'), backgroundColor: AppTheme.errorColor),
                  );
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuperAdminDashboard extends StatelessWidget {
  const _SuperAdminDashboard();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Organizacion>>(
      future: context.read<AuthProvider>().getAllOrganizaciones(),
      builder: (context, snapshot) {
        final orgs = snapshot.data ?? [];
        final activas = orgs.where((o) => o.activa).length;
        final suspendidas = orgs.where((o) => !o.activa).length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(child: _buildSummaryCard('Total', '${orgs.length}', Icons.business, AppTheme.primaryColor)),
                const SizedBox(width: 12),
                Expanded(child: _buildSummaryCard('Activas', '$activas', Icons.check_circle, AppTheme.secondaryColor)),
                const SizedBox(width: 12),
                Expanded(child: _buildSummaryCard('Suspendidas', '$suspendidas', Icons.block, AppTheme.errorColor)),
              ],
            ),
            const SizedBox(height: 24),
            Text('Últimas organizaciones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            ...orgs.take(10).map((org) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(org.activa ? Icons.check_circle : Icons.block, color: org.activa ? AppTheme.secondaryColor : AppTheme.errorColor),
                title: Text(org.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Creada: ${org.fechaCreacion.day}/${org.fechaCreacion.month}/${org.fechaCreacion.year}'),
                trailing: Text(org.activa ? 'ACTIVA' : 'BLOQUEADA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: org.activa ? AppTheme.secondaryColor : AppTheme.errorColor)),
              ),
            )),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _OrganizacionesScreen extends StatefulWidget {
  const _OrganizacionesScreen();

  @override
  State<_OrganizacionesScreen> createState() => _OrganizacionesScreenState();
}

class _OrganizacionesScreenState extends State<_OrganizacionesScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Organizacion>>(
      future: context.read<AuthProvider>().getAllOrganizaciones(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final orgs = snapshot.data ?? [];
        if (orgs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.business_outlined, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text('No hay organizaciones', style: TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Crear primera organización'),
                  onPressed: () {
                    final parent = context.findAncestorStateOfType<_SuperAdminNavigationScreenState>();
                    parent?._showCrearOrgDialog(context);
                  },
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orgs.length,
          itemBuilder: (context, index) {
            final org = orgs[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (org.activa ? AppTheme.secondaryColor : AppTheme.errorColor).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    org.activa ? Icons.check_circle : Icons.block,
                    color: org.activa ? AppTheme.secondaryColor : AppTheme.errorColor,
                    size: 20,
                  ),
                ),
                title: Text(org.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(
                  'NIT: ${org.nit ?? "—"} • Creada: ${org.fechaCreacion.day}/${org.fechaCreacion.month}/${org.fechaCreacion.year}',
                  style: const TextStyle(fontSize: 11),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOrgInfoRow('Estado', org.activa ? '🟢 Activa' : '🔴 Bloqueada'),
                        _buildOrgInfoRow('Método de pago', org.metodoPago),
                        _buildOrgInfoRow('Cuenta', org.numeroCuenta.isNotEmpty ? org.numeroCuenta : '—'),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              icon: Icon(org.activa ? Icons.block : Icons.check_circle, size: 16),
                              label: Text(org.activa ? 'Suspender' : 'Activar', style: const TextStyle(fontSize: 11)),
                              onPressed: () => _toggleOrg(context, org),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: org.activa ? AppTheme.errorColor : AppTheme.secondaryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.delete_forever, size: 16),
                              label: const Text('Eliminar', style: TextStyle(fontSize: 11)),
                              onPressed: () => _deleteOrg(context, org),
                              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.errorColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOrgInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _toggleOrg(BuildContext context, Organizacion org) async {
    final auth = context.read<AuthProvider>();
    final success = await auth.toggleOrgActive(org.id, !org.activa);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(org.activa ? '🔴 Organización suspendida' : '🟢 Organización activada'),
        ),
      );
      setState(() {});
    }
  }

  void _deleteOrg(BuildContext context, Organizacion org) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Organización'),
        content: Text('¿Eliminar "${org.nombre}"? Se borrarán todos sus usuarios, rifas y datos. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              Navigator.pop(ctx);
              final auth = context.read<AuthProvider>();
              final success = await auth.deleteOrganizacion(org.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '✅ Organización eliminada' : '⚠️ Error al eliminar'),
                    backgroundColor: success ? AppTheme.secondaryColor : AppTheme.errorColor,
                  ),
                );
                setState(() {});
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
