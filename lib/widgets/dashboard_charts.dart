import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class DashboardCharts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.primary;

    return SfCircularChart(
      margin: EdgeInsets.zero,
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CircularSeries>[
        DoughnutSeries<_ChartData, String>(
          dataSource: _sampleData,
          xValueMapper: (_ChartData data, _) => data.category,
          yValueMapper: (_ChartData data, _) => data.value,
          pointColorMapper: (_ChartData data, _) => data.color,
          innerRadius: '65%',
          radius: '85%',
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            labelPosition: ChartDataLabelPosition.outside,
            textStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
            ),
            connectorLineSettings: ConnectorLineSettings(
              length: '12%',
              color: Theme.of(context).dividerColor.withOpacity(0.3),
            ),
          ),
          enableTooltip: true,
          animationDuration: 800,
          explode: true,
          explodeIndex: 0,
          explodeOffset: '5%',
          strokeColor: Theme.of(context).scaffoldBackgroundColor,
          strokeWidth: 2,
        ),
      ],
    );
  }

  static final List<_ChartData> _sampleData = [
    _ChartData('Normal', 40, Colors.cyanAccent),
    _ChartData('Leve', 30, Colors.pinkAccent),
    _ChartData('Moderado', 20, Colors.amber),
    _ChartData('Grave', 10, Colors.redAccent),
  ];
}

class _ChartData {
  final String category;
  final double value;
  final Color color;
  _ChartData(this.category, this.value, this.color);
}
