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
      child: Material(
        type: MaterialType.transparency,
        child: Consumer<TuitionProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.errorMessage != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        FLucideIcons.cloudOff,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Úi! Có lỗi rồi!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        provider.errorMessage!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FButton(
                        onPress: () => _fetchTuitionFee(forceRefresh: true),
                        child: const Text('Thử lại'),
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

            final paidItems = fee.items.where((i) => !i.isPending).toList();
            final unpaidItems = fee.items.where((i) => i.isPending).toList();

            return RefreshIndicator(
              onRefresh: () => _fetchTuitionFee(forceRefresh: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                children: [
                  _buildHeroCard(context, fee.remainingAmount),
                  const SizedBox(height: 16),
                  
                  _buildStatsRow(context, fee),
                  const SizedBox(height: 32),
                  
                  if (unpaidItems.isNotEmpty) ...[
                    Text(
                      'Cần thanh toán',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FCard(
                      child: Column(
                        children: unpaidItems.asMap().entries.map((entry) {
                          final isLast = entry.key == unpaidItems.length - 1;
                          return _buildDebtItem(context, entry.value, isLast);
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                  
                  if (paidItems.isNotEmpty) ...[
                    Text(
                      'Lịch sử giao dịch',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FAccordion(
                      children: paidItems.map((item) => _buildHistoryAccordionItem(context, item)).toList(),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, double remainingAmount) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isPaid = remainingAmount <= 0;

    if (isPaid) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(FLucideIcons.checkCircle, color: colors.primary, size: 48),
            const SizedBox(height: 16),
            Text(
              'Đã hoàn thành học phí!',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FLucideIcons.alertCircle, color: colors.error, size: 24),
              const SizedBox(width: 8),
              Text(
                'TỔNG DƯ NỢ',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.error,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatCurrency(remainingAmount),
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vui lòng thanh toán sớm để không ảnh hưởng đến việc học.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.error.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, TuitionFee fee) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    return Row(
      children: [
        Expanded(
          child: FCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tổng học phí',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(fee.totalPayable),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đã thanh toán',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(fee.totalPaid),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDebtItem(BuildContext context, TuitionItem item, bool isLast) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : Border(
          bottom: BorderSide(color: colors.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.errorContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(FLucideIcons.creditCard, size: 20, color: colors.error),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.note.isNotEmpty ? item.note : 'Học phí',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.periodName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.periodName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            _formatCurrency(item.amount),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.error,
            ),
          ),
        ],
      ),
    );
  }

  FAccordionItem _buildHistoryAccordionItem(BuildContext context, TuitionItem item) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return FAccordionItem(
      title: Row(
        children: [
          Expanded(
            child: Text(
              item.note.isNotEmpty ? item.note : 'Học phí',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          FBadge(
            variant: FBadgeVariant.secondary,
            child: const Text('Đã đóng'),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (item.periodName.isNotEmpty) ...[
              _buildHistoryDetailRow(context, 'Đợt', item.periodName),
              const SizedBox(height: 8),
            ],
            _buildHistoryDetailRow(context, 'Số tiền', _formatCurrency(item.amount)),
            if (item.amountPaid > 0) ...[
              const SizedBox(height: 8),
              _buildHistoryDetailRow(context, 'Đã đóng', _formatCurrency(item.amountPaid)),
            ],
            if (item.details.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Chi tiết môn học',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              ...item.details.map((detail) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        detail.note.isNotEmpty ? detail.note : detail.feeName,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    Text(
                      _formatCurrency(detail.totalAmount),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
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
