import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        if (valor < 800) return 'Bajo';
        if (valor < 1500) return 'Mediano';
        return 'Alto';
      default:
        return '';
    }
  }

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
