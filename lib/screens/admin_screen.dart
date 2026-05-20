import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/rifa_provider.dart';
import '../models/rifa.dart';
import '../services/firebase_service.dart';
import '../services/report_service.dart';
import '../widgets/edit_rifa_dialog.dart';
import 'sales_list_screen.dart';
import 'admin_users_screen.dart';

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
      body: Consumer<RifaProvider>(
        builder: (context, provider, child) {
          if (provider.rifas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildManageUsersCard(),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 64,
                      color: AppTheme.textSecondary.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No hay rifas para administrar',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea una rifa desde la pantalla de Inicio',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadRifas(),
            color: AppTheme.primaryColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.rifas.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildManageUsersCard(),
                  );
                }
                final rifa = provider.rifas[index - 1];
                return _buildAdminRifaCard(context, rifa, provider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdminRifaCard(BuildContext context, Rifa rifa, RifaProvider provider) {
    return FutureBuilder<Map<String, dynamic>>(
      future: provider.getEstadisticasForRifa(rifa.id, rifa.precioNumero),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {
          'totalVendidos': 0, 'totalDisponibles': 0,
          'totalVendido': 0.0, 'pendientePago': 0.0,
          'numerosPagados': 0, 'numerosReservados': 0,
        };
        return _buildAdminRifaCardContent(context, rifa, provider, stats);
      },
    );
  }

  Widget _buildAdminRifaCardContent(BuildContext context, Rifa rifa, RifaProvider provider, Map<String, dynamic> stats) {
    final int vendidos = stats['totalVendidos'] as int? ?? 0;
    final progreso = rifa.cantidadNumeros > 0 ? vendidos / rifa.cantidadNumeros : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (rifa.activa ? AppTheme.secondaryColor : AppTheme.errorColor).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            rifa.activa ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: rifa.activa ? AppTheme.secondaryColor : AppTheme.errorColor,
            size: 22,
          ),
        ),
        title: Text(
          rifa.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${rifa.cantidadNumeros} números • ${AppConstants.formatCurrencyCOP(rifa.precioNumero)}',
              style: const TextStyle(fontSize: 11),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progreso,
                minHeight: 6,
                backgroundColor: AppTheme.dividerColor,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progreso > 0.8 ? AppTheme.secondaryColor : AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(progreso * 100).toInt()}% vendido ($vendidos/${rifa.cantidadNumeros})',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: progreso > 0.8 ? AppTheme.secondaryColor : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        children: [
          _buildStatsSection(stats, rifa),
          const Divider(color: AppTheme.dividerColor, height: 24),
          _buildActionsSection(context, rifa, provider),
        ],
      ),
    );
  }

  Widget _buildManageUsersCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.12),
            AppTheme.primaryColor.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const AdminUsersScreen(),
              transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 250),
            ),
          ),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.people_alt_rounded, color: AppTheme.primaryColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gestionar Usuarios',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Crear vendedores y administrar equipo',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.primaryColor, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(Map<String, dynamic> stats, Rifa rifa) {
    final int vendidos = stats['totalVendidos'] as int? ?? 0;
    final int disponibles = rifa.cantidadNumeros - vendidos;
    final int numerosPagados = stats['numerosPagados'] as int? ?? 0;
    final int numerosReservados = stats['numerosReservados'] as int? ?? 0;
    final double pagadosValor = numerosPagados * rifa.precioNumero;
    final double reservadosValor = numerosReservados * rifa.precioNumero;

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
            Expanded(child: _buildStatItem('Vendidos', '$vendidos', Icons.sell_rounded, AppTheme.primaryColor)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatItem('Disponibles', '$disponibles', Icons.inventory_2_rounded, AppTheme.secondaryColor)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildStatItem('Pagados', AppConstants.formatCurrencyCOP(pagadosValor), Icons.payments_rounded, Colors.green)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatItem('Pendiente', AppConstants.formatCurrencyCOP(reservadosValor), Icons.pending_rounded, Colors.orange)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context, Rifa rifa, RifaProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildActionTile(
          icon: Icons.edit_rounded,
          label: 'Editar Rifa',
          subtitle: 'Modificar nombre, precio, descripción',
          color: Colors.blue,
          onTap: () => _showEditDialog(context, rifa, provider),
        ),
        _buildActionTile(
          icon: rifa.activa ? Icons.pause_circle_rounded : Icons.play_circle_rounded,
          label: rifa.activa ? 'Cerrar Rifa' : 'Activar Rifa',
          subtitle: rifa.activa ? 'Desactivar ventas temporalmente' : 'Habilitar ventas',
          color: rifa.activa ? Colors.orange : AppTheme.secondaryColor,
          onTap: () => _toggleRifaStatus(context, rifa, provider),
        ),
        _buildActionTile(
          icon: Icons.receipt_long_rounded,
          label: 'Ver Ventas',
          subtitle: 'Lista completa de participantes',
          color: Colors.teal,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SalesListScreen(rifa: rifa)),
          ),
        ),
        _buildActionTile(
          icon: Icons.emoji_events_rounded,
          label: 'Establecer Ganador',
          subtitle: 'Definir el número ganador del sorteo',
          color: Colors.amber,
          onTap: () => _showSetWinnerDialog(context, rifa, provider),
        ),
        _buildActionTile(
          icon: Icons.download_for_offline_rounded,
          label: 'Exportar Datos',
          subtitle: 'Descargar reporte CSV o PDF',
          color: AppTheme.primaryColor,
          onTap: () => _exportData(context, rifa, provider),
        ),
        _buildActionTile(
          icon: Icons.delete_forever_rounded,
          label: 'Eliminar Rifa',
          subtitle: 'Acción irreversible',
          color: AppTheme.errorColor,
          onTap: () => _confirmDeleteRifa(context, rifa, provider),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: color,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.5), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Rifa rifa, RifaProvider provider) {
    showDialog(
      context: context,
      builder: (_) => EditRifaDialog(rifa: rifa, provider: provider),
    );
  }

  void _toggleRifaStatus(BuildContext context, Rifa rifa, RifaProvider provider) {
    final newStatus = !rifa.activa;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppTheme.cardColor,
        title: Text(newStatus ? 'Activar Rifa' : 'Cerrar Rifa'),
        content: Text(newStatus
            ? '¿Estás seguro de activar "${rifa.nombre}"?'
            : '¿Estás seguro de cerrar "${rifa.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus ? AppTheme.secondaryColor : Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              provider.actualizarRifa(rifa.copyWith(activa: newStatus));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(newStatus ? '✅ Rifa activada' : '⏸️ Rifa cerrada')),
              );
            },
            child: Text(newStatus ? 'ACTIVAR' : 'CERRAR'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteRifa(BuildContext context, Rifa rifa, RifaProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppTheme.cardColor,
        title: const Text('Eliminar Rifa'),
        content: Text('¿Está seguro de eliminar "${rifa.nombre}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              provider.eliminarRifa(rifa.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🗑️ Rifa eliminada')),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _exportData(BuildContext context, Rifa rifa, RifaProvider provider) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppTheme.cardColor,
        title: const Text('Exportar Reporte'),
        content: const Text('Selecciona el formato:'),
        actions: [
          TextButton.icon(
            onPressed: () { Navigator.pop(ctx); provider.exportarDatosCSV(rifaId: rifa.id, nombreRifa: rifa.nombre); },
            icon: const Icon(Icons.table_chart_rounded, size: 18),
            label: const Text('CSV'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final auth = context.read<AuthProvider>();
              final config = await FirebaseService.instance.getAppConfig(organizacionId: auth.organizacionId);
              final participantes = await FirebaseService.instance.getParticipantesOnce(rifa.id);
              final numerosMap = await FirebaseService.instance.getNumeros(rifa.id);
              final numerosEstado = numerosMap.map((k, v) => MapEntry(k, v.estado.name));
              if (participantes.isEmpty) return;
              try {
                await ReportService.instance.generatePdfReport(
                  rifa: rifa,
                  participantes: participantes,
                  organizacion: config?.organizacion,
                  numerosEstado: numerosEstado,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✅ PDF exportado: ${rifa.nombre}')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('⚠️ Error: $e'), backgroundColor: Colors.orange),
                  );
                }
              }
            },
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
            label: const Text('PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppTheme.cardColor,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Establecer Ganador'),
          ],
        ),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLength: rifa.tipoRifa == '3 cifras' ? 3 : 2,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Al establecer un ganador, la rifa se marcará como CERRADA automáticamente.',
                      style: TextStyle(fontSize: 11, color: Colors.amber.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: AppTheme.backgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.setNumeroGanador(rifa.id, controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🏆 Ganador establecido'), backgroundColor: Colors.amber),
                );
              }
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }
}
