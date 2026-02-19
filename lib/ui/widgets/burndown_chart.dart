import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:praxis/services/app_provider.dart';
import 'package:praxis/theme/app_theme.dart';
import 'package:praxis/ui/widgets/glass_container.dart';

class BurndownChart extends StatelessWidget {
  const BurndownChart({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final sprint = provider.activeSprint;
    final cards = provider.cards;
    final theme = Theme.of(context);

    if (sprint == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.white10),
            const SizedBox(height: 16),
            const Text('No active sprint',
                style: TextStyle(color: Colors.white38, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Create a sprint to see burndown data.',
                style: TextStyle(color: Colors.white24, fontSize: 12)),
          ],
        ),
      );
    }

    final totalPoints =
        cards.fold<int>(0, (sum, c) => sum + c.points);
    final duration =
        sprint.endDate.difference(sprint.startDate).inDays + 1;

    final idealSpots = [
      FlSpot(0, totalPoints.toDouble()),
      FlSpot(duration.toDouble(), 0),
    ];

    final completedPoints = cards
        .where((c) => c.columnId == 3)
        .fold<int>(0, (sum, c) => sum + c.points);
    final pendingPoints = totalPoints - completedPoints;
    final daysElapsed =
        DateTime.now().difference(sprint.startDate).inDays;
    final validDay = daysElapsed.clamp(0, duration);

    final actualSpots = [
      FlSpot(0, totalPoints.toDouble()),
      FlSpot(validDay.toDouble(), pendingPoints.toDouble()),
    ];

    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chart title + legend
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sprint Burndown',
                    style: theme.textTheme.displayMedium?.copyWith(
                        fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    sprint.name,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Stats boxes
            _statBox('Total', '$totalPoints pts', Colors.white38),
            const SizedBox(width: 12),
            _statBox('Done',
                '${completedPoints} pts', AppTheme.accent),
            const SizedBox(width: 12),
            _statBox('Remaining',
                '${pendingPoints} pts', AppTheme.secondary),
          ],
        ),
        const SizedBox(height: 8),
        // Legend
        Row(
          children: [
            _legendItem('Ideal', Colors.white30, isDashed: true),
            const SizedBox(width: 20),
            _legendItem('Actual', primaryColor),
          ],
        ),
        const SizedBox(height: 24),

        // Chart
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                getDrawingHorizontalLine: (value) =>
                    const FlLine(color: Colors.white10, strokeWidth: 1),
                getDrawingVerticalLine: (value) =>
                    const FlLine(color: Colors.white10, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  axisNameWidget: const Text('Story Points',
                      style:
                          TextStyle(color: Colors.white38, fontSize: 10)),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  axisNameWidget: const Text('Days',
                      style:
                          TextStyle(color: Colors.white38, fontSize: 10)),
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: (duration / 5).ceilToDouble().clamp(1, 999),
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'D${value.toInt()}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10),
                      ),
                    ),
                  ),
                ),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.white10)),
              minX: 0,
              maxX: duration.toDouble(),
              minY: 0,
              maxY: (totalPoints > 0 ? totalPoints + 3 : 10).toDouble(),
              lineBarsData: [
                // Ideal
                LineChartBarData(
                  spots: idealSpots,
                  isCurved: false,
                  color: Colors.white24,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  dashArray: [6, 4],
                ),
                // Actual
                LineChartBarData(
                  spots: actualSpots,
                  isCurved: true,
                  color: primaryColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, pct, barData, idx) =>
                        FlDotCirclePainter(
                      radius: 5,
                      color: secondaryColor,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withOpacity(0.25),
                        primaryColor.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _statBox(String label, String value, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      opacity: 0.08,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color)),
          Text(label,
              style:
                  const TextStyle(fontSize: 10, color: Colors.white38)),
        ],
      ),
    );
  }

  static Widget _legendItem(String label, Color color,
      {bool isDashed = false}) {
    return Row(
      children: [
        CustomPaint(
          size: const Size(28, 2),
          painter: _LinePainter(color, isDashed),
        ),
        const SizedBox(width: 6),
        Text(label,
            style:
                const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  final Color color;
  final bool isDashed;
  _LinePainter(this.color, this.isDashed);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    if (isDashed) {
      double x = 0;
      while (x < size.width) {
        canvas.drawLine(
            Offset(x, size.height / 2),
            Offset((x + 4).clamp(0, size.width), size.height / 2),
            paint);
        x += 8;
      }
    } else {
      canvas.drawLine(
          const Offset(0, 1), Offset(size.width, 1), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
