import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({Key? key}) : super(key: key);

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  GoogleMapController? mapController;
  LatLng? ubicacionActual;
  Set<Marker> marcadores = {};
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    obtenerUbicacion().then((_) => cargarMediciones());
  }

  Future<void> obtenerUbicacion() async {
    bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      await Geolocator.openLocationSettings();
      return;
    }
    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) return;
    }
    if (permiso == LocationPermission.deniedForever) return;

    final posicion = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      ubicacionActual = LatLng(posicion.latitude, posicion.longitude);
    });
  }

  String nivelDeGas(String gas, double valor) {
    switch (gas) {
      case 'pm25':
        return valor < 15 ? 'Bajo' : (valor < 35 ? 'Medio' : 'Alto');
      case 'pm10':
        return valor < 30 ? 'Bajo' : (valor < 50 ? 'Medio' : 'Alto');
      case 'tvoc':
        return valor < 150 ? 'Bajo' : (valor < 300 ? 'Medio' : 'Alto');
      case 'nh3':
        return valor < 20 ? 'Bajo' : (valor < 40 ? 'Medio' : 'Alto');
      case 'co':
        return valor < 5 ? 'Bajo' : (valor < 10 ? 'Medio' : 'Alto');
      case 'co2':
        return valor < 800 ? 'Bajo' : (valor < 1500 ? 'Medio' : 'Alto');
      case 'no2':
        return valor < 50 ? 'Bajo' : (valor < 100 ? 'Medio' : 'Alto');
      default:
        return '-';
    }
  }

  Future<void> cargarMediciones() async {
    setState(() => cargando = true);

    // ⚠️ Traé sólo lo reciente / limitado (ajustá el número)
    final snapshot =
        await FirebaseFirestore.instance
            .collection('mediciones')
            .orderBy('timestamp', descending: true)
            .limit(500)
            .get();

    // Agrupa por coordenada redondeada para quedarte con la última en cada punto
    final Map<String, Map<String, dynamic>> ultimas = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final lat = (data['latitud'] as num?)?.toDouble();
      final lon = (data['longitud'] as num?)?.toDouble();
      final ts = (data['timestamp'] as num?)?.toInt();

      if (lat == null || lon == null || ts == null) continue;

      final key = '${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)}';
      if (!ultimas.containsKey(key) || ts > (ultimas[key]!['timestamp'] ?? 0)) {
        ultimas[key] = {
          ...data,
          'latitud': lat,
          'longitud': lon,
          'timestamp': ts,
        };
      }
    }

    final nuevos = <Marker>{};
    for (var e in ultimas.entries) {
      final data = e.value;
      final lat = data['latitud'] as double;
      final lon = data['longitud'] as double;

      final pm25 = (data['pm25'] as num?)?.toDouble() ?? 0.0;
      final pm10 = (data['pm10'] as num?)?.toDouble() ?? 0.0;
      final tvoc = (data['tvoc'] as num?)?.toDouble() ?? 0.0;
      final co2 = (data['co2'] as num?)?.toDouble() ?? 0.0;
      final no2 = (data['no2'] as num?)?.toDouble() ?? 0.0;
      final co = (data['co'] as num?)?.toDouble() ?? 0.0;
      final nh3 = (data['nh3'] as num?)?.toDouble() ?? 0.0;
      final fecha = data['fechaHora'] ?? 'sin fecha';

      nuevos.add(
        Marker(
          markerId: MarkerId(e.key),
          position: LatLng(lat, lon),
          infoWindow: const InfoWindow(title: 'Tocar para ver detalles'),
          onTap: () async {
            // 🔁 Geocoding bajo demanda (rápido para el usuario y sin bloquear el render)
            String direccion = 'Ubicación desconocida';
            try {
              final placemarks = await placemarkFromCoordinates(lat, lon);
              if (placemarks.isNotEmpty) {
                final p = placemarks.first;
                direccion = [
                  p.street,
                  p.locality,
                  p.subAdministrativeArea,
                  p.administrativeArea,
                  p.country,
                ].where((e) => e != null && e.isNotEmpty).join(', ');
              }
            } catch (_) {}

            if (!mounted) return;
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (context) {
                TextStyle label = const TextStyle(fontWeight: FontWeight.bold);
                TextStyle value = const TextStyle(fontSize: 15);

                Widget fila(
                  String nombre,
                  String unidad,
                  double valor,
                  String gasKey,
                ) {
                  final nivel = nivelDeGas(gasKey, valor);
                  Color color = switch (nivel) {
                    'Bajo' => Colors.green,
                    'Medio' => Colors.orange,
                    'Alto' => Colors.red,
                    _ => Colors.grey,
                  };
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$nombre:', style: label),
                        Text(
                          '${valor.toStringAsFixed(1)} $unidad   ($nivel)',
                          style: value.copyWith(color: color),
                        ),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        Text(
                          '📍 Ubicación: (${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('🏙️ Lugar: $direccion'),
                        const SizedBox(height: 8),
                        Text('🕒 Fecha: $fecha'),
                        const Divider(),
                        fila('PM2.5', 'µg/m³', pm25, 'pm25'),
                        fila('PM10', 'µg/m³', pm10, 'pm10'),
                        fila('TVOC', 'ppb', tvoc, 'tvoc'),
                        fila('CO₂', 'ppm', co2, 'co2'),
                        fila('NO₂', 'ppb', no2, 'no2'),
                        fila('CO', 'ppm', co, 'co'),
                        fila('NH₃', 'ppb', nh3, 'nh3'),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
    }

    setState(() {
      marcadores = nuevos;
      cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mapa de mediciones")),
      body:
          ubicacionActual == null || cargando
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: ubicacionActual!,
                  zoom: 13,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                markers: marcadores,
                onMapCreated: (controller) {
                  mapController = controller;
                },
              ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.refresh),
        onPressed: cargarMediciones,
      ),
    );
  }
}
