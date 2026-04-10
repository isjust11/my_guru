import 'dart:async';
import 'package:flutter_gemma/flutter_gemma.dart';

/// Supported model configurations for MyGuru.
enum GemmaModelConfig {
  gemma3_270m(
    name: 'Gemma 3 (270M)',
    description: 'Nhẹ nhất, phù hợp điện thoại cấu hình thấp (~300MB)',
    url: 'https://huggingface.co/litert-community/gemma-3-270m-it/resolve/main/gemma-3-270m-it-int8.task',
    sizeInMB: 300,
    needsAuth: true,
  ),
  gemma3_1b(
    name: 'Gemma 3 (1B)',
    description: 'Cân bằng chất lượng & hiệu suất (~1GB)',
    url: 'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1B-it-int8.task',
    sizeInMB: 1000,
    needsAuth: true,
  ),
  deepSeekR1(
    name: 'DeepSeek R1 (1.5B)',
    description: 'Suy luận mạnh, có chế độ "thinking" (~1.5GB)',
    url: 'https://huggingface.co/litert-community/DeepSeek-R1-Distill-Qwen-1.5B/resolve/main/DeepSeek-R1-Distill-Qwen-1.5B-int8.task',
    sizeInMB: 1500,
    needsAuth: false,
  );

  final String name;
  final String description;
  final String url;
  final int sizeInMB;
  final bool needsAuth;

  const GemmaModelConfig({
    required this.name,
    required this.description,
    required this.url,
    required this.sizeInMB,
    required this.needsAuth,
  });
}

/// Service class that wraps flutter_gemma for MyGuru.
class GemmaService {
  dynamic _model;
  dynamic _chat;
  bool _isModelReady = false;
  GemmaModelConfig? _currentConfig;

  bool get isModelReady => _isModelReady;
  GemmaModelConfig? get currentConfig => _currentConfig;

  /// Check if a model is already installed.
  Future<bool> isModelInstalled(GemmaModelConfig config) async {
    try {
      final fileName = config.url.split('/').last;
      return await FlutterGemma.isModelInstalled(fileName);
    } catch (_) {
      return false;
    }
  }

  /// Download and install a model with progress tracking.
  Stream<int> installModel(GemmaModelConfig config) {
    final controller = StreamController<int>();

    () async {
      try {
        final modelType = config == GemmaModelConfig.deepSeekR1
            ? ModelType.deepSeek
            : ModelType.gemmaIt;

        await FlutterGemma.installModel(
          modelType: modelType,
        ).fromNetwork(
          config.url,
        ).withProgress((progress) {
          controller.add(progress);
        }).install();

        _currentConfig = config;
        controller.add(100);
        await controller.close();
      } catch (e) {
        controller.addError(e);
        await controller.close();
      }
    }();

    return controller.stream;
  }

  /// Initialize the model for inference.
  Future<void> initializeModel({GemmaModelConfig? config}) async {
    config ??= _currentConfig ?? GemmaModelConfig.gemma3_270m;
    _currentConfig = config;

    _model = await FlutterGemma.getActiveModel(
      maxTokens: 2048,
      preferredBackend: PreferredBackend.gpu,
    );

    _isModelReady = true;
  }

  /// Start a new chat session.
  Future<void> startNewChat() async {
    if (!_isModelReady || _model == null) return;

    final isDeepSeek = _currentConfig == GemmaModelConfig.deepSeekR1;

    _chat = await _model.createChat(
      temperature: 0.8,
      topK: isDeepSeek ? 1 : 40,
      systemInstruction:
          'Bạn là MyGuru, một trợ lý AI thông minh. '
          'Bạn trả lời mọi câu hỏi một cách chính xác, ngắn gọn và hữu ích. '
          'Bạn có thể trả lời bằng tiếng Việt hoặc tiếng Anh tùy theo ngôn ngữ câu hỏi.',
    );
  }

  /// Send a message and get a streamed response.
  Stream<String> sendMessage(String message) {
    final controller = StreamController<String>();

    () async {
      try {
        if (_chat == null) await startNewChat();

        await _chat.addQueryChunk(
          Message.text(text: message, isUser: true),
        );

        final responseStream = _chat.generateChatResponseAsync();
        final buffer = StringBuffer();

        await for (final response in responseStream) {
          if (response is TextResponse) {
            buffer.write(response.token);
            controller.add(buffer.toString());
          }
        }

        await controller.close();
      } catch (e) {
        controller.addError(e);
        await controller.close();
      }
    }();

    return controller.stream;
  }

  /// Dispose resources.
  Future<void> dispose() async {
    try {
      await _model?.close();
    } catch (_) {}
    _model = null;
    _chat = null;
    _isModelReady = false;
  }
}
