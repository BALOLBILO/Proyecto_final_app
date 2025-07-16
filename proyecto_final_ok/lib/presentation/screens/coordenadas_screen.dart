import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyecto_final_ok/presentation/coordenadas_provider.dart';
import 'package:proyecto_final_ok/presentation/firestore_provider.dart';

class CoordenadasScreen extends ConsumerWidget {
  const CoordenadasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicionesAsync = ref.watch(medicionesPorCoordenadaProvider);
    final lat = ref.watch(latitud);
    final lon = ref.watch(longitud);

    return Scaffold(
      appBar: AppBar(title: Text('Mediciones en lat/lon')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Coordenadas seleccionadas:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text("Lat: $lat, Lon: $lon"),
            SizedBox(height: 20),
            Expanded(
              child: medicionesAsync.when(
                data: (mediciones) {
                  if (mediciones.isEmpty) {
                    return Text("No hay mediciones para estas coordenadas.");
                  }
                  return ListView.builder(
                    itemCount: mediciones.length,
                    itemBuilder: (context, index) {
                      final med = mediciones[index];
                      return Card(
                        margin: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        elevation: 2,
                        child: ListTile(
                          title: Text(
                            "Fecha: ${med.fechaHora}",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text("PM2.5: ${med.pm25}, PM10: ${med.pm10}"),
                              Text(
                                "CO2: ${med.co2}, TVOC: ${med.tvoc}, NH3: ${med.nh3}, CO: ${med.co}",
                              ),
                              Text("Lat: ${med.latitud}, Lon: ${med.longitud}"),
                              Text("Timestamp: ${med.timestamp}"),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
