import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proyecto_final_ok/presentation/lugar_provider.dart';

class InicioScreen extends ConsumerWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opciones = [
      {
        'icon': Icons.analytics_outlined,
        'titulo': 'Mediciones',
        'color': Colors.teal,
        'ruta': '/mediciones',
      },
      {
        'icon': Icons.map_outlined,
        'titulo': 'Mapa',
        'color': Colors.green,
        'ruta': '/mapa',
      },
      {
        'icon': Icons.place_outlined,
        'titulo': 'Lugar',
        'color': Colors.blue,
        'ruta': '/lugar',
      },
      {
        'icon': Icons.history_outlined,
        'titulo': 'Datos recientes',
        'color': Colors.orange,
        'ruta': '/datosRecientes',
      },
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFb2f7ef), Color(0xFFeff7f6), Color(0xFFaed9e0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              const Text(
                '🌍 ECORUTA',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00695c),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Monitoreo ambiental inteligente',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 25),

              // Lista de opciones
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  itemCount: opciones.length,
                  itemBuilder: (context, index) {
                    final item = opciones[index];
                    return GestureDetector(
                      onTap: () {
                        if (item['titulo'] == 'Lugar') {
                          ref.read(lugarPantalla.notifier).state = 1;
                        }
                        context.push(item['ruta'] as String);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: (item['color'] as Color).withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: (item['color'] as Color)
                                .withOpacity(0.15),
                            radius: 26,
                            child: Icon(
                              item['icon'] as IconData,
                              color: item['color'] as Color,
                              size: 28,
                            ),
                          ),
                          title: Text(
                            item['titulo'] as String,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: (item['color'] as Color).withOpacity(0.7),
                            size: 18,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 👇 Imagen "del colectivo" debajo de la lista (abajo de Datos recientes)
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/icons/Eco_Ruta.png',
                      height: 120, // ajustá si querés
                      fit: BoxFit.contain,
                      semanticLabel: 'Logo EcoRuta',
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  '© 2025 ECORUTA - Proyecto académico',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
