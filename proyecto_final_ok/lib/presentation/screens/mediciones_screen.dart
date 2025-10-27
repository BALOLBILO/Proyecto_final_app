import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:proyecto_final_ok/presentation/descripcion_provider.dart';
import 'package:proyecto_final_ok/presentation/mediciones_provider.dart';

class MedicionesScreen extends ConsumerWidget {
  final String? destino; // a dónde ir después de elegir gas
  const MedicionesScreen({super.key, this.destino});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mapea la etiqueta visible al nombre de campo en Firestore
    final gasFirestoreMap = <String, String>{
      'CO₂': 'co2',
      'CO': 'co',
      'NH₃': 'nh3',
      'TVOC': 'tvoc',
      'PM2.5': 'pm25',
      'PM10': 'pm10',
    };

    final mediciones = const ['CO₂', 'CO', 'NH₃', 'TVOC', 'PM2.5', 'PM10'];
    final descripcionValue = ref.watch(descripcion);
    final descripcionTexto = _descripcionPara(descripcionValue);

    return Scaffold(
      appBar: AppBar(title: const Text('Mediciones')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seleccionado: ${descripcionValue.isEmpty ? '—' : descripcionValue}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Bloque de descripción con altura fija (no salta el layout)
            Container(
              height: 220,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child:
                  descripcionValue.isNotEmpty
                      ? SingleChildScrollView(
                        child: Text(
                          descripcionTexto,
                          style: const TextStyle(fontSize: 14),
                        ),
                      )
                      : const Center(
                        child: Text(
                          'Selecciona un gas para ver su descripción',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
            ),

            const SizedBox(height: 16),
            const Divider(thickness: 1.5),
            const SizedBox(height: 8),
            const Text(
              'Gases disponibles:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                itemCount: mediciones.length,
                itemBuilder: (context, index) {
                  final item = mediciones[index];
                  final isSelected = item == descripcionValue;
                  return ListTile(
                    leading: const Icon(Icons.blur_on),
                    title: Text(item),
                    selected: isSelected,
                    selectedTileColor: Colors.blue.shade100,
                    onTap: () => ref.read(descripcion.notifier).state = item,
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Botón flotante: setea gasSeleccionado y navega según 'destino'
      floatingActionButton: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: const CircleBorder(),
        ),
        onPressed: () {
          if (descripcionValue.isEmpty) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Selecciona un gas')));
            return;
          }

          final firestoreKey = gasFirestoreMap[descripcionValue];
          if (firestoreKey == null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Gas desconocido')));
            return;
          }

          // Guarda el gas elegido para que otras pantallas lo consuman
          ref.read(gasSeleccionado.notifier).state = firestoreKey;

          // Si venimos de Coordenadas y se pidió flujo “personalizada”
          if (destino == 'personalizada') {
            context.push('/medicionPersonalizada'); // usa lat/lon guardados
          } else {
            // Comportamiento por defecto
            context.push('/medicionesEspecifica');
          }
        },
        child: const Icon(Icons.arrow_forward),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  String _descripcionPara(String gas) {
    switch (gas) {
      case 'CO₂':
        return 'El dióxido de carbono es un gas inofensivo en niveles normales, pero en concentraciones elevadas puede provocar fatiga, dolor de cabeza y dificultad para concentrarse. Si supera los 5000 ppm, puede generar pérdida de conciencia o incluso asfixia. Afecta especialmente a personas en espacios cerrados sin buena ventilación, como oficinas, aulas o vehículos. También es común en zonas industriales donde se lo utiliza en procesos de producción.';
      case 'CO':
        return 'El monóxido de carbono es un gas tóxico que impide el transporte de oxígeno en la sangre. Es incoloro e inodoro, por lo que puede pasar desapercibido. Produce mareos, náuseas y pérdida de conciencia, y en altas concentraciones puede ser mortal. Afecta a cualquier persona expuesta, pero es especialmente peligroso para bebés, ancianos y personas con enfermedades cardíacas. Se encuentra en gases de escape de vehículos, estufas mal ventiladas o incendios.';
      case 'NH₃':
        return 'El amoníaco es un gas con olor fuerte que puede irritar ojos, garganta y vías respiratorias. En altas concentraciones provoca quemaduras químicas y efectos crónicos en personas expuestas con frecuencia. Afecta principalmente a trabajadores rurales, de granjas o industrias químicas. Suele encontrarse en criaderos, plantas de fertilizantes o productos de limpieza industriales.';
      case 'TVOC':
        return 'Los TVOC son un conjunto de sustancias químicas que se evaporan fácilmente y contaminan el aire interior. Pueden causar irritación ocular, dolor de cabeza, mareos e incluso efectos cancerígenos a largo plazo (como el formaldehído). Afectan principalmente a niños, personas asmáticas y ancianos. Están presentes en pinturas, muebles nuevos, alfombras, adhesivos y productos de limpieza.';
      case 'PM2.5':
        return 'Las PM2.5 son partículas muy pequeñas que penetran en los pulmones y pueden llegar al torrente sanguíneo. Se asocian con enfermedades respiratorias, cardiovasculares y cáncer. Son especialmente peligrosas para niños, ancianos y personas con enfermedades pulmonares. Se generan en la quema de combustibles, tráfico vehicular, incendios y actividades industriales.';
      case 'PM10':
        return 'Las PM10 son partículas más grandes que las PM2.5, pero aún lo suficientemente pequeñas como para entrar en las vías respiratorias. Provocan tos, irritación nasal y empeoramiento de alergias. Son comunes en zonas con mucho polvo, obras en construcción, caminos de tierra o zonas urbanas con tránsito intenso.';
      default:
        return '';
    }
  }
}
