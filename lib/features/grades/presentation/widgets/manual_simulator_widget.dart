import 'package:flutter/material.dart';

import 'package:tlucalendar/features/grades/domain/services/grade_analytics_service.dart';

class ManualSimulatorWidget extends StatefulWidget {
  const ManualSimulatorWidget({super.key});

  @override
  State<ManualSimulatorWidget> createState() => _ManualSimulatorWidgetState();
}

class _ManualSimulatorWidgetState extends State<ManualSimulatorWidget> {
  double _markQT = 7.0;
  double _markTHI = 7.0;
  double _weightQT = 0.5; // 50%

  String _charMarkFrom10(double mark) {
    if (mark >= 8.5) return 'A';
    if (mark >= 7.0) return 'B';
    if (mark >= 5.5) return 'C';
    if (mark >= 4.0) return 'D';
    return 'F';
  }

  Color _getColorForChar(String charMark) {
    switch (charMark) {
      case 'A': return Colors.green;
      case 'B': return Colors.blue;
      case 'C': return Colors.orange;
      case 'D': return Colors.deepOrange;
      case 'F': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double finalMark = (_markQT * _weightQT) + (_markTHI * (1.0 - _weightQT));
    final String charMark = _charMarkFrom10(finalMark);
    final double gpa4 = GradeAnalyticsService.charToGpa4(charMark);

    return Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Trọng số (QT - Thi):"),
              DropdownButton<double>(
                value: _weightQT,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 0.3, child: Text("30% - 70%")),
                  DropdownMenuItem(value: 0.4, child: Text("40% - 60%")),
                  DropdownMenuItem(value: 0.5, child: Text("50% - 50%")),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _weightQT = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSlider("Điểm Quá Trình", _markQT, (val) => setState(() => _markQT = val)),
          const SizedBox(height: 16),
          _buildSlider("Điểm Thi", _markTHI, (val) => setState(() => _markTHI = val)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getColorForChar(charMark).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getColorForChar(charMark).withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildResultItem("Hệ 10", finalMark.toStringAsFixed(1)),
                _buildResultItem("Điểm Chữ", charMark, color: _getColorForChar(charMark)),
                _buildResultItem("Hệ 4", gpa4.toStringAsFixed(1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
            Text(value.toStringAsFixed(1), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 10,
          divisions: 100,
          activeColor: Theme.of(context).colorScheme.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildResultItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
      ],
    );
  }
}
