import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/app_theme.dart';

class EarningsProjectionChart extends StatelessWidget {
  final double currentBalance;
  final double dailyRate; // 2% daily = 0.02
  final int daysToProject; // Default 30 days

  const EarningsProjectionChart({
    Key? key,
    required this.currentBalance,
    this.dailyRate = 0.02,
    this.daysToProject = 30,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Balance Projection',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Next $daysToProject days at 2% daily',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                  ),
                ],
              ),
              Icon(
                Icons.trending_up,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildProjectionSummary(context),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: _buildLineChart(),
          ),
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildProjectionSummary(BuildContext context) {
    final futureBalance = _calculateFutureBalance(daysToProject);
    final totalEarnings = futureBalance - currentBalance;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            context,
            'Current',
            '\$${currentBalance.toStringAsFixed(2)}',
            AppTheme.darkColor,
          ),
          _buildSummaryItem(
            context,
            'Projected',
            '\$${futureBalance.toStringAsFixed(2)}',
            AppTheme.primaryColor,
          ),
          _buildSummaryItem(
            context,
            'Earnings',
            '+\$${totalEarnings.toStringAsFixed(2)}',
            Colors.green[600]!,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6B7280),
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildLineChart() {
    final historicalSpots = _generateHistoricalSpots();
    final futureSpots = _generateFutureSpots();
    final allSpots = [...historicalSpots, ...futureSpots];

    // Find min and max for Y-axis
    final values = allSpots.map((spot) => spot.y).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final yRange = maxY - minY;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: yRange / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[200]!,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey[200]!,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text('Today');
                if (value == daysToProject.toDouble()) {
                  return Text(
                    'Day $daysToProject',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF6B7280),
                    ),
                  );
                }
                if (value % 10 == 0) {
                  return Text(
                    'Day ${value.toInt()}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF6B7280),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: yRange / 5,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  '\$${value.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6B7280),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!),
        ),
        minX: -7,
        maxX: daysToProject.toDouble(),
        minY: minY - (yRange * 0.1),
        maxY: maxY + (yRange * 0.1),
        lineBarsData: [
          // Historical line (solid dark red)
          LineChartBarData(
            spots: historicalSpots,
            isCurved: true,
            color: const Color(0xFF991B1B), // Dark red
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFF991B1B),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF991B1B).withOpacity(0.3), // Dark red with opacity
                  const Color(0xFF991B1B).withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Future projection line (dotted red)
          LineChartBarData(
            spots: futureSpots,
            isCurved: true,
            color: AppTheme.primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dashArray: [8, 4], // Dotted line for future
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                if (index == 0 || index == futureSpots.length - 1) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppTheme.primaryColor,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                }
                return FlDotCirclePainter(
                  radius: 2,
                  color: AppTheme.primaryColor.withOpacity(0.5),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.15),
                  AppTheme.primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generateHistoricalSpots() {
    // Generate 7 days of historical data (showing growth, not decline)
    List<FlSpot> spots = [];
    
    // Calculate what the balance was 7 days ago
    // If current balance is result of 7 days growth: current = initial * (1.02)^7
    // Then: initial = current / (1.02)^7
    double balanceSevenDaysAgo = currentBalance / pow(1 + dailyRate, 7);
    
    // Now calculate forward from 7 days ago to today
    double balance = balanceSevenDaysAgo;
    for (int i = 7; i >= 0; i--) {
      spots.add(FlSpot(-i.toDouble(), balance));
      if (i > 0) {
        balance = balance * (1 + dailyRate); // Forward calculation
      }
    }

    return spots;
  }

  List<FlSpot> _generateFutureSpots() {
    List<FlSpot> spots = [];
    double balance = currentBalance;

    // Start from day 0 (today)
    spots.add(FlSpot(0, balance));

    // Calculate forward with compound interest
    for (int i = 1; i <= daysToProject; i++) {
      balance = balance * (1 + dailyRate);
      spots.add(FlSpot(i.toDouble(), balance));
    }

    return spots;
  }

  double _calculateFutureBalance(int days) {
    // Compound interest formula: A = P(1 + r)^t
    return currentBalance * pow(1 + dailyRate, days);
  }

  // Helper for power calculation
  double pow(double base, int exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Past 7 Days', const Color(0xFF991B1B), false),
        const SizedBox(width: 24),
        _buildLegendItem('Next $daysToProject Days', AppTheme.primaryColor, true),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDashed) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
          child: isDashed
              ? CustomPaint(
                  painter: DashedLinePainter(color: color),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const dashWidth = 4;
    const dashSpace = 2;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
