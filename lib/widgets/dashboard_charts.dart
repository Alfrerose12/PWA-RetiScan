import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardCharts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Estadísticas de Pacientes', style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  color: Colors.green,
                  value: 40,
                  title: '40% Normal',
                  radius: 50,
                  titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                PieChartSectionData(
                  color: Colors.orange,
                  value: 30,
                  title: '30% Leve',
                  radius: 50,
                  titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                PieChartSectionData(
                  color: Colors.red,
                  value: 30,
                  title: '30% Grave',
                  radius: 50,
                  titleStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
