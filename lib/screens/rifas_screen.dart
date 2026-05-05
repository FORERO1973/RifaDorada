import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/rifa_provider.dart';
import '../models/rifa.dart';
import '../widgets/rifa_card.dart';
import 'crear_rifa_screen.dart';

class RifasScreen extends StatelessWidget {
  const RifasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis Rifas', style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
          backgroundColor: AppTheme.backgroundColor,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.5)),
                ),
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Activas'),
                  Tab(text: 'Cerradas'),
                ],
              ),
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: AppTheme.backgroundColor),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CrearRifaScreen()),
                ),
              ),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _RifasActivasTab(),
            _RifasCerradasTab(),
          ],
        ),
      ),
    );
  }
}

class _RifasActivasTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<RifaProvider>(
      builder: (context, provider, child) {
        final rifasActivas = provider.rifas.where((r) => r.activa).toList();

        if (rifasActivas.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Icon(
                    Icons.celebration_rounded,
                    size: 64,
                    color: AppTheme.primaryColor.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No hay rifas activas',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Crea tu primera rifa para empezar',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CrearRifaScreen()),
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Crear Nueva Rifa'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rifasActivas.length,
          itemBuilder: (context, index) {
            final rifa = rifasActivas[index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 400 + (index * 100)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: RifaCard(
                  rifa: rifa,
                  showDetails: true,
                  onEdit: provider.isAdmin ? () => _showEditDialog(context, rifa, provider) : null,
                  onDelete: provider.isAdmin ? () => _confirmDeleteRifa(context, rifa, provider) : null,
                  onTap: () {
                    provider.setRifaSeleccionada(rifa);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _RifaDetalleScreen(),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, Rifa rifa, RifaProvider provider) {
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


  void _confirmDeleteRifa(BuildContext context, Rifa rifa, RifaProvider provider) {
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
}

class _RifasCerradasTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<RifaProvider>(
      builder: (context, provider, child) {
        final rifasCerradas = provider.rifas.where((r) => !r.activa).toList();

        if (rifasCerradas.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Icon(
                    Icons.event_busy_rounded,
                    size: 64,
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No hay rifas cerradas',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tus rifas finalizadas aparecerán aquí',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rifasCerradas.length,
          itemBuilder: (context, index) {
            final rifa = rifasCerradas[index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 400 + (index * 100)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: RifaCard(
                  rifa: rifa,
                  showDetails: true,
                  onTap: () {},
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RifaDetalleScreen extends StatefulWidget {
  const _RifaDetalleScreen();

  @override
  State<_RifaDetalleScreen> createState() => _RifaDetalleScreenState();
}

class _RifaDetalleScreenState extends State<_RifaDetalleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RifaProvider>();
      final rifa = provider.rifaSeleccionada;
      if (rifa != null) {
        provider.loadParticipantes(rifa.id);
        provider.loadNumeros(rifa.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RifaProvider>();
    final rifa = provider.rifaSeleccionada;

    if (rifa == null) {
      return const Scaffold(
        body: Center(child: Text('Error: No hay rifa')),
      );
    }

    final stats = provider.getEstadisticas();

    return Scaffold(
      appBar: AppBar(
        title: Text(rifa.nombre),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatsGrid(stats),
          const SizedBox(height: 24),
          _buildParticipantesList(provider),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estadísticas',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              icon: Icons.sell,
              value: '${stats['totalVendidos']}',
              label: 'Vendidos',
              color: AppTheme.primaryColor,
            ),
            _buildStatCard(
              icon: Icons.inventory_2,
              value: '${stats['totalDisponibles']}',
              label: 'Disponibles',
              color: AppTheme.secondaryColor,
            ),
            _buildStatCard(
              icon: Icons.payments,
              value: AppConstants.formatCurrencyCOP(stats['totalVendido'] ?? 0),
              label: 'Vendido',
              color: AppTheme.primaryColor,
            ),
            _buildStatCard(
              icon: Icons.pending,
              value: AppConstants.formatCurrencyCOP(stats['pendientePago'] ?? 0),
              label: 'Pendiente',
              color: Colors.orange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantesList(RifaProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Participantes',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            IconButton(
              icon: const Icon(Icons.download, color: AppTheme.primaryColor),
              onPressed: () async {
                await provider.exportarDatosCSV();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Datos exportados')),
                  );
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (provider.participantes.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No hay participantes aún',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.participantes.length,
            itemBuilder: (context, index) {
              final p = provider.participantes[index];
              return _buildParticipanteItem(p, provider);
            },
          ),
      ],
    );
  }

  Widget _buildParticipanteItem(participante, RifaProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: Text(
            participante.nombre[0].toUpperCase(),
            style: const TextStyle(color: AppTheme.backgroundColor),
          ),
        ),
        title: Text(participante.nombre),
        subtitle: Text(
          '${participante.ciudad} • ${participante.numerosString}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                participante.estaPagado
                    ? Icons.check_circle
                    : Icons.pending,
                color: participante.estaPagado
                    ? AppTheme.secondaryColor
                    : Colors.orange,
              ),
              onPressed: () => provider.marcarPago(
                participante.id,
                !participante.estaPagado,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppTheme.errorColor),
              onPressed: () => _confirmDelete(context, participante, provider),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, participante, RifaProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Participante'),
        content: Text('¿Está seguro de eliminar a ${participante.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () {
              provider.eliminarParticipante(participante.id, participante.numeros);
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}