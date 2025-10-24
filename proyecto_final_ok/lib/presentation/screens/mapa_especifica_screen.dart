import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:proyecto_final_ok/presentation/mediciones_provider.dart';

class MapaEspecificoScreen extends ConsumerStatefulWidget {
  const MapaEspecificoScreen({super.key});

  @override
  ConsumerState<MapaEspecificoScreen> createState() =>
      _MapaEspecificoScreenState();
}

class _MapaEspecificoScreenState extends ConsumerState<MapaEspecificoScreen> {
  GoogleMapController? mapController;
  Set<Marker> marcadores = {};
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  /// 🔥 Carga las mediciones desde Firestore y pinta los puntos según el gas seleccionado
  Future<void> cargarDatos() async {
    final gas = ref.read(gasSeleccionado); // ej: "co2", "pm25"
    final snapshot =
        await FirebaseFirestore.instance.collection('mediciones').get();

    final nuevosMarcadores =
        snapshot.docs.map((doc) {
          final data = doc.data();
          final lat = (data['latitud'] as num?)?.toDouble() ?? 0.0;
          final lon = (data['longitud'] as num?)?.toDouble() ?? 0.0;
          final valor = (data[gas] as num?)?.toDouble() ?? 0.0;

          // 🎨 Color según gas y valor (mismos rangos que tu switch)
          Color color;
          switch (gas) {
            case 'pm25':
              if (valor < 15)
                color = Colors.green;
              else if (valor < 35)
                color = Colors.orange;
              else
                color = Colors.red;
              break;

            case 'pm10':
              if (valor < 30)
                color = Colors.green;
              else if (valor < 50)
                color = Colors.orange;
              else
                color = Colors.red;
              break;

            case 'tvoc':
              if (valor < 150)
                color = Colors.green;
              else if (valor < 300)
                color = Colors.orange;
              else
                color = Colors.red;
              break;

            case 'nh3':
              if (valor < 20)
                color = Colors.green;
              else if (valor < 40)
                color = Colors.orange;
              else
                color = Colors.red;
              break;

            case 'co':
              if (valor < 5)
                color = Colors.green;
              else if (valor < 10)
                color = Colors.orange;
              else
                color = Colors.red;
              break;

            case 'co2':
              if (valor < 800)
                color = Colors.green;
              else if (valor < 1500)
                color = Colors.orange;
              else
                color = Colors.red;
              break;

            default:
              color = Colors.blueGrey;
          }

          return Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(lat, lon),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              HSLColor.fromColor(color).hue,
            ),
            infoWindow: InfoWindow(
              title: '${gas.toUpperCase()}: ${valor.toStringAsFixed(1)}',
              snippet: '(${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)})',
            ),
          );
        }).toSet();

    setState(() {
      marcadores = nuevosMarcadores;
      cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gas = ref.watch(gasSeleccionado);

    return Scaffold(
      appBar: AppBar(title: Text("Mapa de ${gas.toUpperCase()}")),
      body:
          cargando
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(-34.6037, -58.3816), // Centro Buenos Aires
                      zoom: 12,
                    ),
                    markers: marcadores,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    onMapCreated: (controller) => mapController = controller,
                  ),

                  // 🟢🟠🔴 Leyenda flotante
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Card(
                      elevation: 6,
                      color: Colors.white.withOpacity(0.9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: const [
                            _ColorLegend(color: Colors.green, label: 'Bajo'),
                            _ColorLegend(
                              color: Colors.orange,
                              label: 'Mediano',
                            ),
                            _ColorLegend(color: Colors.red, label: 'Alto'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: cargarDatos,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

/// Pequeño widget para los ítems de la leyenda
class _ColorLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ColorLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
