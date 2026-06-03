import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../models/rifa.dart';
import '../widgets/chatbot_widget.dart';
import '../widgets/hero_section.dart';
import '../widgets/how_it_works.dart';
import '../widgets/trust_section.dart';
import '../widgets/footer_section.dart';
import '../widgets/premium_raffle_card.dart';
import '../widgets/registration_stepper.dart';
import '../widgets/ticket_image_generator.dart';

class LandingScreen extends StatefulWidget {
  final String? rifaId;

  const LandingScreen({super.key, this.rifaId});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  List<Rifa> _rifas = [];
  Map<String, List<Map<String, dynamic>>> _participantNumbers = {};
  bool _isLoading = true;
  Rifa? _selectedRifa;
  Set<String> _selectedNumbers = {};
  final _nombreController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _documentoController = TextEditingController();
  String _ciudadSeleccionada = AppConstants.ciudadesColombia.first;
  String _citySearchQuery = '';
  bool _isSubmitting = false;
  String? _successMessage;
  String? _errorMessage;
  String _chatbotUrl = '';
  Timer? _refreshTimer;
  int _activeRangeStart = 0;
  int _currentStep = 0;
  static const _rangeSize = 100;
  String _whatsappNumber = '573001234567';

  // Scroll & navigation
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _raffleGridKey = GlobalKey();
  bool _showBackToTop = false;
  double _scrollOffset = 0;

  // Success animation
  late AnimationController _successAnimController;
  late Animation<double> _successScaleAnim;

