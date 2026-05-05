import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/rifa_provider.dart';
import '../models/participante.dart';
import '../models/rifa.dart';
import 'ticket_screen.dart';

class SalesListScreen extends StatefulWidget {
  final Rifa rifa;

  const SalesListScreen({super.key, required this.rifa});

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  String _searchQuery = '';
  String _filterStatus = 'Todos'; // Todos, Pagados, Pendientes
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RifaProvider>().loadParticipantes(widget.rifa.id);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Gestionar Ventas'),
            Text(
              widget.rifa.nombre,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.primaryColor),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: Consumer<RifaProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredList = provider.participantes.where((p) {
                  final matchesSearch =
                      p.nombre.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      p.whatsapp.contains(_searchQuery) ||
                      p.numeros.any((n) => n.contains(_searchQuery));

                  final matchesFilter =
                      _filterStatus == 'Todos' ||
                      (_filterStatus == 'Pagados' &&
                          p.estadoPago == EstadoPago.pagado) ||
                      (_filterStatus == 'Pendientes' &&
                          p.estadoPago == EstadoPago.pendiente);

                  return matchesSearch && matchesFilter;
                }).toList();

                if (filteredList.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    return _buildParticipanteCard(
                      filteredList[index],
                      provider,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.surfaceColor,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, número o WhatsApp...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Todos', 'Pagados', 'Pendientes'].map((filter) {
                final isSelected = _filterStatus == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _filterStatus = filter),
                    selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primaryColor,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipanteCard(Participante p, RifaProvider provider) {
    final isPaid = p.estadoPago == EstadoPago.pagado;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                      Text(
                        p.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'WhatsApp: ${p.whatsapp}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? AppTheme.secondaryColor.withValues(alpha: 0.2)
                        : AppTheme.errorColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPaid ? 'PAGADO' : 'PENDIENTE',
                    style: TextStyle(
                      color: isPaid
                          ? AppTheme.secondaryColor
                          : AppTheme.errorColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: p.numeros
                  .map(
                    (n) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? AppTheme.numeroPagado.withValues(alpha: 0.2)
                            : AppTheme.numeroReservado.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isPaid
                              ? AppTheme.numeroPagado.withValues(alpha: 0.5)
                              : AppTheme.numeroReservado.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        n,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isPaid
                              ? AppTheme.numeroPagado
                              : AppTheme.numeroReservado,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            if (p.notas != null && p.notas!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  p.notas!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButton(
                  icon: Icons.delete_outline,
                  color: AppTheme.errorColor,
                  onTap: () => _confirmDelete(p, provider),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.message_outlined,
                  color: Colors.green,
                  onTap: () => _contactWhatsApp(p),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.confirmation_number_outlined,
                  color: AppTheme.primaryColor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TicketScreen(participante: p, rifa: widget.rifa),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (!isPaid)
                  ElevatedButton.icon(
                    onPressed: () => provider.marcarPago(p.id, true),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('MARCAR PAGO'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => provider.marcarPago(p.id, false),
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text('REVERTIR'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron resultados',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  void _contactWhatsApp(Participante p) async {
    final status = p.estadoPago == EstadoPago.pagado
        ? 'CONFIRMADO'
        : 'PENDIENTE';
    final numbers = p.numeros.join(', ');
    final message =
        'Hola ${p.nombre}, te hablo de RifaDorada por tu reserva en la rifa "${widget.rifa.nombre}".\n\n'
        '📌 Números: $numbers\n'
        '💰 Valor total: ${AppConstants.formatCurrencyCOP(p.numeros.length * widget.rifa.precioNumero)}\n'
        'Estado: $status\n\n'
        '${p.estadoPago == EstadoPago.pendiente ? "Por favor confirma tu pago adjuntando el comprobante." : "Gracias por tu participación!"}';

    final url =
        'https://wa.me/${p.whatsappFormateado}?text=${Uri.encodeComponent(message)}';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _confirmDelete(Participante p, RifaProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Registro'),
        content: Text(
          '¿Deseas eliminar a ${p.nombre} y liberar sus números (${p.numeros.join(", ")})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            onPressed: () {
              provider.eliminarParticipante(p.id, p.numeros);
              Navigator.pop(context);
            },
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
  }
}
