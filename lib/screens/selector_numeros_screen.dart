import 'dart:io';
import 'dart:async';
import 'dart:convert';
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

enum NumberFilter { all, available, reserved, paid, selected }

class _SelectorNumerosView extends StatefulWidget {
  const _SelectorNumerosView();

  @override
  State<_SelectorNumerosView> createState() => _SelectorNumerosViewState();
}

class _SelectorNumerosViewState extends State<_SelectorNumerosView>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _gridScrollController = ScrollController();
  int _currentPage = 0;
  String _searchQuery = '';
  bool _carouselPaused = false;
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  NumberFilter _activeFilter = NumberFilter.all;
  int _selectedRange = 0;
  List<Map<String, dynamic>> _ranges = [];

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
        _buildRanges(rifa);
      }
    });
  }

  void _buildRanges(Rifa rifa) {
    final total = rifa.cantidadNumeros;
    final is3Cifras = rifa.tipoRifa == '3 cifras';
    if (!is3Cifras || total <= 200) {
      _ranges = [];
      return;
    }
    final rangeSize = 200;
    for (int i = 0; i < total; i += rangeSize) {
      final end = (i + rangeSize - 1).clamp(0, total - 1);
      _ranges.add({
        'start': i,
        'end': end,
        'label': '${i.toString().padLeft(3, '0')}-${end.toString().padLeft(3, '0')}',
      });
    }
    _selectedRange = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    _gridScrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onCarouselInteraction() {
    setState(() => _carouselPaused = true);
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) setState(() => _carouselPaused = false);
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || _carouselPaused) return;
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

  bool _shouldShowNumber({
    required bool isAvailable,
    required bool isReserved,
    required bool isPaid,
    required bool isSelected,
  }) {
    if (_activeFilter == NumberFilter.all) return true;
    switch (_activeFilter) {
      case NumberFilter.available:
        return isAvailable && !isReserved && !isPaid;
      case NumberFilter.reserved:
        return isReserved && !isPaid;
      case NumberFilter.paid:
        return isPaid;
      case NumberFilter.selected:
        return isSelected;
      default:
        return true;
    }
  }

  void _scrollToNumber(String query) {
    final rifa = context.read<RifaProvider>().rifaSeleccionada;
    if (rifa == null || query.isEmpty) return;

    final number = int.tryParse(query);
    if (number == null || number < 0 || number >= rifa.cantidadNumeros) return;

    // Switch to the correct range tab if needed
    if (_ranges.isNotEmpty) {
      int targetRange = _selectedRange;
      for (int i = 0; i < _ranges.length; i++) {
        final start = _ranges[i]['start'] as int;
        final end = _ranges[i]['end'] as int;
        if (number >= start && number <= end) {
          targetRange = i;
          break;
        }
      }

      if (targetRange != _selectedRange) {
        setState(() => _selectedRange = targetRange);
        WidgetsBinding.instance.addPostFrameCallback((_) => _animateToNumber(number));
        return;
      }
    }

    _animateToNumber(number);
  }

  void _animateToNumber(int number) {
    final rifa = context.read<RifaProvider>().rifaSeleccionada;
    if (rifa == null) return;

    final rangeOffset = _ranges.isEmpty ? 0 : (_ranges[_selectedRange]['start'] as int);
    final index = number - rangeOffset;
    if (index < 0) return;

    final crossAxisCount = rifa.tipoRifa == '3 cifras' ? 6 : 10;
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 32.0;
    final cellWidth = (availableWidth - (crossAxisCount - 1) * 6.0) / crossAxisCount;
    final cellHeight = cellWidth / 1.0;
    final rowHeight = cellHeight + 6.0;

    final row = index ~/ crossAxisCount;
    final targetOffset = row * rowHeight;
    final maxScroll = _gridScrollController.position.maxScrollExtent;

    _gridScrollController.animateTo(
      targetOffset.clamp(0.0, maxScroll),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
            icon: const Icon(Icons.grid_view_rounded),
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
          if (rifa.imagenes.isNotEmpty)
            _buildImageCarousel(rifa),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            color: AppTheme.surfaceColor,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoChip(
                      context,
                      Icons.attach_money_rounded,
                      AppConstants.formatCurrencyCOP(rifa.precioNumero),
                      'Precio',
                    ),
                    _buildInfoChip(
                      context,
                      Icons.numbers_rounded,
                      '${rifa.cantidadNumeros}',
                      'Números',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                            setState(() => _searchQuery = value);
                            _scrollToNumber(value);
                          },
                        style: GoogleFonts.outfit(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Buscar número...',
                          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor, size: 16),
                          suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.cancel_rounded, size: 14),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                }
                              )
                            : null,
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildQuickSelectionBar(provider),
                  ],
                ),
                if (_ranges.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 32,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _ranges.length,
                      itemBuilder: (context, index) {
                        final range = _ranges[index];
                        final isSelected = _selectedRange == index;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedRange = index);
                              if (_searchQuery.isNotEmpty) {
                                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNumber(_searchQuery));
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primaryColor : AppTheme.cardColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor),
                              ),
                              child: Text(
                                range['label'] as String,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? AppTheme.backgroundColor : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 4),
              ],
            ),
          ),
          Expanded(
            child: RepaintBoundary(
              child: GridView.builder(
                controller: _gridScrollController,
                padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 10),
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: rifa.tipoRifa == '3 cifras' ? 6 : 10,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 1,
                ),
                itemCount: _ranges.isEmpty
                    ? rifa.cantidadNumeros
                    : (_ranges[_selectedRange]['end'] as int) - (_ranges[_selectedRange]['start'] as int) + 1,
                itemBuilder: (context, index) {
                  final rangeOffset = _ranges.isEmpty ? 0 : (_ranges[_selectedRange]['start'] as int);
                  final numero = (rangeOffset + index).toString().padLeft(
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

                  if (!_shouldShowNumber(
                    isAvailable: isAvailable,
                    isReserved: isReserved,
                    isPaid: isPaid,
                    isSelected: isSelected,
                  )) {
                    return const SizedBox.shrink();
                  }

                  Color backgroundColor;
                  Color textColor;
                  Border? border;

                  if (isSelected) {
                    backgroundColor = AppTheme.numeroSeleccionado;
                    textColor = Colors.white;
                  } else if (isPaid) {
                    backgroundColor = AppTheme.numeroPagado;
                    textColor = AppTheme.numeroPagadoText;
                  } else if (isReserved) {
                    backgroundColor = AppTheme.numeroReservado;
                    textColor = AppTheme.numeroReservadoText;
                  } else {
                    backgroundColor = AppTheme.numeroDisponible;
                    textColor = AppTheme.textPrimary.withValues(alpha: 0.7);
                    border = Border.all(color: AppTheme.numeroDisponibleBorder);
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
          _buildInteractiveLegend(),
          if (provider.numerosSeleccionados.isNotEmpty)
            _buildSelectionBar(provider),
        ],
      ),
    );
  }

  Widget _buildSelectionBar(RifaProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (provider.numerosSeleccionados.length <= 8)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: provider.numerosSeleccionados.map((n) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.numeroSeleccionado.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.numeroSeleccionado.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          n,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.numeroSeleccionado,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => provider.toggleNumeroSeleccion(n),
                          child: const Icon(Icons.cancel_rounded, size: 14, color: AppTheme.numeroSeleccionado),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 12),
            Row(
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
                      const SizedBox(height: 2),
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
                const SizedBox(width: 12),
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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTheme.primaryColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickSelectionBar(RifaProvider provider) {
    final rifa = provider.rifaSeleccionada;
    if (rifa == null) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildQuickBtn('+1', () => _selectRandomNumbers(provider, 1)),
        const SizedBox(width: 6),
        _buildQuickBtn('+5', () => _selectRandomNumbers(provider, 5)),
        const SizedBox(width: 6),
        _buildQuickBtn('+10', () => _selectRandomNumbers(provider, 10)),
      ],
    );
  }

  Widget _buildQuickBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor.withValues(alpha: 0.15), AppTheme.primaryColor.withValues(alpha: 0.05)],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primaryColor),
        ),
      ),
    );
  }

  void _selectRandomNumbers(RifaProvider provider, int count) {
    final rifa = provider.rifaSeleccionada;
    if (rifa == null) return;

    final available = <String>[];
    for (int i = 0; i < rifa.cantidadNumeros; i++) {
      final num = i.toString().padLeft(rifa.tipoRifa == '3 cifras' ? 3 : 2, '0');
      if (provider.isNumeroDisponible(num) && !provider.isNumeroSeleccionado(num)) {
        available.add(num);
      }
    }

    available.shuffle();
    final toSelect = available.take(count).toList();
    for (final num in toSelect) {
      provider.toggleNumeroSeleccion(num);
    }
  }

  Widget _buildInteractiveLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(top: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFilterChip('Todos', NumberFilter.all, AppTheme.textPrimary, border: true),
          _buildFilterChip('Libre', NumberFilter.available, AppTheme.primaryColor, border: true),
          _buildFilterChip('Reservado', NumberFilter.reserved, AppTheme.numeroReservado),
          _buildFilterChip('Pagado', NumberFilter.paid, AppTheme.numeroPagado),
          _buildFilterChip('Selección', NumberFilter.selected, AppTheme.numeroSeleccionado),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, NumberFilter filter, Color color, {bool border = false}) {
    final isActive = _activeFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? color : (border ? AppTheme.dividerColor : Colors.transparent),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            color: isActive ? color : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildImageCarousel(Rifa rifa) {
    return SizedBox(
      height: 140,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: rifa.imagenes.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              _onCarouselInteraction();
            },
            itemBuilder: (context, index) {
              return _buildImageWidget(rifa.imagenes[index]);
            },
          ),
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

    Widget imageWidget;
    if (kIsWeb || path.startsWith('http') || path.startsWith('blob:')) {
      imageWidget = Image.network(
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
      );
    } else if (path.startsWith('data:image/')) {
      final base64 = path.contains('base64,') ? path.split('base64,')[1] : path;
      imageWidget = Image.memory(
        base64Decode(base64),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.white24)),
      );
    } else {
      imageWidget = Image.file(
        File(path),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.white24)),
      );
    }

    return Container(color: Colors.black, child: imageWidget);
  }
}

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
            ] : widget.isPaid ? [
              BoxShadow(
                color: AppTheme.numeroPagado.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 1),
              )
            ] : null,
          ),
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                widget.numero,
                style: GoogleFonts.outfit(
                  color: widget.textColor,
                  fontWeight: widget.isSelected || widget.isPaid || widget.isReserved
                      ? FontWeight.w900
                      : FontWeight.w600,
                  fontSize: widget.tipoRifa == '3 cifras' ? 14 : 16,
                ),
              ),
              if (widget.isPaid && !widget.isSelected)
                Positioned(
                  top: 2,
                  right: 3,
                  child: Icon(Icons.check_rounded, color: Colors.white.withValues(alpha: 0.8), size: 10),
                ),
              if (widget.isReserved && !widget.isSelected && !widget.isPaid)
                Positioned(
                  top: 2,
                  right: 3,
                  child: Icon(Icons.schedule_rounded, color: AppTheme.backgroundColor.withValues(alpha: 0.7), size: 10),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
