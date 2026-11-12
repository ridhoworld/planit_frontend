import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/report_provider.dart';
import '../../services/format_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().fetchReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rep = context.watch<ReportProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan & Analisis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => rep.fetchReports(),
          ),
        ],
      ),
      body: rep.isLoading && rep.categoryBreakdown.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => rep.fetchReports(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Month Selector Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Distribusi Pengeluaran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Text(
                          'Bulan ${rep.selectedMonth} / ${rep.selectedYear}',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // PIE CHART CARD
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Pengeluaran: ${FormatService.rupiah(rep.totalExpense)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 20),

                          if (rep.categoryBreakdown.isEmpty)
                            const SizedBox(
                              height: 180,
                              child: Center(
                                child: Text('Belum ada data pengeluaran di periode ini', style: TextStyle(color: Color(0xFF64748B))),
                              ),
                            )
                          else ...[
                            SizedBox(
                              height: 200,
                              child: PieChart(
                                PieChartData(
                                  pieTouchData: PieTouchData(
                                    touchCallback: (event, pieTouchResponse) {
                                      setState(() {
                                        if (!event.isInterestedForInteractions ||
                                            pieTouchResponse == null ||
                                            pieTouchResponse.touchedSection == null) {
                                          _touchedIndex = -1;
                                          return;
                                        }
                                        _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                      });
                                    },
                                  ),
                                  borderData: FlBorderData(show: false),
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 40,
                                  sections: _buildPieSections(rep.categoryBreakdown),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Divider(color: Theme.of(context).dividerColor),
                            const SizedBox(height: 10),
                            // Category breakdown list
                            ...rep.categoryBreakdown.map((c) => _buildCategoryRow(c)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 6-MONTH TREND CARD
                  Text(
                    'Tren Arus Kas 6 Bulan Terakhir',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildLegend(AppTheme.incomeColor, 'Pemasukan'),
                              const SizedBox(width: 16),
                              _buildLegend(AppTheme.expenseColor, 'Pengeluaran'),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (rep.monthlyTrend.isEmpty)
                            const SizedBox(
                              height: 180,
                              child: Center(child: Text('Belum ada tren historis', style: TextStyle(color: Color(0xFF64748B)))),
                            )
                          else
                            SizedBox(
                              height: 220,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: _calculateMaxY(rep.monthlyTrend),
                                  barTouchData: BarTouchData(enabled: true),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (val, meta) {
                                          int index = val.toInt();
                                          if (index >= 0 && index < rep.monthlyTrend.length) {
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 6),
                                              child: Text(
                                                rep.monthlyTrend[index]['month_label'] ?? '',
                                                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                              ),
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        },
                                      ),
                                    ),
                                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  gridData: const FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                  barGroups: _buildBarGroups(rep.monthlyTrend),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  List<PieChartSectionData> _buildPieSections(List<Map<String, dynamic>> items) {
    return List.generate(items.length, (i) {
      final item = items[i];
      final isTouched = i == _touchedIndex;
      final radius = isTouched ? 65.0 : 50.0;
      final colorHex = item['color'] ?? '#3B82F6';
      final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));

      final pct = double.tryParse(item['percentage']?.toString() ?? '0') ?? 0.0;

      return PieChartSectionData(
        color: color,
        value: pct,
        title: '${pct.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  Widget _buildCategoryRow(Map<String, dynamic> c) {
    final colorHex = c['color'] ?? '#3B82F6';
    final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              c['name'] ?? 'Kategori',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '${c['percentage']}%',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          Text(
            FormatService.rupiah(c['amount']),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      ],
    );
  }

  double _calculateMaxY(List<Map<String, dynamic>> trend) {
    double maxVal = 100000;
    for (var m in trend) {
      double inc = double.tryParse(m['income']?.toString() ?? '0') ?? 0;
      double exp = double.tryParse(m['expense']?.toString() ?? '0') ?? 0;
      if (inc > maxVal) maxVal = inc;
      if (exp > maxVal) maxVal = exp;
    }
    return maxVal * 1.2;
  }

  List<BarChartGroupData> _buildBarGroups(List<Map<String, dynamic>> trend) {
    return List.generate(trend.length, (i) {
      final item = trend[i];
      final inc = double.tryParse(item['income']?.toString() ?? '0') ?? 0;
      final exp = double.tryParse(item['expense']?.toString() ?? '0') ?? 0;

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: inc,
            color: AppTheme.incomeColor,
            width: 10,
            borderRadius: BorderRadius.circular(3),
          ),
          BarChartRodData(
            toY: exp,
            color: AppTheme.expenseColor,
            width: 10,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      );
    });
  }
}

