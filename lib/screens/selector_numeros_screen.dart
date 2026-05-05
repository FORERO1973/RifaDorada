import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/rifa_provider.dart';
import '../models/rifa.dart';
import 'registro_participante_screen.dart';
import 'imagen_estado_screen.dart';

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

class _SelectorNumerosViewState extends State<_SelectorNumerosView>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  String _searchQuery = '';
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
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
    _pulseController.dispose();
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
            child: RepaintBoundary(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: rifa.tipoRifa == '3 cifras' ? 6 : 10,
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

                  if (isSelected) {
                    backgroundColor = AppTheme.numeroSeleccionado;
                    textColor = Colors.white;
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

                  return RepaintBoundary(
                    child: _NumeroTile(
                      numero: numero,
                      backgroundColor: backgroundColor,
                      textColor: textColor,
                      border: border,
                      isSelected: isSelected,
                      isPaid: isPaid,
                      isReserved: isReserved,
                      isAvailable: isAvailable,
                      tipoRifa: rifa.tipoRifa,
                      onTap: isAvailable || isSelected
                          ? () => provider.toggleNumeroSeleccion(numero)
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
          _buildLegend(),
          if (provider.numerosSeleccionados.isNotEmpty)
            _buildSelectionBar(provider),
        ],
      ),
    );
  }

  Widget _buildSelectionBar(RifaProvider provider) {
    return Container(
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
            ScaleTransition(
              scale: _pulseAnimation,
              child: ElevatedButton(
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
                child: const Row(
                  children: [
                    Text('CONTINUAR'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
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
    if (path.isEmpty) return const Center(child: Icon(Icons.image_not_supported));

    return Container(
      color: Colors.black,
      child: kIsWeb || path.startsWith('http') || path.startsWith('blob:')
          ? Image.network(
              path,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Error loading image: $error');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.broken_image, color: Colors.white24, size: 40),
                      const SizedBox(height: 8),
                      const Text(
                        'Error al cargar imagen',
                        style: TextStyle(color: Colors.white24, fontSize: 10),
                      ),
                    ],
                  ),
                );
              },
            )
          : Image.file(
              File(path),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.white24)),
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

/// Individual number tile with animated selection
class _NumeroTile extends StatefulWidget {
  final String numero;
  final Color backgroundColor;
  final Color textColor;
  final Border? border;
  final bool isSelected;
  final bool isPaid;
  final bool isReserved;
  final bool isAvailable;
  final String tipoRifa;
  final VoidCallback? onTap;

  const _NumeroTile({
    required this.numero,
    required this.backgroundColor,
    required this.textColor,
    this.border,
    required this.isSelected,
    required this.isPaid,
    required this.isReserved,
    required this.isAvailable,
    required this.tipoRifa,
    this.onTap,
  });

  @override
  State<_NumeroTile> createState() => _NumeroTileState();
}

class _NumeroTileState extends State<_NumeroTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: widget.border,
            boxShadow: widget.isSelected ? [
              BoxShadow(
                color: AppTheme.numeroSeleccionado.withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ] : null,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.numero,
            style: GoogleFonts.outfit(
              color: widget.textColor,
              fontWeight: widget.isSelected || widget.isPaid || widget.isReserved
                  ? FontWeight.w900
                  : FontWeight.w600,
              fontSize: widget.tipoRifa == '3 cifras' ? 14 : 16,
            ),
          ),
        ),
      ),
    );
  }
}
