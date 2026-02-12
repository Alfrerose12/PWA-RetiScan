import 'package:flutter/material.dart';
import '../models/analysis.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;

  final List<EyeAnalysis> analysisHistory = [
    EyeAnalysis(
      id: '1',
      date: DateTime(2024, 11, 15, 14, 30),
      status: 'Normal',
      imagePath: '',
      medicalInfo: {},
    ),
    EyeAnalysis(
      id: '2',
      date: DateTime(2024, 11, 1, 10, 15),
      status: 'Normal',
      imagePath: '',
      medicalInfo: {},
    ),
    EyeAnalysis(
      id: '3',
      date: DateTime(2024, 10, 15, 16, 45),
      status: 'Leve',
      imagePath: '',
      medicalInfo: {},
    ),
    EyeAnalysis(
      id: '4',
      date: DateTime(2024, 10, 1, 9, 0),
      status: 'Normal',
      imagePath: '',
      medicalInfo: {},
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimations = List.generate(
      analysisHistory.length,
      (index) => Tween<Offset>(
        begin: Offset(0.3, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.15,
            0.5 + (index * 0.15),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    _fadeAnimations = List.generate(
      analysisHistory.length,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.15,
            0.5 + (index * 0.15),
            curve: Curves.easeIn,
          ),
        ),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Normal':
        return Colors.green;
      case 'Leve':
        return Colors.orange;
      case 'Moderado':
        return Colors.deepOrange;
      case 'Severo':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Normal':
        return Icons.check_circle;
      case 'Leve':
        return Icons.warning;
      case 'Moderado':
        return Icons.error;
      case 'Severo':
        return Icons.dangerous;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Histórico de Análisis',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2D385E).withOpacity(0.1),
                  Color(0xFF5258A4).withOpacity(0.1),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF5258A4).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.timeline,
                    color: Color(0xFF5258A4),
                    size: 28,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total de Análisis',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${analysisHistory.length} registros',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D385E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: analysisHistory.length,
              itemBuilder: (context, index) {
                final analysis = analysisHistory[index];
                return SlideTransition(
                  position: _slideAnimations[index],
                  child: FadeTransition(
                    opacity: _fadeAnimations[index],
                    child: _buildHistoryCard(analysis, index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(EyeAnalysis analysis, int index) {
    final statusColor = _getStatusColor(analysis.status);
    final statusIcon = _getStatusIcon(analysis.status);
    final isLeft = index % 2 == 0;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          if (!isLeft) Expanded(child: SizedBox()),
          if (!isLeft) _buildTimelineDot(statusColor),
          if (!isLeft) SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.1),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: statusColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {},
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                statusIcon,
                                color: statusColor,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${analysis.date.day}/${analysis.date.month}/${analysis.date.year}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF2D385E),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '${analysis.date.hour}:${analysis.date.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            analysis.status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isLeft) SizedBox(width: 16),
          if (isLeft) _buildTimelineDot(statusColor),
          if (isLeft) Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildTimelineDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}