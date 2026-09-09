import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'presentation/screens/mapa_eleitoral_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega o .env com segurança sem travar o aplicativo
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Aviso: arquivo .env não carregado: $e");
  }

  runApp(const GeoNexusApp());
}

class GeoNexusApp extends StatelessWidget {
  const GeoNexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoNexus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E)),
        useMaterial3: true,
      ),
      home: const MapaEleitoralScreen(),
    );
  }
}