import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:proyecto_final_ok/presentation/coordenadas_provider.dart';
import 'package:proyecto_final_ok/presentation/firestore_provider.dart';

class CoordenadasScreen extends ConsumerWidget {
  const CoordenadasScreen({super.key});

  String clasificar(String gas, double valor) {
    switch (gas) {
      case 'pm25':
        if (valor < 15) return 'Bajo';
        if (valor < 35) return 'Mediano';
        return 'Alto';
      case 'pm10':
        if (valor < 30) return 'Bajo';
        if (valor < 50) return 'Mediano';
        return 'Alto';
      case 'tvoc':
        if (valor < 150) return 'Bajo';
        if (valor < 300) return 'Mediano';
        return 'Alto';
      case 'nh3':
        if (valor < 20) return 'Bajo';
        if (valor < 40) return 'Mediano';
        return 'Alto';
      case 'co':
        if (valor < 5) return 'Bajo';
        if (valor < 10) return 'Mediano';
        return 'Alto';
      case 'co2':
        if (valor < 600) return 'Bajo';
        if (valor < 1000) return 'Mediano';
        return 'Alto';
      default:
        return '';
    }
  }

  Future<String> obtenerDireccion(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        return [
          p.street,
          p.locality,
          p.subAdministrativeArea,
          p.administrativeArea,
          p.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
      }
      return 'Dirección no encontrada';
    } catch (_) {
      return 'Error obteniendo dirección';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicionesAsync = ref.watch(medicionesPorCoordenadaProvider);
    final lat = ref.watch(latitud);
    final lon = ref.watch(longitud);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mediciones en ubicación seleccionada'),
        actions: [
          IconButton(
            tooltip: 'Inicio',
            icon: const Icon(Icons.home_rounded),
            onPressed: () {
              // Usá go(...) si querés reemplazar el stack. Si preferís apilar, cambiá por push('/inicio')
              context.go('/inicio');
            },
          ),
        ],
      ),

      // 👉 Dos FABs apilados: Elegir gas + Ver en mapa
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'elegir_gas',
            icon: const Icon(Icons.tune),
            label: const Text('Elegir gas'),
            onPressed: () {
              // Navega a MedicionesScreen y, tras elegir gas, irá a MedicionPersonalizada
              context.push('/mediciones', extra: 'personalizada');
            },
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'ver_mapa',
            icon: const Icon(Icons.map),
            label: const Text('Ver en mapa'),
            onPressed: () {
              // Abre el mapa centrado en estas coordenadas
              context.push('/mapa', extra: LatLng(lat, lon));
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<String>(
              future: obtenerDireccion(lat, lon),
              builder: (context, snapshot) {
                final direccion = snapshot.data ?? 'Cargando dirección...';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "📍 Lugar:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(direccion, style: const TextStyle(fontSize: 15)),
                    const SizedBox(height: 8),
                    Text(
                      "🧭 Coordenadas: ($lat, $lon)",
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
            Expanded(
              child: medicionesAsync.when(
                data: (mediciones) {
                  if (mediciones.isEmpty) {
                    return const Center(
                      child: Text("No hay mediciones para esta ubicación."),
                    );
                  }
                  return ListView.builder(
                    itemCount: mediciones.length,
                    itemBuilder: (context, index) {
                      final med = mediciones[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        elevation: 2,
                        child: ListTile(
                          title: Text(
                            "Fecha: ${med.fechaHora}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                "PM2.5: ${med.pm25} (${clasificar('pm25', med.pm25)})",
                              ),
                              Text(
                                "PM10: ${med.pm10} (${clasificar('pm10', med.pm10)})",
                              ),
                              Text(
                                "TVOC: ${med.tvoc} (${clasificar('tvoc', med.tvoc)})",
                              ),
                              Text(
                                "NH3: ${med.nh3} (${clasificar('nh3', med.nh3)})",
                              ),
                              Text(
                                "CO: ${med.co} (${clasificar('co', med.co)})",
                              ),
                              Text(
                                "CO2: ${med.co2} (${clasificar('co2', med.co2)})",
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
