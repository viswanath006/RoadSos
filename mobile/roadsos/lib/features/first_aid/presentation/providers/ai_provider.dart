import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/ai_repository.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class AiChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  AiChatState({
    required this.messages,
    required this.isLoading,
    this.error,
  });

  factory AiChatState.initial() => AiChatState(
        messages: [
          ChatMessage(
            text: "Hello! I am your AI First Aid Assistant. Ask me any emergency or first aid questions (e.g. 'What to do for severe bleeding?').",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ],
        isLoading: false,
      );

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final aiFirstAidRepositoryProvider = Provider<AiFirstAidRepository>((ref) {
  return AiFirstAidRepository();
});

final aiChatProvider = StateNotifierProvider.autoDispose<AiChatNotifier, AiChatState>((ref) {
  final repository = ref.read(aiFirstAidRepositoryProvider);
  return AiChatNotifier(repository);
});

class AiChatNotifier extends StateNotifier<AiChatState> {
  final AiFirstAidRepository _repository;

  AiChatNotifier(this._repository) : super(AiChatState.initial());

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );

    try {
      final reply = await _repository.fetchFirstAidGuidance(text);
      final aiMessage = ChatMessage(
        text: reply,
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );
    } catch (e) {
      final errorMessage = ChatMessage(
        text: "⚠️ Sorry, I had trouble reaching the emergency AI server. Please check your network or try again.",
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearChat() {
    state = AiChatState.initial();
  }
}
