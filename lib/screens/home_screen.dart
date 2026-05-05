import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/rifa_provider.dart';
import '../widgets/rifa_card.dart';
import '../models/rifa.dart';
import 'crear_rifa_screen.dart';
import 'selector_numeros_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _headerAnimController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _headerFade = CurvedAnimation(
      parent: _headerAnimController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RifaProvider>().loadRifas();
      _headerAnimController.forward();
    });
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RifaProvider>();
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SlideTransition(
                      position: _headerSlide,
                      child: FadeTransition(
                        opacity: _headerFade,
                        child: _buildHeader(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildWinnersSection(context, provider),
                    const SizedBox(height: 24),
                    _buildQuickStats(),
                    const SizedBox(height: 24),
                    _buildActiveRifasTitle(),
                  ],
                ),
              ),
            ),
            _buildRifasList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Glowing aura
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
              // Logo Image
              Image.asset(
                'assets/logo/logo.png',
                height: 150,
                fit: BoxFit.contain,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppTheme.accentGold, AppTheme.primaryColor, AppTheme.primaryDark],
            ).createShader(bounds),
            child: Text(
              'RifaDorada',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'BIENVENIDO AL PANEL PRINCIPAL',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              letterSpacing: 2,
              fontWeight: FontWeight.w800,
              color: AppTheme.textSecondary.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWinnersSection(BuildContext context, RifaProvider provider) {
    final rifasConGanador = provider.rifas.where((r) => r.numeroGanador != null).toList();

    if (rifasConGanador.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'ÚLTIMOS GANADORES',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: rifasConGanador.length,
            itemBuilder: (context, index) {
              final rifa = rifasConGanador[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(19),
                          bottomLeft: Radius.circular(19),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.military_tech_rounded, color: AppTheme.primaryColor, size: 24),
                          const SizedBox(height: 4),
                          Text(
                            rifa.numeroGanador!,
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              rifa.nombre,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Lotería: ${rifa.loteria ?? "N/A"}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd/MM/yyyy').format(rifa.fechaSorteo ?? rifa.fechaCreacion),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Consumer<RifaProvider>(
      builder: (context, provider, child) {
        final rifasActivas = provider.rifas.where((r) => r.activa).length;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: AppTheme.goldGradient,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Icon(
                  Icons.diamond_rounded,
                  size: 150,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RESUMEN GENERAL',
                    style: GoogleFonts.outfit(
                      color: AppTheme.backgroundColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 2,
                    ),
                  ),
                  const Icon(
                    Icons.auto_graph_rounded,
                    color: AppTheme.backgroundColor,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.confirmation_number_rounded,
                      value: '$rifasActivas',
                      label: 'Rifas Activas',
                    ),
                  ),
                  Container(
                    width: 1.5,
                    height: 50,
                    color: AppTheme.backgroundColor.withValues(alpha: 0.1),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.group_rounded,
                      value: '${provider.rifas.fold(0, (sum, r) => sum + r.cantidadNumeros)}',
                      label: 'Cupos Totales',
                    ),
                  ),
                ],
              ),
            ],
          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            color: AppTheme.backgroundColor,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: AppTheme.backgroundColor.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }


  Widget _buildActiveRifasTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Rifas Disponibles',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        TextButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CrearRifaScreen()),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Nueva'),
        ),
      ],
    );
  }

  Widget _buildRifasList() {
    return Consumer<RifaProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          );
        }

        if (provider.rifas.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.celebration,
                    size: 80,
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay rifas disponibles',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea una nueva rifa para comenzar',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CrearRifaScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Crear Rifa'),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final rifa = provider.rifas[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: RifaCard(
                  rifa: rifa,
                  onEdit: provider.isAdmin ? () => _showEditDialog(context, rifa, provider) : null,
                  onDelete: provider.isAdmin ? () => _confirmDeleteRifa(context, rifa, provider) : null,
                  onTap: () {
                    provider.setRifaSeleccionada(rifa);
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const SelectorNumerosScreen(),
                        transitionsBuilder: (_, animation, __, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.05, 0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              )),
                              child: child,
                            ),
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 350),
                      ),
                    );
                  },
                ),

              );
            }, childCount: provider.rifas.length),
          ),
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
