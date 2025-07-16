import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto_final_ok/entities/medicion.dart';
import 'package:proyecto_final_ok/presentation/coordenadas_provider.dart';

final medicionesPorCoordenadaProvider =
    FutureProvider.autoDispose<List<Medicion>>((ref) async {
      final lat = ref.watch(latitud);
      final lon = ref.watch(longitud);

      print("Buscando en Firestore cerca de lat: $lat, lon: $lon (±0.002)");

      final snapshot =
          await FirebaseFirestore.instance
              .collection('mediciones')
              .where('latitud', isGreaterThanOrEqualTo: lat - 0.002)
              .where('latitud', isLessThanOrEqualTo: lat + 0.002)
              .where('longitud', isGreaterThanOrEqualTo: lon - 0.002)
              .where('longitud', isLessThanOrEqualTo: lon + 0.002)
              .orderBy('latitud')
              .orderBy('longitud')
              .orderBy('timestamp', descending: true)
              .limit(20)
              .get();

      return snapshot.docs
          .map((doc) => Medicion.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
