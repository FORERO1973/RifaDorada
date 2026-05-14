import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/rifa_provider.dart';
import '../models/participante.dart';
import '../models/rifa.dart';
import '../services/firebase_service.dart';
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
                      (_filterStatus == 'Abonados' &&
                          p.estadoPago == EstadoPago.abonado) ||
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
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Todos', 'Pagados', 'Abonados', 'Pendientes'].map((filter) {
                final isSelected = _filterStatus == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(filter, style: const TextStyle(fontSize: 11)),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _filterStatus = filter),
                    selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
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
    final isAbonado = p.estadoPago == EstadoPago.abonado || (p.totalPagado > 0 && !isPaid);
    final precioTotal = p.numeros.length * widget.rifa.precioNumero;
    
    Color estadoColor;
    String estadoLabel;
    if (isPaid) {
      estadoColor = AppTheme.secondaryColor;
      estadoLabel = 'PAGADO';
    } else if (isAbonado) {
      estadoColor = Colors.orange;
      estadoLabel = 'ABONADO';
    } else {
      estadoColor = AppTheme.errorColor;
      estadoLabel = 'PENDIENTE';
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
                    color: estadoColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    estadoLabel,
                    style: TextStyle(
                      color: estadoColor,
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
            if (p.totalPagado > 0) ...[
              const SizedBox(height: 8),
              Text(
                isPaid 
                  ? 'Pagado: ${AppConstants.formatCurrencyCOP(p.totalPagado)}'
                  : 'Abonado: ${AppConstants.formatCurrencyCOP(p.totalPagado)} - Saldo: ${AppConstants.formatCurrencyCOP(precioTotal - p.totalPagado)}',
                style: TextStyle(color: estadoColor, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
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
                  label: 'Eliminar',
                ),
                _buildActionButton(
                  icon: Icons.message_outlined,
                  color: Colors.green,
                  onTap: () => _contactWhatsApp(p),
                  label: 'WhatsApp',
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.add_circle_outline,
                  color: Colors.orange,
                  onTap: () => _showAbonoDialog(context, p, provider),
                  label: 'Abonar',
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
                  label: 'Ticket',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: !isPaid
                      ? ElevatedButton.icon(
                          onPressed: () => _confirmAction(
                            context,
                            title: 'Confirmar Pago',
                            message: '¿Estás seguro de marcar como PAGADO a ${p.nombre}?',
                            onConfirm: () => provider.marcarPago(p.id, true),
                          ),
                          icon: const Icon(Icons.check_circle_outline, size: 16),
                          label: const Text(
                            'PAGAR',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 40),
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: () => _confirmAction(
                            context,
                            title: 'Revertir Pago',
                            message: '¿Estás seguro de REVERTIR el pago de ${p.nombre}?',
                            onConfirm: () => provider.marcarPago(p.id, false),
                          ),
                          icon: const Icon(Icons.history, size: 16),
                          label: const Text(
                            'REVERTIR',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            side: BorderSide(color: AppTheme.dividerColor),
                            minimumSize: const Size(0, 40),
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
            },
            child: const Text('CONFIRMAR'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? label,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            if (label != null) ...[
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.w500)),
            ],
          ],
        ),
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
              await provider.eliminarParticipante(p.id, p.numeros, rifaId: widget.rifa.id);
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

  void _showAbonoDialog(BuildContext context, Participante p, RifaProvider provider) {
    final montoController = TextEditingController();
    final notaController = TextEditingController();
    String metodoPago = 'efectivo';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final precioTotal = p.numeros.length * widget.rifa.precioNumero;
          final faltante = precioTotal - p.totalPagado;

          return AlertDialog(
            title: Column(
              children: [
                const Text('Registrar Abono'),
                Text(
                  '${p.nombre}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                ),
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
                    value: metodoPago,
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
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [10000, 20000, 50000, faltante.toInt()]
                        .where((m) => m > 0)
                        .map((monto) => ActionChip(
                              label: Text(AppConstants.formatCurrencyCOP(monto.toDouble())),
                              onPressed: () => montoController.text = monto.toString(),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCELAR'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () {
                  final monto = double.tryParse(montoController.text);
                  if (monto == null || monto <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ingrese un monto válido')),
                    );
                    return;
                  }
                  provider.registrarAbono(
                    participanteId: p.id,
                    monto: monto,
                    nota: notaController.text.isNotEmpty ? notaController.text : null,
                    metodoPago: metodoPago,
                  );
                  Navigator.pop(context);
                },
                child: const Text('REGISTRAR ABONO'),
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
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
