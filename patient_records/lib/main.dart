import 'package:flutter/material.dart';
import 'services/clinic_repository.dart';
import 'theme/app_theme.dart';
import 'views/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = ClinicRepository();
  await repository.init();

  runApp(const ClinicApp());
}

class ClinicApp extends StatelessWidget {
  const ClinicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medicare Clinic Management System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainLayout(),
    );
  }
}


