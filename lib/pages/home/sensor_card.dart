import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ndn_sensor_app/extensions.dart';
import 'package:ndn_sensor_app/labeled_text.dart';
import 'package:ndn_sensor_app/provided/sensor_data_handler.dart';
import 'package:provider/provider.dart';

class SensorCard extends StatefulWidget {
  final String ndnPath;
  final String title;

  const SensorCard({
    required this.ndnPath,
    required this.title,
    super.key,
  });

  @override
  State<SensorCard> createState() => _SensorCardState();
}

class _SensorCardState extends State<SensorCard> {
  LineChartData chartData(List<double> history) {
    var colorScheme = Theme.of(context).colorScheme;
    var gradientColors = [
      colorScheme.inversePrimary,
      colorScheme.primary,
    ];
    var gridColor = colorScheme.onSurface.withOpacity(0.2);
    var intervalY = 5.0;
    var relevantHistory = history.lastNElements(15 * 3).averageNElements(3).map((e) => e.roundToN(2)).toList();
    var minY = 0.0;
    var maxY = 30.0;
    if (relevantHistory.isNotEmpty) {
      minY = min((relevantHistory.reduce((a, b) => min(a, b)) / intervalY).floorToDouble() * intervalY, 0);
      maxY = ((relevantHistory.reduce((a, b) => max(a, b)) * 1.2) / intervalY).roundToDouble() * intervalY;
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 5,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          if (value == 0) {
            return FlLine(
              color: Colors.blue,
              strokeWidth: 2,
            );
          }

          return FlLine(
            color: gridColor,
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: gridColor,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) => Text(""),
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: intervalY,
            getTitlesWidget: (value, meta) => Text("${value.round()}"),
            reservedSize: 30,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d)),
      ),
      minX: 0,
      maxX: max(relevantHistory.length.toDouble() - 1, 0),
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: relevantHistory.indexed.map<FlSpot>((e) => FlSpot(e.$1.toDouble(), e.$2.roundToN(2))).toList(),
          isCurved: true,
          gradient: LinearGradient(
            colors: gradientColors,
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(
            show: true,
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: gradientColors.map((color) => color.withOpacity(0.3)).toList(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var sensorDataHandler = context.read<SensorDataHandler>();

    return ChangeNotifierProvider.value(
      value: sensorDataHandler.getData(widget.ndnPath),
      builder: (context, child) {
        return Consumer<SensorData>(
          builder: (context, value, child) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                height: 280,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.sensors_rounded, size: 30),
                            SizedBox(width: 10),
                            Expanded(
                              child: LabeledText.bottom(
                                text: "${widget.title}  -  ${value.lastItem?.roundToNPadded(2)} °C",
                                labelText: widget.ndnPath,
                                textStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                                labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Divider(),
                        ),
                        Expanded(
                          child: LineChart(
                            chartData(value.history),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
