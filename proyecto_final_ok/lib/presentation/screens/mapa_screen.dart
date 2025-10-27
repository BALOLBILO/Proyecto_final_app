import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart'; // 👈 para ir a /inicio
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyecto_final_ok/presentation/coordenadas_provider.dart';

class MapaScreen extends StatefulWidget {
  final LatLng? focoInicial; // opcional: centra acá con zoom alto
  const MapaScreen({super.key, this.focoInicial});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final Completer<GoogleMapController> _ctrlCompleter = Completer();
  GoogleMapController? mapController;

  LatLng? ubicacionActual;
  Set<Marker> marcadores = {};
  bool cargando = true;

  BitmapDescriptor? _greyIcon;
  bool _didFocusOnce = false;

  static const _ambitosBA = <String>[
    'Ciudad Autónoma de Buenos Aires', // CABA
    'Buenos Aires', // Provincia de Buenos Aires
  ];

  @override
  void initState() {
    super.initState();
    _makeGreyPin(size: 96).then((icon) {
      if (mounted) setState(() => _greyIcon = icon);
    });
    if (widget.focoInicial == null) obtenerUbicacion();
    cargarMediciones();
  }

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }

  // ===== Icono gris custom =====
  Future<BitmapDescriptor> _makeGreyPin({int size = 96}) async {
    final rec = ui.PictureRecorder();
    final canvas = ui.Canvas(rec);
    final fill = ui.Paint()..color = const ui.Color(0xFF9E9E9E); // gris 500
    final stroke =
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = size * 0.06
          ..color = const ui.Color(0xFF616161); // gris 700

    final r = size * 0.35;
    final c = ui.Offset(size / 2, size / 2 - size * 0.1);

    canvas.drawCircle(c, r, fill);
    canvas.drawCircle(c, r, stroke);

    final path =
        ui.Path()
          ..moveTo(size / 2, size.toDouble() - size * 0.1)
          ..lineTo(c.dx - r * 0.5, c.dy + r * 0.4)
          ..lineTo(c.dx + r * 0.5, c.dy + r * 0.4)
          ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);

    final img = await rec.endRecording().toImage(size, size);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(Uint8List.view(bytes!.buffer));
  }

  // ===== Ubicación actual =====
  Future<void> obtenerUbicacion() async {
    final servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      await Geolocator.openLocationSettings();
      return;
    }
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) return;
    }
    if (permiso == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    if (!mounted) return;
    setState(() => ubicacionActual = LatLng(pos.latitude, pos.longitude));
  }

  // ===== Clasificación (detalle) =====
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

  // ===== Cargar mediciones (última por coord) =====
  Future<void> cargarMediciones() async {
    setState(() => cargando = true);

    final snapshot =
        await FirebaseFirestore.instance
            .collection('mediciones')
            .orderBy('timestamp', descending: true)
            .limit(500)
            .get();

    final Map<String, Map<String, dynamic>> ultimas = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();

      final lat = (data['latitud'] as num?)?.toDouble();
      final lon = (data['longitud'] as num?)?.toDouble();

      // timestamp robusto: soporta Timestamp o num
      final tsField = data['timestamp'];
      int? ts;
      if (tsField is Timestamp) {
        ts = tsField.millisecondsSinceEpoch;
      } else if (tsField is num) {
        // si vino en segundos → pasamos a ms
        ts = tsField > 2000000000 ? tsField.toInt() : (tsField * 1000).toInt();
      }

      if (lat == null || lon == null || ts == null) continue;

      final key = '${lat.toStringAsFixed(4)},${lon.toStringAsFixed(4)}';
      if (!ultimas.containsKey(key) || ts > (ultimas[key]!['__ts'] ?? 0)) {
        ultimas[key] = {
          ...data,
          'latitud': lat,
          'longitud': lon,
          '__ts': ts, // auxiliar interno para dedup
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
          icon: _greyIcon ?? BitmapDescriptor.defaultMarker, // gris
          infoWindow: const InfoWindow(title: 'Tocar para ver detalles'),
          onTap: () async {
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
                return Consumer(
                  builder: (context, ref, _) {
                    TextStyle label = const TextStyle(
                      fontWeight: FontWeight.bold,
                    );
                    TextStyle value = const TextStyle(fontSize: 15);

                    Widget fila(
                      String nombre,
                      String unidad,
                      double val,
                      String gasKey,
                    ) {
                      final nivel = nivelDeGas(gasKey, val);
                      final color = switch (nivel) {
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
                              '${val.toStringAsFixed(1)} $unidad   ($nivel)',
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
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

                            // ⬇️ Botón: setea providers y navega a /coordenada
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.location_on_rounded),
                                label: const Text('Ver mediciones'),
                                onPressed: () {
                                  ref.read(latitud.notifier).state = lat;
                                  ref.read(longitud.notifier).state = lon;
                                  Navigator.of(
                                    context,
                                  ).pop(); // cerrar bottom sheet
                                  context.push('/coordenada'); // ir a la screen
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      marcadores = nuevos;
      cargando = false;
    });

    // Reintento de foco a zoom alto al terminar de cargar
    if (widget.focoInicial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _focusToMax(widget.focoInicial!);
      });
    }
  }

  // ===== Enfoque/zoom alto =====
  Future<void> _focusToMax(LatLng target) async {
    if (_didFocusOnce) return; // solo una vez
    _didFocusOnce = true;
    final ctrl = mapController ?? await _ctrlCompleter.future;
    await ctrl.animateCamera(CameraUpdate.newLatLngZoom(target, 20.0));
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

      if (resp.statusCode != 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Búsqueda falló (HTTP ${resp.statusCode})')),
        );
        return;
      }

      final List data = jsonDecode(resp.body);
      if (data.isEmpty) {
        if (!mounted) return;
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

      final ctrl = mapController ?? await _ctrlCompleter.future;
      await ctrl.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lon), 20.0), // zoom alto
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error de red al buscar')));
    }
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    final target =
        widget.focoInicial ??
        ubicacionActual ??
        const LatLng(-34.6037, -58.3816);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mapa de mediciones"),
        actions: [
          IconButton(
            tooltip: 'Inicio',
            icon: const Icon(Icons.home_rounded), // 👈 botón casa
            onPressed: () => context.go('/inicio'),
          ),
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
              : GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: target,
                  zoom:
                      widget.focoInicial != null ? 17 : 13, // luego forzamos 20
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
                zoomGesturesEnabled: true,
                markers: marcadores,
                onMapCreated: (controller) async {
                  mapController = controller;
                  if (!_ctrlCompleter.isCompleted) {
                    _ctrlCompleter.complete(controller);
                  }
                  if (widget.focoInicial != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      await Future.delayed(const Duration(milliseconds: 150));
                      await _focusToMax(widget.focoInicial!);
                    });
                  }
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: cargarMediciones,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
