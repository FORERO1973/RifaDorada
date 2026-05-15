import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/rifa_provider.dart';
import '../models/rifa.dart';
import '../services/firebase_service.dart';
import '../services/report_service.dart';
import '../models/app_config.dart';
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
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Panel de Administración',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
                maxLines: 1,
              ),
            ),
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
    return _HoverCard(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (rifa.activa ? AppTheme.secondaryColor : AppTheme.errorColor).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            rifa.activa ? Icons.check_circle : Icons.cancel,
            color: rifa.activa ? AppTheme.secondaryColor : AppTheme.errorColor,
            size: 20,
          ),
        ),
        title: Text(
          rifa.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Text(
          '${rifa.cantidadNumeros} números • ${AppConstants.formatCurrencyCOP(rifa.precioNumero)}',
          style: const TextStyle(fontSize: 11),
        ),
        children: [
          _buildStatsSection(stats, rifa),
          const Divider(color: AppTheme.dividerColor, height: 16),
          _buildActionsSection(context, rifa, provider),
        ],
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
            Expanded(
              child: _buildStatItem('Vendidos', '$vendidos', Icons.sell, AppTheme.primaryColor),
            ),
            Expanded(
              child: _buildStatItem('Disponibles', '$disponibles', Icons.inventory_2, AppTheme.secondaryColor),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatItem('Pagados', AppConstants.formatCurrencyCOP(pagadosValor), Icons.payments, Colors.green),
            ),
            Expanded(
              child: _buildStatItem('Pendiente', AppConstants.formatCurrencyCOP(reservadosValor), Icons.pending, Colors.orange),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatItem('Números Pagados', '${stats['numerosPagados'] ?? 0}', Icons.people, Colors.blue),
            ),
            Expanded(
              child: _buildStatItem('Números Reservados', '${stats['numerosReservados'] ?? 0}', Icons.people_outline, Colors.orange),
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
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 0, // ESPACIO VERTICAL ELIMINADO
          crossAxisSpacing: 8,
          childAspectRatio: 1.15, // AÚN MÁS COMPACTO
          children: [
            _buildCircularAction(
              icon: Icons.edit_rounded,
              label: 'Editar',
              color: Colors.blue,
              onTap: () => _showEditDialog(context, rifa, provider),
            ),
            _buildCircularAction(
              icon: rifa.activa ? Icons.pause_rounded : Icons.play_arrow_rounded,
              label: rifa.activa ? 'Cerrar' : 'Activar',
              color: rifa.activa ? Colors.orange : AppTheme.secondaryColor,
              onTap: () => _toggleRifaStatus(context, rifa, provider),
            ),
            _buildCircularAction(
              icon: Icons.people_alt_rounded,
              label: 'Ventas',
              color: Colors.teal,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SalesListScreen(rifa: rifa)),
              ),
            ),
            _buildCircularAction(
              icon: Icons.emoji_events_rounded,
              label: 'Ganador',
              color: Colors.amber,
              onTap: () => _showSetWinnerDialog(context, rifa, provider),
            ),
            _buildCircularAction(
              icon: Icons.file_download_rounded,
              label: 'Exportar',
              color: AppTheme.primaryColor,
              onTap: () => _exportData(context, rifa, provider),
            ),
            _buildCircularAction(
              icon: Icons.delete_forever_rounded,
              label: 'Eliminar',
              color: AppTheme.errorColor,
              onTap: () => _confirmDeleteRifa(context, rifa, provider),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircularAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return _HoverIcon(
      icon: icon,
      label: label,
      color: color,
      onTap: onTap,
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

  void _exportData(BuildContext context, Rifa rifa, RifaProvider provider) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exportar Reporte'),
        content: const Text('Selecciona el formato:'),
        actions: [
          TextButton.icon(
            onPressed: () { Navigator.pop(ctx); provider.exportarDatosCSV(rifaId: rifa.id, nombreRifa: rifa.nombre); },
            icon: const Icon(Icons.table_chart_outlined, size: 18),
            label: const Text('CSV (Excel)'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final config = await FirebaseService.instance.getAppConfig();
              final participantes = await FirebaseService.instance.getParticipantesOnce(rifa.id);
              if (participantes.isEmpty) return;
              try {
                await ReportService.instance.generatePdfReport(
                  rifa: rifa,
                  participantes: participantes,
                  organizacion: config?.organizacion,
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
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text('PDF'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
          ),
        ],
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

// --- WIDGETS AUXILIARES PARA EL EFECTO HOVER ---

class _HoverCard extends StatefulWidget {
  final Widget child;
  const _HoverCard({required this.child});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: _isHovered 
              ? AppTheme.surfaceColor.withValues(alpha: 1.0) 
              : AppTheme.surfaceColor.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered ? AppTheme.primaryColor.withValues(alpha: 0.5) : AppTheme.dividerColor.withValues(alpha: 0.5),
            width: _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: _isHovered ? [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              blurRadius: 8,
              spreadRadius: 1,
            )
          ] : [],
        ),
        child: widget.child,
      ),
    );
  }
}

class _HoverIcon extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _HoverIcon({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_HoverIcon> createState() => _HoverIconState();
}

class _HoverIconState extends State<_HoverIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              customBorder: const CircleBorder(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                transform: _isHovered ? (Matrix4.identity()..scale(1.1)) : Matrix4.identity(),
                transformAlignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isHovered ? [
                      widget.color,
                      widget.color.withValues(alpha: 0.7),
                    ] : [
                      widget.color.withValues(alpha: 0.8),
                      widget.color,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: _isHovered ? 0.4 : 0.2),
                      blurRadius: _isHovered ? 8 : 4,
                      offset: Offset(0, _isHovered ? 4 : 2),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 22),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.label,
            style: TextStyle(
              color: _isHovered ? AppTheme.primaryColor : AppTheme.textPrimary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
