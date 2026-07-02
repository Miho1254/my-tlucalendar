import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';
import 'package:forui_assets/forui_assets.dart';
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

            final paidItems = fee.items.where((i) => i.isComplete || i.remaining <= 0).toList();
            final unpaidItems = fee.items.where((i) => !i.isComplete && i.remaining > 0).toList();

            return RefreshIndicator(
              onRefresh: () => _fetchTuitionFee(forceRefresh: true),
              child: FTabs(
                expands: true,
                children: [
                  FTabEntry(
                    label: const Text('Tổng quan'),
                    child: _buildOverviewTab(context, fee),
                  ),
                  FTabEntry(
                    label: Text('Khoản nợ${unpaidItems.isNotEmpty ? " (${unpaidItems.length})" : ""}'),
                    child: _buildDebtTab(context, fee, unpaidItems),
                  ),
                  FTabEntry(
                    label: const Text('Lịch sử'),
                    child: _buildHistoryTab(context, paidItems),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, TuitionFee fee) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isPaid = fee.remainingAmount <= 0;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FCard(
            title: const Text('Học phí đã đóng'),
            subtitle: const Text('Tổng hợp các kỳ đã đóng'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatCurrency(fee.totalPaid),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đã đóng',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!isPaid) ...[
            FAlert(
              variant: FAlertVariant.destructive,
              icon: const Icon(FLucideIcons.alertTriangle),
              title: Text('Còn nợ ${_formatCurrency(fee.remainingAmount)}'),
              subtitle: const Text('Vui lòng đóng học phí đúng hạn'),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: FCard(
                  title: const Text('Tổng HP'),
                  child: Text(
                    _formatCurrency(fee.totalPayable),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FCard(
                  title: const Text('Còn nợ'),
                  child: Text(
                    _formatCurrency(fee.remainingAmount),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isPaid ? colors.onSurface : colors.error,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDebtTab(BuildContext context, TuitionFee fee, List<TuitionItem> unpaidItems) {
    final theme = Theme.of(context);

    if (unpaidItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FAlert(
                variant: FAlertVariant.primary,
                icon: const Icon(FLucideIcons.checkCircle),
                title: const Text('Bạn đã đóng đủ học phí!'),
                subtitle: const Text('Không có khoản nợ nào'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FCard(
            title: const Text('Khoản cần đóng'),
            subtitle: Text('${unpaidItems.length} khoản chưa thanh toán'),
            child: Column(
              children: unpaidItems.map((item) => _buildDebtItem(context, item)).toList(),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDebtItem(BuildContext context, TuitionItem item) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.outline.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.note.isNotEmpty ? item.note : 'Học phí',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item.periodName.isNotEmpty) ...[
                  const SizedBox(height: 4),
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
            _formatCurrency(item.remaining),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context, List<TuitionItem> paidItems) {
    final theme = Theme.of(context);

    if (paidItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(FLucideIcons.receipt, size: 64),
              const SizedBox(height: 16),
              Text(
                'Chưa có lịch sử đóng học phí',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: FAccordion(
        children: paidItems.map((item) => _buildHistoryAccordionItem(context, item)).toList(),
      ),
    );
  }

  Widget _buildHistoryAccordionItem(BuildContext context, TuitionItem item) {
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
