import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyecto_final_ok/presentation/firestore_provider_reciente.dart'; // donde definiste ultimas50MedicionesProvider

class UltimasMedicionesScreen extends ConsumerWidget {
  const UltimasMedicionesScreen({super.key});

  String _fmtNum(num? x) => x == null ? '-' : x.toStringAsFixed(2);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ultimas50MedicionesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Últimas 50 mediciones')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (err, stack) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Error: $err'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed:
                        () => ref.refresh(ultimas50MedicionesStreamProvider),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
        data: (mediciones) {
          if (mediciones.isEmpty) {
            return const Center(child: Text('No hay mediciones.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.refresh(ultimas50MedicionesStreamProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: mediciones.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final m = mediciones[i];

                // Ajustá estas propiedades según tu entidad Medicion
                final fecha =
                    (m.fechaHora ?? '')
                        .toString(); // si tenés DateTime, formatealo
                final lat = m.latitud;
                final lon = m.longitud;

                return Card(
                  elevation: 2,
                  child: ListTile(
                    title: Text(
                      'Fecha: $fecha',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PM2.5: ${_fmtNum(m.pm25)}  •  PM10: ${_fmtNum(m.pm10)}',
                          ),
                          Text(
                            'TVOC: ${_fmtNum(m.tvoc)}  •  CO₂: ${_fmtNum(m.co2)}',
                          ),
                          Text(
                            'CO: ${_fmtNum(m.co)}  •  NH₃: ${_fmtNum(m.nh3)}',
                          ),
                          const SizedBox(height: 6),
                          Text('Lat: ${_fmtNum(lat)}  •  Lon: ${_fmtNum(lon)}'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
