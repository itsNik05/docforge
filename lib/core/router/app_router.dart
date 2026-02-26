import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/merge_pdf/presentation/pages/merge_pdf_page.dart';
import '../../features/scan_pdf/presentation/pages/scan_page.dart';


final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/merge',
      builder: (context, state) => const MergePdfPage(),
    ),
    GoRoute(
      path: '/scan',
      builder: (context, state) => const ScanPage(),
    ),
  ],
);