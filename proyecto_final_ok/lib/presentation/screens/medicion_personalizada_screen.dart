import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:proyecto_final_ok/presentation/coordenadas_provider.dart';
import 'package:proyecto_final_ok/presentation/firestore_provider.dart';
import 'package:proyecto_final_ok/presentation/mediciones_provider.dart';

class MedicionPersonalizadaScreen extends ConsumerWidget {
  const MedicionPersonalizadaScreen({super.key});

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
        if (valor < 800) return 'Bajo';
        if (valor < 1500) return 'Mediano';
        return 'Alto';
      default:
        return '';
    }
  }

  double _valorDe(dynamic med, String gas) {
    switch (gas) {
      case 'pm25':
        return (med.pm25 ?? 0).toDouble();
      case 'pm10':
        return (med.pm10 ?? 0).toDouble();
      case 'tvoc':
        return (med.tvoc ?? 0).toDouble();
      case 'nh3':
        return (med.nh3 ?? 0).toDouble();
      case 'co':
        return (med.co ?? 0).toDouble();
      case 'co2':
        return (med.co2 ?? 0).toDouble();
      default:
        return 0.0;
    }
  }

  String _formatearFecha(dynamic fechaHora) {
    if (fechaHora is DateTime) {
      return '${fechaHora.toLocal()}';
    }
    return '$fechaHora';
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
    final gas = ref.watch(gasSeleccionado); // ej: 'pm25', 'co2', etc.

    return Scaffold(
      appBar: AppBar(title: const Text('Medición personalizada')),

      // ⬇️ Dos FABs: Top 20 y Gráfico
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'fabTop',
            backgroundColor: Colors.deepPurple,
            icon: const Icon(Icons.star),
            label: const Text('Top 20'),
            onPressed: () {
              // Navega a la pantalla que lista el Top 20 por gas
              context.push(
                '/coordenada',
              ); // ajustá si tu ruta tiene otro nombre
            },
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'fabGrafico',
            icon: const Icon(Icons.show_chart),
            label: const Text('Gráfico'),
            onPressed: () {
              context.push('/grafico');
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

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
                      final valor = _valorDe(med, gas);
                      final nivel = clasificar(gas, valor);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        elevation: 2,
                        child: ListTile(
                          title: Text(
                            "Fecha: ${_formatearFecha(med.fechaHora)}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              "$gas: ${valor.toStringAsFixed(2)} ($nivel)",
                            ),
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
