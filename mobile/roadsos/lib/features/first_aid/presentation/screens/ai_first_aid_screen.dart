import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/ai_provider.dart';

class AiFirstAidScreen extends ConsumerStatefulWidget {
  const AiFirstAidScreen({super.key});

  @override
  ConsumerState<AiFirstAidScreen> createState() => _AiFirstAidScreenState();
}

class _AiFirstAidScreenState extends ConsumerState<AiFirstAidScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    ref.read(aiChatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _sendSuggestion(String text) {
    ref.read(aiChatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider);

    // Auto-scroll on new message
    ref.listen<AiChatState>(aiChatProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length || next.isLoading) {
        _scrollToBottom();
      }
    });

    final hasUserMessages = chatState.messages.any((m) => m.isUser);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.teal.withOpacity(0.1),
              child: const Icon(Icons.psychology_outlined, color: Colors.teal, size: 22),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'First Aid AI',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                Text(
                  'Emergency Assistant',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (chatState.messages.length > 1)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
              onPressed: () {
                ref.read(aiChatProvider.notifier).clearChat();
              },
              tooltip: 'Reset Chat',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages List
            Expanded(
              child: chatState.messages.isEmpty
                  ? const Center(child: Text('Start a conversation.'))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: chatState.messages.length,
                      itemBuilder: (context, index) {
                        final msg = chatState.messages[index];
                        return _buildMessageBubble(msg);
                      },
                    ),
            ),

            // Suggestions section (visible only if user hasn't asked anything yet)
            if (!hasUserMessages && !chatState.isLoading) ...[
              _buildSuggestionsPanel(),
            ],

            // Loading indicator
            if (chatState.isLoading) ...[
              _buildLoadingIndicator(),
            ],

            // Input panel
            _buildInputPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final alignment = msg.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bgColor = msg.isUser ? AppTheme.sosRed : Colors.white;
    final textColor = msg.isUser ? Colors.white : AppTheme.textPrimary;
    final borderRadius = msg.isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          );

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: borderRadius,
          border: msg.isUser ? null : Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.isUser)
              Text(
                msg.text,
                style: TextStyle(color: textColor, fontSize: 14.5, fontWeight: FontWeight.w500, height: 1.35),
              )
            else
              _MarkdownText(text: msg.text),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: msg.isUser ? Colors.white70 : AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsPanel() {
    final suggestions = [
      'What to do for severe bleeding?',
      'How to perform CPR on an adult?',
      'First aid steps for minor burns',
      'What to do if someone broke a leg?',
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Suggested Emergency Inquiries:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((s) {
              return ActionChip(
                elevation: 0,
                pressElevation: 1,
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.teal.withOpacity(0.3)),
                label: Text(
                  s,
                  style: const TextStyle(color: Colors.teal, fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                onPressed: () => _sendSuggestion(s),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Analyzing emergency protocol...',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildInputPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, -1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _messageController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                style: const TextStyle(fontSize: 14.5),
                decoration: const InputDecoration(
                  hintText: 'Type emergency issue (e.g. choking, shock)...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.sosRed,
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple Markdown Parser Widget that processes bold text `**` and lines starting with `-` or numbers.
class _MarkdownText extends StatelessWidget {
  const _MarkdownText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final List<Widget> children = [];

    for (var line in lines) {
      if (line.trim().isEmpty) {
        children.add(const SizedBox(height: 6));
        continue;
      }

      // Check if it's a bullet point starting with '-' or '*'
      bool isBullet = line.trim().startsWith('-') || line.trim().startsWith('*') && !line.trim().startsWith('**');
      // Check if it's numbered list e.g., "1. " or "2. "
      bool isNumbered = RegExp(r'^\d+\.\s+').hasMatch(line.trim());

      String content = line;
      if (isBullet) {
        content = line.trim().substring(1).trim();
      } else if (isNumbered) {
        final match = RegExp(r'^\d+\.\s+').firstMatch(line.trim());
        if (match != null) {
          content = line.trim().substring(match.end).trim();
        }
      }

      final textSpan = _parseBoldText(content);

      if (isBullet) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.teal)),
                Expanded(
                  child: RichText(
                    text: textSpan,
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (isNumbered) {
        final prefix = RegExp(r'^\d+\.').stringMatch(line.trim()) ?? '1.';
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$prefix ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.teal)),
                Expanded(
                  child: RichText(
                    text: textSpan,
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Regular line
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: RichText(
              text: textSpan,
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  TextSpan _parseBoldText(String rawText) {
    final List<TextSpan> spans = [];
    final pattern = RegExp(r'\*\*(.*?)\*\*');
    int start = 0;

    for (final match in pattern.allMatches(rawText)) {
      if (match.start > start) {
        spans.add(
          TextSpan(
            text: rawText.substring(start, match.start),
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13.5, height: 1.4),
          ),
        );
      }
      
      // Check if it's the emergency warning to color it red
      final boldContent = match.group(1) ?? '';
      final isWarning = boldContent.contains('WARNING') || boldContent.contains('EMERGENCY');

      spans.add(
        TextSpan(
          text: boldContent,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isWarning ? AppTheme.sosRed : AppTheme.textPrimary,
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
      );
      start = match.end;
    }

    if (start < rawText.length) {
      spans.add(
        TextSpan(
          text: rawText.substring(start),
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13.5, height: 1.4),
        ),
      );
    }

    return TextSpan(children: spans);
  }
}
