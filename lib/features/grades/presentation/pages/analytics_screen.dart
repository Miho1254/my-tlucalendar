import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tlucalendar/providers/grade_provider.dart';
import 'package:forui/forui.dart';
import 'package:forui_assets/forui_assets.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:tlucalendar/providers/auth_provider.dart';
import 'package:tlucalendar/utils/semester_parser.dart';

import 'package:tlucalendar/features/grades/domain/services/grade_analytics_service.dart';
import 'package:tlucalendar/features/grades/presentation/widgets/manual_simulator_widget.dart';
import 'package:tlucalendar/features/grades/presentation/widgets/graduation_goal_widget.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gradeProvider = Provider.of<GradeProvider>(context, listen: false);
      if (gradeProvider.analyticsResult == null && !gradeProvider.isLoading) {
        _fetchGrades();
      }
    });
  }

  Future<void> _fetchGrades({bool forceRefresh = false}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final gradeProvider = Provider.of<GradeProvider>(context, listen: false);
    final token = authProvider.accessToken;
    if (token != null) {
      await gradeProvider.fetchGrades(token, forceRefresh: forceRefresh);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: FHeader.nested(
        title: const Text('Phân tích học tập'),
        prefixes: [
          FHeaderAction(
            icon: const Icon(Icons.arrow_back, size: 20),
            onPress: () => Navigator.of(context).pop(),
          ),
        ],
        suffixes: [
          FHeaderAction(
            icon: const Icon(FLucideIcons.refreshCw, size: 20),
            onPress: () => _fetchGrades(forceRefresh: true),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Consumer<GradeProvider>(
          builder: (context, gradeProvider, _) {
            final analytics = gradeProvider.analyticsResult;
            if (analytics == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (analytics.trend.isEmpty) {
              return const Center(child: Text("Chưa đủ dữ liệu để phân tích"));
            }

            return FTabs(
              expands: true,
              children: [
                FTabEntry(
                  label: const Text('Tổng quan', maxLines: 1, overflow: TextOverflow.ellipsis),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSummaryCard(analytics, context),
                        const SizedBox(height: 24),
                        _buildGPAChart(analytics, context),
                        const SizedBox(height: 24),
                        _buildScholarshipWidget(analytics, context),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                FTabEntry(
                  label: const Text('Phân tích', maxLines: 1, overflow: TextOverflow.ellipsis),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildRadarChart(analytics, context),
                        const SizedBox(height: 24),
                        _buildQTvsTHIChart(analytics, context),
                        const SizedBox(height: 24),
                        _buildAdvisorCards(analytics, context),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                FTabEntry(
                  label: const Text('Công cụ', maxLines: 1, overflow: TextOverflow.ellipsis),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FCard(
                          title: const Text('Giả lập điểm'),
                          subtitle: const Text('Tính toán điểm thi cần đạt để lấy điểm tổng kết kỳ vọng'),
                          child: const ManualSimulatorWidget(),
                        ),
                        const SizedBox(height: 24),
                        FCard(
                          title: const Text('Máy tính Mục tiêu'),
                          subtitle: const Text('Tính GPA cần thiết của các tín chỉ còn lại để đạt bằng tốt nghiệp'),
                          child: GraduationGoalWidget(
                            currentGpa: analytics.cumulativeGpa4,
                            passedCredits: analytics.totalPassedCredits,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(GradeAnalyticsResult analytics, BuildContext context) {
    String rankName = "Kém";
    Color rankColor = Colors.red;
    IconData rankIcon = FLucideIcons.skull;
    double nextRankGpa = 2.0;
    String nextRankName = "Trung Bình";
    double currentGpa = analytics.cumulativeGpa4;
    double prevRankGpa = 0.0;

    if (currentGpa >= 3.6) {
      rankName = "Xuất Sắc";
      rankColor = Colors.amber.shade600;
      rankIcon = FLucideIcons.trophy;
      nextRankGpa = 4.0;
      nextRankName = "Xuất Sắc";
      prevRankGpa = 3.6;
    } else if (currentGpa >= 3.2) {
      rankName = "Giỏi";
      rankColor = Colors.blue.shade500;
      rankIcon = FLucideIcons.medal;
      nextRankGpa = 3.6;
      nextRankName = "Xuất Sắc";
      prevRankGpa = 3.2;
    } else if (currentGpa >= 2.5) {
      rankName = "Khá";
      rankColor = Colors.green.shade500;
      rankIcon = FLucideIcons.award;
      nextRankGpa = 3.2;
      nextRankName = "Giỏi";
      prevRankGpa = 2.5;
    } else if (currentGpa >= 2.0) {
      rankName = "Trung Bình";
      rankColor = Colors.orange.shade500;
      rankIcon = FLucideIcons.shield;
      nextRankGpa = 2.5;
      nextRankName = "Khá";
      prevRankGpa = 2.0;
    }

    double progress = 1.0;
    if (nextRankGpa > currentGpa) {
       progress = (currentGpa - prevRankGpa) / (nextRankGpa - prevRankGpa);
    }
    progress = progress.clamp(0.0, 1.0);
    final double gpaNeeded = (nextRankGpa - currentGpa).clamp(0.0, 4.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FCard(
          title: const Text('Hồ Sơ Học Tập'),
          subtitle: const Text('Tổng quan năng lực hiện tại'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: rankColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(rankIcon, color: rankColor, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xếp loại: $rankName',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: rankColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currentGpa.toStringAsFixed(2),
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4, left: 4),
                              child: Text(
                                '/ 4.0',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (currentGpa < 3.6) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mục tiêu: $nextRankName',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Cần ${gpaNeeded.toStringAsFixed(2)} GPA',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: rankColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Stack(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            width: constraints.maxWidth * progress,
                            decoration: BoxDecoration(
                              color: rankColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                ),
              ] else ...[
                 FAlert(
                  title: const Text('Thành tích xuất sắc!'),
                  subtitle: const Text('Bạn đang ở mức xếp loại cao nhất. Hãy giữ vững phong độ!'),
                  icon: const Icon(FLucideIcons.flame, color: Colors.orange),
                  variant: FAlertVariant.primary,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FCard(
                title: const Text('Hệ 10'),
                child: Text(
                  analytics.cumulativeGpa10.toStringAsFixed(2),
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FCard(
                title: const Text('Tín chỉ'),
                child: Text(
                  '${analytics.totalPassedCredits} đạt',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGPAChart(GradeAnalyticsResult analytics, BuildContext context) {
    if (analytics.trend.isEmpty) return const SizedBox.shrink();
    
    // Find min and max for chart bounds
    double minGpa = 4.0;
    double maxGpa = 0.0;
    for (var t in analytics.trend) {
      if (t.gpa4 < minGpa) minGpa = t.gpa4;
      if (t.gpa4 > maxGpa) maxGpa = t.gpa4;
    }
    minGpa = (minGpa - 0.5).clamp(0.0, 4.0);
    maxGpa = (maxGpa + 0.5).clamp(0.0, 4.0);

    return FCard(
      title: const Text('Phong độ học tập (Hệ 4)'),
      child: Padding(
        padding: const EdgeInsets.only(top: 24.0, right: 16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                height: 200,
                width: analytics.trend.length > 5 ? analytics.trend.length * 50.0 : constraints.maxWidth,
                child: LineChart(
            LineChartData(
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (touchedSpot) => Theme.of(context).brightness == Brightness.dark 
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : Theme.of(context).colorScheme.primary,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      return LineTooltipItem(
                        spot.y.toStringAsFixed(2),
                        Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.white, 
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      meta: meta,
                      space: 4,
                      child: Text(value.toStringAsFixed(1), style: Theme.of(context).textTheme.labelSmall),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value % 1 == 0 && value.toInt() >= 0 && value.toInt() < analytics.trend.length) {
                        return SideTitleWidget(
                          meta: meta,
                          space: 4,
                          child: Text("Kỳ ${value.toInt() + 1}", style: Theme.of(context).textTheme.labelSmall),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minX: -0.2,
              maxX: (analytics.trend.length - 1).toDouble() + 0.2,
              minY: minGpa,
              maxY: maxGpa,
              lineBarsData: [
                LineChartBarData(
                  spots: analytics.trend.asMap().entries.map((e) {
                    return FlSpot(e.key.toDouble(), e.value.gpa4);
                  }).toList(),
                  isCurved: true,
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
            duration: const Duration(milliseconds: 150),
            curve: Curves.linear,
          ),
        ),
      );
      },
    ),
  ),
);
}

  Widget _buildQTvsTHIChart(GradeAnalyticsResult analytics, BuildContext context) {
    if (analytics.trend.isEmpty) return const SizedBox.shrink();

    return FCard(
      title: const Text('Điểm Quá Trình & Điểm Thi'),
      subtitle: const Text('Tương quan giữa hai cột điểm chính'),
      child: Padding(
        padding: const EdgeInsets.only(top: 24.0, right: 16.0, bottom: 8.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                height: 200,
                width: analytics.trend.length > 5 ? analytics.trend.length * 50.0 : constraints.maxWidth,
                child: BarChart(
            BarChartData(
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => Theme.of(context).brightness == Brightness.dark 
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : Theme.of(context).colorScheme.primaryContainer,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final isQT = rodIndex == 0;
                    return BarTooltipItem(
                      '${isQT ? "QT: " : "Thi: "}${rod.toY.toStringAsFixed(1)}',
                      Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: isQT ? Colors.blue : Colors.orange, 
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      meta: meta,
                      space: 4,
                      child: Text(value.toStringAsFixed(0), style: Theme.of(context).textTheme.labelSmall),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < analytics.trend.length) {
                        return SideTitleWidget(
                          meta: meta,
                          space: 4,
                          child: Text("Kỳ ${value.toInt() + 1}", style: Theme.of(context).textTheme.labelSmall),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              maxY: 10,
              barGroups: analytics.trend.asMap().entries.map((e) {
                final int index = e.key;
                final sem = e.value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: sem.avgQT,
                      color: Colors.blue,
                      width: 8,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    BarChartRodData(
                      toY: sem.avgTHI,
                      color: Colors.orange,
                      width: 8,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                );
              }).toList(),
            ),
            duration: const Duration(milliseconds: 150),
            curve: Curves.linear,
          ),
        ),
      );
      },
    ),
  ),
);
}

  Widget _buildRadarChart(GradeAnalyticsResult analytics, BuildContext context) {
    if (analytics.skillGroups.length < 3) return const SizedBox.shrink();

    return FCard(
      title: const Text('Bản đồ Kỹ năng'),
      subtitle: const Text('Phân tích theo điểm hệ 10'),
      child: SizedBox(
        height: 250,
        child: RadarChart(
          RadarChartData(
            radarBackgroundColor: Colors.transparent,
            radarBorderData: const BorderSide(color: Colors.transparent),
            tickBorderData: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
            gridBorderData: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2), width: 1.5),
            tickCount: 5,
            ticksTextStyle: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.transparent),
            titleTextStyle: Theme.of(context).textTheme.labelMedium,
            getTitle: (index, angle) {
              final group = analytics.skillGroups[index];
              return RadarChartTitle(
                text: group.groupName,
                angle: 0,
                positionPercentageOffset: 0.1,
              );
            },
            dataSets: [
              RadarDataSet(
                fillColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                borderColor: Theme.of(context).colorScheme.primary,
                entryRadius: 3,
                dataEntries: analytics.skillGroups.map((g) => RadarEntry(value: g.averageScore)).toList(),
                borderWidth: 2,
              ),
            ],
          ),
          duration: const Duration(milliseconds: 150),
          curve: Curves.linear,
        ),
      ),
    );
  }

  Widget _buildPersonaSpotlight(GradeAnalyticsResult analytics, BuildContext context) {
    if (analytics.personaMessage == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: FCard(
        title: const Text("Hồ Sơ Học Tập"),
        subtitle: const Text("Phân tích phong cách học"),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              analytics.personaMessage!.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: Theme.of(context).colorScheme.primary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              analytics.personaMessage!.subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvisorCards(GradeAnalyticsResult analytics, BuildContext context) {
    final List<Widget> redAlerts = [];
    final List<Widget> strategyAlerts = [];
    final List<Widget> achievementAlerts = [];
    final colorScheme = Theme.of(context).colorScheme;

    void addAlert(AdvisorMessage? msg, IconData icon, Color color, FAlertVariant variant, List<Widget> targetList) {
      if (msg != null) {
        targetList.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FAlert(
              variant: variant,
              icon: Icon(icon, color: color),
              title: Text(msg.title),
              subtitle: Text(msg.subtitle),
            ),
          ),
        );
      }
    }

    Color adaptColor(Color darkColor, Color lightColor) {
      return Theme.of(context).brightness == Brightness.light ? lightColor : darkColor;
    }

    // 🔴 Báo Động Đỏ (Red Alerts)
    addAlert(analytics.failedMessage, FLucideIcons.alertTriangle, colorScheme.error, FAlertVariant.destructive, redAlerts);
    addAlert(analytics.nemesisMessage, FLucideIcons.swords, adaptColor(Colors.redAccent, Colors.red.shade700), FAlertVariant.primary, redAlerts);
    addAlert(analytics.trailingMessage, FLucideIcons.alertCircle, adaptColor(Colors.orange, Colors.orange.shade700), FAlertVariant.primary, redAlerts);
    addAlert(analytics.overloadMessage, FLucideIcons.zap, adaptColor(Colors.orangeAccent, Colors.orange.shade700), FAlertVariant.primary, redAlerts);
    if (analytics.trendMessage != null) {
      final msg = analytics.trendMessage!;
      if (msg.title.contains('Vẫn trong vùng nguy hiểm') || msg.title.contains('Mắc kẹt vùng đỏ') || msg.title.contains('rơi tự do')) {
         addAlert(msg, FLucideIcons.trendingDown, colorScheme.error, FAlertVariant.destructive, redAlerts);
      }
    }

    // 💡 Chiến lược (Strategy)
    addAlert(analytics.improvementMessage, FLucideIcons.lightbulb, adaptColor(Colors.blue, Colors.blue.shade700), FAlertVariant.primary, strategyAlerts);
    addAlert(analytics.nextRankMessage, FLucideIcons.target, adaptColor(Colors.indigo, Colors.indigo.shade700), FAlertVariant.primary, strategyAlerts);
    addAlert(analytics.teamCarryMessage, FLucideIcons.scale, adaptColor(Colors.purple, Colors.purple.shade700), FAlertVariant.primary, strategyAlerts);
    
    // 🌟 Thành tựu (Achievements & Fun Facts)
    addAlert(analytics.achievementMessage, FLucideIcons.award, adaptColor(Colors.amber, Colors.amber.shade700), FAlertVariant.primary, achievementAlerts);
    addAlert(analytics.shiningStarMessage, FLucideIcons.star, adaptColor(Colors.amber, Colors.amber.shade700), FAlertVariant.primary, achievementAlerts);
    addAlert(analytics.bestSemesterMessage, FLucideIcons.trophy, adaptColor(Colors.amber, Colors.amber.shade700), FAlertVariant.primary, achievementAlerts);
    addAlert(analytics.aStreakMessage, FLucideIcons.flame, adaptColor(Colors.deepOrange, Colors.deepOrange.shade700), FAlertVariant.primary, achievementAlerts);
    addAlert(analytics.noFailMessage, FLucideIcons.shield, adaptColor(Colors.teal, Colors.teal.shade700), FAlertVariant.primary, achievementAlerts);
    addAlert(analytics.consistencyMessage, FLucideIcons.activity, adaptColor(Colors.blue, Colors.blue.shade700), FAlertVariant.primary, achievementAlerts);
    
    if (analytics.trendMessage != null) {
      final msg = analytics.trendMessage!;
      if (msg.title.contains('thăng hoa') || msg.title.contains('Bứt phá') || msg.title.contains('lên')) {
         addAlert(msg, FLucideIcons.trendingUp, adaptColor(Colors.green, Colors.green.shade700), FAlertVariant.primary, achievementAlerts);
      } else if (msg.title.contains('Ổn định') || msg.title.contains('Tân binh')) {
         addAlert(msg, FLucideIcons.activity, adaptColor(Colors.blue, Colors.blue.shade700), FAlertVariant.primary, achievementAlerts);
      }
    }

    if (redAlerts.isEmpty && strategyAlerts.isEmpty && achievementAlerts.isEmpty && analytics.personaMessage == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (analytics.personaMessage != null) _buildPersonaSpotlight(analytics, context),
        
        if (redAlerts.isNotEmpty) ...[
          Text("🔴 Cảnh Báo", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 12),
          ...redAlerts,
          const SizedBox(height: 12),
        ],

        if (strategyAlerts.isNotEmpty) ...[
          Text("💡 Chiến Lược", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: adaptColor(Colors.blue.shade400, Colors.blue.shade700))),
          const SizedBox(height: 12),
          ...strategyAlerts,
          const SizedBox(height: 12),
        ],

        if (achievementAlerts.isNotEmpty) ...[
          Text("🌟 Thành Tựu", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: adaptColor(Colors.amber.shade400, Colors.amber.shade700))),
          const SizedBox(height: 12),
          ...achievementAlerts,
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildScholarshipWidget(GradeAnalyticsResult analytics, BuildContext context) {
    if (analytics.trend.isEmpty) return const SizedBox.shrink();

    final latestSem = analytics.trend.last;
    
    String statusText;
    String requirementText;
    Color color;

    final isLight = Theme.of(context).brightness == Brightness.light;

    if (latestSem.hasFailedSubject) {
      statusText = "KHÔNG ĐẠT";
      requirementText = "Có môn bị điểm F";
      color = Theme.of(context).colorScheme.error;
    } else if (latestSem.gpa4 >= 3.6) {
      statusText = "XUẤT SẮC";
      requirementText = "Yêu cầu: Điểm rèn luyện ≥ 90";
      color = isLight ? Colors.orange.shade800 : Colors.amber.shade400;
    } else if (latestSem.gpa4 >= 3.2) {
      statusText = "GIỎI";
      requirementText = "Yêu cầu: Điểm rèn luyện ≥ 80";
      color = isLight ? Colors.blue.shade700 : Colors.blue.shade400;
    } else if (latestSem.gpa4 >= 2.5) {
      statusText = "KHÁ";
      requirementText = "Yêu cầu: Điểm rèn luyện ≥ 70";
      color = isLight ? Colors.green.shade700 : Colors.green.shade400;
    } else {
      statusText = "KHÔNG ĐẠT";
      requirementText = "Trung bình chung < 2.5";
      color = Theme.of(context).colorScheme.onSurfaceVariant;
    }

    return FCard(
      title: const Text("Dự báo Học bổng"),
      subtitle: Text(latestSem.semesterName.toReadableSemester),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            statusText,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            requirementText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
