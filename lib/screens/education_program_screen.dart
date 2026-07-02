import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:forui/forui.dart';
import 'package:tlucalendar/providers/auth_provider.dart';
import 'package:tlucalendar/providers/education_program_provider.dart';
import 'package:tlucalendar/features/education_program/domain/entities/education_program.dart';

class EducationProgramScreen extends StatefulWidget {
  const EducationProgramScreen({super.key});

  @override
  State<EducationProgramScreen> createState() => _EducationProgramScreenState();
}

class _EducationProgramScreenState extends State<EducationProgramScreen>
    with SingleTickerProviderStateMixin {
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
      if (provider.program != null && mounted) {
        _setupTabs(provider.program!);
      }
    }
  }

  void _setupTabs(EducationProgram program) {
    if (!mounted) return;
    final semesters = program.subjectsBySemester.keys.toList()..sort();
    _tabController = TabController(length: semesters.length, vsync: this);
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
                    provider.errorMessage!,
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
            _setupTabs(program);
          }

          return Column(
            children: [
              _buildProgramHeader(context, program),
              _buildSemesterTabs(context, semesters, program),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: semesters.map((semester) {
                    return _buildSemesterContent(context, program, semester);
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgramHeader(BuildContext context, EducationProgram program) {
    final theme = FTheme.of(context);
    final colors = theme.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: colors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            program.name,
            style: theme.typography.body.lg.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${program.totalCredits} tín chỉ • ${program.subjects.length} môn học',
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

  Widget _buildSemesterContent(BuildContext context, EducationProgram program, int semester) {
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

          return _buildKnowledgeBlock(context, blockName, blockSubjects);
        },
      ),
    );
  }

  Widget _buildKnowledgeBlock(BuildContext context, String blockName, List<ProgramSubject> subjects) {
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
                    style: theme.typography.body.sm.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.foreground,
                    ),
                  ),
                ),
                FBadge(
                  variant: FBadgeVariant.secondary,
                  child: Text('$totalCredits TC'),
                ),
              ],
            ),
          ),
          ...subjects.map((subject) => _buildSubjectItem(context, subject)),
        ],
      ),
    );
  }

  Widget _buildSubjectItem(BuildContext context, ProgramSubject subject) {
    final theme = FTheme.of(context);
    final colors = theme.colors;
    final isRequired = subject.subjectType == 1;

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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subject.name,
                        style: theme.typography.body.sm.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colors.foreground,
                        ),
                      ),
                    ),
                  ],
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
                        color: isRequired
                            ? Colors.blue.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        subject.subjectTypeLabel,
                        style: theme.typography.body.xs.copyWith(
                          color: isRequired ? Colors.blue.shade600 : Colors.orange.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.muted.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${subject.credits}',
              style: theme.typography.body.sm.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.foreground,
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
