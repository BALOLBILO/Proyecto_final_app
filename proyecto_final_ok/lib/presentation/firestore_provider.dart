import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto_final_ok/entities/medicion.dart';
import 'package:proyecto_final_ok/presentation/coordenadas_provider.dart';

final medicionesPorCoordenadaProvider = FutureProvider.autoDispose<
  List<Medicion>
>((ref) async {
  final lat = ref.watch(latitud);
  final lon = ref.watch(longitud);

  // 1) Trae los "primeros 20" según orden espacial (lat, lon)
  final qs =
      await FirebaseFirestore.instance
          .collection('mediciones')
          .where('latitud', isGreaterThanOrEqualTo: lat - 0.002)
          .where('latitud', isLessThanOrEqualTo: lat + 0.002)
          .where('longitud', isGreaterThanOrEqualTo: lon - 0.002)
          .where('longitud', isLessThanOrEqualTo: lon + 0.002)
          .orderBy('latitud')
          .orderBy('longitud')
          .limit(20)
          .get();

  // Helper robusto para sacar DateTime del campo timestamp/fechaHora
  DateTime tsOf(Map<String, dynamic> data) {
    final t = data['timestamp'];
    if (t is Timestamp) return t.toDate(); // Firestore Timestamp
    if (t is num) {
      // si vino en segundos → ms; si ya es ms, lo tomamos directo
      final ms = t > 2000000000 ? t.toInt() : (t * 1000).toInt();
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    final fh = data['fechaHora'];
    if (fh is String && fh.isNotEmpty) {
      final iso = fh.contains('T') ? fh : fh.replaceFirst(' ', 'T');
      return DateTime.tryParse(iso) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  // 2) Parseo + orden en memoria por timestamp DESC
  final items =
      qs.docs.map((d) {
          final data = d.data();
          return {'med': Medicion.fromMap(data), 'ts': tsOf(data)};
        }).toList()
        ..sort((a, b) => (b['ts'] as DateTime).compareTo(a['ts'] as DateTime));

  return items.map((e) => e['med'] as Medicion).toList();
});
