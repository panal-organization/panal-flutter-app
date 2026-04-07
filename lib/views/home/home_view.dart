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

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });

    _messageController.clear();

    try {
      final result = await _aiService.generatePlan(text);

      print("RESULT COMPLETO:");
      print(result);

      final draft = result['draft_preview'];
      final summary = result['summary_preview'];

      setState(() {
        _messages.add(ChatMessage(
          text: (draft != null || summary != null)
              ? ""
              : result['message'] ?? "Respuesta generada",
          isUser: false,
          data: result,
        ));
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "Error: $e",
          isUser: false,
        ));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildMessages() {
    return ListView.builder(
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

  Widget _buildMessageContent(ChatMessage msg) {
    if (msg.data != null) {
      final data = msg.data!;

      // Manejo de draft
      if (data['draft_preview'] != null) {
        final draft = data['draft_preview'];

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
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                _confirmTicket(data);
              },
              child: const Text("Confirmar ticket"),
            ),
          ],
        );
      }

      // Manejo de summary
      if (data['summary_preview'] != null) {
        final summary = data['summary_preview'];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Agente de IA",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(summary['resumen'] ?? ''),
          ],
        );
      }
    }

    // Fallback
    return Text(
      msg.text.isNotEmpty ? msg.text : "Sin contenido",
      style: TextStyle(
        color: msg.isUser ? Colors.white : Colors.black,
      ),
    );
  }

  void _confirmTicket(Map data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmar ticket"),
        content: const Text("¿Deseas crear este ticket?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);

              final aiLogId = data['ai_log_id'];
              print("Crear ticket con ai_log_id: $aiLogId");

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Ticket confirmado")),
              );
            },
            child: const Text("Confirmar"),
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
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
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