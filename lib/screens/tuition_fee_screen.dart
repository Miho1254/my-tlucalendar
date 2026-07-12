import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';
import 'package:tlucalendar/providers/auth_provider.dart';
import 'package:tlucalendar/providers/tuition_provider.dart';
import 'package:tlucalendar/features/tuition/domain/entities/tuition_fee.dart';
import 'package:tlucalendar/utils/semester_parser.dart';
import 'package:tlucalendar/utils/error_messages.dart';

class TuitionFeeScreen extends StatefulWidget {
  const TuitionFeeScreen({super.key});

  @override
  State<TuitionFeeScreen> createState() => _TuitionFeeScreenState();
}

class _TuitionFeeScreenState extends State<TuitionFeeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTuitionFee(forceRefresh: true);
    });
  }

  Future<void> _fetchTuitionFee({bool forceRefresh = false}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final tuitionProvider = Provider.of<TuitionProvider>(context, listen: false);
    final token = authProvider.accessToken;
    if (token != null) {
      await tuitionProvider.fetchTuitionFee(token, forceRefresh: forceRefresh);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: FHeader.nested(
        title: const Text('Học phí'),
        prefixes: [
          FHeaderAction(
            icon: const Icon(Icons.arrow_back, size: 20),
            onPress: () => Navigator.of(context).pop(),
          ),
        ],
        suffixes: [
          FHeaderAction(
            icon: const Icon(FLucideIcons.refreshCw, size: 20),
            onPress: () => _fetchTuitionFee(forceRefresh: true),
          ),
        ],
      ),
      child: Consumer<TuitionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.tuitionFee == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.tuitionFee == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(FLucideIcons.cloudOff, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Úi! Có lỗi rồi!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ErrorMessages.friendly(provider.errorMessage),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FButton(
                      child: const Text('Thử lại'),
                      onPress: () => _fetchTuitionFee(forceRefresh: true),
                    ),
                  ],
                ),
              ),
            );
          }

          final fee = provider.tuitionFee;
          if (fee == null) {
            return const Center(child: Text('Không có dữ liệu'));
          }

          final paidItems = fee.items.where((i) => !i.isPending).toList().reversed.toList();
          final unpaidItems = fee.items.where((i) => i.isPending).toList();
          final semesterFees = _calculateSemesterFees(fee);

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () => _fetchTuitionFee(forceRefresh: true),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  children: [
                    _buildHeroStats(context, fee),
                    const SizedBox(height: 32),
                    
                    if (semesterFees.length >= 2) ...[
                      _buildTuitionChart(context, semesterFees),
                      const SizedBox(height: 32),
                    ],

                    if (unpaidItems.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 12),
                        child: Text(
                          'CẦN THANH TOÁN',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      ...unpaidItems.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildDebtCard(context, item),
                      )),
                      const SizedBox(height: 20),
                    ],
                    
                    if (paidItems.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 12),
                        child: Text(
                          'LỊCH SỬ GIAO DỊCH',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      ...paidItems.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ExpandableHistoryCard(item: item),
                      )),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              if (provider.isLoading)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTuitionChart(BuildContext context, List<_SemesterFee> semesterFees) {
    double minAmount = semesterFees.map((e) => e.amount).reduce(min);
    double maxAmount = semesterFees.map((e) => e.amount).reduce(max);
    
    // padding for Y axis
    minAmount = (minAmount * 0.8);
    maxAmount = (maxAmount * 1.1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'BIẾN ĐỘNG HỌC PHÍ',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        FCard(
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0, right: 16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    height: 200,
                    width: semesterFees.length > 5 ? semesterFees.length * 60.0 : constraints.maxWidth,
                    child: LineChart(
                      LineChartData(
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (touchedSpot) => Theme.of(context).brightness == Brightness.dark 
                                ? Theme.of(context).colorScheme.surfaceContainerHighest
                                : Theme.of(context).colorScheme.primary,
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final sf = semesterFees[spot.x.toInt()];
                                return LineTooltipItem(
                                  '${sf.info?.shortReadableName ?? sf.label}\n${_formatCurrency(sf.amount)}',
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
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                if (value == minAmount || value == maxAmount) return const SizedBox.shrink();
                                return SideTitleWidget(
                                  meta: meta,
                                  space: 4,
                                  child: Text('${(value / 1000000).toStringAsFixed(1)}Tr', style: Theme.of(context).textTheme.labelSmall),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                if (value % 1 == 0 && value.toInt() >= 0 && value.toInt() < semesterFees.length) {
                                  final info = semesterFees[value.toInt()].info;
                                  final text = info != null ? 'Kỳ ${info.semester}' : 'Kỳ';
                                  return SideTitleWidget(
                                    meta: meta,
                                    space: 4,
                                    child: Text(text, style: Theme.of(context).textTheme.labelSmall),
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
                        maxX: (semesterFees.length - 1).toDouble() + 0.2,
                        minY: minAmount,
                        maxY: maxAmount,
                        lineBarsData: [
                          LineChartBarData(
                            spots: semesterFees.asMap().entries.map((e) {
                              return FlSpot(e.key.toDouble(), e.value.amount);
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
        ),
      ],
    );
  }

  Widget _buildHeroStats(BuildContext context, TuitionFee fee) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final greenColor = const Color(0xFF10B981);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tổng học phí',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _formatCurrency(fee.totalPayable),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ),
          
          const SizedBox(height: 36),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đã thanh toán',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatCurrency(fee.totalPaid),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: greenColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng dư nợ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatCurrency(fee.remainingAmount),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: fee.remainingAmount > 0 ? colors.error : colors.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDebtCard(BuildContext context, TuitionItem item) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    return FCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(FLucideIcons.alertCircle, color: colors.error, size: 20),
                const SizedBox(width: 8),
                Text(
                  'CẦN THANH TOÁN',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.error,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.periodName.isNotEmpty ? item.periodName : 'Khoản nợ học phí',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatCurrency(item.amount),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpandableHistoryCard extends StatefulWidget {
  final TuitionItem item;
  
  const ExpandableHistoryCard({super.key, required this.item});

  @override
  State<ExpandableHistoryCard> createState() => _ExpandableHistoryCardState();
}

class _ExpandableHistoryCardState extends State<ExpandableHistoryCard> {
  bool _expanded = false;

  String _cleanSubjectName(String name) {
    var cleaned = name.replaceAll(RegExp(r'\s*[\(\[].*?[\)\]]$'), '').trim();
    cleaned = cleaned.replaceAll(RegExp(r'Học phí\s+(môn\s+|học phần\s+)?', caseSensitive: false), '');
    final dashIndex = cleaned.lastIndexOf('-');
    if (dashIndex > 0 && dashIndex > cleaned.length - 15) { 
      cleaned = cleaned.substring(0, dashIndex).trim();
    }
    
    if (cleaned.isNotEmpty) {
      cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);
    }
    return cleaned;
  }

  String _formatSemester(String semester) {
    if (semester.isEmpty) return 'Kỳ học';
    final parts = semester.split('_');
    if (parts.length >= 3) {
      return 'Học kỳ ${parts[0]} (${parts[1]}-${parts[2]})';
    }
    return semester;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final greenColor = const Color(0xFF10B981);

    return GestureDetector(
      onTap: () {
        setState(() {
          _expanded = !_expanded;
        });
      },
      child: FCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(FLucideIcons.checkCircle2, color: greenColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'ĐÃ HOÀN THÀNH',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: greenColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _expanded ? FLucideIcons.chevronUp : FLucideIcons.chevronDown,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.item.semesterName.isNotEmpty 
                    ? _formatSemester(widget.item.semesterName) 
                    : (widget.item.periodName.isNotEmpty ? widget.item.periodName : 'Thanh toán học phí'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatCurrency(widget.item.amountPaid),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: greenColor,
                ),
              ),
              
              if (_expanded) ...[
                const SizedBox(height: 12),
                Divider(color: theme.dividerColor, height: 1),
                const SizedBox(height: 12),
                if (widget.item.details.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: widget.item.details.map((detail) {
                      final cleanedName = _cleanSubjectName(detail.note.isNotEmpty ? detail.note : detail.feeName);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Icon(FLucideIcons.book, size: 16, color: colors.onSurfaceVariant.withValues(alpha: 0.7)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    cleanedName,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      height: 1.4,
                                      color: colors.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(left: 28),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  _formatCurrency(detail.totalAmount),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: greenColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                else
                  Text(
                    'Không có thông tin chi tiết.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _formatCurrency(double amount) {
  if (amount == 0) return '0 ₫';
  final formatted = amount.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]}.',
  );
  return '$formatted ₫';
}

class _SemesterFee {
  final String label;
  final double amount;
  final SemesterInfo? info;

  _SemesterFee(this.label, this.amount, this.info);
}

List<_SemesterFee> _calculateSemesterFees(TuitionFee fee) {
  final Map<String, double> totals = {};
  final Map<String, SemesterInfo?> infos = {};

  for (var item in fee.items) {
    final key = item.semesterName.isNotEmpty ? item.semesterName : item.periodName;
    if (key.isEmpty) continue;
    
    totals[key] = (totals[key] ?? 0) + item.amount;
    if (!infos.containsKey(key)) {
      infos[key] = item.semesterName.parseSemester();
    }
  }

  final list = totals.entries.map((e) {
    return _SemesterFee(e.key, e.value, infos[e.key]);
  }).toList();

  list.sort((a, b) {
    if (a.info != null && b.info != null) {
      if (a.info!.startYear != b.info!.startYear) {
        return a.info!.startYear.compareTo(b.info!.startYear);
      }
      return a.info!.semester.compareTo(b.info!.semester);
    }
    return 0;
  });

  return list;
}
