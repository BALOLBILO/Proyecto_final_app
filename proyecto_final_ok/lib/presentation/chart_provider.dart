// chart_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:proyecto_final_ok/presentation/mediciones_provider.dart';
import 'package:proyecto_final_ok/presentation/firestore_provider.dart'; // medicionesPorCoordenadaProvider

final serieGraficoProvider = FutureProvider.autoDispose<List<FlSpot>>((
  ref,
) async {
  final gas = ref.watch(gasSeleccionado); // 'pm25', 'co2', etc.
  final meds = await ref.watch(medicionesPorCoordenadaProvider.future);

  // Orden cronológico (asc) y me quedo con los últimos 20
  final list = [...meds]..sort((a, b) {
    final ta = (a.timestamp is num) ? (a.timestamp as num).toInt() : 0;
    final tb = (b.timestamp is num) ? (b.timestamp as num).toInt() : 0;
    return ta.compareTo(tb);
  });
  final tail = list.length > 20 ? list.sublist(list.length - 20) : list;

  double valorDe(dynamic m) {
    switch (gas) {
      case 'pm25':
        return (m.pm25 ?? 0).toDouble();
      case 'pm10':
        return (m.pm10 ?? 0).toDouble();
      case 'tvoc':
        return (m.tvoc ?? 0).toDouble();
      case 'nh3':
        return (m.nh3 ?? 0).toDouble();
      case 'co':
        return (m.co ?? 0).toDouble();
      case 'co2':
        return (m.co2 ?? 0).toDouble();
      default:
        return 0.0;
    }
  }

  // x = índice (0..n-1), y = valor del gas
  return [
    for (var i = 0; i < tail.length; i++)
      FlSpot(i.toDouble(), valorDe(tail[i])),
  ];
});
