import 'package:proyecto_final_ok/presentation/screens/Inicio_screen.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/inicio',
  routes: [
    GoRoute(path: '/inicio', builder: (context, state) => const InicioScreen()),
  ],
);
