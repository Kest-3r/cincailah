import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dart_openai/dart_openai.dart';
import 'firebase_options.dart';
import 'pages/welcome.dart';
import 'env/env.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Set OpenAI API key once
  OpenAI.apiKey = Env.key1;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multi Page Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const Welcome(),
    );
  }
}
