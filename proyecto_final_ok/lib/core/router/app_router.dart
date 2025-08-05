import 'package:proyecto_final_ok/presentation/screens/Inicio_screen.dart';
import 'package:proyecto_final_ok/presentation/screens/lugar_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:proyecto_final_ok/presentation/screens/coordenadas_screen.dart';
import 'package:proyecto_final_ok/presentation/screens/medicion_personalizada_screen.dart';
import 'package:proyecto_final_ok/presentation/screens/mediciones_especifica_screen.dart';
import 'package:proyecto_final_ok/presentation/screens/mediciones_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/inicio',
  routes: [
    GoRoute(path: '/lugar', builder: (context, state) => const LugarScreen()),
    GoRoute(
      path: '/coordenada',
      builder: (context, state) => const CoordenadasScreen(),
    ),
    GoRoute(path: '/inicio', builder: (context, state) => const InicioScreen()),
    GoRoute(
      path: '/mediciones',
      builder: (context, state) => const MedicionesScreen(),
    ),
    GoRoute(
      path: '/medicionesEspecifica',
      builder: (context, state) => const MedicionesEspecificasScreen(),
    ),
    GoRoute(
      path: '/medicionPersonalizada',
      builder: (context, state) => const MedicionPersonalizadaScreen(),
    ),
  ],
);
