import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/invoice.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/invoices_page.dart'; // <-- Add this import
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(InvoiceAdapter());
  await Hive.openBox<Invoice>('invoices');
  runApp(const SmartInvoiceApp());
}

class SmartInvoiceApp extends StatelessWidget {
  const SmartInvoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Invoice Processor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue.shade700,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/history': (context) => const HistoryScreen(),
        '/invoices': (context) => const InvoicesPage(), // <-- Add this line
        '/settings': (context) => const SettingsScreen(),
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: const Center(child: Text('Page not found')),
        ),
      ),
    );
  }
}
