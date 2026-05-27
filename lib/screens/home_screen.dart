import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/rifa_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/rifa_card.dart';
import '../widgets/edit_rifa_dialog.dart';
import '../widgets/shimmer_loading.dart';
import '../models/rifa.dart';
import 'crear_rifa_screen.dart';
import 'selector_numeros_screen.dart';
import 'imagen_estado_screen.dart';
import 'sales_list_screen.dart';
import 'configuracion_screen.dart';
import 'stats_screen.dart';
import '../services/firebase_service.dart';
import '../services/report_service.dart';

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
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<RifaProvider>().loadRifas(),
          color: AppTheme.primaryColor,
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
                          child: _buildHeader(auth),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildWinnersSection(context, provider),
                      const SizedBox(height: 24),
                      _buildQuickStats(),
                      const SizedBox(height: 24),
                      _buildQuickActions(context, provider),
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
      ),
    );
  }

  Widget _buildHeader(AuthProvider auth) {
    final user = auth.currentUser;
    final hour = DateTime.now().hour;
    final saludo = hour < 12 ? 'Buenos días' : hour < 18 ? 'Buenas tardes' : 'Buenas noches';
    final userName = user?.nombre.isNotEmpty == true ? user!.nombre : 'Administrador';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.goldGradient,
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.surfaceColor,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$saludo,',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    userName,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset('assets/logo/logo.png', fit: BoxFit.cover),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'RIFADORADA',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildWinnersSection(BuildContext context, RifaProvider provider) {
    final rifasConGanador = provider.rifas.where((r) => r.numeroGanador != null).toList();

    if (rifasConGanador.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.emoji_events_rounded, color: AppTheme.primaryColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Aún no hay ganadores!',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Los ganadores aparecerán aquí cuando se establezcan',
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
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'ÚLTIMOS GANADORES',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: rifasConGanador.length,
            itemBuilder: (context, index) {
              final rifa = rifasConGanador[index];
              return Container(
                width: 260,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.surfaceColor,
                      AppTheme.primaryColor.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(17),
                          bottomLeft: Radius.circular(17),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.military_tech_rounded, color: AppTheme.primaryColor, size: 22),
                          const SizedBox(height: 4),
                          Text(
                            rifa.numeroGanador!,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              rifa.nombre,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Lotería: ${rifa.loteria ?? "N/A"}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                            ),
                            if (rifa.fechaSorteo != null)
                              Text(
                                DateFormat('dd/MM/yyyy').format(rifa.fechaSorteo!),
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
        final totalRifas = provider.rifas.length;
        final rifasActivas = provider.rifas.where((r) => r.activa).length;
        final totalCupos = provider.rifas.fold<int>(0, (sum, r) => sum + r.cantidadNumeros);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RESUMEN GENERAL',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.15),
                    AppTheme.primaryColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildStatItemMini('Rifas', '$totalRifas', Icons.confirmation_number_rounded, AppTheme.secondaryColor)),
                  _buildStatDivider(),
                  Expanded(child: _buildStatItemMini('Activas', '$rifasActivas', Icons.style_rounded, AppTheme.primaryColor)),
                  _buildStatDivider(),
                  Expanded(child: _buildStatItemMini('Cupos', '$totalCupos', Icons.grid_view_rounded, Colors.blue)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItemMini(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: AppTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 50,
      color: AppTheme.primaryColor.withValues(alpha: 0.15),
    );
  }

  Widget _buildQuickActions(BuildContext context, RifaProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACCIONES RÁPIDAS',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.1,
          children: [
            _buildQuickActionCard(
              icon: Icons.add_circle_outline_rounded,
              label: 'Nueva Rifa',
              color: AppTheme.primaryColor,
              onTap: () => Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const CrearRifaScreen(),
                  transitionsBuilder: (_, animation, __, child) => SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  transitionDuration: const Duration(milliseconds: 350),
                ),
              ),
            ),
            _buildQuickActionCard(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Ver Estado',
              color: Colors.blue,
              onTap: () {
                if (provider.rifas.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Primero crea una rifa'), backgroundColor: Colors.orange),
                  );
                } else {
                  _showRifaSelectionSheet((rifa) async {
                    provider.setRifaSeleccionada(rifa);
                    await provider.loadNumeros(rifa.id);
                    if (context.mounted) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ImagenEstadoScreen()));
                    }
                  });
                }
              },
            ),
            _buildQuickActionCard(
              icon: Icons.people_alt_rounded,
              label: 'Ventas',
              color: Colors.teal,
              onTap: () {
                if (provider.rifas.isNotEmpty) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SalesListScreen(rifa: provider.rifas.first)));
                }
              },
            ),
            _buildQuickActionCard(
              icon: Icons.download_for_offline_rounded,
              label: 'Exportar',
              color: Colors.purple,
              onTap: () {
                if (provider.rifas.isEmpty) return;
                if (provider.rifas.length == 1) {
                  _showExportFormatDialog(context, provider.rifas.first, provider);
                } else {
                  _showRifaSelectionSheet((rifa) {
                    _showExportFormatDialog(context, rifa, provider);
                  });
                }
              },
            ),
            _buildQuickActionCard(
              icon: Icons.smart_toy_rounded,
              label: 'WhatsApp',
              color: Colors.green,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ConfiguracionScreen()));
              },
            ),
            _buildQuickActionCard(
              icon: Icons.bar_chart_rounded,
              label: 'Stats',
              color: Colors.orange,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen()));
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRifaSelectionSheet(void Function(Rifa rifa) onSelected) {
    final rifas = context.read<RifaProvider>().rifas;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Selecciona una rifa', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            ...rifas.map((r) => ListTile(
                  leading: Icon(Icons.confirmation_number_rounded, color: AppTheme.primaryColor),
                  title: Text(r.nombre, style: GoogleFonts.outfit(color: AppTheme.textPrimary)),
                  subtitle: Text('\$${NumberFormat('#,###', 'es_CO').format(r.precioNumero)}/num', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  onTap: () {
                    final selected = r;
                    Navigator.pop(ctx);
                    Future.microtask(() => onSelected(selected));
                  },
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _showExportFormatDialog(BuildContext ctx, Rifa rifa, RifaProvider provider) async {
    final result = await showDialog<String>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppTheme.cardColor,
        title: const Text('Exportar Reporte'),
        content: const Text('Selecciona el formato:'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(dialogCtx, 'csv'),
            icon: const Icon(Icons.table_chart_rounded, size: 18),
            label: const Text('CSV'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(dialogCtx, 'pdf'),
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

    if (result == null || ctx.mounted == false) return;

    if (result == 'csv') {
      provider.exportarDatosCSV(rifaId: rifa.id, nombreRifa: rifa.nombre);
    } else {
      try {
        final auth = ctx.read<AuthProvider>();
        final config = await FirebaseService.instance.getAppConfig(organizacionId: auth.organizacionId);
        final participantes = await FirebaseService.instance.getParticipantesOnce(rifa.id);
        final numerosMap = await FirebaseService.instance.getNumeros(rifa.id);
        final numerosEstado = numerosMap.map((k, v) => MapEntry(k, v.estado.name));
        if (participantes.isEmpty) {
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('No hay participantes para exportar'), backgroundColor: Colors.orange),
            );
          }
          return;
        }
        await ReportService.instance.generatePdfReport(
          rifa: rifa,
          participantes: participantes,
          organizacion: config?.organizacion,
          numerosEstado: numerosEstado,
        );
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text('PDF exportado: ${rifa.nombre}')),
          );
        }
      } catch (e) {
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text('Error al exportar PDF: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
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
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const CrearRifaScreen(),
              transitionsBuilder: (_, animation, __, child) => SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: FadeTransition(opacity: animation, child: child),
              ),
              transitionDuration: const Duration(milliseconds: 350),
            ),
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
          return const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            sliver: ShimmerLoading(itemCount: 3, itemHeight: 140),
          );
        }

        if (provider.error != null) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off_rounded, size: 64, color: AppTheme.errorColor.withValues(alpha: 0.6)),
                  const SizedBox(height: 16),
                  Text('Error al cargar', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(provider.error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.read<RifaProvider>().loadRifas(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
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
