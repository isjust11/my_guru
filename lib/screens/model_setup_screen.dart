import 'package:flutter/material.dart';
import '../services/gemma_service.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

class ModelSetupScreen extends StatefulWidget {
  const ModelSetupScreen({super.key});

  @override
  State<ModelSetupScreen> createState() => _ModelSetupScreenState();
}

class _ModelSetupScreenState extends State<ModelSetupScreen>
    with SingleTickerProviderStateMixin {
  final GemmaService _gemmaService = GemmaService();
  GemmaModelConfig _selectedConfig = GemmaModelConfig.gemma3_270m;
  bool _isDownloading = false;
  int _downloadProgress = 0;
  String? _error;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _checkExistingModel();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingModel() async {
    // Check if any model is already installed
    for (final config in GemmaModelConfig.values) {
      if (await _gemmaService.isModelInstalled(config)) {
        if (mounted) {
          _navigateToChat(config);
        }
        return;
      }
    }
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
      _error = null;
    });

    try {
      await for (final progress
          in _gemmaService.installModel(_selectedConfig)) {
        if (mounted) {
          setState(() => _downloadProgress = progress);
        }
      }

      if (mounted) {
        _navigateToChat(_selectedConfig);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _error = 'Lỗi tải model: $e';
        });
      }
    }
  }

  void _navigateToChat(GemmaModelConfig config) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          gemmaService: _gemmaService,
          modelConfig: config,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.surfaceGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(flex: 1),
                _buildLogo(),
                const SizedBox(height: 32),
                _buildTitle(),
                const SizedBox(height: 48),
                if (_isDownloading) _buildDownloadProgress() else _buildModelSelector(),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentBlue.withValues(alpha: 0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: const Center(
          child: Text(
            '✦',
            style: TextStyle(
              fontSize: 48,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'MyGuru',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Trợ lý AI thông minh chạy trên thiết bị của bạn',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildModelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Chọn mô hình AI',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        ...GemmaModelConfig.values.map((config) => _buildModelCard(config)),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: const TextStyle(color: Color(0xFFF85149), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _startDownload,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.download_rounded, size: 20),
                const SizedBox(width: 8),
                Text('Tải ${_selectedConfig.name} (${_selectedConfig.sizeInMB}MB)'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModelCard(GemmaModelConfig config) {
    final isSelected = config == _selectedConfig;
    return GestureDetector(
      onTap: () => setState(() => _selectedConfig = config),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentBlue.withValues(alpha: 0.1)
              : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppTheme.accentBlue
                : AppTheme.borderDark,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.accentBlue : AppTheme.textMuted,
                  width: 2,
                ),
                color: isSelected ? AppTheme.accentBlue : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.name,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    config.description,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadProgress() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderDark),
          ),
          child: Column(
            children: [
              Text(
                'Đang tải ${_selectedConfig.name}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vui lòng chờ, quá trình này chỉ cần thực hiện một lần.',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.borderDark,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 8,
                    width: (MediaQuery.of(context).size.width - 120) *
                        (_downloadProgress / 100),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '$_downloadProgress%',
                style: const TextStyle(
                  color: AppTheme.accentBlue,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
