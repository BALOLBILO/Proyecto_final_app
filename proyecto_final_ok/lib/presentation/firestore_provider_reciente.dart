import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto_final_ok/entities/medicion.dart';

final ultimas50MedicionesStreamProvider =
    StreamProvider.autoDispose<List<Medicion>>((ref) {
      return FirebaseFirestore.instance
          .collection('mediciones')
          .where(
            'timestamp',
            isGreaterThan: 0,
          ) // ✅ filtra los que tienen timestamp válido
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots()
          .map(
            (snap) =>
                snap.docs.map((d) {
                  final data = d.data();
                  print("🕒 ${data['timestamp']}"); // para debug
                  return Medicion.fromMap(data);
                }).toList(),
          );
    });
