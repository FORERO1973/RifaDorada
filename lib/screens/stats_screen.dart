import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../providers/rifa_provider.dart';
import '../models/rifa.dart';
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
        final primeraRifa = provider.rifas.first;
        setState(() {
          selectedRifa = primeraRifa;
        });
        provider.setRifaSeleccionada(primeraRifa);
        provider.loadParticipantes(primeraRifa.id);
        provider.loadNumeros(primeraRifa.id);
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

        // Keep selectedRifa in sync with provider's rifas list (match by ID)
        if (selectedRifa != null) {
          final match = provider.rifas.where((r) => r.id == selectedRifa!.id);
          if (match.isEmpty) {
            selectedRifa = provider.rifas.first;
          } else {
            selectedRifa = match.first;
          }
        } else {
          selectedRifa = provider.rifas.first;
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
                        _buildTrendChart(provider),
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
      child: DropdownButton<String>(
        value: selectedRifa?.id,
        underline: const SizedBox(),
        dropdownColor: Theme.of(context).cardColor,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryColor),
        items: provider.rifas.map((rifa) {
          return DropdownMenuItem<String>(
            value: rifa.id,
            child: Text(
              rifa.nombre.length > 15 ? '${rifa.nombre.substring(0, 12)}...' : rifa.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          );
        }).toList(),
        onChanged: (rifaId) {
          if (rifaId != null) {
            final rifa = provider.rifas.firstWhere((r) => r.id == rifaId);
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
    
    final totalPagado = (stats['totalVendido'] as num?)?.toDouble() ?? 0.0;
    final pendiente = (stats['pendientePago'] as num?)?.toDouble() ?? 0.0;
    final int numerosVendidos = stats['totalVendidos'] as int? ?? 0;
    final int totalNumeros = selectedRifa?.cantidadNumeros ?? 1;
    final double progreso = totalNumeros > 0 ? (numerosVendidos / totalNumeros) : 0.0;
    final double potencialTotal = totalNumeros * (selectedRifa?.precioNumero ?? 0);
    final double totalVendido = totalPagado + pendiente;
    
    return Column(
      children: [
        // Progress Ring Card (Full width)
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progreso,
                      strokeWidth: 8,
                      backgroundColor: AppTheme.dividerColor,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      strokeCap: StrokeCap.round,
                    ),
                    Text(
                      '${(progreso * 100).toInt()}%',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROGRESO DE VENTAS',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatMoney(totalVendido),
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'de ${formatMoney(potencialTotal)}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _buildStatCard(
              'Recaudado',
              formatMoney(totalPagado),
              Icons.payments_rounded,
              LinearGradient(colors: [Colors.green.shade600, Colors.green.shade800]),
            ),
            _buildStatCard(
              'Pendiente',
              formatMoney(pendiente),
              Icons.pending_actions_rounded,
              LinearGradient(colors: [Colors.orange.shade600, Colors.orange.shade800]),
            ),
            _buildStatCard(
              'Potencial',
              formatMoney(potencialTotal),
              Icons.account_balance_wallet_rounded,
              AppTheme.goldGradient,
            ),
            _buildStatCard(
              'Vendidos',
              '${stats['totalVendidos'] ?? 0}',
              Icons.confirmation_number_rounded,
              LinearGradient(colors: [Colors.blue.shade600, Colors.blue.shade800]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Gradient gradient) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (gradient.colors.last).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.outfit(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                  letterSpacing: 1,
                ),
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
    final int totalNumeros = selectedRifa?.cantidadNumeros ?? 1;
    final int vendidos = stats['totalVendidos'] as int? ?? 0;
    final int pagadosCount = stats['numerosPagados'] as int? ?? 0;
    final int reservadosCount = stats['numerosReservados'] as int? ?? 0;
    final int disponiblesCount = totalNumeros - vendidos;
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
                    color: Colors.green.shade600,
                    value: pagadosCount.toDouble(),
                    title: '$pagadosCount',
                    radius: 50,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  PieChartSectionData(
                    color: Colors.orange.shade600,
                    value: reservadosCount.toDouble(),
                    title: '$reservadosCount',
                    radius: 50,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  PieChartSectionData(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    value: disponiblesCount.toDouble(),
                    title: '$disponiblesCount',
                    radius: 40,
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
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
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
            maxY: (stats['totalVendido'] ?? 0) + (stats['pendientePago'] ?? 0),
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
              BarChartGroupData(
                x: 0,
                barRods: [
                  BarChartRodData(
                    toY: (stats['totalVendido'] as num?)?.toDouble() ?? 0.0,
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
                    toY: (stats['pendientePago'] as num?)?.toDouble() ?? 0.0,
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

  Widget _buildTrendChart(RifaProvider provider) {
    if (provider.participantes.isEmpty) {
      return _buildChartContainer(
        title: 'Tendencia de Ventas',
        subtitle: 'Números vendidos en los últimos 7 días',
        child: SizedBox(
          height: 200,
          child: Center(
            child: Text(
              'No hay ventas registradas',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final Map<int, int> salesByDay = {};
    
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      final key = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
      salesByDay[key] = 0;
    }

    for (final p in provider.participantes) {
      final pDate = DateTime(p.fechaRegistro.year, p.fechaRegistro.month, p.fechaRegistro.day);
      final existingKey = salesByDay.keys.firstWhere(
        (k) => DateTime.fromMillisecondsSinceEpoch(k).day == pDate.day &&
               DateTime.fromMillisecondsSinceEpoch(k).month == pDate.month &&
               DateTime.fromMillisecondsSinceEpoch(k).year == pDate.year,
        orElse: () => 0,
      );
      if (existingKey != 0) {
        salesByDay[existingKey] = (salesByDay[existingKey] ?? 0) + p.numeros.length;
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
        child: spots.isEmpty
            ? Center(
                child: Text(
                  'No hay datos de ventas',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              )
            : LineChart(
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
    int numerosPagados = 0;
    int numerosReservados = 0;

    for (final rifa in provider.rifas) {
      final stats = provider.getEstadisticasForRifa(rifa.id, rifa.precioNumero);
      totalVendido += (stats['totalVendido'] as num?)?.toDouble() ?? 0.0;
      pendientePago += (stats['pendientePago'] as num?)?.toDouble() ?? 0.0;
      totalVendidosCount += stats['totalVendidos'] as int? ?? 0;
      totalDisponiblesCount += stats['totalDisponibles'] as int? ?? 0;
      numerosPagados += stats['numerosPagados'] as int? ?? 0;
      numerosReservados += stats['numerosReservados'] as int? ?? 0;
    }
    
    return {
      'totalVendido': totalVendido,
      'pendientePago': pendientePago,
      'totalVendidos': totalVendidosCount,
      'totalDisponibles': totalDisponiblesCount,
      'numerosPagados': numerosPagados,
      'numerosReservados': numerosReservados,
    };
  }

}
