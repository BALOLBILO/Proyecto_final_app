import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proyecto_final_ok/presentation/descripcion_provider.dart';

class MedicionesScreen extends ConsumerWidget {
  const MedicionesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final descripcionValue = ref.watch(descripcion);

    String descripcion1 = '';
    if (descripcionValue == 'CO₂') {
      descripcion1 =
          'El dióxido de carbono es un gas inofensivo en niveles normales, pero en concentraciones elevadas puede provocar fatiga, dolor de cabeza y dificultad para concentrarse. Si supera los 5000 ppm, puede generar pérdida de conciencia o incluso asfixia. Afecta especialmente a personas en espacios cerrados sin buena ventilación, como oficinas, aulas o vehículos. También es común en zonas industriales donde se lo utiliza en procesos de producción.';
    } else if (descripcionValue == 'CO') {
      descripcion1 =
          'El monóxido de carbono es un gas tóxico que impide el transporte de oxígeno en la sangre. Es incoloro e inodoro, por lo que puede pasar desapercibido. Produce mareos, náuseas y pérdida de conciencia, y en altas concentraciones puede ser mortal. Afecta a cualquier persona expuesta, pero es especialmente peligroso para bebés, ancianos y personas con enfermedades cardíacas. Se encuentra en gases de escape de vehículos, estufas mal ventiladas o incendios.';
    } else if (descripcionValue == 'NH₃') {
      descripcion1 =
          'El amoníaco es un gas con olor fuerte que puede irritar ojos, garganta y vías respiratorias. En altas concentraciones provoca quemaduras químicas y efectos crónicos en personas expuestas con frecuencia. Afecta principalmente a trabajadores rurales, de granjas o industrias químicas. Suele encontrarse en criaderos, plantas de fertilizantes o productos de limpieza industriales.';
    } else if (descripcionValue == 'TVOC') {
      descripcion1 =
          'Los TVOC son un conjunto de sustancias químicas que se evaporan fácilmente y contaminan el aire interior. Pueden causar irritación ocular, dolor de cabeza, mareos e incluso efectos cancerígenos a largo plazo (como el formaldehído). Afectan principalmente a niños, personas asmáticas y ancianos. Están presentes en pinturas, muebles nuevos, alfombras, adhesivos y productos de limpieza.';
    } else if (descripcionValue == 'PM2.5') {
      descripcion1 =
          'Las PM2.5 son partículas muy pequeñas que penetran en los pulmones y pueden llegar al torrente sanguíneo. Se asocian con enfermedades respiratorias, cardiovasculares y cáncer. Son especialmente peligrosas para niños, ancianos y personas con enfermedades pulmonares. Se generan en la quema de combustibles, tráfico vehicular, incendios y actividades industriales.';
    } else if (descripcionValue == 'PM10') {
      descripcion1 =
          'Las PM10 son partículas más grandes que las PM2.5, pero aún lo suficientemente pequeñas como para entrar en las vías respiratorias. Provocan tos, irritación nasal y empeoramiento de alergias. Son comunes en zonas con mucho polvo, obras en construcción, caminos de tierra o zonas urbanas con tránsito intenso.';
    }

    final mediciones = ['CO₂', 'CO', 'NH₃', 'TVOC', 'PM2.5', 'PM10'];

    return Scaffold(
      appBar: AppBar(title: const Text('Mediciones')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seleccionado: $descripcionValue',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // BLOQUE FIJO CON ALTURA CONSTANTE
            Container(
              height: 220, // espacio reservado para que no se mueva
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child:
                  descripcionValue.isNotEmpty
                      ? SingleChildScrollView(
                        child: Text(
                          descripcion1,
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
            const Divider(thickness: 1.5), // NO SE MUEVE MÁS

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
                  return ListTile(
                    leading: const Icon(Icons.blur_on),
                    title: Text(item),
                    selected: item == descripcionValue,
                    selectedTileColor: Colors.blue.shade100,
                    onTap: () {
                      ref.read(descripcion.notifier).state = item;
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: const CircleBorder(),
        ),
        onPressed: () {
          if (descripcionValue == '') {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Selecciona un gas')));
          } else {
            context.push('/lugar');
          }
        },
        child: const Icon(Icons.arrow_forward),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
