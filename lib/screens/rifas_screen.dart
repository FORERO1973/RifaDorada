import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/rifa_provider.dart';
import '../models/rifa.dart';
import '../models/participante.dart';
import '../services/firebase_service.dart';
import '../services/report_service.dart';
import '../widgets/rifa_card.dart';
import '../widgets/edit_rifa_dialog.dart';
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
            const _RifasActivasTab(),
            const _RifasCerradasTab(),
          ],
        ),
      ),
    );
  }
}

class _RifasActivasTab extends StatefulWidget {
  const _RifasActivasTab();
  @override
  State<_RifasActivasTab> createState() => _RifasActivasTabState();
}

class _RifasActivasTabState extends State<_RifasActivasTab> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RifaProvider>(
      builder: (context, provider, child) {
        var rifasActivas = provider.rifas.where((r) => r.activa).toList();
        if (_searchQuery.isNotEmpty) {
          rifasActivas = rifasActivas.where((r) =>
              r.nombre.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
        }

        if (rifasActivas.isEmpty && _searchQuery.isEmpty) {
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

        if (rifasActivas.isEmpty && _searchQuery.isNotEmpty) {
          return Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text('No se encontraron rifas', style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadRifas(),
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 0),
            itemCount: rifasActivas.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _buildSearchBar(),
                );
              }
              final rifa = rifasActivas[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: RifaCard(
                  rifa: rifa,
                  showDetails: true,
                  onEdit: () => _showEditDialog(context, rifa, provider),
                  onDelete: () => _confirmDeleteRifa(context, rifa, provider),
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
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Buscar rifa por nombre...',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
        filled: true,
        fillColor: AppTheme.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.dividerColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 14),
      onChanged: (value) => setState(() => _searchQuery = value),
    );
  }

  void _showEditDialog(BuildContext context, Rifa rifa, RifaProvider provider) {
    showDialog(
      context: context,
      builder: (_) => EditRifaDialog(rifa: rifa, provider: provider),
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

class _RifasCerradasTab extends StatefulWidget {
  const _RifasCerradasTab();
  @override
  State<_RifasCerradasTab> createState() => _RifasCerradasTabState();
}

class _RifasCerradasTabState extends State<_RifasCerradasTab> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RifaProvider>(
      builder: (context, provider, child) {
        var rifasCerradas = provider.rifas.where((r) => !r.activa).toList();
        if (_searchQuery.isNotEmpty) {
          rifasCerradas = rifasCerradas.where((r) =>
              r.nombre.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
        }

        if (rifasCerradas.isEmpty && _searchQuery.isEmpty) {
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

        if (rifasCerradas.isEmpty && _searchQuery.isNotEmpty) {
          return Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text('No se encontraron rifas', style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadRifas(),
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 0),
            itemCount: rifasCerradas.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _buildSearchBar(),
                );
              }
              final rifa = rifasCerradas[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: RifaCard(
                  rifa: rifa,
                  showDetails: true,
                  onTap: () {},
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Buscar rifa por nombre...',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
        filled: true,
        fillColor: AppTheme.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.dividerColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 14),
      onChanged: (value) => setState(() => _searchQuery = value),
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
  String _filterVendedor = 'Todos';
  List<Map<String, dynamic>> _vendedores = [];
  final Map<String, String> _vendedorNames = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RifaProvider>();
      final rifa = provider.rifaSeleccionada;
      if (rifa != null) {
        provider.loadParticipantes(rifa.id);
        provider.loadNumeros(rifa.id);
        _loadVendedores(rifa.id);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVendedores(String rifaId) async {
    final stats = await context.read<RifaProvider>().getVendedorStats(rifaId: rifaId);
    final vendedores = stats['vendedores'] as List<dynamic>? ?? [];
    if (mounted) {
      setState(() {
        _vendedores = vendedores.map((v) => v as Map<String, dynamic>).toList();
        for (final v in _vendedores) {
          final vid = v['vendedorId'] as String? ?? '';
          final nombre = v['nombre'] as String? ?? vid;
          _vendedorNames[vid] = nombre;
        }
      });
    }
  }

  String _resolveVendedorName(Participante p) {
    final vid = (p.vendedorId?.isNotEmpty == true) ? p.vendedorId! : 'admin';
    if (p.creadoPorNombre?.isNotEmpty == true) return p.creadoPorNombre!;
    return _vendedorNames[vid] ?? (vid == 'admin' ? 'Admin' : vid);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RifaProvider>();
    final rifa = provider.rifaSeleccionada;

    if (rifa == null) return const Scaffold(body: Center(child: Text('Error: No hay rifa')));

    final filteredParticipantes = provider.participantes.where((p) {
      final matchesSearch = p.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.whatsapp.contains(_searchQuery) ||
              p.numeros.any((n) => n.contains(_searchQuery));
      final vid = (p.vendedorId?.isNotEmpty == true) ? p.vendedorId : 'admin';
      final matchesVendedor = _filterVendedor == 'Todos' || vid == _filterVendedor;
      return matchesSearch && matchesVendedor;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(rifa.nombre)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FutureBuilder<Map<String, dynamic>>(
            future: provider.getEstadisticasForRifa(rifa.id, rifa.precioNumero),
            builder: (context, snapshot) {
              final stats = snapshot.data ?? {
                'totalVendidos': 0, 'totalDisponibles': 0,
                'totalVendido': 0.0, 'pendientePago': 0.0,
                'numerosPagados': 0, 'numerosReservados': 0,
                'participantesPagados': 0, 'participantesPendientes': 0,
                'participantesAbonados': 0,
              };
              return _buildStatsGrid(stats);
            },
          ),
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
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.1,
      children: [
        _buildStatCard(icon: Icons.sell, value: '${stats['totalVendidos']}', label: 'Vendidos', color: AppTheme.primaryColor),
        _buildStatCard(icon: Icons.inventory_2, value: '${stats['totalDisponibles']}', label: 'Disponibles', color: AppTheme.secondaryColor),
        _buildStatCard(icon: Icons.check_circle, value: '${stats['participantesPagados']}', label: 'Pagados', color: Colors.green),
        _buildStatCard(icon: Icons.pending, value: '${stats['participantesPendientes']}', label: 'Pendientes', color: Colors.orange),
        _buildStatCard(icon: Icons.payment, value: '${stats['participantesAbonados']}', label: 'Abonados', color: Colors.purple),
        _buildStatCard(icon: Icons.payments, value: AppConstants.formatCurrencyCOP(stats['totalVendido'] ?? 0), label: 'Recaudado', color: AppTheme.primaryColor),
      ],
    );
  }

  Widget _buildStatCard({required IconData icon, required String value, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 2),
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_vendedores.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filterVendedor,
                        isDense: true,
                        dropdownColor: AppTheme.cardColor,
                        icon: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.primaryColor, size: 16),
                        items: [
                          const DropdownMenuItem(value: 'Todos', child: Text('Todos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          ..._vendedores.map((v) {
                            final vid = v['vendedorId'] as String? ?? '';
                            final nombre = v['nombre'] as String? ?? (vid == 'admin' ? 'Admin' : vid);
                            return DropdownMenuItem<String>(
                              value: vid,
                              child: Text(nombre, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _filterVendedor = val);
                        },
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.file_download_rounded, color: AppTheme.primaryColor),
                  tooltip: 'Exportar reporte',
                  onPressed: () => _showExportDialog(context, provider),
                ),
              ],
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
        final isAbonado = p.estadoPago == EstadoPago.abonado;

        Color statusColor;
        String statusLabel;
        if (isPaid) {
          statusColor = AppTheme.secondaryColor;
          statusLabel = 'PAGADO';
        } else if (isAbonado) {
          statusColor = Colors.orange;
          statusLabel = 'ABONADO';
        } else {
          statusColor = AppTheme.errorColor;
          statusLabel = 'PENDIENTE';
        }

        Color numeroColor;
        if (isPaid) {
          numeroColor = AppTheme.numeroPagado;
        } else if (isAbonado) {
          numeroColor = Colors.purple;
        } else {
          numeroColor = AppTheme.numeroReservado;
        }

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
                          if (_vendedorNames.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.person_outline_rounded, size: 12, color: AppTheme.primaryColor),
                                  const SizedBox(width: 3),
                                  Text(
                                    _resolveVendedorName(p),
                                    style: TextStyle(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: p.numeros.map((n) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: numeroColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: numeroColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(n, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: numeroColor)),
                  )).toList(),
                ),
                const SizedBox(height: 10),
                _buildAbonosSection(p, rifa),
                const Divider(height: 16),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.end,
                  children: [
                    if (provider.isAdmin)
                      _buildIconAction(icon: Icons.delete_outline, color: AppTheme.errorColor, label: 'Eliminar', onTap: () => _confirmDelete(p, provider)),
                    _buildIconAction(icon: Icons.message_outlined, color: Colors.green, label: 'WhatsApp', onTap: () => _contactWhatsApp(p, rifa)),
                    _buildIconAction(
                      icon: Icons.confirmation_number_outlined,
                      color: AppTheme.primaryColor,
                      label: 'Ticket',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TicketScreen(participante: p, rifa: rifa)))
                    ),
                    if (!isPaid)
                      _buildIconAction(
                        icon: Icons.add_card_rounded,
                        color: Colors.purple,
                        label: 'Abono',
                        onTap: () => _showAbonoDialog(context, p, provider, rifa),
                      ),
                    if (!isPaid)
                      _buildIconAction(
                        icon: Icons.check_circle_outline,
                        color: AppTheme.secondaryColor,
                        label: 'Pagar',
                        onTap: () => _confirmPago(context, p, provider),
                      )
                    else
                      _buildIconAction(
                        icon: Icons.history,
                        color: AppTheme.textSecondary,
                        label: 'Revertir',
                        onTap: () => _confirmAction(context, 'Revertir Pago', '¿Estás seguro de REVERTIR el pago de ${p.nombre}?', () => provider.marcarPago(p.id, false)),
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

  Widget _buildIconAction({required IconData icon, required Color color, required VoidCallback onTap, String label = ''}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(border: Border.all(color: color.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(10)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            if (label.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: color)),
            ],
          ],
        ),
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

  void _showAbonoDialog(BuildContext ctx, Participante p, RifaProvider provider, Rifa rifa) {
    final precioTotal = p.numeros.length * rifa.precioNumero;
    final montoController = TextEditingController();
    final notaController = TextEditingController();
    String metodoPago = 'efectivo';

    showDialog(
      context: ctx,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final faltante = precioTotal - p.totalPagado;

          return AlertDialog(
            title: Column(
              children: [
                const Text('Registrar Abono'),
                Text(p.nombre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow('Total rifa', AppConstants.formatCurrencyCOP(precioTotal)),
                        _buildInfoRow('Abonado', AppConstants.formatCurrencyCOP(p.totalPagado)),
                        _buildInfoRow('Saldo', AppConstants.formatCurrencyCOP(faltante), color: AppTheme.errorColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: montoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Monto',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: metodoPago,
                    decoration: const InputDecoration(
                      labelText: 'Método de pago',
                      border: OutlineInputBorder(),
                    ),
                    items: ['efectivo', 'transferencia', 'datáfono', 'bizum', 'otro']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
                        .toList(),
                    onChanged: (v) => setState(() => metodoPago = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notaController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Nota (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                onPressed: () async {
                  final monto = double.tryParse(montoController.text.trim());
                  if (monto == null || monto <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ingrese un monto válido'), backgroundColor: AppTheme.errorColor),
                    );
                    return;
                  }
                  if (monto > faltante) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('El abono no puede superar el saldo pendiente'), backgroundColor: AppTheme.errorColor),
                    );
                    return;
                  }
                  final navigator = Navigator.of(context, rootNavigator: true);
                  navigator.pop();
                  await provider.registrarAbono(
                    participanteId: p.id,
                    monto: monto,
                    nota: notaController.text.isNotEmpty ? notaController.text : null,
                    metodoPago: metodoPago,
                    rifaId: rifa.id,
                    precioNumero: rifa.precioNumero,
                  );
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Abono de \$${monto.toStringAsFixed(0)} registrado'), backgroundColor: Colors.purple),
                  );
                },
                child: const Text('Registrar Abono'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        ],
      ),
    );
  }

  Widget _buildAbonosSection(Participante p, Rifa rifa) {
    final precioTotal = p.numeros.length * rifa.precioNumero;
    final saldo = precioTotal - p.totalPagado;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Abonos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary)),
              Text('Total: ${AppConstants.formatCurrencyCOP(p.totalPagado)}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple)),
            ],
          ),
          if (p.abonos.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...p.abonos.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.payment, size: 14, color: Colors.purple),
                      const SizedBox(width: 6),
                      Text(DateFormat('dd/MM').format(a.fecha),
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(a.metodoPago,
                            style: TextStyle(fontSize: 9, color: Colors.purple, fontWeight: FontWeight.bold)),
                      ),
                      if (a.nota != null && a.nota!.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.notes, size: 12, color: AppTheme.textSecondary),
                      ],
                    ],
                  ),
                  Text(AppConstants.formatCurrencyCOP(a.monto),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            )),
          ] else ...[
            const SizedBox(height: 8),
            Text('Sin abonos registrados', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
          const Divider(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Saldo pendiente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(
                AppConstants.formatCurrencyCOP(saldo),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: saldo > 0 ? AppTheme.errorColor : AppTheme.secondaryColor,
                ),
              ),
            ],
          ),
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
    final rifa = provider.rifaSeleccionada;
    if (rifa == null) return;
    await provider.marcarPago(p.id, true, rifaId: rifa.id, precioNumero: rifa.precioNumero);

    if (!ctx.mounted) return;
    final idx = provider.participantes.indexWhere((x) => x.id == p.id);
    final updated = idx >= 0 ? provider.participantes[idx] : p.copyWith(estadoPago: EstadoPago.pagado, totalPagado: p.numeros.length * rifa.precioNumero);
    Navigator.push(ctx, MaterialPageRoute(
      builder: (_) => TicketScreen(participante: updated, rifa: rifa, autoSend: true),
    ));
  }

  void _contactWhatsApp(Participante p, Rifa rifa) async {
    final auth = context.read<AuthProvider>();
    final config = await FirebaseService.instance.getAppConfig(organizacionId: auth.organizacionId);
    final cuenta = (config?.numeroCuenta ?? '').trim();
    final metodo = config?.metodoPago ?? 'nequi';
    final labelCuenta = cuenta.isNotEmpty ? '$cuenta (${metodo.toUpperCase()})' : 'la cuenta indicada';

    final total = p.numeros.length * rifa.precioNumero;
    final restante = total - p.totalPagado;
    final estado = p.estadoPago == EstadoPago.pagado
        ? '✅ PAGADO'
        : p.estadoPago == EstadoPago.abonado
            ? '💳 ABONADO'
            : '⏳ PENDIENTE';

    final message = [
      'Hola ${p.nombre}, te hablo de RifaDorada por tu reserva en la rifa "${rifa.nombre}".',
      '',
      '📌 Números: ${p.numeros.join(", ")}',
      '💰 Valor total: ${AppConstants.formatCurrencyCOP(total)}',
      '📊 Estado: $estado',
      if (restante > 0) '⏳ Saldo: ${AppConstants.formatCurrencyCOP(restante)}',
      '',
      '━━ 📌 ━━',
      '1. Consigna a $labelCuenta',
      '2. Envía el comprobante por este chat',
      '3. ¡Listo! Ya participas',
      '',
      '📞 ¿Dudas? Escribe y te ayudamos',
      '',
      '🍀 ¡Mucha suerte!',
    ].join('\n');

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

  void _showExportDialog(BuildContext context, RifaProvider provider) {
    final rifa = provider.rifaSeleccionada;
    if (rifa == null) return;
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
            label: const Text('Excel'),
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
}
