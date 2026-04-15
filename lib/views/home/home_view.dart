import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_colors.dart';
import './ai_service.dart';
import './chat_message.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final TextEditingController _messageController = TextEditingController();
  final AiService _aiService = AiService();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isPremium = true; // default true until prefs loaded
  bool _prefsLoaded = false;

  static const String _premiumPlanId = '69a3df3381a5be4cb1bd8bc3';

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final planId = prefs.getString('workspace_plan_id');
    if (mounted) {
      setState(() {
        _isPremium = planId == _premiumPlanId || planId == null;
        _prefsLoaded = true;
      });
    }
  }

  void _startNewChat() {
    setState(() {
      _messages = [];
    });
    _messageController.clear();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });

    _messageController.clear();

    try {
      final result = await _aiService.sendToPlan(text);

      setState(() {
        _messages.add(
          ChatMessage(
            text: result['message'] ?? "Respuesta generada",
            isUser: false,
            data: result,
          ),
        );
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(text: "Asistente no disponible", isUser: false),
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _confirmTicket(String aiLogId) async {
    // Cerramos el diálogo antes de la llamada
    Navigator.pop(context);

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _aiService.confirmTicket(aiLogId);

      final executionResult = result['execution_result'];
      final ticketId = executionResult?['ticket_id'];

      setState(() {
        _messages.add(
          ChatMessage(
            text: ticketId != null
                ? "Ticket creado exitosamente.\nID: $ticketId"
                : result['message'] ?? "Ticket procesado.",
            isUser: false,
            data: result,
          ),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ticketId != null
                ? "Ticket creado correctamente"
                : "Ticket confirmado",
          ),
          backgroundColor: AppColors.secondaryBase,
        ),
      );
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(text: "Asistente no disponible", isUser: false),
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showConfirmDialog(String aiLogId, Map<String, dynamic> draft) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmar ticket"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              draft['titulo'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(draft['descripcion'] ?? ''),
            const SizedBox(height: 6),
            Text("Prioridad: ${draft['prioridad'] ?? ''}"),
            Text("Categoría: ${draft['categoria'] ?? ''}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryBase,
              foregroundColor: AppColors.primaryOn,
            ),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => _confirmTicket(aiLogId),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryBase,
              foregroundColor: AppColors.primaryOn,
            ),
            child: const Text("Confirmar"),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    return _messages.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return Align(
                alignment: msg.isUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  decoration: BoxDecoration(
                    color: msg.isUser ? AppColors.secondaryBase : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(24),
                      topRight: const Radius.circular(24),
                      bottomLeft: Radius.circular(msg.isUser ? 24 : 6),
                      bottomRight: Radius.circular(msg.isUser ? 6 : 24),
                    ),
                    border: msg.isUser
                        ? null
                        : Border.all(color: Colors.grey.shade100, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _buildMessageContent(msg),
                ),
              );
            },
          );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.secondaryBase.withOpacity(0.15),
                  AppColors.secondaryBase.withOpacity(0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.secondaryBase,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Asistente con IA",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textBase,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Describe tu problema o solicitud\ny te ayudaré a gestionarlo.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage msg) {
    if (msg.data != null) {
      final data = msg.data!;
      final executionResult = data['execution_result'];
      final intent = data['intent'];
      final action = data['action'];

      // Determine if this is a ticket draft or creation flow
      final isTicketFlow = intent == 'create_ticket' || action == 'draft';

      // Extract draft data
      final draft = data['result'] ?? data['draft_preview'];
      final aiLogId = data['ai_log_id'];

      // Extract plan/steps
      final steps = data['steps'] as List? ?? data['plan'] as List?;

      // 1. Ticket ya creado (respuesta del continue o finalización)
      if (executionResult != null && executionResult['ticket_id'] != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  "Ticket Finalizado",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            if (steps != null) ...[
              const SizedBox(height: 12),
              _buildPlanSteps(steps),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "ID de Seguimiento:",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    "${executionResult['ticket_id']}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }

      // 2. Borrador o Plan pendiente de confirmación
      if (isTicketFlow && draft != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: AppColors.secondaryBase,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  intent == 'create_ticket'
                      ? "Plan de Acción"
                      : "Borrador Generado",
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: AppColors.secondaryBase,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            if (steps != null) ...[
              const SizedBox(height: 12),
              _buildPlanSteps(steps),
            ],
            const SizedBox(height: 16),
            Text(
              draft['titulo'] ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textBase,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              draft['descripcion'] ?? '',
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.4,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTag(
                  "Prioridad: ${draft['prioridad'] ?? ''}",
                  Icons.flag_rounded,
                ),
                _buildTag(draft['categoria'] ?? '', Icons.category_rounded),
              ],
            ),
            if (aiLogId != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () => _showConfirmDialog(aiLogId, draft),
                  icon: const Icon(
                    Icons.done_all_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Confirmar e Iniciar",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryBase,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      }
    }

    // Fallback texto plano
    return Text(
      msg.text.isNotEmpty
          ? msg.text
          : (msg.data?['message'] ?? "Sin contenido"),
      style: TextStyle(
        color: msg.isUser ? Colors.white : AppColors.textBase,
        fontSize: 15,
        height: 1.4,
      ),
    );
  }

  Widget _buildPlanSteps(List steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps.map((step) {
        final isCompleted = step['status'] == 'completed';
        final isReady =
            step['status'] == 'ready' ||
            step['status'] == 'requires_confirmation';

        String label = step['tool']?.toString() ?? 'Procesando...';
        if (label == 'draft') label = 'Preparar borrador';
        if (label == 'create_ticket_from_draft')
          label = 'Confirmar y crear ticket';
        if (label == 'create_ticket') label = 'Generar el ticket';

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Icon(
                isCompleted
                    ? Icons.check_circle_rounded
                    : (isReady
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked),
                size: 14,
                color: isCompleted
                    ? Colors.green
                    : (isReady ? AppColors.secondaryBase : Colors.grey),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isCompleted
                        ? Colors.grey.shade700
                        : (isReady ? AppColors.textBase : Colors.grey),
                    fontWeight: isReady ? FontWeight.bold : FontWeight.normal,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.contentBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget containerInputSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: AppColors.menuBackground.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Escribe tu mensaje...',
                filled: true,
                fillColor: Colors.white.withOpacity(0.9),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                hintStyle: TextStyle(
                  color: AppColors.menuBackground.withOpacity(0.6),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: const BorderSide(
                    color: AppColors.secondaryBase,
                    width: 1.8,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.secondaryBase,
            radius: 20,
            child: IconButton(
              icon: const Icon(Icons.send, size: 18),
              color: AppColors.primaryOn,
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────── FREE PLAN UPGRADE SCREEN ───────────────
  Widget _buildFreeUpgradeScreen() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.warningBase.withOpacity(0.15),
                    AppColors.warningBase.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 52,
                color: AppColors.warningBase,
              ),
            ),
            const SizedBox(height: 28),

            // Title
            const Text(
              'Agente de IA',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textBase,
              ),
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              'Esta función está disponible\nexclusivamente en el plan Premium.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Features list
            _buildFeatureItem(
              Icons.smart_toy_outlined,
              'Asistente con IA',
              'Crea tickets y genera planes automáticamente.',
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              Icons.people_alt_outlined,
              'Usuarios ilimitados',
              'Invita a todo tu equipo al workspace.',
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              Icons.inventory_2_outlined,
              'Almacenes ilimitados',
              'Organiza tu inventario sin restricciones.',
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              Icons.confirmation_number_outlined,
              'Tickets ilimitados',
              'Sin límite diario de creación de tickets.',
            ),
            const SizedBox(height: 36),

            // CTA Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openUpgradePage,
                icon: const Icon(Icons.star_rounded, color: Colors.white),
                label: const Text(
                  'Obtener Premium',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warningBase,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Desbloquea todas las funcionalidades y lleva tu negocio al siguiente nivel.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.secondaryBase.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: AppColors.secondaryBase),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textBase,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openUpgradePage() async {
    final upgradeUrl = Uri.parse(
      'http://192.168.0.141:5173/panal-web-application/pricing',
    );
    if (await canLaunchUrl(upgradeUrl)) {
      await launchUrl(upgradeUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_prefsLoaded) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.secondaryBase),
      );
    }

    // FREE plan: show upgrade screen
    if (!_isPremium) {
      return _buildFreeUpgradeScreen();
    }

    // PREMIUM plan: show full AI chat
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              tooltip: "Nueva conversación",
              icon: Icon(Icons.edit_square, color: AppColors.secondaryBase),
              onPressed: _startNewChat,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildMessages()),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(),
              ),
            containerInputSection(context),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
