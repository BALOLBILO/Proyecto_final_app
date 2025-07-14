import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto_final_ok/entities/medicion.dart';

final medicionesProvider = FutureProvider.autoDispose<List<Medicion>>((
  ref,
) async {
  final snapshot =
      await FirebaseFirestore.instance
          .collection('mediciones')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

  print("Firestore emitió ${snapshot.docs.length} documentos");

  return snapshot.docs
      .map((doc) => Medicion.fromMap(doc.data() as Map<String, dynamic>))
      .toList();
});
