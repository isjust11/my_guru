import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/gemma_service.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_bar.dart';

class ChatScreen extends StatefulWidget {
  final GemmaService gemmaService;
  final GemmaModelConfig modelConfig;

  const ChatScreen({
    super.key,
    required this.gemmaService,
    required this.modelConfig,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isGenerating = false;
  bool _isInitializing = true;
  StreamSubscription? _responseSubscription;

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  @override
  void dispose() {
    _responseSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeModel() async {
    try {
      await widget.gemmaService.initializeModel(config: widget.modelConfig);
      await widget.gemmaService.startNewChat();
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitializing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khởi tạo model: $e'),
            backgroundColor: const Color(0xFFF85149),
          ),
        );
      }
    }
  }

  void _sendMessage(String text) {
    if (_isGenerating || _isInitializing) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _messages.add(ChatMessage(text: '', isUser: false, isThinking: true));
      _isGenerating = true;
    });

    _scrollToBottom();

    _responseSubscription =
        widget.gemmaService.sendMessage(text).listen(
      (partialResponse) {
        if (mounted) {
          setState(() {
            _messages.last = ChatMessage(
              text: partialResponse,
              isUser: false,
              isThinking: false,
            );
          });
          _scrollToBottom();
        }
      },
      onDone: () {
        if (mounted) {
          setState(() => _isGenerating = false);
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _messages.last = ChatMessage(
              text: 'Xin lỗi, có lỗi xảy ra: $error',
              isUser: false,
              isThinking: false,
            );
            _isGenerating = false;
          });
        }
      },
    );
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

  void _startNewConversation() {
    _responseSubscription?.cancel();
    setState(() {
      _messages.clear();
      _isGenerating = false;
    });
    widget.gemmaService.startNewChat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.surfaceGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: _isInitializing
                    ? _buildLoadingState()
                    : _messages.isEmpty
                        ? _buildEmptyState()
                        : _buildChatList(),
              ),
              ChatInputBar(
                onSend: _sendMessage,
                isLoading: _isGenerating || _isInitializing,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('✦', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MyGuru',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  widget.modelConfig.name,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _startNewConversation,
            icon: const Icon(
              Icons.add_comment_rounded,
              color: AppTheme.textSecondary,
              size: 22,
            ),
            tooltip: 'Cuộc trò chuyện mới',
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppTheme.accentBlue,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Đang khởi tạo AI...',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Lần đầu có thể mất vài giây',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentBlue.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Text('✦', style: TextStyle(fontSize: 36, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Xin chào! Tôi là MyGuru',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Hỏi tôi bất cứ điều gì bạn muốn biết.\n'
              'Tôi chạy hoàn toàn trên thiết bị của bạn.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 15,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('AI là gì?'),
                _buildSuggestionChip('Viết một bài thơ'),
                _buildSuggestionChip('Giải thích lượng tử'),
                _buildSuggestionChip('Mẹo học lập trình'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(
        text,
        style: const TextStyle(
          color: AppTheme.accentBlue,
          fontSize: 13,
        ),
      ),
      backgroundColor: AppTheme.accentBlue.withValues(alpha: 0.1),
      side: BorderSide(
        color: AppTheme.accentBlue.withValues(alpha: 0.3),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      onPressed: () => _sendMessage(text),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return ChatBubble(message: _messages[index]);
      },
    );
  }
}
