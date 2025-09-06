import 'package:dart_openai/dart_openai.dart';
import 'chat_repository.dart';
import '../env/env.dart';

class AICompanionService {
  static void init() {
    OpenAI.apiKey = Env.key1; // comes from your .env
  }

  final ChatRepository repo;
  final String userId;
  List<OpenAIChatCompletionChoiceMessageModel> _history = [];

  AICompanionService(this.repo, this.userId);
  /*static Future<String> getReply(String userMessage) async {
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

    return response.choices.first.message.content?.first.text ??
        "Sorry, I couldn’t think of a reply.";
  }*/
  static Future<String> getReply(String userMessage, {String? summary}) async {
    final messages = [
      OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.system,
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
            "You are Miu 🐱, a playful but caring cat companion for mental health. "
            "You listen with empathy, keep replies easy to read, and sprinkle in subtle cat-like traits "
            "(like purrs, paw references, or meows) without making it hard to understand. "
            "Always stay friendly, comforting, and supportive.",
          ),
        ],
      ),
    ];

    if (summary != null) {
      messages.add(
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.system,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(
              "Here is a summary of past conversations with the user: $summary",
            ),
          ],
        ),
      );
    }

    messages.add(
      OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.user,
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(userMessage),
        ],
      ),
    );

    final response = await OpenAI.instance.chat.create(
      model: "gpt-4o-mini",
      messages: messages,
    );

    return response.choices.first.message.content?.first.text ??
        "Miu couldn’t reply this time 🐾";
  }

  static Future<String> summarizeConversation(List<String> messages) async {
    // Clean & join
    final transcript = messages
        .map((m) => m.trim())
        .where((m) => m.isNotEmpty)
        .join("\n");

    if (transcript.isEmpty) {
      return "No conversation to summarize yet.";
    }

    // Debug log
    print("=== Summarize Input ===\n$transcript\n=======================");

    final response = await OpenAI.instance.chat.create(
      model: "gpt-4o-mini",
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.system,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(
              "Summarize the following conversation in a warm, empathetic way. "
              "Keep it concise but capture important themes about the user's feelings and concerns. "
              "Do NOT write it as dialogue, just a summary for Miu to remember.",
            ),
          ],
        ),
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(
              "Here is the transcript:\n---BEGIN---\n$transcript\n---END---",
            ),
          ],
        ),
      ],
    );

    return response.choices.first.message.content?.first.text ??
        "User and Miu had a friendly chat.";
  }
}
