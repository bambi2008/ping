import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../app/theme.dart';

/// Monthly spending trend line chart using fl_chart.
/// Shows up to 6 months of history.
class TrendChart extends StatelessWidget {
  final List<MapEntry<DateTime, double>> data;
  final String currencySymbol;
  final double currentMonthTotal;

  const TrendChart({
    super.key,
    required this.data,
    required this.currencySymbol,
    required this.currentMonthTotal,
  });

  @override
  Widget build(BuildContext context) {
    // Build chart data points: historical + current month
    final spots = <FlSpot>[];
    final labels = <String, double>{}; // x → label

    if (data.isEmpty) {
      // Just show current month as a single point
      spots.add(FlSpot(0, currentMonthTotal));
      labels['${_monthLabel(DateTime.now())}'] = 0;
    } else {
      for (int i = 0; i < data.length; i++) {
        spots.add(FlSpot(i.toDouble(), data[i].value));
        labels['${_monthLabel(data[i].key)}'] = i.toDouble();
      }
      // Add current month as the last point
      final lastX = data.length.toDouble();
      spots.add(FlSpot(lastX, currentMonthTotal));
      labels['${_monthLabel(DateTime.now())}'] = lastX;
    }

    final maxY = spots.isEmpty
        ? 100.0
        : (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b)) * 1.15;
    final minY = 0.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = PingTheme.primary;
    final gridColor = PingTheme.hairlineBorder(context);
    final labelColor = PingTheme.subtleText(context);

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _niceInterval(maxY),
            getDrawingHorizontalLine: (value) => FlLine(
              color: gridColor,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: _niceInterval(maxY),
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(
                    '$currencySymbol${value.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: labelColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final label = labels.entries
                      .where((e) => e.value == value)
                      .map((e) => e.key)
                      .firstOrNull;
                  if (label == null) return const SizedBox.shrink();
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        color: labelColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (spots.length - 1).toDouble().clamp(0, double.infinity),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              preventCurveOverShooting: true,
              color: lineColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    lineColor.withValues(alpha: 0.20),
                    lineColor.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '$currencySymbol${spot.y.toStringAsFixed(2)}',
                    TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  double _niceInterval(double maxY) {
    if (maxY <= 50) return 10;
    if (maxY <= 100) return 20;
    if (maxY <= 500) return 100;
    if (maxY <= 1000) return 200;
    return (maxY / 5).roundToDouble();
  }

  String _monthLabel(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[d.month - 1];
  }
}
