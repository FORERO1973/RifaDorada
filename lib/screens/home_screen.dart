import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/rifa_provider.dart';
import '../widgets/rifa_card.dart';
import '../models/rifa.dart';
import '../models/participante.dart';
import 'crear_rifa_screen.dart';
import 'ticket_screen.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RifaProvider>().loadRifas();
    });
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
                    _buildHeader(),
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
          Text(
            'RifaDorada',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              shadows: [
                Shadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            textAlign: TextAlign.center,
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
                      MaterialPageRoute(
                        builder: (_) => const SelectorNumerosScreen(),
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


class SelectorNumerosScreen extends StatelessWidget {
  const SelectorNumerosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SelectorNumerosView();
  }
}

class _SelectorNumerosView extends StatefulWidget {
  const _SelectorNumerosView();

  @override
  State<_SelectorNumerosView> createState() => _SelectorNumerosViewState();
}

class _SelectorNumerosViewState extends State<_SelectorNumerosView> {
  final PageController _pageController = PageController();
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  String _searchQuery = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RifaProvider>();
      final rifa = provider.rifaSeleccionada;
      if (rifa != null) {
        provider.loadNumeros(rifa.id);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final provider = context.read<RifaProvider>();
        final imagesCount = provider.rifaSeleccionada?.imagenes.length ?? 0;
        if (imagesCount > 1) {
          _currentPage = (_currentPage + 1) % imagesCount;
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOutQuart,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RifaProvider>();
    final rifa = provider.rifaSeleccionada;

    if (rifa == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Seleccionar Números')),
        body: const Center(child: Text('No hay rifa seleccionada')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(rifa.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ImagenEstadoScreen()),
            ),
            tooltip: 'Ver Estado',
          ),
        ],
      ),
      body: Column(
        children: [
          if (rifa.fechaSorteo != null)
            _buildCountdown(rifa),
          if (rifa.imagenes.isNotEmpty)
            _buildImageCarousel(rifa),
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.surfaceColor,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoChip(
                      context,
                      Icons.attach_money,
                      AppConstants.formatCurrencyCOP(rifa.precioNumero),
                      'Por número',
                    ),
                    _buildInfoChip(
                      context,
                      Icons.tag,
                      '${rifa.cantidadNumeros}',
                      'Total números',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  keyboardType: TextInputType.number,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: GoogleFonts.outfit(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Buscar número...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                    suffixIcon: _searchQuery.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear), 
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          }
                        )
                      : null,
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: rifa.tipoRifa == '3 cifras' ? 6 : 8,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 1,
              ),
              itemCount: rifa.cantidadNumeros,
              itemBuilder: (context, index) {
                final numero = index.toString().padLeft(
                  rifa.tipoRifa == '3 cifras' ? 3 : 2,
                  '0',
                );

                if (_searchQuery.isNotEmpty && !numero.contains(_searchQuery)) {
                  return const SizedBox.shrink();
                }

                final isSelected = provider.isNumeroSeleccionado(numero);
                final isAvailable = provider.isNumeroDisponible(numero);
                final numObj = provider.numeros[numero];
                final isReserved = numObj?.estaReservado ?? false;
                final isPaid = numObj?.estaPagado ?? false;

                Color backgroundColor;
                Color textColor;
                Border? border;
                List<BoxShadow>? shadows;

                if (isSelected) {
                  backgroundColor = AppTheme.numeroSeleccionado;
                  textColor = Colors.white;
                  shadows = [
                    BoxShadow(
                      color: AppTheme.numeroSeleccionado.withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ];
                } else if (isPaid) {
                  backgroundColor = AppTheme.numeroPagado;
                  textColor = Colors.white;
                } else if (isReserved) {
                  backgroundColor = AppTheme.numeroReservado;
                  textColor = AppTheme.backgroundColor;
                } else {
                  backgroundColor = AppTheme.surfaceColor;
                  textColor = AppTheme.textPrimary.withValues(alpha: 0.7);
                  border = Border.all(color: AppTheme.dividerColor);
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: InkWell(
                    onTap: isAvailable || isSelected
                        ? () => provider.toggleNumeroSeleccion(numero)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: border,
                        boxShadow: shadows,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        numero,
                        style: GoogleFonts.outfit(
                          color: textColor,
                          fontWeight: isSelected || isPaid || isReserved ? FontWeight.w900 : FontWeight.w600,
                          fontSize: rifa.tipoRifa == '3 cifras' ? 14 : 16,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _buildLegend(),
          if (provider.numerosSeleccionados.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                border: Border.all(color: AppTheme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${provider.cantidadNumerosSeleccionados} SELECCIONADO(S)',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppConstants.formatCurrencyCOP(provider.totalSeleccion),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegistroParticipanteScreen(),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('CONTINUAR'),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

        ],
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(top: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildLegendItem('Libre', AppTheme.surfaceColor, border: true),
          _buildLegendItem('Reservado', AppTheme.numeroReservado),
          _buildLegendItem('Pagado', AppTheme.numeroPagado),
          _buildLegendItem('Tu Selección', AppTheme.numeroSeleccionado),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, {bool border = false}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: border ? Border.all(color: AppTheme.dividerColor) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildImageCarousel(Rifa rifa) {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: rifa.imagenes.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return _buildImageWidget(rifa.imagenes[index]);
            },
          ),
          // Gradiente inferior para legibilidad
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                ),
              ),
            ),
          ),
          // Flechas de navegación
          if (rifa.imagenes.length > 1) ...[
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 32),
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 32),
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),
          ],
          // Indicadores de página
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                rifa.imagenes.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == index ? AppTheme.primaryColor : Colors.white24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(String path) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo difuminado para llenar el espacio
          if (kIsWeb || path.startsWith('http') || path.startsWith('blob:'))
            Image.network(path, fit: BoxFit.cover, opacity: const AlwaysStoppedAnimation(0.3))
          else
            Image.file(File(path), fit: BoxFit.cover, opacity: const AlwaysStoppedAnimation(0.3)),
          
          // Imagen principal contenida para que se vea completa
          if (kIsWeb || path.startsWith('http') || path.startsWith('blob:'))
            Image.network(
              path,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.white24)),
            )
          else
            Image.file(
              File(path),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.white24)),
            ),
        ],
      ),
    );
  }

  Widget _buildCountdown(Rifa rifa) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final now = DateTime.now();
        final diff = rifa.fechaSorteo!.difference(now);

        if (diff.isNegative) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: AppTheme.errorColor.withValues(alpha: 0.1),
            child: const Text(
              'EL SORTEO YA SE REALIZÓ',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.errorColor),
            ),
          );
        }

        final days = diff.inDays;
        final hours = diff.inHours % 24;
        final minutes = diff.inMinutes % 60;
        final seconds = diff.inSeconds % 60;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border(bottom: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_outlined, color: AppTheme.primaryColor, size: 16),
              const SizedBox(width: 8),
              _buildTimePart(days, 'D'),
              _buildTimeDivider(),
              _buildTimePart(hours, 'H'),
              _buildTimeDivider(),
              _buildTimePart(minutes, 'M'),
              _buildTimeDivider(),
              _buildTimePart(seconds, 'S'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimePart(int value, String label) {
    return Row(
      children: [
        Text(
          value.toString().padLeft(2, '0'),
          style: GoogleFonts.outfit(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTimeDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text(':', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)),
    );
  }
}

class RegistroParticipanteScreen extends StatefulWidget {
  const RegistroParticipanteScreen({super.key});

  @override
  State<RegistroParticipanteScreen> createState() =>
      _RegistroParticipanteScreenState();
}

class _RegistroParticipanteScreenState
    extends State<RegistroParticipanteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _documentoController = TextEditingController();
  String _ciudadSeleccionada = AppConstants.ciudadesColombia.first;
  bool _isPickingContact = false;

  Future<void> _pickContact() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La búsqueda de contactos no está disponible en la web')),
      );
      return;
    }

    try {
      final permission = await Permission.contacts.request();
      if (permission.isGranted) {
        setState(() => _isPickingContact = true);
        final contact = await FlutterContacts.openExternalPick();
        setState(() => _isPickingContact = false);

        if (contact != null) {
          // Obtener detalles completos del contacto seleccionado
          final fullContact = await FlutterContacts.getContact(contact.id);
          if (fullContact != null) {
            setState(() {
              _nombreController.text = fullContact.displayName;
              if (fullContact.phones.isNotEmpty) {
                // Limpiar el número de espacios y caracteres especiales
                String phone = fullContact.phones.first.number
                    .replaceAll(RegExp(r'\s+'), '')
                    .replaceAll(RegExp(r'[^\d+]'), '');
                
                // Si el número empieza por +57, quitarlo o ajustarlo según necesidad
                if (phone.startsWith('+57')) {
                  phone = phone.substring(3);
                } else if (phone.startsWith('57') && phone.length > 10) {
                  phone = phone.substring(2);
                }
                
                _whatsappController.text = phone;
              }
            });
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permiso de contactos denegado')),
          );
        }
      }
    } catch (e) {
      setState(() => _isPickingContact = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al acceder a contactos: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _whatsappController.dispose();
    _documentoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RifaProvider>();
    final rifa = provider.rifaSeleccionada;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Participante')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSelectionSummary(provider),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _isPickingContact ? null : _pickContact,
              icon: _isPickingContact 
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.contact_phone_rounded),
              label: const Text('BUSCAR EN MIS CONTACTOS'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppTheme.primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _nombreController,
              label: 'Nombre Completo',
              icon: Icons.person,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese su nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _whatsappController,
              label: 'WhatsApp',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese su número de WhatsApp';
                }
                if (value.length < 10) {
                  return 'Ingrese un número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _ciudadSeleccionada,
              decoration: InputDecoration(
                labelText: 'Ciudad',
                prefixIcon: const Icon(Icons.location_city),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: AppConstants.ciudadesColombia.map((ciudad) {
                return DropdownMenuItem(value: ciudad, child: Text(ciudad));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _ciudadSeleccionada = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _documentoController,
              label: 'Documento (opcional)',
              icon: Icons.badge,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            _buildTotalSection(provider, rifa!),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: provider.isLoading ? null : _submitForm,
              child: provider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirmar Registro'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionSummary(RifaProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NÚMEROS SELECCIONADOS',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: provider.numerosSeleccionados.map((val) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  val,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.backgroundColor,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
      ),
      validator: validator,
    );
  }

  Widget _buildTotalSection(RifaProvider provider, rifa) {
    return Container(
      padding: const EdgeInsets.all(28),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL A PAGAR',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: AppTheme.backgroundColor.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppConstants.formatCurrencyCOP(provider.totalSeleccion),
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.backgroundColor,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.payments_rounded,
              color: AppTheme.primaryColor,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<RifaProvider>();
    final rifa = provider.rifaSeleccionada;
    final numerosSeleccionados = provider.numerosSeleccionados.toList();
    final totalSeleccion = provider.totalSeleccion;

    try {
      final id = await provider.registrarParticipante(
        nombre: _nombreController.text.trim(),
        whatsapp: _whatsappController.text.trim(),
        ciudad: _ciudadSeleccionada,
        documento: _documentoController.text.trim().isEmpty
            ? null
            : _documentoController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Registro exitoso!'),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );

        final message = AppConstants.generateWhatsAppMessage(
          nombre: _nombreController.text.trim(),
          numeros: numerosSeleccionados,
          total: totalSeleccion,
          nombreRifa: rifa?.nombre ?? '',
        );
        final participante = Participante(
          id: id,
          rifaId: rifa?.id ?? '',
          nombre: _nombreController.text.trim(),
          whatsapp: _whatsappController.text.trim(),
          ciudad: _ciudadSeleccionada,
          documento: _documentoController.text.trim().isEmpty ? null : _documentoController.text.trim(),
          numeros: numerosSeleccionados,
          estadoPago: EstadoPago.pendiente,
          fechaRegistro: DateTime.now(),
          totalPagado: 0,
        );

        _showWhatsAppDialog(message, _whatsappController.text.trim(), participante, rifa!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showWhatsAppDialog(String message, String whatsapp, Participante participante, Rifa rifa) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registro Completado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Desea enviar la confirmación por WhatsApp?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(message, style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TicketScreen(participante: participante, rifa: rifa),
                ),
              );
            },
            child: const Text('VER TICKET'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Más tarde'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final phone = AppConstants.formatPhoneNumber(whatsapp);
              final url = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.send),
            label: const Text('Enviar'),
          ),
        ],
      ),
    );
  }
}

