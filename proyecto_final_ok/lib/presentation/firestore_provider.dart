import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto_final_ok/entities/medicion.dart';
import 'package:proyecto_final_ok/presentation/coordenadas_provider.dart';

final medicionesPorCoordenadaProvider = FutureProvider.autoDispose<
  List<Medicion>
>((ref) async {
  final lat = ref.watch(latitud);
  final lon = ref.watch(longitud);

  // 🔧 Radio en km (0.05 = 50 m). Ajustalo si hace falta.
  const radiusKm = 0.05;

  // (Opcional) ventana temporal para no traer “todo”
  // final since = DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;

  // 1) Leemos TODAS las subcolecciones llamadas 'mediciones'
  final qs =
      await FirebaseFirestore.instance
          .collectionGroup('mediciones')
          // .where('timestamp', isGreaterThan: since) // <- opcional si guardás ms
          .limit(2000) // subí/bajá para test. Luego podés reducir.
          .get();

  print('📄 collectionGroup -> leídos: ${qs.docs.length} docs');

  // 2) Distancia Haversine (km)
  double dKm(double la1, double lo1, double la2, double lo2) {
    const R = 6371.0;
    final dLat = (la2 - la1) * pi / 180;
    final dLon = (lo2 - lo1) * pi / 180;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(la1 * pi / 180) *
            cos(la2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  DateTime tsOf(Map<String, dynamic> m) {
    final t = m['timestamp'];
    if (t is Timestamp) return t.toDate();
    if (t is num) {
      final ms = t > 2000000000 ? t.toInt() : (t * 1000).toInt();
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    final fh = m['fechaHora'];
    if (fh is String && fh.isNotEmpty) {
      final iso = fh.contains('T') ? fh : fh.replaceFirst(' ', 'T');
      return DateTime.tryParse(iso) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  // 3) Filtramos por radio
  final nearby = <Map<String, dynamic>>[];
  for (final doc in qs.docs) {
    final m = doc.data() as Map<String, dynamic>;
    final la = (m['latitud'] as num?)?.toDouble();
    final lo = (m['longitud'] as num?)?.toDouble();
    if (la == null || lo == null) continue;
    if (dKm(lat, lon, la, lo) <= radiusKm) nearby.add(m);
  }

  print(
    '🔍 Dentro de ${(radiusKm * 1000).toStringAsFixed(0)} m: ${nearby.length} docs',
  );

  // 4) Ordenamos por fecha desc y devolvemos 20
  nearby.sort((a, b) => tsOf(b).compareTo(tsOf(a)));
  final top20 = nearby.take(20).map((m) => Medicion.fromMap(m)).toList();
  return top20;
});
