import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final medicionesFormateadasProvider = StreamProvider.autoDispose((ref) {
  return FirebaseFirestore.instance
      .collection('mediciones')
      .orderBy('timestamp', descending: true)
      .limit(20)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final ts = (data['timestamp'] ?? 0) as int;
          final dt = DateTime.fromMillisecondsSinceEpoch(ts);
          final fechaStr =
              "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
              "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

          return {
            'co2': (data['co2'] ?? 0).toDouble(),
            'pm25': (data['pm25'] ?? 0).toDouble(),
            'fecha': fechaStr,
          };
        }).toList();
      });
});
