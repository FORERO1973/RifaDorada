import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/rifa_provider.dart';
import '../models/rifa.dart';
import '../models/participante.dart';
import '../services/firebase_service.dart';
import '../widgets/rifa_card.dart';
import 'crear_rifa_screen.dart';
import 'ticket_screen.dart';

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
            return Padding(
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
            );
          },
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, Rifa rifa, RifaProvider provider) {
    // Reutilizar el diálogo de edición ya definido
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
                Icon(Icons.event_busy_rounded, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text('No hay rifas cerradas', style: TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rifasCerradas.length,
          itemBuilder: (context, index) {
            final rifa = rifasCerradas[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: RifaCard(
                rifa: rifa,
                showDetails: true,
                onTap: () {},
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RifaProvider>();
    final rifa = provider.rifaSeleccionada;

    if (rifa == null) return const Scaffold(body: Center(child: Text('Error: No hay rifa')));

    final stats = provider.getEstadisticas();
    final filteredParticipantes = provider.participantes.where((p) {
      return p.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             p.whatsapp.contains(_searchQuery) ||
             p.numeros.any((n) => n.contains(_searchQuery));
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(rifa.nombre)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatsGrid(stats),
          const SizedBox(height: 24),
          _buildSearchAndTitle(provider),
          const SizedBox(height: 16),
          _buildParticipantesList(filteredParticipantes, rifa, provider),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(icon: Icons.sell, value: '${stats['totalVendidos']}', label: 'Vendidos', color: AppTheme.primaryColor),
        _buildStatCard(icon: Icons.inventory_2, value: '${stats['totalDisponibles']}', label: 'Disponibles', color: AppTheme.secondaryColor),
        _buildStatCard(icon: Icons.payments, value: AppConstants.formatCurrencyCOP(stats['totalVendido'] ?? 0), label: 'Vendido', color: AppTheme.primaryColor),
        _buildStatCard(icon: Icons.pending, value: AppConstants.formatCurrencyCOP(stats['pendientePago'] ?? 0), label: 'Pendiente', color: Colors.orange),
      ],
    );
  }

  Widget _buildStatCard({required IconData icon, required String value, required String label, required Color color}) {
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildSearchAndTitle(RifaProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Participantes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.file_download_rounded, color: AppTheme.primaryColor),
              onPressed: () => provider.exportarDatosCSV(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar por nombre, número o WhatsApp...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty 
                ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  }) 
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          onChanged: (val) => setState(() => _searchQuery = val),
        ),
      ],
    );
  }

  Widget _buildParticipantesList(List<Participante> participantes, Rifa rifa, RifaProvider provider) {
    if (participantes.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No se encontraron resultados')));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: participantes.length,
      itemBuilder: (context, index) {
        final p = participantes[index];
        final isPaid = p.estadoPago == EstadoPago.pagado;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('WhatsApp: ${p.whatsapp}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isPaid ? AppTheme.secondaryColor : AppTheme.errorColor).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(isPaid ? 'PAGADO' : 'PENDIENTE', style: TextStyle(color: isPaid ? AppTheme.secondaryColor : AppTheme.errorColor, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: p.numeros.map((n) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isPaid ? AppTheme.numeroPagado : AppTheme.numeroReservado).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: (isPaid ? AppTheme.numeroPagado : AppTheme.numeroReservado).withValues(alpha: 0.3)),
                    ),
                    child: Text(n, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isPaid ? AppTheme.numeroPagado : AppTheme.numeroReservado)),
                  )).toList(),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildIconAction(icon: Icons.delete_outline, color: AppTheme.errorColor, onTap: () => _confirmDelete(p, provider)),
                    const SizedBox(width: 8),
                    _buildIconAction(icon: Icons.message_outlined, color: Colors.green, onTap: () => _contactWhatsApp(p, rifa)),
                    const SizedBox(width: 8),
                    _buildIconAction(
                      icon: Icons.confirmation_number_outlined, 
                      color: AppTheme.primaryColor, 
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TicketScreen(participante: p, rifa: rifa)))
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: !isPaid
                        ? ElevatedButton.icon(
                            onPressed: () => _confirmPago(context, p, provider),
                            icon: const Icon(Icons.check_circle_outline, size: 16),
                            label: const Text('PAGAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryColor, foregroundColor: Colors.white, minimumSize: const Size(0, 38)),
                          )
                        : OutlinedButton.icon(
                            onPressed: () => _confirmAction(context, 'Revertir Pago', '¿Estás seguro de REVERTIR el pago de ${p.nombre}?', () => provider.marcarPago(p.id, false)),
                            icon: const Icon(Icons.history, size: 16),
                            label: const Text('REVERTIR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.textSecondary, side: const BorderSide(color: AppTheme.dividerColor), minimumSize: const Size(0, 38)),
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconAction({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(border: Border.all(color: color.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  void _confirmAction(BuildContext context, String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title), content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(onPressed: () { onConfirm(); Navigator.pop(context); }, child: const Text('CONFIRMAR')),
        ],
      ),
    );
  }

  Future<void> _confirmPago(BuildContext ctx, Participante p, RifaProvider provider) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Pago'),
        content: Text('¿Estás seguro de marcar como PAGADO a ${p.nombre}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryColor),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('CONFIRMAR'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await provider.marcarPago(p.id, true);

    final rifa = provider.rifaSeleccionada;
    if (!ctx.mounted || rifa == null) return;
    Navigator.push(ctx, MaterialPageRoute(
      builder: (_) => TicketScreen(participante: p, rifa: rifa, autoSend: true),
    ));
  }

  void _contactWhatsApp(Participante p, Rifa rifa) async {
    final message = 'Hola ${p.nombre}, te contacto de RifaDorada por la rifa "${rifa.nombre}"';
    final url = 'https://wa.me/${p.whatsappFormateado}?text=${Uri.encodeComponent(message)}';
    if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _confirmDelete(Participante p, RifaProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Eliminar a ${p.nombre}?'),
            const SizedBox(height: 8),
            Text('Números: ${p.numeros.join(", ")}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(child: Text('Los números quedarán disponibles y se notificará al cliente.', style: TextStyle(fontSize: 12))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              Navigator.pop(context);
              await provider.eliminarParticipante(p.id, p.numeros);
              await FirebaseService.instance.enviarMensajePersonalizado(
                p.whatsappFormateado,
                '🔄 *Venta cancelada*\n\nHola ${p.nombre}, tu registro en la rifa ha sido cancelado y tus números (${p.numeros.join(", ")}) han sido liberados.\n\nSi tienes dudas, contacta al organizador.',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✅ ${p.nombre} eliminado y notificado'), backgroundColor: Colors.orange),
                );
              }
            },
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
  }
}
