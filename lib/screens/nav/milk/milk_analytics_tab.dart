// milk_analytics_tab.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math' as math;
import '../../../models/milk.dart';
import '../../../models/goat.dart';
import '../../../constants/app_colors.dart';

class MilkAnalyticsTab extends StatefulWidget {
  final List<MilkProduction> milkRecords;
  final List<Goat> allGoats;

  const MilkAnalyticsTab({
    super.key,
    required this.milkRecords,
    required this.allGoats,
  });

  @override
  State<MilkAnalyticsTab> createState() => _MilkAnalyticsTabState();
}

class _MilkAnalyticsTabState extends State<MilkAnalyticsTab> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String selectedPeriod = 'Last 7 Days';
  String selectedChartType = 'Line';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.milkRecords.isEmpty) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductionTrendsCard(),
            const SizedBox(height: 24),
            _buildProductionAnalysisCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.chartLine,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Data for Analytics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some milk production records to see analytics',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  Widget _buildProductionTrendsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Production Trends',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _buildPeriodSelector(),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: _buildProductionChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['Last 7 Days', 'Last 30 Days', 'Last 3 Months'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedPeriod,
          items: periods.map((period) => DropdownMenuItem(
            value: period,
            child: Text(
              period,
              style: const TextStyle(fontSize: 12),
            ),
          )).toList(),
          onChanged: (value) => setState(() => selectedPeriod = value!),
        ),
      ),
    );
  }

  Widget _buildProductionChart() {
    final chartData = _getChartData();

    if (chartData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FontAwesomeIcons.chartLine, color: Colors.grey.shade400, size: 32),
            const SizedBox(height: 8),
            Text('No data available', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return CustomPaint(
      size: const Size(double.infinity, 250),
      painter: LineChartPainter(chartData, AppColors.primary),
    );
  }


  Widget _buildProductionAnalysisCard() {
    final analysis = _calculateProductionAnalysis();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.chartBar, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Production Analysis',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAnalysisItem(
                  'Morning Production',
                  '${analysis['morningTotal']!.toStringAsFixed(1)} L',
                  '${analysis['morningPercentage']!.toStringAsFixed(1)}%',
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalysisItem(
                  'Evening Production',
                  '${analysis['eveningTotal']!.toStringAsFixed(1)} L',
                  '${analysis['eveningPercentage']!.toStringAsFixed(1)}%',
                  Colors.indigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const FaIcon(FontAwesomeIcons.lightbulb, color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    analysis['insight']!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildAnalysisItem(String title, String value, String percentage, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            percentage,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

// Data calculation methods

  List<ChartDataPoint> _getChartData() {
    final now = DateTime.now();
    final days = selectedPeriod == 'Last 7 Days' ? 7 : selectedPeriod == 'Last 30 Days' ? 30 : 90;

    final Map<String, double> dailyTotals = {};

    for (final record in widget.milkRecords) {
      final daysDiff = now.difference(record.recordDate).inDays;
      if (daysDiff <= days) {
        final dateKey = '${record.recordDate.day}/${record.recordDate.month}';
        dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + (record.totalYield ?? 0);
      }
    }

    return dailyTotals.entries
        .map((e) => ChartDataPoint(e.key, e.value))
        .toList()
      ..sort((a, b) => a.dateLabel.compareTo(b.dateLabel));
  }


  Map<String, dynamic> _calculateProductionAnalysis() {
    final morningTotal = widget.milkRecords.fold(0.0, (sum, record) => sum + (record.morningYield ?? 0));
    final eveningTotal = widget.milkRecords.fold(0.0, (sum, record) => sum + (record.eveningYield ?? 0));
    final total = morningTotal + eveningTotal;

    final morningPercentage = total > 0 ? (morningTotal / total) * 100 : 0;
    final eveningPercentage = total > 0 ? (eveningTotal / total) * 100 : 0;

    String insight;
    if (morningPercentage > 60) {
      insight = 'Morning milking is more productive. Consider optimizing evening feed schedules.';
    } else if (eveningPercentage > 60) {
      insight = 'Evening milking shows higher yield. Morning nutrition might need attention.';
    } else {
      insight = 'Well-balanced production between morning and evening sessions.';
    }

    return {
      'morningTotal': morningTotal,
      'eveningTotal': eveningTotal,
      'morningPercentage': morningPercentage,
      'eveningPercentage': eveningPercentage,
      'insight': insight,
    };
  }


}

class ChartDataPoint {
  final String dateLabel;
  final double yield;

  ChartDataPoint(this.dateLabel, this.yield);
}

class LineChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final Color lineColor;

  LineChartPainter(this.data, this.lineColor);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    final maxY = data.map((e) => e.yield).reduce(math.max);
    final minY = 0.0;
    final range = maxY - minY;

    // Draw grid lines
    for (int i = 0; i <= 5; i++) {
      final y = size.height * 0.8 - (size.height * 0.8 * i / 5);
      canvas.drawLine(
        Offset(40, y),
        Offset(size.width - 20, y),
        gridPaint,
      );

      // Y-axis labels
      final labelValue = (range * i / 5).toStringAsFixed(0);
      textPainter.text = TextSpan(
        text: '${labelValue}L',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(5, y - textPainter.height / 2));
    }

    if (data.length < 2) return;

    // Create path for line
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = 40 + (size.width - 60) * i / (data.length - 1);
      final y = size.height * 0.8 - (size.height * 0.8 * (data[i].yield - minY) / range);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height * 0.8);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      // Draw dots
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = lineColor);

      // X-axis labels
      if (i % math.max(1, data.length ~/ 5) == 0) {
        textPainter.text = TextSpan(
          text: data[i].dateLabel,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 9),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height * 0.85));
      }
    }

    // Complete fill path
    fillPath.lineTo(40 + (size.width - 60), size.height * 0.8);
    fillPath.close();

    // Draw fill and line
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class PieChartPainter extends CustomPainter {
  final Map<String, int> data;

  PieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 3;
    final total = data.values.reduce((a, b) => a + b);

    double startAngle = -math.pi / 2;

    for (final entry in data.entries) {
      final sweepAngle = (entry.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = _getQualityColorForPie(entry.key)
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw percentage text
      final percentage = (entry.value / total * 100).toStringAsFixed(1);
      final textAngle = startAngle + sweepAngle / 2;
      final textRadius = radius * 0.7;
      final textX = center.dx + textRadius * math.cos(textAngle);
      final textY = center.dy + textRadius * math.sin(textAngle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '$percentage%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(textX - textPainter.width / 2, textY - textPainter.height / 2));

      startAngle += sweepAngle;
    }

    // Draw center circle
    canvas.drawCircle(
      center,
      radius * 0.4,
      Paint()..color = Colors.white,
    );
  }

  Color _getQualityColorForPie(String quality) {
    switch (quality) {
      case 'A+': return Colors.green;
      case 'A': return Colors.lightGreen;
      case 'B+': return Colors.orange;
      case 'B': return Colors.deepOrange;
      case 'C': return Colors.grey;
      default: return Colors.grey;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

