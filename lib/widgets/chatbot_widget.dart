import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';

class ChatBotWidget extends StatefulWidget {
  final String chatbotUrl;
  final String? rifaContactNumber;

  const ChatBotWidget({
    super.key,
    required this.chatbotUrl,
    this.rifaContactNumber,
  });

  @override
  State<ChatBotWidget> createState() => _ChatBotWidgetState();
}

class _ChatBotWidgetState extends State<ChatBotWidget>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  final List<ChatMessage> _messages = [];
  final _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );
    _addBotMessage(
      '¡Hola! 👋 Soy el asistente de RifaDorada. ¿En qué puedo ayudarte?',
    );
    _addQuickReplies([
      '¿Cómo participo?',
      'Ver rifas activas',
      'Necesito ayuda',
    ]);
  }

  @override
  void dispose() {
    _fabController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: false));
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
    });
    _scrollToBottom();
  }

  void _addQuickReplies(List<String> options) {
    setState(() {
      _messages.add(ChatMessage(quickReplies: options, isUser: false));
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _addUserMessage(text);
    setState(() => _isTyping = true);

    try {
      final response = await _getBotResponse(text);

      setState(() => _isTyping = false);
      _addBotMessage(response);

      if (text.toLowerCase().contains('rif') || text.toLowerCase().contains('activ')) {
        _addQuickReplies(['¿Cómo me registro?', 'Necesito ayuda']);
      } else if (text.toLowerCase().contains('ayuda') || text.toLowerCase().contains('contact')) {
        _addQuickReplies(['Ver rifas activas', '¿Cómo participo?']);
      } else if (text.toLowerCase().contains('particip') || text.toLowerCase().contains('registro')) {
        _addQuickReplies(['Ver rifas activas', 'Necesito ayuda']);
      }
    } catch (e) {
      setState(() => _isTyping = false);
      _addBotMessage(
        'Lo siento, hubo un error de conexión. Puedes contactarnos directamente por WhatsApp.',
      );
    }
  }

  Future<String> _getBotResponse(String userMessage) async {
    final msg = userMessage.toLowerCase();

    if (msg.contains('cómo particip') || msg.contains('como particip')) {
      return '🎯 *Para participar:*\n\n1️⃣ Selecciona una rifa disponible\n2️⃣ Elige tus números de la suerte\n3️⃣ Completa tus datos\n4️⃣ Recibe tu ticket por WhatsApp\n\n¡Es muy fácil! ¿Quieres ver las rifas activas?';
    }

    if (msg.contains('rif') || msg.contains('activ')) {
      return '🎫 Tenemos rifas activas en este momento. Desplázate hacia arriba para verlas y selecciona la que más te guste. ¡No te quedes sin participar!';
    }

    if (msg.contains('ayuda') || msg.contains('contact')) {
      final number = widget.rifaContactNumber ?? '573001234567';
      return '📞 *Estamos para ayudarte:*\n\n💬 Escríbenos directo a WhatsApp:\nhttps://wa.me/$number\n\nHorario: Lunes a Domingo, 8am - 8pm';
    }

    if (msg.contains('precio') || msg.contains('valor') || msg.contains('cuesta')) {
      return '💰 El precio varía según la rifa. Cada rifa muestra el valor por número en su tarjeta. ¡Hay opciones para todos los presupuestos!';
    }

    if (msg.contains('pago') || msg.contains('pagar') || msg.contains('abon')) {
      return '💳 *Métodos de pago:*\n\n• Transferencia bancaria\n• Nequi\n• Daviplata\n• Efectivo\n\nDespués de registrarte, envía tu comprobante por WhatsApp para confirmar tu participación.';
    }

    return 'Gracias por tu mensaje. 😊 Puedo ayudarte con:\n\n• Cómo participar\n• Rifas disponibles\n• Métodos de pago\n• Contactar soporte\n\n¿Qué necesitas saber?';
  }

  void _openWhatsApp() {
    final number = widget.rifaContactNumber ?? '573001234567';
    final url = 'https://wa.me/$number?text=${Uri.encodeComponent('Hola, necesito ayuda con RifaDorada')}';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Stack(
      children: [
        Positioned(
          bottom: isMobile ? 90 : 100,
          right: 16,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            offset: _isOpen ? Offset.zero : const Offset(0, 0.15),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              opacity: _isOpen ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !_isOpen,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: isMobile ? width - 32 : 380,
                  height: isMobile ? 450 : 520,
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildChatHeader(),
                      const Divider(height: 1, color: AppTheme.dividerColor),
                      Expanded(child: _buildMessagesList()),
                      if (_isTyping) _buildTypingIndicator(),
                      _buildInputArea(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          right: 16,
          child: GestureDetector(
            onTap: () => setState(() => _isOpen = !_isOpen),
            child: AnimatedBuilder(
              animation: _fabAnimation,
              builder: (context, child) {
                return Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF25D366),
                        const Color(0xFF128C7E),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF25D366).withValues(alpha: 0.4 + (_fabAnimation.value * 0.2)),
                        blurRadius: 20 + (_fabAnimation.value * 10),
                        spreadRadius: 2 + (_fabAnimation.value * 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isOpen ? Icons.close_rounded : Icons.chat_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF25D366).withValues(alpha: 0.15),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF25D366), Color(0xFF128C7E)],
              ),
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asistente RifaDorada',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF25D366),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'En línea',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: const Color(0xFF25D366),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            color: AppTheme.textSecondary,
            tooltip: 'Abrir en WhatsApp',
            onPressed: _openWhatsApp,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return _buildMessageBubble(msg);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;

    if (msg.quickReplies != null && msg.quickReplies!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: msg.quickReplies!.map((reply) {
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _sendMessage(reply),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.4),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    reply,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? AppTheme.primaryColor.withValues(alpha: 0.15)
              : AppTheme.surfaceColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          msg.text!,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: isUser ? AppTheme.primaryColor : AppTheme.textPrimary,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 400 + (i * 200)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Container(
                      margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppTheme.textSecondary.withValues(alpha: value),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                hintStyle: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppTheme.textSecondary.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: AppTheme.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                isDense: true,
              ),
              onSubmitted: (_) {
                _sendMessage(_textController.text);
                _textController.clear();
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF25D366), Color(0xFF128C7E)],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: () {
                if (_textController.text.trim().isNotEmpty) {
                  _sendMessage(_textController.text);
                  _textController.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String? text;
  final List<String>? quickReplies;
  final bool isUser;

  ChatMessage({this.text, this.quickReplies, required this.isUser});
}
