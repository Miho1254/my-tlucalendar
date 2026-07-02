import 'package:tlucalendar/features/tuition/domain/entities/tuition_fee.dart';

class TuitionFeeModel extends TuitionFee {
  const TuitionFeeModel({
    required super.totalPayable,
    required super.totalPaid,
    required super.remainingAmount,
    required super.items,
  });

  factory TuitionFeeModel.fromJson(Map<String, dynamic> json) {
    final receiveAbleDtos = json['receiveAbleDtos'] as List<dynamic>? ?? [];
    final receiveAbleNotCompleteDtos = json['receiveAbleNotCompleteDtos'] as List<dynamic>? ?? [];

    List<TuitionItem> parseItems(List<dynamic> dtos) {
      return dtos.map<TuitionItem>((dto) {
        final semester = dto['semester'] as Map<String, dynamic>?;
        final registerPeriod = dto['registerPeriod'] as Map<String, dynamic>?;
        final details = (dto['details'] as List<dynamic>? ?? []).map<TuitionDetail>((d) {
          final feeItem = d['feeItem'] as Map<String, dynamic>?;
          return TuitionDetail(
            feeName: feeItem?['name']?.toString() ?? 'Học phí',
            amount: (d['amount'] as num?)?.toDouble() ?? 0,
            totalAmount: (d['totalAmount'] as num?)?.toDouble() ?? 0,
            note: d['note']?.toString() ?? '',
          );
        }).toList();

        return TuitionItem(
          id: dto['id'] as int? ?? 0,
          semesterName: semester?['semesterName']?.toString() ?? '',
          periodName: registerPeriod?['name']?.toString() ?? '',
          amount: (dto['amount'] as num?)?.toDouble() ?? 0,
          amountPaid: (dto['amountReceived'] as num?)?.toDouble() ?? 0,
          note: dto['note']?.toString() ?? '',
          isComplete: dto['isComplete'] as bool? ?? false,
          details: details,
        );
      }).toList();
    }

    final items = [
      ...parseItems(receiveAbleDtos),
      ...parseItems(receiveAbleNotCompleteDtos),
    ];

    return TuitionFeeModel(
      totalPayable: (json['totalReceiveAble'] as num?)?.toDouble() ?? 0,
      totalPaid: (json['totalReceived'] as num?)?.toDouble() ?? 0,
      remainingAmount: (json['differenceAmount'] as num?)?.toDouble() ?? 0,
      items: items,
    );
  }
}
