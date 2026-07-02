import 'package:equatable/equatable.dart';

class TuitionFee extends Equatable {
  final double totalPayable;
  final double totalPaid;
  final double remainingAmount;
  final List<TuitionItem> items;

  const TuitionFee({
    required this.totalPayable,
    required this.totalPaid,
    required this.remainingAmount,
    required this.items,
  });

  @override
  List<Object?> get props => [totalPayable, totalPaid, remainingAmount, items];
}

class TuitionItem extends Equatable {
  final int id;
  final String semesterName;
  final String periodName;
  final double amount;
  final double amountPaid;
  final String note;
  final bool isComplete;
  final List<TuitionDetail> details;

  const TuitionItem({
    required this.id,
    required this.semesterName,
    required this.periodName,
    required this.amount,
    required this.amountPaid,
    required this.note,
    required this.isComplete,
    required this.details,
  });

  double get remaining => amount - amountPaid;

  @override
  List<Object?> get props => [id, semesterName, periodName, amount, amountPaid, note, isComplete, details];
}

class TuitionDetail extends Equatable {
  final String feeName;
  final double amount;
  final double totalAmount;
  final String note;

  const TuitionDetail({
    required this.feeName,
    required this.amount,
    required this.totalAmount,
    required this.note,
  });

  @override
  List<Object?> get props => [feeName, amount, totalAmount, note];
}
