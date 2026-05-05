import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../providers/rifa_provider.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<RifaProvider>(context, listen: false);
      if (provider.rifas.isNotEmpty) {
        setState(() {
          selectedRifa = provider.rifas.first;
        });
        provider.loadParticipantes(selectedRifa!.id);
        provider.loadNumeros(selectedRifa!.id);
      }
    });
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

        final stats = selectedRifa != null 
            ? provider.getEstadisticas() 
            : _getGlobalStats(provider);

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
            ),

            child: CustomScrollView(
              slivers: [
                _buildAppBar(context, provider),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCards(stats),
                        const SizedBox(height: 24),
                        _buildSalesChart(stats),
                        const SizedBox(height: 24),
                        _buildRevenueChart(stats),
                        const SizedBox(height: 24),
                        _buildTrendChart(provider.participantes),
                        const SizedBox(height: 100), // Space for bottom bar
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
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.surfaceColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.1),
                AppTheme.surfaceColor,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                                  height: 36,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Estadísticas',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            selectedRifa?.nombre ?? 'Resumen Global',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildRifaSelector(provider),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRifaSelector(RifaProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: DropdownButton<Rifa>(
        value: selectedRifa,
        underline: const SizedBox(),
        dropdownColor: Theme.of(context).cardColor,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryColor),
        items: provider.rifas.map((rifa) {
          return DropdownMenuItem(
            value: rifa,
            child: Text(
              rifa.nombre.length > 15 ? '${rifa.nombre.substring(0, 12)}...' : rifa.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          );
        }).toList(),
        onChanged: (rifa) {
          if (rifa != null) {
            setState(() {
              selectedRifa = rifa;
            });
            provider.setRifaSeleccionada(rifa);
            provider.loadParticipantes(rifa.id);
            provider.loadNumeros(rifa.id);
          }
        },
      ),
    );
  }
  Widget _buildSummaryCards(Map<String, dynamic> stats) {
    String formatMoney(double value) => AppConstants.formatCurrencyCOP(value);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 3.0,
      children: [
        _buildStatCard(
          'Recaudado',
          formatMoney((stats['totalVendido'] as num).toDouble()),
          Icons.payments_rounded,
          LinearGradient(colors: [Colors.green.shade600, Colors.green.shade800]),
        ),
        _buildStatCard(
          'Pendiente',
          formatMoney((stats['pendientePago'] as num).toDouble()),
          Icons.pending_actions_rounded,
          LinearGradient(colors: [Colors.orange.shade600, Colors.orange.shade800]),
        ),
        _buildStatCard(
          'Potencial',
          formatMoney(((stats['totalVendido'] as num).toDouble()) + ((stats['pendientePago'] as num).toDouble()) + ((stats['totalDisponibles'] as num).toDouble() * (selectedRifa?.precioNumero ?? 0))),
          Icons.account_balance_wallet_rounded,
          AppTheme.goldGradient,
        ),
        _buildStatCard(
          'Vendidos',
          stats['totalVendidos'].toString(),
          Icons.confirmation_number_rounded,
          LinearGradient(colors: [Colors.blue.shade600, Colors.blue.shade800]),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Gradient gradient) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (gradient.colors.last).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
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


  Widget _buildSalesChart(Map<String, dynamic> stats) {
    final vendidos = stats['totalVendidos'] as int;
    final disponibles = stats['totalDisponibles'] as int;
    final total = vendidos + disponibles;
    final porcentaje = total > 0 ? (vendidos / total * 100).toStringAsFixed(1) : '0';

    return _buildChartContainer(
      title: 'Distribución de Números',
      subtitle: '$porcentaje% de la rifa vendida',
      child: SizedBox(
        height: 200,
        child: PieChart(
          PieChartData(
            sectionsSpace: 4,
            centerSpaceRadius: 40,
            sections: [
              PieChartSectionData(
                color: AppTheme.primaryColor,
                value: vendidos.toDouble(),
                title: '$vendidos',
                radius: 50,
                titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              PieChartSectionData(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                value: disponibles.toDouble(),
                title: '$disponibles',
                radius: 40,
                titleStyle: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 10),
              ),

            ],
          ),
        ),
      ),
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
            maxY: (stats['totalVendido'] + stats['pendientePago']).toDouble(),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.black87,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    AppConstants.formatCurrencyCOP(rod.toY),
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
              BarChartGroupData(
                x: 0,
                barRods: [
                  BarChartRodData(
                    toY: stats['totalVendido'].toDouble(),
                    color: Colors.green,
                    width: 30,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ],
              ),
              BarChartGroupData(
                x: 1,
                barRods: [
                  BarChartRodData(
                    toY: stats['pendientePago'].toDouble(),
                    color: Colors.orange,
                    width: 30,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendChart(List<Participante> participantes) {
    // Group sales by day for the last 7 days
    final now = DateTime.now();
    final Map<int, int> salesByDay = {};
    
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      salesByDay[DateTime(day.year, day.month, day.day).millisecondsSinceEpoch] = 0;
    }

    for (final p in participantes) {
      final pDate = DateTime(p.fechaRegistro.year, p.fechaRegistro.month, p.fechaRegistro.day).millisecondsSinceEpoch;
      if (salesByDay.containsKey(pDate)) {
        salesByDay[pDate] = (salesByDay[pDate] ?? 0) + p.numeros.length;
      }
    }

    final sortedKeys = salesByDay.keys.toList()..sort();
    final List<FlSpot> spots = [];
    for (int i = 0; i < sortedKeys.length; i++) {
      spots.add(FlSpot(i.toDouble(), salesByDay[sortedKeys[i]]!.toDouble()));
    }

    return _buildChartContainer(
      title: 'Tendencia de Ventas',
      subtitle: 'Números vendidos en los últimos 7 días',
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= sortedKeys.length) return const SizedBox();
                    final date = DateTime.fromMillisecondsSinceEpoch(sortedKeys[value.toInt()]);
                    return Text(DateFormat('dd').format(date), style: const TextStyle(fontSize: 10));
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
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.2),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          Text(
            subtitle,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }


  Map<String, dynamic> _getGlobalStats(RifaProvider provider) {
    double totalVendido = 0;
    double pendientePago = 0;
    int totalVendidosCount = 0;
    int totalDisponiblesCount = 0;
    int participantesPagados = 0;
    int participantesPendientes = 0;

    for (final rifa in provider.rifas) {
      final stats = provider.getEstadisticasForRifa(rifa.id, rifa.precioNumero);
      totalVendido += stats['totalVendido'];
      pendientePago += stats['pendientePago'];
      totalVendidosCount += stats['totalVendidos'] as int;
      totalDisponiblesCount += stats['totalDisponibles'] as int;
      participantesPagados += stats['participantesPagados'] as int;
      participantesPendientes += stats['participantesPendientes'] as int;
    }
    
    return {
      'totalVendido': totalVendido,
      'pendientePago': pendientePago,
      'totalVendidos': totalVendidosCount,
      'totalDisponibles': totalDisponiblesCount,
      'participantesPagados': participantesPagados,
      'participantesPendientes': participantesPendientes,
    };
  }

}