class ImagenEstadoScreen extends StatelessWidget {
  const ImagenEstadoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RifaProvider>();
    final rifa = provider.rifaSeleccionada;

    if (rifa == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Estado de Números')),
        body: const Center(child: Text('No hay rifa seleccionada')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estado de Números'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Compartiendo...')));
            },
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    rifa.nombre,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem('Disponible', AppTheme.numeroDisponible),
                      const SizedBox(width: 8),
                      _buildLegendItem('Reservado', AppTheme.numeroReservado),
                      const SizedBox(width: 8),
                      _buildLegendItem('Pagado', AppTheme.numeroPagado),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: rifa.tipoRifa == '3 cifras' ? 8 : 10,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: rifa.cantidadNumeros,
                itemBuilder: (context, index) {
                  final numero = index.toString().padLeft(
                    rifa.tipoRifa == '3 cifras' ? 3 : 2,
                    '0',
                  );

                  final numObj = provider.numeros[numero];
                  final isReserved = numObj?.estaReservado ?? false;
                  final isPaid = numObj?.estaPagado ?? false;

                  return Container(
                    decoration: BoxDecoration(
                      color: isPaid
                          ? AppTheme.numeroPagado
                          : (isReserved ? AppTheme.numeroReservado : AppTheme.numeroDisponible),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      numero,
                      style: TextStyle(
                        fontSize: rifa.tipoRifa == '3 cifras' ? 8 : 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
