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

    List<TuitionItem> parseItems(List<dynamic> dtos, {bool isPending = false}) {
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
          isPending: isPending,
          details: details,
        );
      }).toList();
    }

    final items = [
      ...parseItems(receiveAbleDtos),
      ...parseItems(receiveAbleNotCompleteDtos, isPending: true),
    ];

    return TuitionFeeModel(
      totalPayable: (json['totalReceiveAble'] as num?)?.toDouble() ?? 0,
      totalPaid: (json['totalReceived'] as num?)?.toDouble() ?? 0,
      remainingAmount: (json['differenceAmount'] as num?)?.toDouble() ?? 0,
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPayable': totalPayable,
      'totalPaid': totalPaid,
      'remainingAmount': remainingAmount,
      'items': items.map((i) => {
        'id': i.id,
        'semesterName': i.semesterName,
        'periodName': i.periodName,
        'amount': i.amount,
        'amountPaid': i.amountPaid,
        'note': i.note,
        'isComplete': i.isComplete,
        'isPending': i.isPending,
        'details': i.details.map((d) => {
          'feeName': d.feeName,
          'amount': d.amount,
          'totalAmount': d.totalAmount,
          'note': d.note,
        }).toList(),
      }).toList(),
    };
  }

  factory TuitionFeeModel.fromCacheJson(Map<String, dynamic> json) {
    return TuitionFeeModel(
      totalPayable: (json['totalPayable'] as num?)?.toDouble() ?? 0,
      totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0,
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0,
      items: (json['items'] as List<dynamic>? ?? []).map((i) => TuitionItem(
        id: i['id'] as int? ?? 0,
        semesterName: i['semesterName']?.toString() ?? '',
        periodName: i['periodName']?.toString() ?? '',
        amount: (i['amount'] as num?)?.toDouble() ?? 0,
        amountPaid: (i['amountPaid'] as num?)?.toDouble() ?? 0,
        note: i['note']?.toString() ?? '',
        isComplete: i['isComplete'] as bool? ?? false,
        isPending: i['isPending'] as bool? ?? false,
        details: (i['details'] as List<dynamic>? ?? []).map((d) => TuitionDetail(
          feeName: d['feeName']?.toString() ?? '',
          amount: (d['amount'] as num?)?.toDouble() ?? 0,
          totalAmount: (d['totalAmount'] as num?)?.toDouble() ?? 0,
          note: d['note']?.toString() ?? '',
        )).toList(),
      )).toList(),
    );
  }
}

