import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:proyecto_final_ok/presentation/coordenadas_provider.dart';
import 'package:proyecto_final_ok/presentation/lugar_provider.dart';

class LugarScreen extends ConsumerStatefulWidget {
  const LugarScreen({super.key});

  @override
  ConsumerState<LugarScreen> createState() => _LugarScreenState();
}

class _LugarScreenState extends ConsumerState<LugarScreen> {
  final TextEditingController controller = TextEditingController();
  List<dynamic> lugares = [];
  void buscarLugares(String query) async {
    if (query.isEmpty) {
      setState(() => lugares = []);
      return;
    }

    final url = Uri.parse(
      "https://nominatim.openstreetmap.org/search"
      "?q=${Uri.encodeComponent(query)}"
      "&countrycodes=AR"
      "&format=json"
      "&addressdetails=1"
      "&limit=5",
    );

    final response = await http.get(
      url,
      headers: {'User-Agent': 'miappflutter/1.0'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        lugares = data;
      });
    } else {
      setState(() => lugares = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lugarA = ref.watch(lugarPantalla);

    final lat = ref.watch(latitud);
    final lon = ref.watch(longitud);

    return Scaffold(
      appBar: AppBar(title: Text('Buscar lugar')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Ingrese ubicación',
                border: OutlineInputBorder(),
              ),
              onChanged: buscarLugares,
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: lugares.length,
                itemBuilder: (context, index) {
                  final lugar = lugares[index];
                  final displayName = lugar['display_name'];
                  final latFound = double.parse(lugar['lat']);
                  final lonFound = double.parse(lugar['lon']);

                  return ListTile(
                    title: Text(displayName),
                    subtitle: Text('Lat: $latFound, Lon: $lonFound'),
                    onTap: () {
                      ref.read(latitud.notifier).state = latFound;
                      ref.read(longitud.notifier).state = lonFound;
                      if (lugarA == 1) {
                        context.push('/coordenada');
                      } else if (lugarA == 2) {
                        context.push('/medicionPersonalizada');
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Guardado: Lat $latFound, Lon $lonFound',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Seleccionado: Lat: $lat, Lon: $lon",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
