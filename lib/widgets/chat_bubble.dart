import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../theme/app_theme.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) _buildAvatar(),
          if (!message.isUser) const SizedBox(width: 8),
          Flexible(child: _buildBubble(context)),
          if (message.isUser) const SizedBox(width: 8),
          if (message.isUser) _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Text(
          '✦',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: AppTheme.accentGreen.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Icon(Icons.person_rounded, size: 18, color: AppTheme.accentGreen),
      ),
    );
  }

  Widget _buildBubble(BuildContext context) {
    final isUser = message.isUser;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUser
            ? AppTheme.accentBlue.withValues(alpha: 0.15)
            : AppTheme.cardDark,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 18),
        ),
        border: Border.all(
          color: isUser
              ? AppTheme.accentBlue.withValues(alpha: 0.3)
              : AppTheme.borderDark,
          width: 1,
        ),
      ),
      child: message.isThinking
          ? _buildThinkingIndicator()
          : Text(
              message.text,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                height: 1.5,
                fontWeight: isUser ? FontWeight.w400 : FontWeight.w400,
              ),
            ),
    );
  }

  Widget _buildThinkingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ThinkingDots(),
        const SizedBox(width: 8),
        const Text(
          'Đang suy nghĩ...',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _ThinkingDots extends StatefulWidget {
  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0, end: -6).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animations[index].value),
              child: Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
