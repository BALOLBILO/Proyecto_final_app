import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:proyecto_final_ok/presentation/chart_provider.dart';
import 'package:proyecto_final_ok/presentation/mediciones_provider.dart';

class GraficoGasScreen extends ConsumerWidget {
  const GraficoGasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gas = ref.watch(gasSeleccionado);
    final spotsAsync = ref.watch(serieGraficoProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Gráfico ${gas.toUpperCase()} (últimos 20)'),
        actions: [
          IconButton(
            tooltip: 'Inicio',
            icon: const Icon(Icons.home_rounded),
            onPressed: () => context.go('/inicio'),
          ),
        ],
      ),
      body: spotsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (spots) {
          if (spots.isEmpty) {
            return const Center(child: Text('Sin datos para graficar'));
          }

          final ys = spots.map((e) => e.y).toList();
          final double minY = math.max(0.0, ys.reduce(math.min) - 1.0);
          final double maxY = ys.reduce(math.max) + 1.0;
          final double maxX = (spots.length - 1).toDouble();

          return Padding(
            padding: const EdgeInsets.all(16.0), // <- EdgeInsets correcto
            child: LineChart(
              LineChartData(
                minX: 0.0,
                maxX: maxX,
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: true),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    spots: spots,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
