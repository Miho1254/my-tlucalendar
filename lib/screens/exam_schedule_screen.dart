import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tlucalendar/providers/exam_provider.dart';
import 'package:tlucalendar/providers/auth_provider.dart';
import 'package:tlucalendar/providers/note_provider.dart';
import 'package:tlucalendar/features/exam/data/models/exam_dtos.dart' as Legacy;
import 'package:tlucalendar/widgets/schedule_skeleton.dart';
import 'package:tlucalendar/widgets/empty_state_widget.dart';
import 'package:tlucalendar/widgets/note_bottom_sheet.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:tlucalendar/utils/semester_parser.dart';

class ExamScheduleScreen extends StatefulWidget {
  const ExamScheduleScreen({super.key});

  @override
  State<ExamScheduleScreen> createState() => _ExamScheduleScreenState();
}

class _ExamScheduleScreenState extends State<ExamScheduleScreen> {
  bool _hasInitialized = false;
  bool? _lastLoginState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasInitialized) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.isLoggedIn) {
          _loadData();
          _hasInitialized = true;
          _lastLoginState = authProvider.isLoggedIn;
        }
      }
    });
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final examProvider = Provider.of<ExamProvider>(context, listen: false);

    if (!authProvider.isLoggedIn || authProvider.accessToken == null) return;

    await examProvider.fetchAvailableSemesters(authProvider.accessToken!);

    if (examProvider.selectedSemesterId != null) {
      await _loadExamSchedule(examProvider.selectedSemesterId!);
    }
  }

  Future<void> _loadExamSchedule(int semesterId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final examProvider = Provider.of<ExamProvider>(context, listen: false);

    if (!authProvider.isLoggedIn) {
      return;
    }

    final hasCache = await examProvider.hasRegisterPeriodsCache(semesterId);

    if (hasCache) {
      await examProvider.selectSemesterFromCache(semesterId);
    } else {
      await examProvider.selectSemester(
        authProvider.accessToken!,
        semesterId,
        authProvider.rawTokenStr,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ExamProvider>(
      builder: (context, authProvider, examProvider, _) {
        if (_lastLoginState != authProvider.isLoggedIn) {
          _lastLoginState = authProvider.isLoggedIn;
          _hasInitialized = false;

          if (authProvider.isLoggedIn && !_hasInitialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_hasInitialized) {
                _loadData();
                _hasInitialized = true;
              }
            });
          }
        }

        if (!authProvider.isLoggedIn) {
          return const Center(child: Text("Vui lòng đăng nhập"));
        }

        if (examProvider.isLoadingSemesters) {
          return const SafeArea(child: ScheduleSkeleton());
        }

        if (examProvider.errorMessage != null &&
            examProvider.availableSemesters.isEmpty) {
          return _buildError(examProvider.errorMessage!, _loadData);
        }

        if (examProvider.availableSemesters.isEmpty) {
          return const Center(child: Text("Không tìm thấy học kỳ nào"));
        }

        if (examProvider.isLoading) {
          return const SafeArea(child: ScheduleSkeleton());
        }

        if (examProvider.errorMessage != null &&
            examProvider.registerPeriods.isEmpty) {
          return _buildError(examProvider.errorMessage!, () async {
            if (examProvider.selectedSemesterId != null) {
              _loadExamSchedule(examProvider.selectedSemesterId!);
            } else {
              _loadData();
            }
          });
        }

        if (examProvider.registerPeriods.isEmpty && !examProvider.isLoading) {
          return FScaffold(
            header: const FHeader.nested(title: Text('Lịch thi')),
            child: RefreshIndicator(
              onRefresh: () async {
                await _loadData();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: _buildNoExams(),
                  ),
                ],
              ),
            ),
          );
        }

        return _buildExamSchedule(context, authProvider, examProvider);
      },
    );
  }

  Widget _buildError(String message, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message),
          ElevatedButton(onPressed: onRetry, child: const Text("Thử lại")),
        ],
      ),
    );
  }

  Widget _buildNoExams() {
    return Center(
      child: EmptyStateWidget(
        title: 'Chưa có lịch thi',
        icon: FLucideIcons.calendarX2,
        isGamified: false,
      ),
    );
  }

  Widget _buildExamSchedule(
    BuildContext context,
    AuthProvider authProvider,
    ExamProvider examProvider,
  ) {
    final selectedSemesterName =
        examProvider.selectedSemester?.semesterName.toReadableSemester ??
        'Chọn học kỳ';

    return RefreshIndicator(
      onRefresh: () async {
        if (examProvider.selectedSemesterId != null) {
          await examProvider.selectSemester(
            authProvider.accessToken!,
            examProvider.selectedSemesterId!,
            authProvider.rawTokenStr,
            forceRefresh: true,
          );
        }
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: false,
            snap: false,
            pinned: false,
            elevation: 0,
            title: Text(
              'Lịch thi',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(80),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: FTileGroup(
                  children: [
                    FTile(
                      prefix: Icon(
                        Icons.tune,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        'Bộ lọc hiển thị',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '$selectedSemesterName • Lần ${examProvider.selectedExamRound}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      suffix: const Icon(Icons.keyboard_arrow_down),
                      onPress: () {
                        HapticFeedback.lightImpact();
                        _showFilterBottomSheet(
                          context,
                          examProvider,
                          authProvider,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (examProvider.errorMessage != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.error.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_off,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        examProvider.errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Exam room details
          _buildExamRoomDetails(context, authProvider, examProvider),

          // Add bottom safe area padding (automatically accounts for the Liquid Glass tab bar)
          const SliverSafeArea(
            top: false,
            bottom: true,
            sliver: SliverToBoxAdapter(child: SizedBox(height: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildExamRoomDetails(
    BuildContext context,
    AuthProvider authProvider,
    ExamProvider examProvider,
  ) {
    if (examProvider.isLoadingRooms) {
      return const SliverToBoxAdapter(
        child: Padding(padding: EdgeInsets.all(16), child: ScheduleSkeleton()),
      );
    }

    if (examProvider.roomErrorMessage != null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    examProvider.roomErrorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (examProvider.selectedSemesterId != null &&
                          examProvider.selectedRegisterPeriodId != null) {
                        examProvider.fetchExamRoomDetails(
                          authProvider.accessToken!,
                          examProvider.selectedSemesterId!,
                          examProvider.selectedRegisterPeriodId!,
                          examProvider.selectedExamRound,
                          authProvider.rawTokenStr,
                        );
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (examProvider.examRooms.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                EmptyStateWidget(
                  title: 'Chưa có phòng thi',
                  icon: FLucideIcons.calendarOff,
                  isGamified: false,
                ),
                const SizedBox(height: 16),
                if (examProvider.selectedSemesterId != null &&
                    examProvider.selectedRegisterPeriodId != null)
                  ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      examProvider.fetchExamRoomDetails(
                        authProvider.accessToken!,
                        examProvider.selectedSemesterId!,
                        examProvider.selectedRegisterPeriodId!,
                        examProvider.selectedExamRound,
                        authProvider.rawTokenStr,
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tải lại'),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final examRoom = examProvider.examRooms[index];
        return AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 375),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: _buildExamRoomCard(context, examRoom, index),
            ),
          ),
        );
      }, childCount: examProvider.examRooms.length),
    );
  }

  void _showFilterBottomSheet(
    BuildContext context,
    ExamProvider examProvider,
    AuthProvider authProvider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer<ExamProvider>(
          builder: (context, provider, _) {
            final colorScheme = Theme.of(context).colorScheme;
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Icon(
                          FLucideIcons.filter,
                          size: 24,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Bộ lọc Lịch Thi',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(FLucideIcons.x),
                          style: IconButton.styleFrom(
                            backgroundColor: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Content
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        const SizedBox(height: 16),
                        // 1. Semester Selector
                        Text(
                          'HỌC KỲ',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant,
                                letterSpacing: 1.0,
                              ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: provider.selectedSemesterId,
                          hint: const Text('Chọn học kỳ'),
                          isExpanded: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          items: provider.availableSemesters.map((s) {
                            return DropdownMenuItem<int>(
                              value: s.id,
                              child: Text(s.semesterName.toReadableSemester),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              HapticFeedback.lightImpact();
                              provider.selectSemester(
                                authProvider.accessToken!,
                                val,
                                authProvider.rawTokenStr,
                              );
                            }
                          },
                        ),

                        const SizedBox(height: 24),

                        // 2. Register Period Selector
                        Text(
                          'ĐỢT HỌC',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant,
                                letterSpacing: 1.0,
                              ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: provider.selectedRegisterPeriodId,
                          hint: const Text('Chọn đợt học'),
                          isExpanded: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          items: provider.registerPeriods.map((p) {
                            return DropdownMenuItem<int>(
                              value: p.id,
                              child: Text(p.name),
                            );
                          }).toList(),
                          onChanged: provider.registerPeriods.isEmpty
                              ? null
                              : (val) {
                                  if (val != null &&
                                      provider.selectedSemesterId != null) {
                                    HapticFeedback.lightImpact();
                                    provider.selectRegisterPeriod(
                                      authProvider.accessToken!,
                                      provider.selectedSemesterId!,
                                      val,
                                      provider.selectedExamRound,
                                      authProvider.rawTokenStr,
                                    );
                                  }
                                },
                        ),

                        const SizedBox(height: 24),

                        // 3. Exam Round Selector
                        Text(
                          'LẦN THI',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant,
                                letterSpacing: 1.0,
                              ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: provider.selectedExamRound,
                          hint: const Text('Chọn lần thi'),
                          isExpanded: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          items: [1, 2, 3, 4, 5].map((round) {
                            return DropdownMenuItem<int>(
                              value: round,
                              child: Text('Lần $round'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              HapticFeedback.lightImpact();
                              if (provider.selectedSemesterId != null &&
                                  provider.selectedRegisterPeriodId != null) {
                                provider.selectExamRound(val);
                                provider.fetchExamRoomDetails(
                                  authProvider.accessToken!,
                                  provider.selectedSemesterId!,
                                  provider.selectedRegisterPeriodId!,
                                  val,
                                  authProvider.rawTokenStr,
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  // Bottom Button
                  Padding(
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      bottom: MediaQuery.of(context).padding.bottom + 24,
                      top: 16,
                    ),
                    child: FButton(
                      onPress: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      child: const Text('Áp dụng'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildExamRoomCard(
    BuildContext context,
    Legacy.StudentExamRoom examRoom,
    int index,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasNote = context.watch<NoteProvider>().hasNoteFor(
      examRoom.id.toString(),
    );

    // Calculate countdown
    String countdownText = '';
    Color countdownColor = colorScheme.primary;

    if (examRoom.examRoom?.examDateString != null) {
      try {
        final parts = examRoom.examRoom!.examDateString!.split('/');
        if (parts.length == 3) {
          final examDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
          final today = DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          );
          final diff = examDate.difference(today).inDays;

          if (diff < 0) {
            countdownText = 'Đã thi xong';
            countdownColor = colorScheme.onSurfaceVariant;
          } else if (diff == 0) {
            countdownText = 'Hôm nay thi!';
            countdownColor = theme.colorScheme.error;
          } else if (diff == 1) {
            countdownText = 'Ngày mai thi';
            countdownColor = Colors.orange;
          } else {
            countdownText = 'Còn $diff ngày';
            countdownColor = diff <= 7 ? Colors.orange : Colors.green;
          }
        }
      } catch (e) {
        // Ignore parse error
      }
    }

    return Padding(
      key: ValueKey(examRoom.id),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FCard.raw(
        style: FCardStyleDelta.delta(
          decoration: DecorationDelta.value(
            BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.15,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Subject Name and Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (countdownText.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: countdownColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  FLucideIcons.clock,
                                  size: 14,
                                  color: countdownColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  countdownText,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: countdownColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          examRoom.subjectName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          FLucideIcons.notebookPen,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        if (hasNote)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () {
                      DateTime? examDate;
                      if (examRoom.examRoom?.examDateString != null) {
                        try {
                          final parts = examRoom.examRoom!.examDateString!
                              .split('/');
                          if (parts.length == 3) {
                            examDate = DateTime(
                              int.parse(parts[2]),
                              int.parse(parts[1]),
                              int.parse(parts[0]),
                            );
                          }
                        } catch (_) {}
                      }

                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => NoteBottomSheet(
                          referenceId: examRoom.id.toString(),
                          title: examRoom.subjectName,
                          eventDate: examDate,
                        ),
                      );
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Content
              if (examRoom.examRoom != null) ...[
                // Highlight SBD & Room (Apple Health style boxes)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.4,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Phòng thi',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              examRoom.examRoom!.room?.name ?? '---',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.4,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Số báo danh',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              examRoom.examCode ?? '---',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Time & Date Details
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildCleanDetailRow(
                        context,
                        'Ngày thi',
                        examRoom.examRoom!.examDateString ?? '---',
                        FLucideIcons.calendarDays,
                      ),
                      Divider(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                        height: 24,
                      ),
                      _buildCleanDetailRow(
                        context,
                        'Thời gian',
                        examRoom.examRoom!.examHour != null
                            ? '${examRoom.examRoom!.examHour!.startString} - ${examRoom.examRoom!.examHour!.endString}'
                            : '---',
                        FLucideIcons.clock,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        FLucideIcons.info,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Chưa có thông tin chi tiết',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCleanDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: colorScheme.onSurface),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
