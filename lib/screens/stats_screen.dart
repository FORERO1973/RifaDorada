import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../providers/rifa_provider.dart';
import '../providers/auth_provider.dart';
import '../models/rifa.dart';
import '../models/participante.dart';
import '../config/constants.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Rifa? selectedRifa;
  String _timePeriod = 'all';
  Map<String, dynamic> _globalStats = {};
  Map<String, dynamic> _vendedorStats = {};
  Map<String, dynamic> _paymentMethodStats = {};
  bool _loadingVendedor = true;
  bool _loadingPayment = true;
  List<Participante> _globalParticipantes = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final provider = context.read<RifaProvider>();
    final auth = context.read<AuthProvider>();
    try {
      selectedRifa = null;
      provider.clearRifaSeleccionada();
      await _refreshGlobalStats(provider);
      if (auth.esAdmin) {
        setState(() => _loadingVendedor = true);
        final vStats = await provider.getVendedorStats();
        if (mounted) setState(() { _vendedorStats = vStats; _loadingVendedor = false; });
      }
      await _loadGlobalParticipants(provider);
      await _refreshGlobalPaymentStats(provider);
    } catch (e) {
      debugPrint('[STATS] Error loading data: $e');
    }
  }

  Future<void> _refreshGlobalStats(RifaProvider provider) async {
    final global = await _getGlobalStats(provider);
    if (mounted) setState(() => _globalStats = global);
  }

  Future<void> _refreshGlobalPaymentStats(RifaProvider provider) async {
    setState(() => _loadingPayment = true);
    final pStats = await provider.getPaymentMethodStatsGlobal();
    if (mounted) setState(() { _paymentMethodStats = pStats; _loadingPayment = false; });
  }

  Future<void> _loadPaymentStats(RifaProvider provider, String rifaId) async {
    setState(() => _loadingPayment = true);
    final pStats = await provider.getPaymentMethodStats(rifaId);
    if (mounted) setState(() { _paymentMethodStats = pStats; _loadingPayment = false; });
  }

  Future<void> _loadGlobalParticipants(RifaProvider provider) async {
    final all = await provider.getAllParticipantes();
    if (mounted) setState(() => _globalParticipantes = all);
  }

  List<Participante> _getFilteredParticipantes(RifaProvider provider) {
    final isGlobal = selectedRifa == null;
    if (isGlobal) return _globalParticipantes;
    return provider.participantes.where((p) => p.rifaId == selectedRifa!.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RifaProvider>(
      builder: (context, provider, child) {
        if (provider.rifas.isEmpty) {
          return Scaffold(
            body: Center(
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
                    child: Icon(Icons.insights_rounded, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                  ),
                  const SizedBox(height: 24),
                  Text('No hay rifas disponibles', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Crea una rifa para ver estadísticas', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                ],
              ),
            ),
          );
        }

        if (selectedRifa != null) {
          final match = provider.rifas.where((r) => r.id == selectedRifa!.id);
          if (match.isEmpty) {
            selectedRifa = provider.rifas.firstOrNull;
          } else {
            selectedRifa = match.first;
          }
        }

        final isGlobal = selectedRifa == null;
        final stats = isGlobal ? _globalStats : provider.getEstadisticas();
        final abonados = stats['participantesAbonados'] as int? ?? 0;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context, provider),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCards(stats, abonados),
                      const SizedBox(height: 12),
                      _buildSalesChart(stats),
                      const SizedBox(height: 12),
                      _buildRevenueChart(stats),
                      const SizedBox(height: 12),
                      _buildPaymentMethodChart(),
                      const SizedBox(height: 12),
                      _buildTrendChart(provider),
                      const SizedBox(height: 12),
                      _buildWeeklyChart(provider),
                      const SizedBox(height: 12),
                      _buildVendedorSection(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, RifaProvider provider) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.surfaceColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryColor.withValues(alpha: 0.06), AppTheme.surfaceColor],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.insights_rounded, color: AppTheme.primaryColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Estadísticas',
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                            ),
                            Text(
                              selectedRifa?.nombre ?? 'Todas las rifas',
                              style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      _buildRifaSelector(provider),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildTimeFilter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeFilter() {
    return Row(
      children: [
        _buildPeriodChip('7d', '7D'),
        const SizedBox(width: 4),
        _buildPeriodChip('30d', '30D'),
        const SizedBox(width: 4),
        _buildPeriodChip('90d', '90D'),
        const SizedBox(width: 4),
        _buildPeriodChip('all', 'Todo'),
      ],
    );
  }

  Widget _buildPeriodChip(String value, String label) {
    final selected = _timePeriod == value;
    return GestureDetector(
      onTap: () => setState(() => _timePeriod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppTheme.primaryColor : AppTheme.dividerColor),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: selected ? AppTheme.backgroundColor : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildRifaSelector(RifaProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedRifa?.id,
          dropdownColor: AppTheme.cardColor,
          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.primaryColor, size: 20),
          items: [
            const DropdownMenuItem(value: null, child: Text('Global', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            ...provider.rifas.map((r) => DropdownMenuItem<String>(
              value: r.id,
              child: Text(
                r.nombre.length > 14 ? '${r.nombre.substring(0, 11)}...' : r.nombre,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            )),
          ],
          onChanged: (rifaId) {
            if (rifaId != null) {
              final rifa = provider.rifas.firstWhere((r) => r.id == rifaId);
              setState(() => selectedRifa = rifa);
              provider.setRifaSeleccionada(rifa);
              provider.loadParticipantes(rifa.id);
              provider.loadNumeros(rifa.id);
              _loadPaymentStats(provider, rifa.id);
              final auth = context.read<AuthProvider>();
              if (auth.esAdmin) {
                setState(() => _loadingVendedor = true);
                provider.getVendedorStats(rifaId: rifaId).then((v) {
                  if (mounted) setState(() { _vendedorStats = v; _loadingVendedor = false; });
                });
              }
            } else {
              setState(() => selectedRifa = null);
              provider.clearRifaSeleccionada();
              _refreshGlobalStats(provider);
              _refreshGlobalPaymentStats(provider);
              _loadGlobalParticipants(provider);
              final auth = context.read<AuthProvider>();
              if (auth.esAdmin) {
                setState(() => _loadingVendedor = true);
                provider.getVendedorStats().then((v) {
                  if (mounted) setState(() { _vendedorStats = v; _loadingVendedor = false; });
                });
              }
            }
          },
        ),
      ),
    );
  }

  String _formatMoney(double value) => AppConstants.formatCurrencyCOP(value);

  Widget _buildSummaryCards(Map<String, dynamic> stats, int abonados) {
    final totalPagado = (stats['totalVendido'] as num?)?.toDouble() ?? 0;
    final pendiente = (stats['pendientePago'] as num?)?.toDouble() ?? 0;
    final numerosVendidos = stats['totalVendidos'] as int? ?? 0;
    final isGlobal = selectedRifa == null;
    final totalNumeros = isGlobal
        ? (_globalStats['totalNumeros'] as int? ?? 1)
        : (selectedRifa?.cantidadNumeros ?? 1);
    final progreso = totalNumeros > 0 ? (numerosVendidos / totalNumeros) : 0.0;
    final potencialTotal = isGlobal
        ? (_globalStats['potencialTotal'] as num?)?.toDouble() ?? 0
        : totalNumeros * (selectedRifa?.precioNumero ?? 0).toDouble();
    final totalVendido = totalPagado + pendiente;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor.withValues(alpha: 0.12), AppTheme.primaryColor.withValues(alpha: 0.04)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progreso.clamp(0.0, 1.0),
                      strokeWidth: 6,
                      backgroundColor: AppTheme.dividerColor,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      strokeCap: StrokeCap.round,
                    ),
                    Text(
                      '${(progreso * 100).toInt()}%',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 13, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROGRESO DE VENTAS',
                      style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatMoney(totalVendido),
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                    ),
                    Text(
                      'de ${_formatMoney(potencialTotal)} · $numerosVendidos/$totalNumeros',
                      style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard('Recaudado', _formatMoney(totalPagado), Icons.payments_rounded,
              LinearGradient(colors: [Colors.green.shade600, Colors.green.shade800])),
            _buildStatCard('Pendiente', _formatMoney(pendiente), Icons.pending_actions_rounded,
              LinearGradient(colors: [Colors.orange.shade600, Colors.orange.shade800])),
            _buildStatCard('Potencial', _formatMoney(potencialTotal), Icons.account_balance_wallet_rounded,
              AppTheme.goldGradient),
            _buildStatCard('Vendidos', '$numerosVendidos', Icons.confirmation_number_rounded,
              LinearGradient(colors: [Colors.blue.shade600, Colors.blue.shade800])),
          ],
        ),
        if (abonados > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.person_pin_rounded, size: 14, color: Colors.orange),
                const SizedBox(width: 4),
                Text('$abonados con abonos parciales', style: GoogleFonts.outfit(fontSize: 11, color: Colors.orange.shade700, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Gradient gradient) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: (gradient.colors.last).withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: -0.5),
                  maxLines: 1,
                ),
              ),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w800, fontSize: 7, letterSpacing: 0.8),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart(Map<String, dynamic> stats) {
    final isGlobal = selectedRifa == null;
    final totalNumeros = isGlobal
        ? (_globalStats['totalNumeros'] as int? ?? 1)
        : (selectedRifa?.cantidadNumeros ?? 1);
    final vendidos = stats['totalVendidos'] as int? ?? 0;
    final pagadosCount = stats['numerosPagados'] as int? ?? 0;
    final reservadosCount = stats['numerosReservados'] as int? ?? 0;
    final disponiblesCount = (totalNumeros - vendidos).clamp(0, totalNumeros);
    final porcentaje = totalNumeros > 0 ? (vendidos / totalNumeros * 100).toStringAsFixed(1) : '0';

    final hasData = vendidos > 0 || disponiblesCount > 0;

    return _buildChartContainer(
      title: 'Distribución de Números',
      subtitle: '$porcentaje% vendido',
      child: hasData
          ? Column(
              children: [
                SizedBox(
                  height: 160,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 35,
                      sections: [
                        if (pagadosCount > 0)
                          PieChartSectionData(
                            color: Colors.green.shade600,
                            value: pagadosCount.toDouble(),
                            title: '$pagadosCount',
                            radius: 45,
                            titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        if (reservadosCount > 0)
                          PieChartSectionData(
                            color: Colors.orange.shade600,
                            value: reservadosCount.toDouble(),
                            title: '$reservadosCount',
                            radius: 45,
                            titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        if (disponiblesCount > 0)
                          PieChartSectionData(
                            color: AppTheme.primaryColor.withValues(alpha: 0.15),
                            value: disponiblesCount.toDouble(),
                            title: '$disponiblesCount',
                            radius: 35,
                            titleStyle: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem('Pagados', Colors.green.shade600),
                    const SizedBox(width: 12),
                    _buildLegendItem('Reservados', Colors.orange.shade600),
                    const SizedBox(width: 12),
                    _buildLegendItem('Disponibles', AppTheme.primaryColor.withValues(alpha: 0.15)),
                  ],
                ),
              ],
            )
          : _buildEmptyChart('Sin datos de distribución'),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildRevenueChart(Map<String, dynamic> stats) {
    final totalPagado = (stats['totalVendido'] as num?)?.toDouble() ?? 0;
    final pendiente = (stats['pendientePago'] as num?)?.toDouble() ?? 0;
    final maxVal = (totalPagado + pendiente).clamp(1.0, double.infinity);

    return _buildChartContainer(
      title: 'Estado de Pagos',
      subtitle: 'Monto pagado vs pendiente',
      child: SizedBox(
        height: 160,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxVal,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => AppTheme.cardColor,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    AppConstants.formatCurrencyCOP((rod.toY as num).toDouble()),
                    const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 11),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    const titles = ['Pagado', 'Pendiente'];
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        titles[value.toInt()],
                        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: [
              BarChartGroupData(x: 0, barRods: [
                BarChartRodData(
                  toY: totalPagado,
                  gradient: LinearGradient(colors: [Colors.green.shade600, Colors.green.shade400]),
                  width: 28,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ]),
              BarChartGroupData(x: 1, barRods: [
                BarChartRodData(
                  toY: pendiente,
                  gradient: LinearGradient(colors: [Colors.orange.shade600, Colors.orange.shade400]),
                  width: 28,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodChart() {
    final methods = _paymentMethodStats['methods'] as Map<String, int>? ?? {};

    if (_loadingPayment) {
      return _buildChartContainer(
        title: 'Métodos de Pago',
        subtitle: 'Cargando...',
        child: const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    if (methods.isEmpty) {
      return _buildChartContainer(
        title: 'Métodos de Pago',
        subtitle: 'Sin transacciones registradas',
        child: _buildEmptyChart('Sin datos de métodos de pago'),
      );
    }

    final total = methods.values.fold(0, (a, b) => a + b);
    final colorMap = <String, Color>{
      'nequi': Colors.purple.shade400,
      'daviplata': Colors.red.shade400,
      'bancolombia': Colors.yellow.shade700,
      'efectivo': Colors.green.shade600,
      'transferencia': Colors.blue.shade400,
      'datáfono': Colors.teal.shade400,
      'bizum': Colors.indigo.shade400,
    };

    return _buildChartContainer(
      title: 'Métodos de Pago',
      subtitle: '$total transacciones',
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 30,
                sections: methods.entries.map((e) => PieChartSectionData(
                  color: colorMap[e.key] ?? Colors.grey,
                  value: e.value.toDouble(),
                  title: e.value > 0 ? '${(e.value / total * 100).toInt()}%' : '',
                  radius: 40,
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                )).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: methods.entries.map((e) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: colorMap[e.key] ?? Colors.grey, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 3),
                Text('${e.key} (${e.value})', style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(RifaProvider provider) {
    final participantes = _getFilteredParticipantes(provider);
    final now = DateTime.now();
    int days;
    switch (_timePeriod) {
      case '7d': days = 7;
      case '30d': days = 30;
      case '90d': days = 90;
      default: days = 9999;
    }

    final Map<int, int> salesByDay = {};
    final cutoff = days < 9999 ? now.subtract(Duration(days: days)) : null;

    for (final p in participantes) {
      if (cutoff != null && p.fechaRegistro.isBefore(cutoff)) continue;
      final key = DateTime(p.fechaRegistro.year, p.fechaRegistro.month, p.fechaRegistro.day).millisecondsSinceEpoch;
      salesByDay[key] = (salesByDay[key] ?? 0) + p.numeros.length;
    }

    final sortedKeys = salesByDay.keys.toList()..sort();
    final spots = sortedKeys.asMap().entries.map((e) => FlSpot(e.key.toDouble(), salesByDay[e.value]!.toDouble())).toList();

    final periodoLabel = days < 9999 ? 'últimos $days días' : 'todo el tiempo';

    return _buildChartContainer(
      title: 'Tendencia de Ventas',
      subtitle: 'Números vendidos · $periodoLabel',
      child: spots.isEmpty
          ? _buildEmptyChart('No hay ventas en el período seleccionado')
          : SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: spots.length <= 12,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= sortedKeys.length) return const SizedBox();
                          final date = DateTime.fromMillisecondsSinceEpoch(sortedKeys[value.toInt()]);
                          return Text(DateFormat('dd/MM').format(date), style: GoogleFonts.outfit(fontSize: 8, color: AppTheme.textSecondary));
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      gradient: AppTheme.goldGradient,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryColor.withValues(alpha: 0.2), AppTheme.primaryColor.withValues(alpha: 0.0)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWeeklyChart(RifaProvider provider) {
    final participantes = _getFilteredParticipantes(provider);
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = monday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    final dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final salesByDay = List.filled(7, 0);

    for (final p in participantes) {
      if (p.fechaRegistro.isBefore(monday) || p.fechaRegistro.isAfter(endOfWeek)) continue;
      final dayIndex = p.fechaRegistro.weekday - 1;
      if (dayIndex >= 0 && dayIndex < 7) {
        salesByDay[dayIndex] += p.numeros.length;
      }
    }

    double maxY = 0;
    final spots = <FlSpot>[];
    for (var i = 0; i < 7; i++) {
      final y = salesByDay[i].toDouble();
      spots.add(FlSpot(i.toDouble(), y));
      if (y > maxY) maxY = y;
    }

    final hasSales = salesByDay.any((s) => s > 0);

    return _buildChartContainer(
      title: 'Comportamiento Semanal',
      subtitle: '${DateFormat('dd/MM').format(monday)} - ${DateFormat('dd/MM').format(now)}',
      child: !hasSales
          ? _buildEmptyChart('No hay ventas esta semana')
          : SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY > 0 ? maxY * 1.3 : 10,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppTheme.dividerColor.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx > 6) return const SizedBox();
                          final isPast = idx < now.weekday - 1;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              dayNames[idx],
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: isPast ? AppTheme.textPrimary : AppTheme.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => AppTheme.cardColor,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final idx = spot.x.toInt();
                          if (idx < 0 || idx > 6) return LineTooltipItem('', const TextStyle());
                          return LineTooltipItem(
                            '${dayNames[idx]}: ${spot.y.toInt()} nums',
                            const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 11),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      gradient: AppTheme.goldGradient,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          if (spot.y == 0) return FlDotCirclePainter(radius: 0);
                          return FlDotCirclePainter(
                            radius: 4,
                            strokeWidth: 2,
                            strokeColor: AppTheme.primaryDark,
                            color: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withValues(alpha: 0.25),
                            AppTheme.primaryColor.withValues(alpha: 0.08),
                            AppTheme.primaryColor.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildChartContainer({required String title, required String subtitle, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary)),
            ],
          ),
          Text(subtitle, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyChart(String message) {
    return SizedBox(
      height: 100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, size: 28, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 6),
            Text(message, style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textSecondary.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }

  Widget _buildVendedorSection() {
    if (_loadingVendedor) return const SizedBox.shrink();
    final vendedores = _vendedorStats['vendedores'] as List<dynamic>? ?? [];
    if (vendedores.isEmpty) return const SizedBox.shrink();

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.esAdmin) return const SizedBox.shrink();

        return _buildChartContainer(
          title: 'Rendimiento por Vendedor',
          subtitle: '${vendedores.length} vendedores',
          child: Column(
            children: [
              ...vendedores.map((v) {
                final vMap = v as Map<String, dynamic>;
                final nombre = vMap['nombre'] as String? ?? 'Vendedor';
                final nums = vMap['numerosVendidos'] as int? ?? 0;
                final ventas = vMap['totalParticipantes'] as int? ?? 0;
                final recaudado = (vMap['totalRecaudado'] as num?)?.toDouble() ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                        child: Text(
                          nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nombre, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13)),
                            Text('$nums números · $ventas ventas', style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      Text(
                        AppConstants.formatCurrencyCOP(recaudado),
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.green.shade700),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getGlobalStats(RifaProvider provider) async {
    double totalVendido = 0;
    double pendientePago = 0;
    int totalVendidosCount = 0;
    int totalDisponiblesCount = 0;
    int numerosPagados = 0;
    int numerosReservados = 0;
    int totalNumeros = 0;
    double potencialTotal = 0;

    for (final rifa in provider.rifas) {
      final stats = await provider.getEstadisticasForRifa(rifa.id, rifa.precioNumero);
      totalVendido += (stats['totalVendido'] as num?)?.toDouble() ?? 0;
      pendientePago += (stats['pendientePago'] as num?)?.toDouble() ?? 0;
      totalVendidosCount += stats['totalVendidos'] as int? ?? 0;
      totalDisponiblesCount += stats['totalDisponibles'] as int? ?? 0;
      numerosPagados += stats['numerosPagados'] as int? ?? 0;
      numerosReservados += stats['numerosReservados'] as int? ?? 0;
      totalNumeros += rifa.cantidadNumeros;
      potencialTotal += rifa.cantidadNumeros * rifa.precioNumero;
    }

    return {
      'totalVendido': totalVendido,
      'pendientePago': pendientePago,
      'totalVendidos': totalVendidosCount,
      'totalDisponibles': totalDisponiblesCount,
      'numerosPagados': numerosPagados,
      'numerosReservados': numerosReservados,
      'participantesAbonados': 0,
      'totalNumeros': totalNumeros,
      'potencialTotal': potencialTotal,
    };
  }
}
