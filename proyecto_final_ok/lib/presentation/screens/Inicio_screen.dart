import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyecto_final_ok/presentation/firestore_provider.dart';
import 'package:proyecto_final_ok/presentation/medicion_provider.dart';

class InicioScreen extends ConsumerWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicionesAsync = ref.watch(medicionesFormateadasProvider);

    return medicionesAsync.when(
      data: (mediciones) {
        return ListView.builder(
          itemCount: mediciones.length,
          itemBuilder: (context, index) {
            final m = mediciones[index];
            return ListTile(
              title: Text("CO2: ${m['co2']} | PM2.5: ${m['pm25']}"),
              subtitle: Text("Fecha: ${m['fecha']}"),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Error: $err")),
    );
  }
}
