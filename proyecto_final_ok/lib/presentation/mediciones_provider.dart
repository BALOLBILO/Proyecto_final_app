import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto_final_ok/entities/medicion.dart';

/// 🧠 Provider que guarda el gas seleccionado.
/// Ejemplos válidos: 'co2', 'tvoc', 'pm25', 'pm10', 'no2', 'co', 'nh3'
final gasSeleccionado = StateProvider<String>((ref) => 'co2');

/// 🔍 Provider que consulta Firestore y devuelve las 20 mediciones
/// con mayor valor del gas seleccionado.
final topMedicionesPorGasProvider = FutureProvider.autoDispose<List<Medicion>>((
  ref,
) async {
  final gas = ref.watch(gasSeleccionado); // 'co2', 'tvoc', etc.

  final snapshot =
      await FirebaseFirestore.instance
          .collection('mediciones')
          .orderBy(gas, descending: true)
          .limit(20)
          .get();

  return snapshot.docs.map((doc) => Medicion.fromMap(doc.data())).toList();
});
