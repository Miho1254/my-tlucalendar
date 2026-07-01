import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tlucalendar/features/grades/domain/entities/student_mark.dart';
import 'package:tlucalendar/providers/auth_provider.dart';
import 'package:tlucalendar/providers/grade_provider.dart';
import 'package:forui/forui.dart';
import 'package:tlucalendar/utils/semester_parser.dart';

class GradeScreen extends StatefulWidget {
  const GradeScreen({super.key});

  @override
  State<GradeScreen> createState() => _GradeScreenState();
}

class _GradeScreenState extends State<GradeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchGrades();
    });
  }

  Future<void> _fetchGrades({bool forceRefresh = false}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final gradeProvider = Provider.of<GradeProvider>(context, listen: false);
    final token = authProvider.accessToken;
    if (token != null) {
      gradeProvider.fetchGrades(token, forceRefresh: forceRefresh);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: FHeader.nested(
        title: const Text('Tra cứu điểm'),
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
      child: Consumer<GradeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.grades.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.grades.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Lỗi: ${provider.errorMessage}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _fetchGrades(forceRefresh: true),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _fetchGrades(forceRefresh: true),
            child: _buildGradeList(provider.groupedGrades),
          );
        },
      ),
    );
  }

  Widget _buildGradeList(Map<String, List<StudentMark>> groupedGrades) {
    if (groupedGrades.isEmpty) {
      return const Center(
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 300,
            child: Center(child: Text('Không có dữ liệu điểm.')),
          ),
        ),
      );
    }

    final semesterKeys = groupedGrades.keys.toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24, top: 16, left: 16, right: 16),
      child: FAccordion(
        children: semesterKeys.asMap().entries.map((entry) {
          final index = entry.key;
          final semesterName = entry.value;
          final grades = groupedGrades[semesterName]!;

          return FAccordionItem(
            initiallyExpanded: index == 0,
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    semesterName.toReadableSemester,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                FBadge(
                  child: Text('${grades.length} môn'),
                  variant: FBadgeVariant.secondary,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: grades.map((mark) => _buildGradeItem(mark)).toList(),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getGradeColor(String charMark, FColors colors) {
    final mark = charMark.trim().toUpperCase();
    if (mark.startsWith('A')) {
      return Colors.green.shade600;
    } else if (mark.startsWith('B')) {
      return Colors.blue.shade600;
    } else if (mark.startsWith('C')) {
      return Colors.orange.shade600;
    } else if (mark.startsWith('D')) {
      return Colors.deepOrange.shade500;
    } else if (mark.startsWith('F')) {
      return colors.destructive;
    }
    return colors.foreground;
  }

  Widget _buildGradeItem(StudentMark mark) {
    final isPass = mark.charMark.isNotEmpty && mark.charMark.toUpperCase() != 'F';
    final hasMark = mark.charMark.isNotEmpty;
    final theme = FTheme.of(context);
    final colors = theme.colors;
    final gradeColor = _getGradeColor(mark.charMark, colors);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(
          color: colors.border,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (hasMark) ...[
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: gradeColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    mark.charMark,
                    style: theme.typography.body.xl.copyWith(
                      color: gradeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mark.subjectName,
                      style: theme.typography.body.md.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${mark.subjectCode} • ${mark.numberOfCredit} TC • Lần học: ${mark.studyTime}',
                      style: theme.typography.body.sm.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasMark) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: colors.muted.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildScoreColumn("Quá trình", mark.markQT.toString()),
                  _buildScoreColumn("Thi", mark.markTHI.toString()),
                  _buildScoreColumn("Tổng kết", mark.mark.toString(), isBold: true, isPass: isPass),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildScoreColumn(String label, String score, {bool isBold = false, bool? isPass}) {
    final theme = FTheme.of(context);
    final colors = theme.colors;

    Color? scoreColor = colors.foreground;
    if (isPass != null) {
      scoreColor = isPass ? Colors.green.shade600 : colors.destructive;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: theme.typography.body.sm.copyWith(
                color: colors.mutedForeground,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          score,
          style: theme.typography.body.md.copyWith(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: scoreColor,
              ),
        ),
      ],
    );
  }
}
