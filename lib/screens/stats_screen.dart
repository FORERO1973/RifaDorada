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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
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
    if (mounted) setState(() { _globalStats = global; });
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
    if (mounted) setState(() { _globalParticipantes = all; });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RifaProvider>(
      builder: (context, provider, child) {
        if (provider.rifas.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('No hay rifas disponibles')),
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
          body: Container(
            decoration: BoxDecoration(color: AppTheme.surfaceColor),
            child: CustomScrollView(
              slivers: [
                _buildAppBar(context, provider),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCards(stats, abonados),
                        const SizedBox(height: 24),
                        _buildSalesChart(stats),
                        const SizedBox(height: 24),
                        _buildRevenueChart(stats),
                        const SizedBox(height: 24),
                        _buildPaymentMethodChart(),
                        const SizedBox(height: 24),
                        _buildTrendChart(provider),
                        const SizedBox(height: 24),
                        _buildWeeklyChart(provider),
                        const SizedBox(height: 24),
                        _buildVendedorSection(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, RifaProvider provider) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.surfaceColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryColor.withValues(alpha: 0.1), AppTheme.surfaceColor],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(boxShadow: [
                                  BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 2),
                                ]),
                                child: Image.asset('assets/logo/logo.png', height: 36, fit: BoxFit.contain),
                              ),
                              const SizedBox(width: 12),
                              Text('Estadísticas', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900, color: AppTheme.primaryColor,
                              )),
                            ],
                          ),
                          Text(
                            selectedRifa?.nombre ?? 'Resumen Global',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    _buildRifaSelector(provider, context.read<AuthProvider>()),
                  ],
                ),
              ),
              _buildTimeFilter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _buildPeriodChip('7d', '7 Días'),
          const SizedBox(width: 6),
          _buildPeriodChip('30d', '30 Días'),
          const SizedBox(width: 6),
          _buildPeriodChip('90d', '90 Días'),
          const SizedBox(width: 6),
          _buildPeriodChip('all', 'Todo'),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String value, String label) {
    final selected = _timePeriod == value;
    return GestureDetector(
      onTap: () => setState(() => _timePeriod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.primaryColor : AppTheme.dividerColor),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: selected ? Colors.white : AppTheme.textSecondary,
        )),
      ),
    );
  }

  Widget _buildRifaSelector(RifaProvider provider, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
      ),
      child: DropdownButton<String>(
        value: selectedRifa?.id,
        underline: const SizedBox(),
        dropdownColor: Theme.of(context).cardColor,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryColor),
        items: [
          const DropdownMenuItem(value: null, child: Text('Global', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          ...provider.rifas.map((rifa) => DropdownMenuItem<String>(
            value: rifa.id,
            child: Text(rifa.nombre.length > 15 ? '${rifa.nombre.substring(0, 12)}...' : rifa.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
            if (auth.esAdmin) {
              setState(() => _loadingVendedor = true);
              provider.getVendedorStats().then((v) {
                if (mounted) setState(() { _vendedorStats = v; _loadingVendedor = false; });
              });
            }
          }
        },
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> stats, int abonados) {
    String formatMoney(double value) => AppConstants.formatCurrencyCOP(value);
    final totalPagado = (stats['totalVendido'] as num?)?.toDouble() ?? 0;
    final pendiente = (stats['pendientePago'] as num?)?.toDouble() ?? 0;
    final numerosVendidos = stats['totalVendidos'] as int? ?? 0;
    final isGlobal = selectedRifa == null;
    final totalNumeros = isGlobal
        ? (_globalStats['totalNumeros'] as int? ?? _globalStats['totalVendidos'] as int? ?? 1)
        : (selectedRifa?.cantidadNumeros ?? 1);
    final progreso = totalNumeros > 0 ? (numerosVendidos / totalNumeros) : 0.0;
    final potencialTotal = isGlobal
        ? (_globalStats['potencialTotal'] as num?)?.toDouble() ?? 0
        : totalNumeros * (selectedRifa?.precioNumero ?? 0).toDouble();
    final totalVendido = totalPagado + pendiente;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.dividerColor),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 70, height: 70,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progreso, strokeWidth: 8,
                      backgroundColor: AppTheme.dividerColor,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      strokeCap: StrokeCap.round,
                    ),
                    Text('${(progreso * 100).toInt()}%', style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.textPrimary,
                    )),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PROGRESO DE VENTAS', style: GoogleFonts.outfit(
                      fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: AppTheme.primaryColor,
                    )),
                    const SizedBox(height: 4),
                    Text(formatMoney(totalVendido), style: GoogleFonts.outfit(
                      fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary,
                    )),
                    Text('de ${formatMoney(potencialTotal)}', style: GoogleFonts.outfit(
                      fontSize: 12, color: AppTheme.textSecondary,
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.3,
          children: [
            _buildStatCard('Recaudado', formatMoney(totalPagado), Icons.payments_rounded,
              LinearGradient(colors: [Colors.green.shade600, Colors.green.shade800])),
            _buildStatCard('Pendiente', formatMoney(pendiente), Icons.pending_actions_rounded,
              LinearGradient(colors: [Colors.orange.shade600, Colors.orange.shade800])),
            _buildStatCard('Potencial', formatMoney(potencialTotal), Icons.account_balance_wallet_rounded,
              AppTheme.goldGradient),
            _buildStatCard('Vendidos', '$numerosVendidos', Icons.confirmation_number_rounded,
              LinearGradient(colors: [Colors.blue.shade600, Colors.blue.shade800])),
          ],
        ),
        if (abonados > 0) Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Icon(Icons.person_pin, size: 16, color: Colors.orange),
              const SizedBox(width: 6),
              Text('$abonados participantes con abonos parciales', style: GoogleFonts.outfit(
                fontSize: 12, color: Colors.orange.shade700, fontWeight: FontWeight.w600,
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Gradient gradient) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: (gradient.colors.last).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: -0.5,
              ), maxLines: 1)),
              const SizedBox(height: 1),
              Text(title.toUpperCase(), style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w800, fontSize: 8, letterSpacing: 1,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
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
    final disponiblesCount = totalNumeros - vendidos;
    final porcentaje = totalNumeros > 0 ? (vendidos / totalNumeros * 100).toStringAsFixed(1) : '0';

    return _buildChartContainer(
      title: 'Distribución de Números',
      subtitle: '$porcentaje% de la rifa vendida',
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    color: Colors.green.shade600, value: pagadosCount.toDouble(),
                    title: '$pagadosCount', radius: 50,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  PieChartSectionData(
                    color: Colors.orange.shade600, value: reservadosCount.toDouble(),
                    title: '$reservadosCount', radius: 50,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  PieChartSectionData(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2), value: disponiblesCount.toDouble(),
                    title: '$disponiblesCount', radius: 40,
                    titleStyle: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Pagados', Colors.green.shade600),
              const SizedBox(width: 16),
              _buildLegendItem('Reservados', Colors.orange.shade600),
              const SizedBox(width: 16),
              _buildLegendItem('Disponibles', AppTheme.primaryColor.withValues(alpha: 0.2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildRevenueChart(Map<String, dynamic> stats) {
    return _buildChartContainer(
      title: 'Estado de Pagos',
      subtitle: 'Pagado vs Pendiente',
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: ((stats['totalVendido'] ?? 0) as num).toDouble() + ((stats['pendientePago'] ?? 0) as num).toDouble(),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.black87,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    AppConstants.formatCurrencyCOP((rod.toY as num).toDouble()),
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
                    return Text(titles[value.toInt()], style: const TextStyle(fontSize: 10));
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
                  toY: (stats['totalVendido'] as num?)?.toDouble() ?? 0,
                  color: Colors.green, width: 30,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ]),
              BarChartGroupData(x: 1, barRods: [
                BarChartRodData(
                  toY: (stats['pendientePago'] as num?)?.toDouble() ?? 0,
                  color: Colors.orange, width: 30,
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
    if (methods.isEmpty || _loadingPayment) {
      return const SizedBox.shrink();
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
      subtitle: 'Distribución de $total transacciones',
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 35,
                sections: methods.entries.map((e) => PieChartSectionData(
                  color: colorMap[e.key] ?? Colors.grey,
                  value: e.value.toDouble(),
                  title: '${(e.value / total * 100).toInt()}%',
                  radius: 45,
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                )).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12, runSpacing: 6,
            children: methods.entries.map((e) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(color: colorMap[e.key] ?? Colors.grey, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 4),
                Text('${e.key} (${e.value})', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(RifaProvider provider) {
    final isGlobal = selectedRifa == null;
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

    final participantes = isGlobal ? _globalParticipantes : provider.participantes;

    for (final p in participantes) {
      if (!isGlobal && p.rifaId != selectedRifa!.id) continue;
      if (cutoff != null && p.fechaRegistro.isBefore(cutoff)) continue;
      final key = DateTime(p.fechaRegistro.year, p.fechaRegistro.month, p.fechaRegistro.day).millisecondsSinceEpoch;
      salesByDay[key] = (salesByDay[key] ?? 0) + p.numeros.length;
    }

    final sortedKeys = salesByDay.keys.toList()..sort();
    final spots = sortedKeys.asMap().entries.map((e) => FlSpot(e.key.toDouble(), salesByDay[e.value]!.toDouble())).toList();

    final periodoLabel = days < 9999 ? 'últimos $days días' : 'todo el tiempo';

    return _buildChartContainer(
      title: 'Tendencia de Ventas',
      subtitle: 'Números vendidos en los $periodoLabel',
      child: SizedBox(
        height: 200,
        child: spots.isEmpty
            ? Center(child: Text('No hay ventas en el período seleccionado', style: TextStyle(color: AppTheme.textSecondary)))
            : LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: spots.length <= 10,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= sortedKeys.length) return const SizedBox();
                          final date = DateTime.fromMillisecondsSinceEpoch(sortedKeys[value.toInt()]);
                          return Text(DateFormat('dd/MM').format(date), style: const TextStyle(fontSize: 8));
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
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryColor.withValues(alpha: 0.2), AppTheme.primaryColor.withValues(alpha: 0.0)],
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
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
    final isGlobal = selectedRifa == null;

    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));

    final dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final salesByDay = List.filled(7, 0);

    final participantes = isGlobal ? _globalParticipantes : provider.participantes;

    for (final p in participantes) {
      if (!isGlobal && p.rifaId != selectedRifa!.id) continue;
      if (p.fechaRegistro.isBefore(monday) || p.fechaRegistro.isAfter(now)) continue;
      final dayIndex = p.fechaRegistro.weekday - 1;
      salesByDay[dayIndex] += p.numeros.length;
    }

    double maxY = 0;
    final spots = <FlSpot>[];
    for (var i = 0; i < 7; i++) {
      final y = salesByDay[i].toDouble();
      spots.add(FlSpot(i.toDouble(), y));
      if (y > maxY) maxY = y;
    }

    return _buildChartContainer(
      title: 'Comportamiento Semanal',
      subtitle: 'Semana del ${DateFormat('dd/MM').format(monday)} al ${DateFormat('dd/MM').format(now)}',
      child: SizedBox(
        height: 200,
        child: spots.every((s) => s.y == 0)
            ? Center(child: Text('No hay ventas esta semana', style: TextStyle(color: AppTheme.textSecondary)))
            : LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY > 0 ? maxY * 1.2 : 10,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppTheme.dividerColor.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx > 6) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              dayNames[idx],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: idx >= now.weekday - 1 ? AppTheme.textSecondary : AppTheme.textPrimary,
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
                      getTooltipColor: (_) => Colors.black87,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final idx = spot.x.toInt();
                          if (idx < 0 || idx > 6) {
                            return LineTooltipItem('', const TextStyle());
                          }
                          return LineTooltipItem(
                            '${dayNames[idx]}: ${spot.y.toInt()} nums',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFD4AF37).withValues(alpha: 0.6),
                          const Color(0xFFFFD700).withValues(alpha: 0.9),
                          const Color(0xFFDAA520),
                        ],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          if (spot.y == 0) return FlDotCirclePainter(radius: 0);
                          return FlDotCirclePainter(
                            radius: 4,
                            strokeWidth: 2,
                            strokeColor: const Color(0xFFDAA520),
                            color: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFD4AF37).withValues(alpha: 0.25),
                            const Color(0xFFFFD700).withValues(alpha: 0.08),
                            const Color(0xFFDAA520).withValues(alpha: 0.0),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          Text(subtitle, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildVendedorSection() {
    if (_loadingVendedor) return const SizedBox.shrink();
    final vendedores = _vendedorStats['vendedores'] as List<dynamic>? ?? [];
    if (vendedores.isEmpty) return const SizedBox.shrink();

    final isGlobal = selectedRifa == null;

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.esAdmin) return const SizedBox.shrink();

        return _buildChartContainer(
          title: 'Rendimiento por Vendedor',
          subtitle: isGlobal
              ? '${vendedores.length} vendedores activos'
              : '${vendedores.length} vendedores en "${selectedRifa!.nombre}"',
          child: Column(
            children: [
              ...vendedores.map((v) {
                final vMap = v as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                        child: Text(
                          (vMap['nombre'] as String? ?? '?')[0].toUpperCase(),
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(vMap['nombre'] as String? ?? 'Vendedor', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            Text('${vMap['numerosVendidos']} números • ${vMap['totalParticipantes']} ventas',
                              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(AppConstants.formatCurrencyCOP((vMap['totalRecaudado'] as num?)?.toDouble() ?? 0),
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.green.shade700)),
                          Text('recaudado', style: TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
                        ],
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
