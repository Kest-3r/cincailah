import 'package:dart_openai/dart_openai.dart';
import 'chat_repository.dart';

class AICompanionService {
  final ChatRepository repo;
  final String userId;
  List<OpenAIChatCompletionChoiceMessageModel> _history = [];

  AICompanionService(this.repo, this.userId);
  static Future<String> getReply(String userMessage) async {
    final response = await OpenAI.instance.chat.create(
      model: "gpt-4o-mini", // small + cheap model
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.system,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(
              "You are Miu, a friendly cat-like AI companion for mental wellness. "
              "Speak warmly, clearly, and empathetically. "
              "You may sprinkle subtle cat traits (meows, purrs) but keep messages human-readable.",
            ),
          ],
        ),
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(userMessage),
          ],
        ),
      ],
    );

    return response.choices.first.message.content?.first.text ?? "";
  }
}