  @override
  void initState() {
    super.initState();
    _loadRifas();
    _loadChatbotUrl();
    _scrollController.addListener(_onScroll);
    _successAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _successScaleAnim = CurvedAnimation(
      parent: _successAnimController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _whatsappController.dispose();
    _documentoController.dispose();
    _refreshTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _successAnimController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final shouldShow = offset > 400;
    if (shouldShow != _showBackToTop) {
      setState(() {
        _showBackToTop = shouldShow;
        _scrollOffset = offset;
      });
    } else if ((_scrollOffset - offset).abs() > 50) {
      setState(() => _scrollOffset = offset);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollToRaffles() {
    final ctx = _raffleGridKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _loadChatbotUrl() async {
    _chatbotUrl = 'https://rifadorada-bot.onrender.com';
    debugPrint('[LANDING] Chatbot URL: $_chatbotUrl');
  }

  Future<void> _loadRifas() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('rifas')
          .where('activa', isEqualTo: true)
          .get();

      final rifas = snapshot.docs.map((doc) {
        final data = doc.data();
        return Rifa(
          id: doc.id,
          nombre: data['nombre'] ?? '',
          descripcion: data['descripcion'] ?? '',
          precioNumero: (data['precioNumero'] ?? 0).toDouble(),
          cantidadNumeros: (data['cantidadNumeros'] ?? 0).toInt(),
          tipoRifa: data['tipoRifa'] == '3 cifras' ? '3 cifras' : '2 cifras',
          fechaCreacion: data['fechaCreacion'] != null
              ? DateTime.parse(data['fechaCreacion'])
              : DateTime.now(),
          fechaSorteo: data['fechaSorteo'] != null
              ? DateTime.parse(data['fechaSorteo'])
              : null,
          loteria: data['loteria'],
          diaSorteo: data['diaSorteo'],
          organizacionId: data['organizacionId'],
          imagenes: List<String>.from(data['imagenes'] ?? []),
          organizacion: data['organizacion'],
          responsable: data['responsable'],
          contactoResponsable: data['contactoResponsable'],
        );
      }).toList();

      final partMap = <String, List<Map<String, dynamic>>>{};
      for (final rifa in rifas) {
        final partSnapshot = await FirebaseFirestore.instance
            .collection('participantes')
            .where('rifaId', isEqualTo: rifa.id)
            .get();

        final entries = <Map<String, dynamic>>[];
        for (final doc in partSnapshot.docs) {
          final data = doc.data();
          final nums = data['numeros'] as List?;
          final estado = data['estadoPago'] as String? ?? 'pendiente';
          if (nums != null) {
            for (final n in nums) {
              entries.add({'numero': n.toString(), 'estado': estado});
            }
          }
        }
        partMap[rifa.id] = entries;
      }

      String configWhatsapp = '573001234567';
      try {
        final configDoc = await FirebaseFirestore.instance
            .collection('config')
            .doc('app')
            .get();
        if (configDoc.exists && configDoc.data()?['telefono'] != null) {
          final tel = configDoc.data()?['telefono'] as String;
          if (tel.trim().isNotEmpty) {
            configWhatsapp = tel.trim().replaceAll(RegExp(r'[^\d]'), '');
          }
        } else if (rifas.isNotEmpty) {
          final orgId = rifas.first.organizacionId;
          if (orgId != null && orgId.isNotEmpty) {
            final orgDoc = await FirebaseFirestore.instance
                .collection('organizaciones')
                .doc(orgId)
                .get();
            if (orgDoc.exists && orgDoc.data()?['telefono'] != null) {
              final tel = orgDoc.data()?['telefono'] as String;
              if (tel.trim().isNotEmpty) {
                configWhatsapp = tel.trim().replaceAll(RegExp(r'[^\d]'), '');
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[LANDING] Error loading config whatsapp: $e');
      }

      setState(() {
        _rifas = rifas;
        _participantNumbers = partMap;
        _whatsappNumber = configWhatsapp;
        _isLoading = false;
      });

      if (widget.rifaId != null && rifas.isNotEmpty) {
        final rifa = rifas.firstWhere(
          (r) => r.id == widget.rifaId,
          orElse: () => rifas.first,
        );
        _selectRifa(rifa);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error cargando rifas: $e';
      });
    }
  }

  void _selectRifa(Rifa rifa) {
    setState(() {
      _selectedRifa = rifa;
      _selectedNumbers = {};
      _activeRangeStart = 0;
      _currentStep = 0;
      _successMessage = null;
      _errorMessage = null;
    });
    _startAutoRefresh();
    _scrollToRaffle();
  }

  void _scrollToRaffle() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _scrollController.animateTo(
          400,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_selectedRifa != null && mounted) {
        _refreshRaffleData(_selectedRifa!);
      }
    });
  }

  Future<void> _refreshRaffleData(Rifa rifa) async {
    try {
      final partSnapshot = await FirebaseFirestore.instance
          .collection('participantes')
          .where('rifaId', isEqualTo: rifa.id)
          .get();

      final entries = <Map<String, dynamic>>[];
      for (final doc in partSnapshot.docs) {
        final data = doc.data();
        final nums = data['numeros'] as List?;
        final estado = data['estadoPago'] as String? ?? 'pendiente';
        if (nums != null) {
          for (final n in nums) {
            entries.add({'numero': n.toString(), 'estado': estado});
          }
        }
      }

      if (mounted) {
        setState(() {
          _participantNumbers[rifa.id] = entries;
        });
      }
    } catch (_) {}
  }

  void _toggleNumber(String number) {
    setState(() {
      if (_selectedNumbers.contains(number)) {
        _selectedNumbers.remove(number);
      } else {
        _selectedNumbers.add(number);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedNumbers = {};
    });
  }

  void _selectQuick(int count) {
    final rifa = _selectedRifa;
    if (rifa == null) return;

    final ocupados = _getOccupiedNumbers(rifa.id);
    final disponibles = <String>[];

    for (int i = 0; i < rifa.cantidadNumeros; i++) {
      final num = i.toString().padLeft(rifa.tipoRifa == '3 cifras' ? 3 : 2, '0');
      if (!ocupados.containsKey(num) && !_selectedNumbers.contains(num)) {
        disponibles.add(num);
      }
    }

    final toAdd = disponibles.take(count).toSet();
    setState(() {
      _selectedNumbers.addAll(toAdd);
    });
  }

  Map<String, String> _getOccupiedNumbers(String rifaId) {
    final entries = _participantNumbers[rifaId] ?? [];
    final map = <String, String>{};
    for (final e in entries) {
      map[e['numero'] as String] = e['estado'] as String;
    }
    return map;
  }

  int get _total {
    final rifa = _selectedRifa;
    if (rifa == null) return 0;
    return (_selectedNumbers.length * rifa.precioNumero).toInt();
  }

  Future<void> _submitRegistration() async {
    if (_selectedRifa == null || _selectedNumbers.isEmpty) return;
    if (_nombreController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Ingresa tu nombre completo');
      return;
    }

    final whatsapp = _whatsappController.text.trim().replaceAll(RegExp(r'[^\d]'), '');
    if (whatsapp.length < 10) {
      setState(() => _errorMessage = 'Ingresa un número de WhatsApp válido');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    String? participantId;

    try {
      final docRef = await FirebaseFirestore.instance.collection('participantes').add({
        'rifaId': _selectedRifa!.id,
        'organizacionId': _selectedRifa!.organizacionId,
        'nombre': _nombreController.text.trim(),
        'whatsapp': whatsapp,
        'ciudad': _ciudadSeleccionada,
        'documento': _documentoController.text.trim().isEmpty
            ? null
            : _documentoController.text.trim(),
        'numeros': _selectedNumbers.toList()..sort(),
        'estadoPago': 'pendiente',
        'totalPagado': 0,
        'fechaRegistro': FieldValue.serverTimestamp(),
        'abonos': [],
      });

      participantId = docRef.id;

      if (_chatbotUrl.isNotEmpty) {
        try {
          final fechaStr = _selectedRifa!.fechaSorteo != null
              ? '${_selectedRifa!.fechaSorteo!.day}/${_selectedRifa!.fechaSorteo!.month}/${_selectedRifa!.fechaSorteo!.year}'
              : null;

          final sent = await TicketImageGenerator.sendTicketImage(
            chatbotUrl: _chatbotUrl,
            whatsapp: whatsapp,
            rifaNombre: _selectedRifa!.nombre,
            numeros: _selectedNumbers.toList()..sort(),
            participanteNombre: _nombreController.text.trim(),
            ciudad: _ciudadSeleccionada,
            precioNumero: _selectedRifa!.precioNumero,
            loteria: _selectedRifa!.loteria,
            fechaSorteo: fechaStr,
            participanteId: participantId,
          );

          if (!sent) {
            debugPrint('[LANDING] Fallback: enviando ticket simple');
            await _sendTextTicket(whatsapp);
          }
        } catch (e) {
          debugPrint('[LANDING] Error enviando ticket: $e');
          await _sendTextTicket(whatsapp);
        }
      }

      final newEntries = _selectedNumbers
          .map((n) => {'numero': n, 'estado': 'pendiente'})
          .toList();
      final existing = _participantNumbers[_selectedRifa!.id] ?? [];
      existing.addAll(newEntries);
      _participantNumbers[_selectedRifa!.id] = existing;

      setState(() {
        _isSubmitting = false;
        _successMessage =
            '¡Registro exitoso! Tu ticket ha sido enviado por WhatsApp.';
        _selectedNumbers = {};
        _nombreController.clear();
        _whatsappController.clear();
        _documentoController.clear();
        _currentStep = 0;
      });
      _successAnimController.forward(from: 0);
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Error al registrar: $e';
      });
    }
  }

  Future<void> _sendTextTicket(String whatsapp) async {
    try {
      final cleanUrl = _chatbotUrl.endsWith('/')
          ? _chatbotUrl.substring(0, _chatbotUrl.length - 1)
          : _chatbotUrl;

      await http.post(
        Uri.parse('$cleanUrl/v1/send/ticket'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'whatsapp': whatsapp,
          'rifaId': _selectedRifa!.id,
          'organizacionId': _selectedRifa!.organizacionId,
        }),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  void _goToNextStep() {
    if (_currentStep == 0 && _selectedNumbers.isEmpty) {
      setState(() => _errorMessage = 'Selecciona al menos un número');
      return;
    }
    if (_currentStep == 1) {
      if (_nombreController.text.trim().isEmpty) {
        setState(() => _errorMessage = 'Ingresa tu nombre completo');
        return;
      }
      final whatsapp = _whatsappController.text.trim().replaceAll(RegExp(r'[^\d]'), '');
      if (whatsapp.length < 10) {
        setState(() => _errorMessage = 'Ingresa un número de WhatsApp válido');
        return;
      }
    }
    setState(() {
      _errorMessage = null;
      if (_currentStep < 2) {
        _currentStep++;
      } else {
        _submitRegistration();
      }
    });
  }

  void _goToPreviousStep() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
        _errorMessage = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1000;
    final isTablet = width > 600 && width <= 1000;

    // Get WhatsApp number from selected rifa or fallback
    final whatsappNumber = _selectedRifa?.contactoResponsable ?? _whatsappNumber;

    return Scaffold(
      body: Container(
        color: AppTheme.backgroundColor,
        child: SafeArea(
          child: _isLoading
              ? _buildLoadingState(isDesktop, isTablet)
              : Stack(
                  children: [
                    CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        // Glassmorphism scroll-aware header
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _GlassHeaderDelegate(
                            scrollOffset: _scrollOffset,
                            selectedRifa: _selectedRifa,
                            onLogoTap: () {
                              setState(() {
                                _selectedRifa = null;
                                _currentStep = 0;
                              });
                              _scrollToTop();
                            },
                            onBackTap: () => setState(() {
                              _selectedRifa = null;
                              _currentStep = 0;
                            }),
                            onAdminTap: () => Navigator.pushNamed(context, '/app'),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: HeroSection(
                            activeRafflesCount: _rifas.length,
                            onViewRaffles: () {
                              if (_selectedRifa != null) {
                                setState(() => _selectedRifa = null);
                              }
                              _scrollToRaffles();
                            },
                          ),
                        ),
                        if (_errorMessage != null)
                          SliverToBoxAdapter(child: _buildErrorBanner()),
                        if (_successMessage != null)
                          SliverToBoxAdapter(child: _buildSuccessBanner()),
                        if (_selectedRifa == null)
                          SliverToBoxAdapter(
                            child: KeyedSubtree(
                              key: _raffleGridKey,
                              child: _buildRaffleGrid(isDesktop, isTablet),
                            ),
                          )
                        else
                          SliverToBoxAdapter(
                            child: _buildRegistrationFlow(isDesktop, isTablet),
                          ),
                        const SliverToBoxAdapter(child: TrustSection()),
                        const SliverToBoxAdapter(child: HowItWorks()),
                        SliverToBoxAdapter(
                          child: FooterSection(
                            onGoToAdmin: () => Navigator.pushNamed(context, '/app'),
                            whatsappNumber: whatsappNumber,
                            onScrollToTop: _scrollToTop,
                            onScrollToRaffles: _scrollToRaffles,
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 40)),
                      ],
                    ),
                    // Back to top button
                    Positioned(
                      bottom: 24,
                      left: 16,
                      child: AnimatedOpacity(
                        opacity: _showBackToTop ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: AnimatedSlide(
                          offset: _showBackToTop ? Offset.zero : const Offset(0, 1),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          child: IgnorePointer(
                            ignoring: !_showBackToTop,
                            child: GestureDetector(
                              onTap: _scrollToTop,
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.cardColor.withValues(alpha: 0.9),
                                  border: Border.all(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.keyboard_arrow_up_rounded,
                                  color: AppTheme.primaryColor,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    ChatBotWidget(
                      chatbotUrl: _chatbotUrl,
                      rifaContactNumber: whatsappNumber,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDesktop, bool isTablet) {
    final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 80 : (isTablet ? 40 : 24),
          vertical: 40,
        ),
        child: Column(
          children: [
            // Shimmer hero
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
              ),
            ).animate().shimmer(
              duration: 1.5.seconds,
              color: AppTheme.primaryColor.withValues(alpha: 0.06),
            ),
            const SizedBox(height: 32),
            // Shimmer raffle cards
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 0.8,
              ),
              itemCount: crossAxisCount * 2,
              itemBuilder: (_, __) => const RaffleCardSkeleton(),
            ),
          ],
        ),
      ),
    );
  }

  // Header is now handled by _GlassHeaderDelegate via SliverPersistentHeader

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_rounded, color: Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: () => setState(() => _errorMessage = null),
          ),
        ],
      ),
    )
        .animate()
        .slideX(begin: -0.2, end: 0, duration: 300.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildSuccessBanner() {
    return ScaleTransition(
      scale: _successScaleAnim,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.withValues(alpha: 0.12),
              AppTheme.cardColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.green.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withValues(alpha: 0.15),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.green,
                size: 36,
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  duration: 500.ms,
                  delay: 200.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: 16),
            Text(
              '¡Registro Exitoso!',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.green,
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 300.ms)
                .slideY(begin: 0.3, end: 0),
            const SizedBox(height: 8),
            Text(
              _successMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 400.ms),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _successMessage = null;
                      _selectedRifa = null;
                      _currentStep = 0;
                    });
                    _scrollToTop();
                  },
                  icon: const Icon(Icons.celebration_rounded, size: 18),
                  label: const Text('VER MÁS RIFAS'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppTheme.textSecondary,
                  onPressed: () => setState(() => _successMessage = null),
                ),
              ],
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 500.ms)
                .slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildRaffleGrid(bool isDesktop, bool isTablet) {
    if (_rifas.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.style_outlined,
              size: 64,
              color: AppTheme.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay rifas activas',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vuelve pronto para participar',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : (isTablet ? 40 : 24),
        vertical: 40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rifas Disponibles',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.2, end: 0),
          const SizedBox(height: 6),
          Text(
            'Selecciona una rifa para participar',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms)
              .slideY(begin: 0.2, end: 0),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 0.8,
            ),
            itemCount: _rifas.length,
            itemBuilder: (context, index) {
              final rifa = _rifas[index];
              final entries = _participantNumbers[rifa.id] ?? [];
              return PremiumRaffleCard(
                rifa: rifa,
                vendidos: entries.length,
                total: rifa.cantidadNumeros,
                onTap: () => _selectRifa(rifa),
                animationDelay: index * 100,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationFlow(bool isDesktop, bool isTablet) {
    final rifa = _selectedRifa!;

    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(80, 40, 80, 40),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _buildStepperContent(rifa),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 2,
              child: _buildRegistrationForm(rifa),
            ),
          ],
        ),
      );
    }

    if (isTablet) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(40, 30, 40, 30),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildStepperContent(rifa),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: _buildRegistrationForm(rifa),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        children: [
          _buildStepperContent(rifa),
          const SizedBox(height: 16),
          _buildRegistrationForm(rifa),
        ],
      ),
    );
  }

  Widget _buildStepperContent(Rifa rifa) {
    return RegistrationStepper(
      currentStep: _currentStep,
      totalSteps: 3,
      stepLabels: const ['Números', 'Datos', 'Confirmar'],
      onNext: _goToNextStep,
      onPrevious: _goToPreviousStep,
      isLastStep: _currentStep == 2,
      isLoading: _isSubmitting,
      child: _buildStepContent(rifa),
    );
  }

  Widget _buildStepContent(Rifa rifa) {
    switch (_currentStep) {
      case 0:
        return _buildNumberSelector(rifa);
      case 1:
        return _buildStepData();
      case 2:
        return _buildStepConfirmation(rifa);
      default:
        return _buildNumberSelector(rifa);
    }
  }

  Widget _buildStepData() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Datos Personales',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Completa tu información para recibir el ticket',
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _nombreController,
          label: 'Nombre Completo',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 10),
        _buildInputField(
          controller: _whatsappController,
          label: 'WhatsApp',
          icon: Icons.phone_android_rounded,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 10),
        _buildCitySelector(),
        const SizedBox(height: 10),
        _buildInputField(
          controller: _documentoController,
          label: 'Documento (opcional)',
          icon: Icons.badge_outlined,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildStepConfirmation(Rifa rifa) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirmar Registro',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildConfirmRow('Rifa', rifa.nombre),
              const SizedBox(height: 8),
              _buildConfirmRow('Números', (_selectedNumbers.toList()..sort()).join(', ')),
              const SizedBox(height: 8),
              _buildConfirmRow('Cantidad', '${_selectedNumbers.length} número(s)'),
              const SizedBox(height: 8),
              _buildConfirmRow('Nombre', _nombreController.text.trim()),
              const SizedBox(height: 8),
              _buildConfirmRow('WhatsApp', _whatsappController.text.trim()),
              const SizedBox(height: 8),
              _buildConfirmRow('Ciudad', _ciudadSeleccionada),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOTAL A PAGAR',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    AppConstants.formatCurrencyCOP(_total.toDouble()),
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Al registrarte, recibirás tu ticket por WhatsApp. Deberás realizar el pago para confirmar tu participación.',
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmRow(String label, dynamic value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value is List ? value.join(', ') : value.toString(),
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberSelector(Rifa rifa) {
    final ocupados = _getOccupiedNumbers(rifa.id);
    final reservados =
        ocupados.entries.where((e) => e.value == 'pendiente').length;
    final pagados =
        ocupados.entries.where((e) => e.value == 'pagado').length;
    final abonados =
        ocupados.entries.where((e) => e.value == 'abonado').length;
    final totalOcupados = ocupados.length;
    final disponibles = rifa.cantidadNumeros - totalOcupados;

    final is3Digits = rifa.tipoRifa == '3 cifras';
    final totalRanges = (rifa.cantidadNumeros / _rangeSize).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                rifa.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            if (_selectedNumbers.isNotEmpty)
              TextButton.icon(
                onPressed: _clearSelection,
                icon: const Icon(Icons.clear_all_rounded, size: 16),
                label: const Text('Limpiar'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${_selectedNumbers.length} sel.',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Precio: ${AppConstants.formatCurrencyCOP(rifa.precioNumero)} c/u',
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildQuickButton('+1', 1),
            _buildQuickButton('+5', 5),
            _buildQuickButton('+10', 10),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            _buildLegendDot(Colors.orange, 'Reservado ($reservados)'),
            _buildLegendDot(const Color(0xFF0052CC), 'Pagado ($pagados)'),
            if (abonados > 0)
              _buildLegendDot(Colors.blue, 'Abonado ($abonados)'),
            _buildLegendDot(AppTheme.primaryColor, 'Libre ($disponibles)'),
          ],
        ),
        if (is3Digits && totalRanges > 1) ...[
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 6),
          _buildRangeTabs(rifa, totalRanges),
        ],
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),
        _buildNumberGridView(rifa, ocupados),
      ],
    );
  }

  Widget _buildRangeTabs(Rifa rifa, int totalRanges) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(totalRanges, (index) {
        final start = index * _rangeSize;
        final end = (start + _rangeSize - 1).clamp(0, rifa.cantidadNumeros - 1);
        final startStr = start.toString().padLeft(rifa.tipoRifa == '3 cifras' ? 3 : 2, '0');
        final endStr = end.toString().padLeft(rifa.tipoRifa == '3 cifras' ? 3 : 2, '0');
        final isActive = _activeRangeStart == start;

        return ChoiceChip(
          label: Text(
            '$startStr–$endStr',
            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          selected: isActive,
          onSelected: (_) => setState(() => _activeRangeStart = start),
          selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary,
          ),
        );
      }),
    );
  }

  Widget _buildNumberGridView(Rifa rifa, Map<String, String> ocupados) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1000;
    final isTablet = width > 600 && width <= 1000;

    final crossAxisCount = isDesktop ? 20 : (isTablet ? 15 : 10);
    final cellWidth = isDesktop ? 44.0 : (isTablet ? 40.0 : 36.0);
    final cellHeight = isDesktop ? 38.0 : (isTablet ? 34.0 : 32.0);
    final fontSize = isDesktop ? 13.0 : (isTablet ? 12.0 : 11.0);

    final start = _activeRangeStart;
    final end = (start + _rangeSize).clamp(0, rifa.cantidadNumeros);

    return SizedBox(
      height: ((end - start) / crossAxisCount).ceil() * (cellHeight + 4) + 20,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: cellWidth / cellHeight,
        ),
        itemCount: end - start,
        itemBuilder: (context, index) {
          final numVal = start + index;
          final num = numVal.toString().padLeft(rifa.tipoRifa == '3 cifras' ? 3 : 2, '0');
          final isSelected = _selectedNumbers.contains(num);
          final isOccupied = ocupados.containsKey(num);

          Color bgColor;
          Color textColor;
          Color borderColor;
          double borderWidth = 1;

          if (isSelected) {
            bgColor = AppTheme.primaryColor;
            textColor = AppTheme.backgroundColor;
            borderColor = AppTheme.primaryColor;
            borderWidth = 2;
          } else if (isOccupied) {
            final estado = ocupados[num]!;
            if (estado == 'pagado') {
              bgColor = const Color(0xFF0052CC);
              textColor = Colors.white;
              borderColor = const Color(0xFF0052CC);
            } else if (estado == 'abonado') {
              bgColor = Colors.blue.withValues(alpha: 0.6);
              textColor = Colors.white;
              borderColor = Colors.blue;
            } else {
              bgColor = Colors.orange.withValues(alpha: 0.3);
              textColor = AppTheme.textPrimary;
              borderColor = Colors.orange;
            }
          } else {
            bgColor = AppTheme.surfaceColor;
            textColor = AppTheme.textPrimary;
            borderColor = AppTheme.dividerColor;
          }

          return GestureDetector(
            onTap: !isOccupied ? () => _toggleNumber(num) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: borderColor, width: borderWidth),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Text(
                num,
                style: GoogleFonts.outfit(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickButton(String label, int count) {
    return OutlinedButton(
      onPressed: () => _selectQuick(count),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildRegistrationForm(Rifa rifa) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryItem(
            icon: Icons.style_rounded,
            label: 'Rifa',
            value: rifa.nombre,
          ),
          const SizedBox(height: 8),
          _buildSummaryItem(
            icon: Icons.pin_rounded,
            label: 'Números',
            value: _selectedNumbers.isEmpty
                ? 'Sin seleccionar'
                : (_selectedNumbers.toList()..sort()).join(', '),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: AppTheme.goldGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.backgroundColor.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      AppConstants.formatCurrencyCOP(_total.toDouble()),
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.backgroundColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.payments_rounded,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Después de registrarte, realiza el pago y envía el comprobante por WhatsApp.',
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(fontSize: 11),
        prefixIcon: Icon(icon, size: 16),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
    );
  }

  Widget _buildCitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ciudad',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _showCityPickerModal(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_city_rounded,
                    color: AppTheme.primaryColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _ciudadSeleccionada,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down_rounded,
                    color: AppTheme.primaryColor, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCityPickerModal() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final filtered = AppConstants.ciudadesColombia.where((c) {
            if (_citySearchQuery.isEmpty) return true;
            return c.toLowerCase().contains(_citySearchQuery.toLowerCase());
          }).toList();

          return AlertDialog(
            backgroundColor: AppTheme.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Selecciona tu ciudad',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    onChanged: (v) => setModalState(() => _citySearchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Buscar ciudad...',
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppTheme.primaryColor),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final city = filtered[i];
                        final isSelected = city == _ciudadSeleccionada;
                        return ListTile(
                          leading: Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.location_on_outlined,
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.textSecondary,
                          ),
                          title: Text(
                            city,
                            style: GoogleFonts.outfit(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          onTap: () {
                            setState(() => _ciudadSeleccionada = city);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.outfit(color: AppTheme.textSecondary),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GlassHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double scrollOffset;
  final Rifa? selectedRifa;
  final VoidCallback onLogoTap;
  final VoidCallback onBackTap;
  final VoidCallback onAdminTap;

  _GlassHeaderDelegate({
    required this.scrollOffset,
    required this.selectedRifa,
    required this.onLogoTap,
    required this.onBackTap,
    required this.onAdminTap,
  });

  @override
  double get minExtent => 70.0;

  @override
  double get maxExtent => 70.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final opacity = (scrollOffset / 150).clamp(0.0, 1.0);
    
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: opacity * 10,
          sigmaY: opacity * 10,
        ),
        child: Container(
          height: 70.0,
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor.withValues(
              alpha: 0.35 + (opacity * 0.5),
            ),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.primaryColor.withValues(
                  alpha: opacity * 0.12,
                ),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              selectedRifa != null
                  ? InkWell(
                      onTap: onBackTap,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.arrow_back_rounded,
                              color: AppTheme.primaryColor,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'VOLVER',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryColor,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : InkWell(
                      onTap: onLogoTap,
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: AppTheme.goldGradient,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.confirmation_number_rounded,
                              color: AppTheme.backgroundColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'RifaDorada',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
              
              InkWell(
                onTap: onAdminTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: AppTheme.primaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'ADMIN',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _GlassHeaderDelegate oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.selectedRifa != selectedRifa;
  }
}
