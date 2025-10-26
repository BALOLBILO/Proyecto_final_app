import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

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

  static const _ambitosBA = <String>[
    'Ciudad Autónoma de Buenos Aires', // CABA
    'Buenos Aires', // Provincia de Buenos Aires
  ];

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }

  // Colorea según gas y valor
  Color _colorFor(String gas, double v) {
    switch (gas) {
      case 'pm25':
        return v < 15 ? Colors.green : (v < 35 ? Colors.orange : Colors.red);
      case 'pm10':
        return v < 30 ? Colors.green : (v < 50 ? Colors.orange : Colors.red);
      case 'tvoc':
        return v < 150 ? Colors.green : (v < 300 ? Colors.orange : Colors.red);
      case 'nh3':
        return v < 20 ? Colors.green : (v < 40 ? Colors.orange : Colors.red);
      case 'co':
        return v < 5 ? Colors.green : (v < 10 ? Colors.orange : Colors.red);
      case 'co2':
        return v < 800 ? Colors.green : (v < 1500 ? Colors.orange : Colors.red);
      default:
        return Colors.blueGrey;
    }
  }

  /// Carga mediciones y deja **un solo marcador por punto** (el más nuevo)
  Future<void> cargarDatos() async {
    setState(() => cargando = true);

    final gas = ref.read(gasSeleccionado); // 'co2', 'pm25', etc.

    final snapshot =
        await FirebaseFirestore.instance
            .collection('mediciones')
            .orderBy('timestamp', descending: true)
            .limit(1000)
            .get();

    // Agrupar por coord redondeada y quedarnos con el más nuevo
    final Map<String, Map<String, dynamic>> ultimas = {};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final lat = (data['latitud'] as num?)?.toDouble();
      final lon = (data['longitud'] as num?)?.toDouble();

      // timestamp robusto (soporta Timestamp y num)
      final tsField = data['timestamp'];
      int? ts;
      if (tsField is Timestamp) {
        ts = tsField.millisecondsSinceEpoch;
      } else if (tsField is num) {
        ts = tsField > 2000000000 ? tsField.toInt() : (tsField * 1000).toInt();
      }

      if (lat == null || lon == null || ts == null) continue;

      final key = '${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)}';
      final prevTs = (ultimas[key]?['__ts'] as int?) ?? -1;
      if (ts > prevTs) {
        ultimas[key] = {...data, 'latitud': lat, 'longitud': lon, '__ts': ts};
      }
    }

    // Crear marcadores (uno por punto) con color según el gas elegido
    final nuevos = <Marker>{};
    ultimas.forEach((key, data) {
      final lat = data['latitud'] as double;
      final lon = data['longitud'] as double;
      final valor = (data[gas] as num?)?.toDouble() ?? 0.0;

      final color = _colorFor(gas, valor);

      nuevos.add(
        Marker(
          markerId: MarkerId(key), // un marcador por coord redondeada
          position: LatLng(lat, lon),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            HSLColor.fromColor(color).hue,
          ),
          infoWindow: InfoWindow(
            title: '${gas.toUpperCase()}: ${valor.toStringAsFixed(1)}',
            snippet: '(${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)})',
          ),
        ),
      );
    });

    if (!mounted) return;
    setState(() {
      marcadores = nuevos;
      cargando = false;
    });
  }

  // ===== Buscador (CABA/Provincia BA) =====
  Future<void> _abrirBuscador() async {
    final direController = TextEditingController();
    String ambitoSel = _ambitosBA.first;

    final result = await showDialog<({String dir, String state})>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Buscar dirección'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: direController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Ej: Díaz Vélez 4048',
                    labelText: 'Dirección',
                  ),
                  onSubmitted: (_) {
                    Navigator.of(
                      ctx,
                    ).pop((dir: direController.text.trim(), state: ambitoSel));
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Ámbito'),
                  items:
                      _ambitosBA
                          .map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          )
                          .toList(),
                  value: ambitoSel,
                  onChanged: (v) => ambitoSel = v ?? _ambitosBA.first,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed:
                    () => Navigator.of(
                      ctx,
                    ).pop((dir: direController.text.trim(), state: ambitoSel)),
                child: const Text('Buscar'),
              ),
            ],
          ),
    );

    if (result == null || result.dir.isEmpty) return;
    await _buscarYEnfocar(dir: result.dir, state: result.state);
  }

  Future<void> _buscarYEnfocar({
    required String dir,
    required String state,
  }) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'street': dir,
      'state': state,
      'country': 'Argentina',
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '1',
    });

    try {
      final resp = await http
          .get(
            uri,
            headers: {
              'User-Agent': 'ProyectoFinalFlutter/1.0 (tu-email@dominio.com)',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (!mounted) return;

      if (resp.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Búsqueda falló (HTTP ${resp.statusCode})')),
        );
        return;
      }

      final List data = jsonDecode(resp.body);
      if (data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontró esa dirección en el ámbito elegido'),
          ),
        );
        return;
      }

      final lat = double.tryParse(data.first['lat'] ?? '');
      final lon = double.tryParse(data.first['lon'] ?? '');
      if (lat == null || lon == null) return;

      final ctrl = mapController;
      if (ctrl != null) {
        await ctrl.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: LatLng(lat, lon), zoom: 19.5),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error de red al buscar')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final gas = ref.watch(gasSeleccionado);

    return Scaffold(
      appBar: AppBar(
        title: Text("Mapa de ${gas.toUpperCase()}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _abrirBuscador,
            tooltip: 'Buscar dirección',
          ),
        ],
      ),
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
                    zoomControlsEnabled: true,
                    zoomGesturesEnabled: true,
                    onMapCreated: (controller) => mapController = controller,
                  ),
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
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
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
