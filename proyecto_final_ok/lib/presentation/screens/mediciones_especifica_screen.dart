import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proyecto_final_ok/presentation/mediciones_provider.dart';
import 'package:proyecto_final_ok/presentation/coordenadas_provider.dart';
import 'package:proyecto_final_ok/presentation/lugar_provider.dart';
import 'package:proyecto_final_ok/presentation/geocoding_provider.dart'; // 👈 usamos el provider de dirección

class MedicionesEspecificasScreen extends ConsumerWidget {
  const MedicionesEspecificasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gas = ref.watch(gasSeleccionado); // ej: 'co2'
    final medicionesAsync = ref.watch(topMedicionesPorGasProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Top 20 de ${gas.toUpperCase()}')),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: medicionesAsync.when(
              data: (mediciones) {
                if (mediciones.isEmpty) {
                  return const Center(child: Text("No hay mediciones."));
                }

                return ListView.builder(
                  itemCount: mediciones.length,
                  itemBuilder: (context, index) {
                    final m = mediciones[index];
                    final valor = m.toMap()[gas];
                    final lat = m.latitud;
                    final lon = m.longitud;

                    // 👇 Provider que obtiene la dirección
                    final direccionAsync = ref.watch(
                      direccionProvider((lat, lon)),
                    );

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                        title: Text(
                          "$gas: ${valor.toString()}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("📅 Fecha: ${m.fechaHora}"),
                            const SizedBox(height: 4),
                            Text(
                              "📍 Coordenadas: (${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)})",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            direccionAsync.when(
                              data:
                                  (direccion) => Text(
                                    "🏙️ Lugar: $direccion",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                              loading:
                                  () => const Text(
                                    "🏙️ Buscando dirección...",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                              error:
                                  (_, __) => const Text(
                                    "🏙️ Error al obtener dirección",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                            ),
                          ],
                        ),
                        onTap: () {
                          ref.read(latitud.notifier).state = lat;
                          ref.read(longitud.notifier).state = lon;
                          context.push(
                            '/medicionPersonalizada',
                          ); // 👈 antes iba a '/coordenada'
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text("❌ Error: $e")),
            ),
          ),
        ],
      ),

      // 🧭 Botones flotantes
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'mapa',
            backgroundColor: Colors.green,
            icon: const Icon(Icons.map),
            label: const Text('Ver mapa'),
            onPressed: () {
              context.push('/mapaEspecifico');
            },
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'buscar',
            backgroundColor: Colors.blue,
            icon: const Icon(Icons.search),
            label: const Text('Buscar'),
            onPressed: () {
              ref.read(lugarPantalla.notifier).state = 2;
              context.push('/lugar');
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
