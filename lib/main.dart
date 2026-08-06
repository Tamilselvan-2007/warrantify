import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const WarrantifyApp());
}

final supabase = Supabase.instance.client;

class WarrantifyApp extends StatelessWidget {
  const WarrantifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Warrantify',
      home: Scaffold(
        appBar: AppBar(title: const Text('Warrantify')),
        body: const Center(child: Text('Supabase connected ✅')),
      ),
    );
  }
}
