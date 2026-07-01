class SemesterInfo {
  final int semester;
  final int startYear;
  final int endYear;

  SemesterInfo({
    required this.semester,
    required this.startYear,
    required this.endYear,
  });

  String get readableName {
    if (semester == 3) {
      return 'Kỳ Hè, $startYear-$endYear';
    }
    return 'Kỳ $semester, $startYear-$endYear';
  }

  String get shortReadableName {
    final shortStart = startYear % 100;
    final shortEnd = endYear % 100;
    if (semester == 3) {
      return 'Kỳ Hè ($shortStart-$shortEnd)';
    }
    return 'Kỳ $semester ($shortStart-$shortEnd)';
  }

  @override
  String toString() => readableName;
}

extension SemesterParserExt on String {
  /// Parses a semester string like '1_2025_2026' into a [SemesterInfo] object.
  SemesterInfo? parseSemester() {
    final parts = split('_');
    if (parts.length >= 3) {
      final term = int.tryParse(parts[0]);
      final startYear = int.tryParse(parts[1]);
      final endYear = int.tryParse(parts[2]);

      if (term != null && startYear != null && endYear != null) {
        return SemesterInfo(
          semester: term,
          startYear: startYear,
          endYear: endYear,
        );
      }
    }
    return null;
  }

  /// Quickly formats '1_2025_2026' -> 'Kỳ 1, 2025-2026'
  String get toReadableSemester {
    final info = parseSemester();
    return info?.readableName ?? this;
  }

  /// Quickly formats '1_2025_2026' -> 'Kỳ 1 (25-26)'
  String get toShortReadableSemester {
    final info = parseSemester();
    return info?.shortReadableName ?? this;
  }
}
