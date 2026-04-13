import 'package:flutter/material.dart';
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
      final result = await _aiService.sendToAgent(text);

      setState(() {
        _messages.add(ChatMessage(
          text: result['message'] ?? "Respuesta generada",
          isUser: false,
          data: result,
        ));
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: "Error: $e", isUser: false));
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

      final ticketId = result['execution_result']?['ticket_id'];
      final status = result['execution_result']?['status'];

      setState(() {
        _messages.add(ChatMessage(
          text: status == 'ticket_created'
              ? "Ticket creado exitosamente.\nID: $ticketId"
              : result['message'] ?? "Ticket procesado.",
          isUser: false,
          data: result,
        ));
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ticketId != null
                ? "Ticket creado: $ticketId"
                : "Ticket confirmado",
          ),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: "Error al confirmar: $e", isUser: false));
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
            Text(draft['titulo'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
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
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return Align(
                alignment:
                    msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: msg.isUser
                        ? AppColors.secondaryBase
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chat_bubble_outline,
                color: Colors.blue.shade400, size: 22),
          ),
          const SizedBox(height: 12),
          const Text(
            "Asistente de tickets",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            "Describe tu problema o solicitud\ny te ayudaré a gestionarlo.",
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage msg) {
    if (msg.data != null) {
      final data = msg.data!;
      final action = data['action'];
      final executionResult = data['execution_result'];

      // Ticket ya creado (respuesta del continue)
      if (executionResult != null &&
          executionResult['status'] == 'ticket_created') {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.blue.shade600, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                "Ticket creado\nID: ${executionResult['ticket_id']}",
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      }

      // Borrador pendiente de confirmación (respuesta del agent)
      if (action == 'draft' && data['result'] != null) {
        final draft = data['result'] as Map<String, dynamic>;
        final aiLogId = data['ai_log_id'] as String;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              draft['titulo'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(draft['descripcion'] ?? ''),
            const SizedBox(height: 4),
            Text("Prioridad: ${draft['prioridad'] ?? ''}"),
            Text("Categoría: ${draft['categoria'] ?? ''}"),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => _showConfirmDialog(aiLogId, draft),
              icon: const Icon(Icons.check, size: 16),
              label: const Text("Confirmar ticket"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryBase,
                foregroundColor: AppColors.primaryOn,
              ),
            ),
          ],
        );
      }
    }

    // Fallback texto plano
    return Text(
      msg.text.isNotEmpty ? msg.text : "Sin contenido",
      style: TextStyle(color: msg.isUser ? Colors.white : Colors.black),
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
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Escribe tu mensaje...',
                filled: true,
                fillColor: Colors.white.withOpacity(0.9),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                hintStyle: TextStyle(
                  color: AppColors.menuBackground.withOpacity(0.6),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.secondaryBase,
            radius: 24,
            child: IconButton(
              icon: const Icon(Icons.send, size: 20),
              color: AppColors.primaryOn,
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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