import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proyecto_final_ok/presentation/mediciones_provider.dart';
import 'package:proyecto_final_ok/presentation/coordenadas_provider.dart';

class MedicionesEspecificasScreen extends ConsumerWidget {
  const MedicionesEspecificasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gas = ref.watch(gasSeleccionado); // por ejemplo: 'co2'
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
                    final valor = m.toMap()[gas]; // Extrae el valor dinámico

                    return ListTile(
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text("$gas: $valor"),
                      subtitle: Text("Fecha: ${m.fechaHora}"),
                      trailing: Text(
                        "(${m.latitud.toStringAsFixed(4)}, ${m.longitud.toStringAsFixed(4)})",
                      ),
                      onTap: () {
                        final lat = m.latitud;
                        final lon = m.longitud;
                        ref.read(latitud.notifier).state = lat;
                        ref.read(longitud.notifier).state = lon;
                        context.push('/coordenada');
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text("❌ Error: $e")),
            ),
          ),
        ],
      ),
    );
  }
}
