import 'package:flutter/material.dart';


class GraduationGoalWidget extends StatefulWidget {
  final double currentGpa;
  final int passedCredits;

  const GraduationGoalWidget({
    super.key,
    required this.currentGpa,
    required this.passedCredits,
  });

  @override
  State<GraduationGoalWidget> createState() => _GraduationGoalWidgetState();
}

class _GraduationGoalWidgetState extends State<GraduationGoalWidget> {
  final TextEditingController _totalCreditsController = TextEditingController(text: '130');
  double _targetGpa = 3.2; // Default to Giỏi

  @override
  void dispose() {
    _totalCreditsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int totalCredits = int.tryParse(_totalCreditsController.text) ?? 130;
    int remainingCredits = totalCredits - widget.passedCredits;
    
    double requiredGpa = 0;
    String message = "";
    bool isImpossible = false;

    if (remainingCredits <= 0) {
      message = "Bạn đã hoàn thành đủ số tín chỉ!";
    } else {
      requiredGpa = ((_targetGpa * totalCredits) - (widget.currentGpa * widget.passedCredits)) / remainingCredits;
      if (requiredGpa > 4.0) {
        isImpossible = true;
        message = "Không thể đạt được mục tiêu này (cần GPA ${requiredGpa.toStringAsFixed(2)}/4.0 cho các tín chỉ còn lại).";
      } else if (requiredGpa <= 0) {
        message = "Chúc mừng! Bạn đã nắm chắc mục tiêu này kể cả khi các môn còn lại 0 điểm (lý thuyết).";
      } else {
        message = "Bạn cần đạt trung bình ${requiredGpa.toStringAsFixed(2)}/4.0 cho $remainingCredits tín chỉ còn lại.";
      }
    }

    return Material(
      type: MaterialType.transparency,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
            children: [
              const Expanded(child: Text("Mục tiêu bằng cấp:")),
              DropdownButton<double>(
                value: _targetGpa,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 3.6, child: Text("Xuất sắc (3.6+)")),
                  DropdownMenuItem(value: 3.2, child: Text("Giỏi (3.2+)")),
                  DropdownMenuItem(value: 2.5, child: Text("Khá (2.5+)")),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _targetGpa = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(child: Text("Tổng tín chỉ ngành học:")),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _totalCreditsController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isImpossible 
                  ? Colors.red.withValues(alpha: 0.1) 
                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isImpossible ? Icons.error_outline : Icons.lightbulb_outline,
                  color: isImpossible ? Colors.red : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isImpossible ? Colors.red : Theme.of(context).colorScheme.primary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
