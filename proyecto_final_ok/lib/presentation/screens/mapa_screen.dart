import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart'; // 👈 necesario para obtener dirección

class MapaScreen extends StatefulWidget {
  const MapaScreen({Key? key}) : super(key: key);

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  GoogleMapController? mapController;
  LatLng? ubicacionActual;
  Set<Marker> marcadores = {};

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

  /// 🔹 Clasifica cada valor según el tipo de gas
  String nivelDeGas(String gas, double valor) {
    switch (gas) {
      case 'pm25':
        if (valor < 15) return 'Bajo';
        if (valor < 35) return 'Medio';
        return 'Alto';
      case 'pm10':
        if (valor < 30) return 'Bajo';
        if (valor < 50) return 'Medio';
        return 'Alto';
      case 'tvoc':
        if (valor < 150) return 'Bajo';
        if (valor < 300) return 'Medio';
        return 'Alto';
      case 'nh3':
        if (valor < 20) return 'Bajo';
        if (valor < 40) return 'Medio';
        return 'Alto';
      case 'co':
        if (valor < 5) return 'Bajo';
        if (valor < 10) return 'Medio';
        return 'Alto';
      case 'co2':
        if (valor < 800) return 'Bajo';
        if (valor < 1500) return 'Medio';
        return 'Alto';
      case 'no2':
        if (valor < 50) return 'Bajo';
        if (valor < 100) return 'Medio';
        return 'Alto';
      default:
        return '-';
    }
  }

  Future<void> cargarMediciones() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('mediciones').get();

    final Map<String, Map<String, dynamic>> ultimas = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final lat = (data['latitud'] as num?)?.toDouble() ?? 0.0;
      final lon = (data['longitud'] as num?)?.toDouble() ?? 0.0;
      final ts = (data['timestamp'] as num?)?.toInt() ?? 0;

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

    final nuevosMarcadores = <Marker>{};

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

      // 👇 Obtenemos la dirección usando geocoding
      String direccion = 'Cargando...';
      try {
        final placemarks = await placemarkFromCoordinates(lat, lon);
        if (placemarks.isNotEmpty) {
          final lugar = placemarks.first;
          direccion = [
            lugar.street,
            lugar.locality,
            lugar.subAdministrativeArea,
            lugar.administrativeArea,
            lugar.country,
          ].where((e) => e != null && e.isNotEmpty).join(', ');
        }
      } catch (_) {
        direccion = 'Ubicación desconocida';
      }

      nuevosMarcadores.add(
        Marker(
          markerId: MarkerId(e.key),
          position: LatLng(lat, lon),
          infoWindow: const InfoWindow(title: 'Tocar para ver detalles'),
          onTap: () {
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
                  Color color;
                  switch (nivel) {
                    case 'Bajo':
                      color = Colors.green;
                      break;
                    case 'Medio':
                      color = Colors.orange;
                      break;
                    case 'Alto':
                      color = Colors.red;
                      break;
                    default:
                      color = Colors.grey;
                  }
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
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        const SizedBox(height: 12),
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
      marcadores = nuevosMarcadores;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mapa de mediciones")),
      body:
          ubicacionActual == null
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
