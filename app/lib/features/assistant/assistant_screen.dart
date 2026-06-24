import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../../core/i18n/strings.dart';
import 'assistant_message.dart';
import 'assistant_repository.dart';

/// Chat avec l'assistant Claude en ligne (Sprint 11, étage 2 IA). Sous
/// l'habilitation `ai.assistant.use`. Si le cloud n'est pas provisionné
/// (`ASSISTANT_API_URL`/`ASSISTANT_API_KEY` absents), affiche un message
/// explicite au lieu de planter.
class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key, required this.tenantId});
  final String tenantId;

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _controller = TextEditingController();
  final _history = <AssistantMessage>[];
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _history.add(AssistantMessage(role: 'user', content: text));
      _controller.clear();
      _sending = true;
      _error = null;
    });
    try {
      final reply = await ref
          .read(assistantRepositoryProvider)
          .sendMessage(history: _history, tenantId: widget.tenantId);
      setState(() {
        _history.add(AssistantMessage(role: 'assistant', content: reply));
      });
    } on AssistantNotConfiguredException {
      setState(() {
        _error = Strings.of(context).assistantNotConfigured;
      });
    } catch (e) {
      setState(() => _error = Strings.of(context).errorWith(e));
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.assistantTitle)),
      body: Column(
        children: [
          if (!Env.isAssistantConfigured)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.errorContainer,
              padding: const EdgeInsets.all(12),
              child: Text(
                s.assistantNotConfiguredBanner,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _history.length,
              itemBuilder: (context, i) {
                final m = _history[i];
                final isUser = m.role == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(m.content),
                  ),
                );
              },
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: s.askAQuestionHint,
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    onPressed: _sending ? null : _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
