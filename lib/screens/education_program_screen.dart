import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';
import 'package:tlucalendar/providers/auth_provider.dart';
import 'package:tlucalendar/providers/education_program_provider.dart';
import 'package:tlucalendar/providers/grade_provider.dart';
import 'package:tlucalendar/features/education_program/domain/entities/education_program.dart';
import 'package:tlucalendar/utils/error_messages.dart';

class EducationProgramScreen extends StatefulWidget {
  const EducationProgramScreen({super.key});

  @override
  State<EducationProgramScreen> createState() => _EducationProgramScreenState();
}

class _EducationProgramScreenState extends State<EducationProgramScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProgram();
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _fetchProgram({bool forceRefresh = false}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<EducationProgramProvider>(context, listen: false);
    final token = authProvider.accessToken;
    if (token != null) {
      await provider.fetchProgram(token, forceRefresh: forceRefresh);
    }
  }

  void _setupTabs(EducationProgram program) {
    if (!mounted) return;
    _tabController?.dispose();
    final semesters = program.subjectsBySemester.keys.toList()..sort();
    _tabController = TabController(length: semesters.length, vsync: this);
  }

  Set<String> _getStudiedCodes(BuildContext context) {
    final gradeProvider = Provider.of<GradeProvider>(context, listen: false);
    return gradeProvider.grades.map((g) => g.subjectCode).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final colors = theme.colors;

    return FScaffold(
      header: FHeader.nested(
        title: const Text('Chương trình đào tạo'),
        prefixes: [
          FHeaderAction(
            icon: const Icon(Icons.arrow_back, size: 20),
            onPress: () => Navigator.of(context).pop(),
          ),
        ],
        suffixes: [
          FHeaderAction(
            icon: const Icon(FLucideIcons.refreshCw, size: 20),
            onPress: () => _fetchProgram(forceRefresh: true),
          ),
        ],
      ),
      child: Consumer<EducationProgramProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off_rounded, size: 64, color: colors.destructive),
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
                    ErrorMessages.friendly(provider.errorMessage),
                    textAlign: TextAlign.center,
                    style: theme.typography.body.md.copyWith(color: colors.mutedForeground),
                  ),
                  const SizedBox(height: 24),
                  FButton(
                    onPress: () => _fetchProgram(forceRefresh: true),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final program = provider.program;
          if (program == null) {
            return const Center(child: Text('Không có dữ liệu'));
          }

          final semesters = program.subjectsBySemester.keys.toList()..sort();
          final ctrl = _tabController;

          if (ctrl == null || ctrl.length != semesters.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _setupTabs(program);
                setState(() {});
              }
            });
            return const Center(child: CircularProgressIndicator());
          }

          final studiedCodes = _getStudiedCodes(context);

          return Column(
            children: [
              _buildProgramInfo(context, program, studiedCodes),
              _buildSemesterTabs(context, semesters, program),
              Expanded(
                child: TabBarView(
                  controller: ctrl,
                  children: semesters.map((semester) {
                    return _buildSemesterContent(context, program, semester, studiedCodes);
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgramInfo(BuildContext context, EducationProgram program, Set<String> studiedCodes) {
    final theme = FTheme.of(context);
    final colors = theme.colors;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            program.name,
            style: theme.typography.body.lg.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${program.totalCredits} tín chỉ · ${program.subjects.length} môn học · ${studiedCodes.length} đã học',
            style: theme.typography.body.sm.copyWith(
              color: colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterTabs(BuildContext context, List<int> semesters, EducationProgram program) {
    final theme = FTheme.of(context);
    final colors = theme.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(
          bottom: BorderSide(color: colors.border),
        ),
      ),
      child: TabBar(
        controller: _tabController!,
        isScrollable: true,
        labelColor: colors.primary,
        unselectedLabelColor: colors.mutedForeground,
        indicatorColor: colors.primary,
        tabs: semesters.map((semester) {
          final credits = program.creditsBySemester(semester);
          return Tab(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getSemesterName(semester),
                  style: theme.typography.body.sm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$credits TC',
                  style: theme.typography.body.xs.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSemesterContent(BuildContext context, EducationProgram program, int semester, Set<String> studiedCodes) {
    final theme = FTheme.of(context);
    final colors = theme.colors;
    final subjects = program.subjectsBySemester[semester] ?? [];

    if (subjects.isEmpty) {
      return Center(
        child: Text(
          'Không có môn học',
          style: theme.typography.body.md.copyWith(color: colors.mutedForeground),
        ),
      );
    }

    // Group by knowledge block
    final grouped = <String, List<ProgramSubject>>{};
    for (final subject in subjects) {
      final block = subject.knowledgeBlock.isNotEmpty ? subject.knowledgeBlock : 'Khác';
      grouped.putIfAbsent(block, () => []).add(subject);
    }

    return RefreshIndicator(
      onRefresh: () => _fetchProgram(forceRefresh: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final blockName = grouped.keys.elementAt(index);
          final blockSubjects = grouped[blockName]!;

          return _buildKnowledgeBlock(context, blockName, blockSubjects, studiedCodes);
        },
      ),
    );
  }

  Widget _buildKnowledgeBlock(BuildContext context, String blockName, List<ProgramSubject> subjects, Set<String> studiedCodes) {
    final theme = FTheme.of(context);
    final colors = theme.colors;
    final totalCredits = subjects.fold(0, (sum, s) => sum + s.credits);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: colors.muted.withValues(alpha: 0.3),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    blockName,
                    style: theme.typography.body.md.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.foreground,
                    ),
                  ),
                ),
                Text(
                  '$totalCredits TC',
                  style: theme.typography.body.xs.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          ...subjects.map((subject) => _buildSubjectItem(context, subject, studiedCodes)),
        ],
      ),
    );
  }

  Widget _buildSubjectItem(BuildContext context, ProgramSubject subject, Set<String> studiedCodes) {
    final theme = FTheme.of(context);
    final colors = theme.colors;
    final isStudied = studiedCodes.contains(subject.code);

    final (Color badgeBg, Color badgeFg) = switch (subject.subjectType) {
      1 => (Colors.blue.withValues(alpha: 0.1), Colors.blue.shade600),
      2 => (Colors.orange.withValues(alpha: 0.1), Colors.orange.shade600),
      3 => (Colors.green.withValues(alpha: 0.1), Colors.green.shade600),
      _ => (colors.muted, colors.mutedForeground),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.name,
                  style: theme.typography.body.sm.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isStudied ? Colors.green.shade700 : colors.foreground,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      subject.code,
                      style: theme.typography.body.xs.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        subject.subjectTypeLabel,
                        style: theme.typography.body.xs.copyWith(
                          color: badgeFg,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isStudied) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Đã học',
                    style: theme.typography.body.xs.copyWith(
                      color: Colors.green.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isStudied ? Colors.green.withValues(alpha: 0.1) : colors.muted.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${subject.credits}',
              style: theme.typography.body.sm.copyWith(
                fontWeight: FontWeight.bold,
                color: isStudied ? Colors.green.shade700 : colors.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSemesterName(int semester) {
    if (semester <= 0) return 'BB';
    return 'Kỳ $semester';
  }
}
