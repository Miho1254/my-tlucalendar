import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';
import 'package:tlucalendar/providers/auth_provider.dart';
import 'package:tlucalendar/providers/tuition_provider.dart';
import 'package:tlucalendar/features/tuition/domain/entities/tuition_fee.dart';

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
      _fetchTuitionFee();
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
    final theme = FTheme.of(context);
    final colors = theme.colors;

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
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 64,
                    color: colors.destructive,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Úi! Có lỗi rồi!',
                    style: theme.typography.body.lg.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.destructive,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: theme.typography.body.md.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FButton(
                    onPress: () => _fetchTuitionFee(forceRefresh: true),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final fee = provider.tuitionFee;
          if (fee == null) {
            return const Center(child: Text('Không có dữ liệu'));
          }

          return RefreshIndicator(
            onRefresh: () => _fetchTuitionFee(forceRefresh: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(context, fee),
                  const SizedBox(height: 24),
                  if (fee.items.isNotEmpty) ...[
                    Text(
                      'Chi tiết theo đợt',
                      style: theme.typography.body.lg.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.foreground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...fee.items.map((item) => _buildItemCard(context, item)),
                  ] else ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 48),
                        child: Column(
                          children: [
                            Icon(
                              FLucideIcons.checkCircle,
                              size: 64,
                              color: Colors.green.shade600,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Bạn đã đóng đủ học phí!',
                              style: theme.typography.body.lg.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.foreground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, TuitionFee fee) {
    final theme = FTheme.of(context);
    final colors = theme.colors;
    final isPaid = fee.remainingAmount <= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPaid
              ? [Colors.green.shade600, Colors.green.shade400]
              : [colors.primary, colors.primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tổng quan',
            style: theme.typography.body.sm.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(fee.totalPayable),
            style: theme.typography.body.xl.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tổng học phí',
            style: theme.typography.body.sm.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  context,
                  'Đã đóng',
                  _formatCurrency(fee.totalPaid),
                  Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  context,
                  'Còn lại',
                  _formatCurrency(fee.remainingAmount),
                  Icons.schedule,
                  isWarning: !isPaid,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool isWarning = false,
  }) {
    final theme = FTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: isWarning ? Colors.orange.shade300 : Colors.white.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.typography.body.xs.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.typography.body.md.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, TuitionItem item) {
    final theme = FTheme.of(context);
    final colors = theme.colors;
    final isComplete = item.isComplete;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isComplete
                    ? Colors.green.withValues(alpha: 0.15)
                    : Colors.orange.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isComplete ? Icons.check : Icons.schedule,
                size: 20,
                color: isComplete ? Colors.green.shade600 : Colors.orange.shade600,
              ),
            ),
            title: Text(
              item.note.isNotEmpty ? item.note : 'Học phí',
              style: theme.typography.body.md.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.foreground,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${_formatCurrency(item.amount)} • ${isComplete ? 'Đã đóng' : 'Chưa đóng'}',
                style: theme.typography.body.sm.copyWith(
                  color: isComplete ? Colors.green.shade600 : Colors.orange.shade600,
                ),
              ),
            ),
          children: [
            if (item.periodName.isNotEmpty) ...[
              _buildDetailRow(context, 'Đợt', item.periodName),
              const SizedBox(height: 8),
            ],
            if (item.details.isNotEmpty) ...[
              Text(
                'Chi tiết môn học',
                style: theme.typography.body.sm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.foreground,
                ),
              ),
              const SizedBox(height: 8),
              ...item.details.map((detail) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.muted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              detail.note.isNotEmpty ? detail.note : detail.feeName,
                              style: theme.typography.body.sm.copyWith(
                                color: colors.foreground,
                              ),
                            ),
                            if (detail.note.isNotEmpty && detail.feeName != detail.note) ...[
                              const SizedBox(height: 2),
                              Text(
                                detail.feeName,
                                style: theme.typography.body.xs.copyWith(
                                  color: colors.mutedForeground,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        _formatCurrency(detail.totalAmount),
                        style: theme.typography.body.sm.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.foreground,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
            ],
            if (item.amountPaid > 0) ...[
              const SizedBox(height: 8),
              _buildDetailRow(context, 'Đã đóng', _formatCurrency(item.amountPaid)),
            ],
            if (!isComplete && item.remaining > 0) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                context,
                'Còn lại',
                _formatCurrency(item.remaining),
                isWarning: true,
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {bool isWarning = false}) {
    final theme = FTheme.of(context);
    final colors = theme.colors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.typography.body.sm.copyWith(
            color: colors.mutedForeground,
          ),
        ),
        Text(
          value,
          style: theme.typography.body.sm.copyWith(
            fontWeight: FontWeight.w600,
            color: isWarning ? Colors.orange.shade600 : colors.foreground,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    if (amount == 0) return '0 ₫';
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$formatted ₫';
  }
}
