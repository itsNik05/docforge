import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'features/scan_pdf/presentation/provider/scan_provider.dart';
import 'features/scan_pdf/domain/repositories/scan_repository.dart';
import 'features/scan_pdf/data/scan_mlkit_service.dart';
import 'core/services/permission_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ScanProvider(
            ScanRepository(ScanMlKitService()),
            PermissionService(),
          ),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
      ),
    );
  }
}