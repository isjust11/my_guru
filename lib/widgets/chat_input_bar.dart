import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ChatInputBar extends StatefulWidget {
  final Function(String) onSend;
  final bool isLoading;

  const ChatInputBar({
    super.key,
    required this.onSend,
    this.isLoading = false,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isLoading) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: const Border(
          top: BorderSide(color: AppTheme.borderDark, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppTheme.primaryDark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: TextField(
                controller: _controller,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                ),
                decoration: const InputDecoration(
                  hintText: 'Hỏi MyGuru bất cứ điều gì...',
                  hintStyle: TextStyle(color: AppTheme.textMuted),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: 48,
            height: 48,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: (_hasText && !widget.isLoading) ? _handleSend : null,
                borderRadius: BorderRadius.circular(24),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: (_hasText && !widget.isLoading)
                        ? AppTheme.primaryGradient
                        : null,
                    color: (_hasText && !widget.isLoading)
                        ? null
                        : AppTheme.cardDark,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.textMuted,
                            ),
                          )
                        : Icon(
                            Icons.arrow_upward_rounded,
                            color: (_hasText && !widget.isLoading)
                                ? Colors.white
                                : AppTheme.textMuted,
                            size: 22,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
