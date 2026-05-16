import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/rifa_provider.dart';
import '../models/participante.dart';
import '../models/rifa.dart';
import '../services/firebase_service.dart';
import 'ticket_screen.dart';

class VendedorVentasScreen extends StatefulWidget {
  const VendedorVentasScreen({super.key});

  @override
  State<VendedorVentasScreen> createState() => _VendedorVentasScreenState();
}

class _VendedorVentasScreenState extends State<VendedorVentasScreen> {
  String _searchQuery = '';
  String _filterRifaId = 'todas';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RifaProvider>();
      provider.loadRifas();
      if (provider.rifaSeleccionada != null) {
        provider.loadParticipantes(provider.rifaSeleccionada!.id);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Clientes', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilters(provider),
          Expanded(
            child: Consumer<RifaProvider>(
              builder: (context, provider, child) {
                final filtered = provider.participantes.where((p) {
                  final matchesSearch = p.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      p.whatsapp.contains(_searchQuery) ||
                      p.numeros.any((n) => n.contains(_searchQuery));
                  final matchesRifa = _filterRifaId == 'todas' || p.rifaId == _filterRifaId;
                  return matchesSearch && matchesRifa;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text('No se encontraron clientes', style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _buildClienteCard(filtered[index], provider);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(RifaProvider provider) {
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
          DropdownButtonFormField<String>(
            value: _filterRifaId,
            decoration: const InputDecoration(
              labelText: 'Filtrar por rifa',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            isExpanded: true,
            items: [
              const DropdownMenuItem(value: 'todas', child: Text('Todas las rifas')),
              ...provider.rifas.map((r) => DropdownMenuItem(
                    value: r.id,
                    child: Text(r.nombre, overflow: TextOverflow.ellipsis),
                  )),
            ],
            onChanged: (val) {
              setState(() => _filterRifaId = val ?? 'todas');
              if (val != null && val != 'todas') {
                provider.loadParticipantes(val);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClienteCard(Participante p, RifaProvider provider) {
    final isPaid = p.estadoPago == EstadoPago.pagado;
    final isAbonado = p.estadoPago == EstadoPago.abonado || (p.totalPagado > 0 && !isPaid);

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

    final rifa = provider.rifas.where((r) => r.id == p.rifaId).firstOrNull;

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
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: estadoColor.withValues(alpha: 0.2),
                        child: Text(
                          p.nombre.isNotEmpty ? p.nombre[0].toUpperCase() : '?',
                          style: TextStyle(fontWeight: FontWeight.bold, color: estadoColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('WhatsApp: ${p.whatsapp}', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: estadoColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(estadoLabel, style: TextStyle(color: estadoColor, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: p.numeros.map((n) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: estadoColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: estadoColor.withValues(alpha: 0.3)),
                ),
                child: Text(n, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: estadoColor)),
              )).toList(),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildAction(
                  icon: Icons.message_outlined,
                  color: Colors.green,
                  onTap: () => _contactWhatsApp(p, rifa),
                ),
                const SizedBox(width: 8),
                _buildAction(
                  icon: Icons.confirmation_number_outlined,
                  color: AppTheme.primaryColor,
                  onTap: () {
                    if (rifa != null) {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => TicketScreen(participante: p, rifa: rifa),
                      ));
                    }
                  },
                ),
                if (!isPaid) ...[
                  const SizedBox(width: 8),
                  _buildAction(
                    icon: Icons.add_circle_outline,
                    color: Colors.orange,
                    onTap: () => _showAbonoDialog(p, provider, rifa),
                  ),
                  if (rifa != null) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmPago(p, provider, rifa),
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('PAGAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAction({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  void _contactWhatsApp(Participante p, Rifa? rifa) async {
    final auth = context.read<AuthProvider>();
    final config = await FirebaseService.instance.getAppConfig(organizacionId: auth.organizacionId);
    final cuenta = (config?.numeroCuenta ?? '').trim();
    final metodo = config?.metodoPago ?? 'nequi';
    final labelCuenta = cuenta.isNotEmpty ? '$cuenta (${metodo.toUpperCase()})' : 'la cuenta indicada';
    final total = (p.numeros.length * (rifa?.precioNumero ?? 0)).toDouble();
    final restante = total - p.totalPagado;

    final estado = p.estadoPago == EstadoPago.pagado
        ? '✅ PAGADO'
        : p.estadoPago == EstadoPago.abonado
            ? '💳 ABONADO'
            : '⏳ PENDIENTE';

    final message = [
      'Hola ${p.nombre}, te hablo de RifaDorada por tu reserva en la rifa "${rifa?.nombre ?? ''}".',
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
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _confirmPago(Participante p, RifaProvider provider, Rifa rifa) async {
    final confirm = await showDialog<bool>(
      context: context,
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

    await provider.marcarPago(p.id, true, rifaId: rifa.id, precioNumero: rifa.precioNumero);

    if (!context.mounted) return;
    final idx = provider.participantes.indexWhere((x) => x.id == p.id);
    final updated = idx >= 0 ? provider.participantes[idx] : p.copyWith(estadoPago: EstadoPago.pagado, totalPagado: p.numeros.length * rifa.precioNumero);
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => TicketScreen(participante: updated, rifa: rifa, autoSend: true),
    ));
  }

  void _showAbonoDialog(Participante p, RifaProvider provider, Rifa? rifa) {
    final precioNumero = rifa?.precioNumero ?? 0;
    final precioTotal = p.numeros.length * precioNumero;
    final montoController = TextEditingController();
    final notaController = TextEditingController();
    String metodoPago = 'efectivo';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final faltante = precioTotal - p.totalPagado;

          return AlertDialog(
            title: Column(
              children: [
                const Text('Registrar Abono'),
                Text(
                  p.nombre,
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
                onPressed: () async {
                  final montoVal = double.tryParse(montoController.text);
                  if (montoVal == null || montoVal <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ingrese un monto válido')),
                    );
                    return;
                  }
                  final (error, estado) = await provider.registrarAbono(
                    participanteId: p.id,
                    monto: montoVal,
                    nota: notaController.text.isNotEmpty ? notaController.text : null,
                    metodoPago: metodoPago,
                    rifaId: rifa?.id,
                    precioNumero: precioNumero,
                  );
                  if (context.mounted) {
                    if (error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('⚠️ $error'), backgroundColor: Colors.orange),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('✅ Abono registrado. Enviando ticket...'),
                          backgroundColor: AppTheme.secondaryColor,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  }
                  Navigator.pop(context);
                  if (error == null && context.mounted) {
                    final idx = provider.participantes.indexWhere((x) => x.id == p.id);
                    final updated = idx >= 0 ? provider.participantes[idx] : p;
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => TicketScreen(participante: updated, rifa: rifa!, autoSend: true),
                    ));
                  }
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
