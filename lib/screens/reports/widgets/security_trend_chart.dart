// lib/screens/reports/widgets/security_trend_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/common/app_card.dart';

class SecurityTrendChart extends StatefulWidget {
  final Map<String, int>? dailyCounts;
  final String title;

  const SecurityTrendChart({
    Key? key,
    this.dailyCounts,
    this.title = 'Security Trend',
  }) : super(key: key);

  @override
  State<SecurityTrendChart> createState() => _SecurityTrendChartState();
}

class _SecurityTrendChartState extends State<SecurityTrendChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final dailyCounts = widget.dailyCounts;

    // If no data provided, use mock data
    final Map<String, int> chartData = dailyCounts != null && dailyCounts.isNotEmpty
        ? dailyCounts
        : _generateMockData();

    // Sort the data by date
    final sortedEntries = chartData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: AppTextStyles.subtitle),
            const SizedBox(height: AppSpacing.medium),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: AppColors.surface,
                      tooltipRoundedRadius: AppRadius.small,
                      tooltipBorder: BorderSide(color: AppColors.border),
                      tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.small,
                        vertical: 4,
                      ),
                      getTooltipItem: (
                          BarChartGroupData group,
                          int groupIndex,
                          BarChartRodData rod,
                          int rodIndex,
                          ) {
                        final entry = sortedEntries[groupIndex];
                        return BarTooltipItem(
                          '${entry.key}: ${entry.value} issues',
                          TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    touchCallback: (FlTouchEvent event, barTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            barTouchResponse == null ||
                            barTouchResponse.spot == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                      });
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
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value.toInt() >= sortedEntries.length) {
                            return const SizedBox.shrink();
                          }

                          final entry = sortedEntries[value.toInt()];
                          // Format the date (assuming entry key is a date string)
                          String date = '';
                          try {
                            final dateObj = DateTime.parse(entry.key);
                            date = DateFormat('MM/dd').format(dateObj);
                          } catch (e) {
                            // If parsing fails, just use the original key
                            date = entry.key;
                            // For mock data with simple day numbers
                            if (date.length <= 2) {
                              date = 'D$date';
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              date,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 2,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppColors.divider,
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      );
                    },
                  ),
                  barGroups: _buildBarGroups(sortedEntries),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(List<MapEntry<String, int>> entries) {
    return List.generate(entries.length, (index) {
      final entry = entries[index];
      final isTouched = index == _touchedIndex;
      final barColor = _getBarColor(entry.value);
      final double barWidth = 16;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: barColor,
            width: barWidth,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 20, // Maximum expected value (adjust based on your data)
              color: AppColors.background,
            ),
          ),
        ],
        showingTooltipIndicators: isTouched ? [0] : [],
      );
    });
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Low', AppColors.success),
        const SizedBox(width: AppSpacing.medium),
        _buildLegendItem('Medium', AppColors.warning),
        const SizedBox(width: AppSpacing.medium),
        _buildLegendItem('High', AppColors.error),
        const SizedBox(width: AppSpacing.medium),
        _buildLegendItem('Critical', AppColors.riskCritical),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Color _getBarColor(int value) {
    if (value <= 0) return Colors.grey[300]!;
    if (value <= 2) return AppColors.success;
    if (value <= 5) return AppColors.warning;
    if (value <= 10) return AppColors.error;
    return AppColors.riskCritical;
  }

  Map<String, int> _generateMockData() {
    // Generate mock data for the last 7 days
    final mockData = <String, int>{};
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      // Generate random values
      final value = i == 0 ? 3 : (i % 7); // Give some pattern to the data
      mockData[dateStr] = value;
    }

    return mockData;
  }
}