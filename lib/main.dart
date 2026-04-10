import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'screens/model_setup_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FlutterGemma with HuggingFace token (from config.json)
  const token = String.fromEnvironment('HUGGINGFACE_TOKEN');
  FlutterGemma.initialize(
    huggingFaceToken: token.isNotEmpty ? token : null,
    maxDownloadRetries: 10,
  );

  runApp(const MyGuruApp());
}

class MyGuruApp extends StatelessWidget {
  const MyGuruApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyGuru',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const ModelSetupScreen(),
    );
  }
}
