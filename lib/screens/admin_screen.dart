import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/rifa_provider.dart';
import '../models/rifa.dart';
import '../services/firebase_service.dart';
import 'login_screen.dart';
import 'sales_list_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RifaProvider>().loadRifas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/logo/logo.png',
                height: 48,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 16),
            const Text('Panel de Administración'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: Consumer<RifaProvider>(
        builder: (context, provider, child) {
          if (provider.rifas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 80,
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay rifas para administrar',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.rifas.length,
            itemBuilder: (context, index) {
              final rifa = provider.rifas[index];
              return _buildAdminRifaCard(context, rifa, provider);
            },
          );
        },
      ),
    );
  }

  Widget _buildAdminRifaCard(BuildContext context, Rifa rifa, RifaProvider provider) {
    final stats = provider.getEstadisticasForRifa(rifa.id, rifa.precioNumero);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.dividerColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        childrenPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: rifa.activa
                ? AppTheme.secondaryColor.withValues(alpha: 0.2)
                : AppTheme.errorColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            rifa.activa ? Icons.check_circle : Icons.cancel,
            color: rifa.activa ? AppTheme.secondaryColor : AppTheme.errorColor,
          ),
        ),
        title: Text(
          rifa.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${rifa.cantidadNumeros} números • ${AppConstants.formatCurrencyCOP(rifa.precioNumero)}',
        ),
        children: [
          _buildStatsSection(stats),
          const Divider(color: AppTheme.dividerColor),
          _buildActionsSection(context, rifa, provider),
        ],
      ),
    );
  }

  Widget _buildStatsSection(Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estadísticas',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Vendidos',
                '${stats['totalVendidos']}',
                Icons.sell,
                AppTheme.primaryColor,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                'Disponibles',
                '${stats['totalDisponibles']}',
                Icons.inventory_2,
                AppTheme.secondaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Vendido',
                AppConstants.formatCurrencyCOP(stats['totalVendido'] ?? 0),
                Icons.payments,
                Colors.green,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                'Pendiente',
                AppConstants.formatCurrencyCOP(stats['pendientePago'] ?? 0),
                Icons.pending,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Pagados',
                '${stats['participantesPagados']}',
                Icons.people,
                Colors.blue,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                'Pendientes',
                '${stats['participantesPendientes']}',
                Icons.person_add,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context, rifa, RifaProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildActionButton(
                icon: Icons.edit,
                label: 'Editar',
                color: Colors.blue,
                onTap: () => _showEditDialog(context, rifa, provider),
              ),
              const SizedBox(width: 10),
              _buildActionButton(
                icon: rifa.activa ? Icons.pause : Icons.play_arrow,
                label: rifa.activa ? 'Cerrar' : 'Activar',
                color: rifa.activa ? Colors.orange : AppTheme.secondaryColor,
                onTap: () => _toggleRifaStatus(context, rifa, provider),
              ),
              const SizedBox(width: 10),
              _buildActionButton(
                icon: Icons.people_outline,
                label: 'Ventas',
                color: Colors.teal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SalesListScreen(rifa: rifa)),
                ),
              ),
              const SizedBox(width: 10),
              _buildActionButton(
                icon: Icons.emoji_events_outlined,
                label: 'Ganador',
                color: Colors.amber,
                onTap: () => _showSetWinnerDialog(context, rifa, provider),
              ),
              const SizedBox(width: 10),
              _buildActionButton(
                icon: Icons.download,
                label: 'Exportar',
                color: AppTheme.primaryColor,
                onTap: () => _exportData(context, rifa, provider),
              ),
              const SizedBox(width: 10),
              _buildActionButton(
                icon: Icons.delete,
                label: 'Eliminar',
                color: AppTheme.errorColor,
                onTap: () => _confirmDeleteRifa(context, rifa, provider),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, rifa, RifaProvider provider) {
    final nombreController = TextEditingController(text: rifa.nombre);
    final descripcionController = TextEditingController(text: rifa.descripcion);
    final precioController = TextEditingController(text: rifa.precioNumero.toString());
    String? selectedLoteria = rifa.loteria;
    String? selectedDia = rifa.diaSorteo;
    DateTime? selectedFecha = rifa.fechaSorteo;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Editar Rifa'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descripcionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: precioController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Precio'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedLoteria,
                  decoration: const InputDecoration(labelText: 'Lotería'),
                  items: LoteriasColombia.principales.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                  onChanged: (val) => setState(() => selectedLoteria = val),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedDia,
                  decoration: const InputDecoration(labelText: 'Día de Sorteo'),
                  items: LoteriasColombia.diasSemana.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (val) => setState(() => selectedDia = val),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Fecha de Sorteo'),
                  subtitle: Text(selectedFecha != null ? DateFormat('dd/MM/yyyy').format(selectedFecha!) : 'No seleccionada'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedFecha ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => selectedFecha = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final updatedRifa = rifa.copyWith(
                  nombre: nombreController.text,
                  descripcion: descripcionController.text,
                  precioNumero: double.tryParse(precioController.text) ?? rifa.precioNumero,
                  loteria: selectedLoteria,
                  diaSorteo: selectedDia,
                  fechaSorteo: selectedFecha,
                );
                provider.actualizarRifa(updatedRifa);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rifa actualizada')),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }


  void _toggleRifaStatus(BuildContext context, rifa, RifaProvider provider) {
    final newStatus = !rifa.activa;
    final updatedRifa = rifa.copyWith(activa: newStatus);
    provider.actualizarRifa(updatedRifa);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newStatus ? 'Rifa activada' : 'Rifa cerrada'),
      ),
    );
  }

  void _confirmDeleteRifa(BuildContext context, rifa, RifaProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Rifa'),
        content: Text('¿Está seguro de eliminar "${rifa.nombre}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () {
              provider.eliminarRifa(rifa.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rifa eliminada')),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _exportData(BuildContext context, rifa, RifaProvider provider) async {
    await provider.exportarDatosCSV();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Datos exportados para ${rifa.nombre}')),
      );
    }
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
  void _showSetWinnerDialog(BuildContext context, Rifa rifa, RifaProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Establecer Ganador'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ingresa el número ganador para "${rifa.nombre}"'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: rifa.tipoRifa == '3 cifras' ? '000' : '00',
                labelText: 'Número Ganador',
              ),
              maxLength: rifa.tipoRifa == '3 cifras' ? 3 : 2,
            ),
            const SizedBox(height: 8),
            const Text(
              'Al establecer un ganador, la rifa se marcará como CERRADA automáticamente.',
              style: TextStyle(fontSize: 12, color: Colors.amber, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.setNumeroGanador(rifa.id, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }
}