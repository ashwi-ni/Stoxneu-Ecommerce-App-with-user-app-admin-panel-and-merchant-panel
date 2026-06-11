import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalesChart extends StatelessWidget {
  final List<DateTime> dates;
  final List<double> totals;

  const SalesChart({
  super.key,
  required this.dates,
  required this.totals,
  });

  @override
  Widget build(BuildContext context) {
    if (dates.isEmpty || totals.isEmpty) {
      return const Center(child: Text("No sales data"));
    }

    // 🔹 Build last 7 days map (with 0 values)
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 6));

    final Map<DateTime, double> salesMap = {};

    for (int i = 0; i < 7; i++) {
      final day = DateTime(start.year, start.month, start.day + i);
      salesMap[day] = 0;
    }

    // 🔹 Fill actual data
    for (int i = 0; i < dates.length; i++) {
      final d = DateTime(dates[i].year, dates[i].month, dates[i].day);

      if (salesMap.containsKey(d)) {
        salesMap[d] = salesMap[d]! + totals[i];
      }
    }

    final chartDates = salesMap.keys.toList();
    final chartTotals = salesMap.values.toList();

    // 🔹 Create spots
    final spots = chartTotals.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

    return LineChart(
      LineChartData(
        minY: 0,

        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
        ),

        borderData: FlBorderData(
          show: true,
          border: const Border(
            left: BorderSide(),
            bottom: BorderSide(),
          ),
        ),

        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= chartDates.length) {
                  return const SizedBox.shrink();
                }

                return Text(
                  DateFormat('dd MMM').format(chartDates[index]),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),

          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
            ),
          ),

          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),

          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),

        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            color: Colors.blue,

            dotData: FlDotData(show: true),

            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.2),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final index = spot.x.toInt();

                if (index < 0 || index >= chartDates.length) {
                  return null;
                }

                final date = chartDates[index];
                final value = spot.y;

                return LineTooltipItem(
                  "${DateFormat('dd MMM').format(date)}\n₹${value.toStringAsFixed(2)}",
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}