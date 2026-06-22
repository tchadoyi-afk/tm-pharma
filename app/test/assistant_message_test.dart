import 'package:flutter_test/flutter_test.dart';
import 'package:tm_pharma/features/assistant/assistant_message.dart';

void main() {
  test('builds the request body with tenant and full history', () {
    final body = buildAssistantRequestBody(
      history: const [
        AssistantMessage(role: 'user', content: 'Bonjour'),
        AssistantMessage(role: 'assistant', content: 'Bonjour, comment puis-je aider ?'),
      ],
      tenantId: 'tenant-1',
    );

    expect(body['tenant_id'], 'tenant-1');
    expect(body['messages'], [
      {'role': 'user', 'content': 'Bonjour'},
      {'role': 'assistant', 'content': 'Bonjour, comment puis-je aider ?'},
    ]);
  });
}
