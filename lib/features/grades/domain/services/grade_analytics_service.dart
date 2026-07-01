import 'package:tlucalendar/features/grades/domain/entities/student_mark.dart';

class RadarSkillGroup {
  final String groupName;
  final double averageScore;
  final int totalCredits;

  RadarSkillGroup(this.groupName, this.averageScore, this.totalCredits);
}

class SemesterTrend {
  final String semesterName;
  final int semesterId;
  final double gpa10;
  final double gpa4;
  final int passedCredits;
  final int registeredCredits;
  final bool hasFailedSubject;
  final double avgQT;
  final double avgTHI;

  SemesterTrend(this.semesterName, this.semesterId, this.gpa10, this.gpa4, this.passedCredits, this.registeredCredits, this.hasFailedSubject, [this.avgQT = 0, this.avgTHI = 0]);
}

class AdvisorMessage {
  final String title;
  final String subtitle;
  AdvisorMessage(this.title, this.subtitle);
}

class GradeAnalyticsResult {
  final double cumulativeGpa10;
  final double cumulativeGpa4;
  final int totalPassedCredits;
  final int totalFailedCredits;
  final String academicRanking;
  final List<SemesterTrend> trend;
  final List<RadarSkillGroup> skillGroups;
  
  // RAW DATA for UI if needed
  final List<StudentMark> failedSubjects;
  final List<StudentMark> trailingSubjects;
  
  // ADVISOR INSIGHTS
  final AdvisorMessage? personaMessage;
  final AdvisorMessage? nemesisMessage;
  final AdvisorMessage? overloadMessage;
  final AdvisorMessage? trendMessage;
  final AdvisorMessage? failedMessage;
  final AdvisorMessage? trailingMessage;
  final AdvisorMessage? shiningStarMessage;
  final AdvisorMessage? consistencyMessage;
  final AdvisorMessage? improvementMessage;
  final AdvisorMessage? teamCarryMessage;
  final AdvisorMessage? achievementMessage;
  final AdvisorMessage? aStreakMessage;
  final AdvisorMessage? noFailMessage;
  final AdvisorMessage? bestSemesterMessage;
  final AdvisorMessage? nextRankMessage;

  GradeAnalyticsResult({
    required this.cumulativeGpa10,
    required this.cumulativeGpa4,
    required this.totalPassedCredits,
    required this.totalFailedCredits,
    required this.academicRanking,
    required this.trend,
    required this.skillGroups,
    required this.failedSubjects,
    required this.trailingSubjects,
    this.personaMessage,
    this.nemesisMessage,
    this.overloadMessage,
    this.trendMessage,
    this.failedMessage,
    this.trailingMessage,
    this.shiningStarMessage,
    this.consistencyMessage,
    this.improvementMessage,
    this.teamCarryMessage,
    this.achievementMessage,
    this.aStreakMessage,
    this.noFailMessage,
    this.bestSemesterMessage,
    this.nextRankMessage,
  });
}

class GradeAnalyticsService {
  static double charToGpa4(String charMark) {
    switch (charMark.toUpperCase()) {
      case 'A': return 4.0;
      case 'B': return 3.0;
      case 'C': return 2.0;
      case 'D': return 1.0;
      case 'F': return 0.0;
      default: return 0.0;
    }
  }

  static String getAcademicRanking(double gpa4) {
    if (gpa4 >= 3.6) return "Xuất sắc";
    if (gpa4 >= 3.2) return "Giỏi";
    if (gpa4 >= 2.5) return "Khá";
    if (gpa4 >= 2.0) return "Trung bình";
    if (gpa4 >= 1.0) return "Yếu";
    return "Kém";
  }

  static bool isGraduationSubject(StudentMark mark) {
    if (!mark.isCalculateMark) return false;
    final code = mark.subjectCode.toUpperCase();
    final name = mark.subjectName.toLowerCase();
    
    if (code.startsWith('CV') || code.startsWith('DK') || code.startsWith('BL') || 
        code.startsWith('BĐ') || code.startsWith('BD') || code.startsWith('BC') || 
        code.startsWith('BR') || name.contains('giáo dục thể chất')) {
      return false;
    }
    if (code.startsWith('QP') || code.startsWith('GDQP') || name.contains('quốc phòng')) {
      return false;
    }
    if (code.startsWith('TATC') || name.contains('tiếng anh tăng cường')) {
      return false;
    }
    return true;
  }
  
  // --- ADVISOR LOGIC ---
  static AdvisorMessage? _generatePersonaAdvice(Map<String, StudentMark> bestMarks, double cumulativeGpa4) {
    double sumQT = 0;
    double sumTHI = 0;
    int count = 0;
    
    for (var m in bestMarks.values) {
      if (m.markQT > 0 || m.markTHI > 0) {
        sumQT += m.markQT;
        sumTHI += m.markTHI;
        count++;
      }
    }
    
    if (count < 3) return null; // Not enough data
    
    double avgQT = sumQT / count;
    double avgTHI = sumTHI / count;
    double diff = avgTHI - avgQT;
    
    if (avgQT > 8.0 && avgTHI < 5.5) {
        return AdvisorMessage("Ong Chăm Chỉ", "Điểm quá trình cao chót vót nhưng điểm thi tà tà. Sự chăm chỉ đi học là phao cứu sinh vững chắc của bạn!");
    } else if (avgQT < 5.5 && avgTHI > 8.0) {
        return AdvisorMessage("Trùm Phòng Thi", "Bình thường im hơi lặng tiếng nhưng vào phòng thi là gánh team. Khả năng bứt tốc cuối kỳ của bạn quá nể!");
    } else if (avgQT > 8.0 && diff < -3.0) {
        return AdvisorMessage("Học Tài Thi Phận", "Tâm lý phòng thi có vẻ bất ổn. Bạn nỗ lực cả kỳ nhưng hay bị rớt phong độ ở bài thi cuối môn.");
    } else if (avgQT >= 8.0 && avgTHI >= 8.0) {
        return AdvisorMessage("Học Bá Toàn Năng", "Đỉnh cả quá trình lẫn thi cử. Không có lỗ hổng nào trong phong cách học của bạn!");
    } else if (avgQT < 5.0 && avgTHI < 5.0) {
        if (cumulativeGpa4 < 2.0) {
          return AdvisorMessage("Cần xem lại ngay", "Cả điểm quá trình lẫn thi cử đều thấp, GPA tích lũy đang ở vùng nguy hiểm. Cần thay đổi phương pháp học triệt để!");
        }
        return AdvisorMessage("Khách Lãng Du", "Có vẻ bạn đam mê các hoạt động ngoại khóa hơn là việc trên giảng đường. Cần tập trung học hơn nhé!");
    } else if (diff.abs() <= 1.0 && avgQT >= 6.5) {
        if (cumulativeGpa4 >= 3.2) {
          return AdvisorMessage("Cán Cân Hoàn Hảo", "Phong độ cực kỳ ổn định từ trên lớp đến phòng thi, với GPA tích lũy ${cumulativeGpa4.toStringAsFixed(2)}. Đẳng cấp!");
        }
        return AdvisorMessage("Cán Cân Ổn Định", "Điểm quá trình và thi cử khá đồng đều. Nền tảng vững, giờ cần đẩy cao hơn nữa!");
    } else {
        if (cumulativeGpa4 < 2.0) {
          return AdvisorMessage("Chiến Binh Cần Chiến Lược", "Phong cách học chưa rõ ràng và GPA đang ở mức báo động. Cần tìm ra phương pháp phù hợp với bản thân.");
        }
        return AdvisorMessage("Chiến Binh Thầm Lặng", "Phong cách học tập của bạn rất khó đoán, luôn biết cách vừa đủ để sinh tồn qua các mùa thi.");
    }
  }

  static AdvisorMessage? _generateNemesisAdvice(List<StudentMark> allMarks) {
    if (allMarks.isEmpty) return null;
    Map<String, int> studyCounts = {};
    for (var m in allMarks) {
      if (m.numberOfCredit > 0 && isGraduationSubject(m)) {
        if (!studyCounts.containsKey(m.subjectCode) || m.studyTime > studyCounts[m.subjectCode]!) {
          studyCounts[m.subjectCode] = m.studyTime;
        }
      }
    }
    
    String? nemesisCode;
    int maxStudyTime = 0;
    
    studyCounts.forEach((code, time) {
      if (time > maxStudyTime) {
        maxStudyTime = time;
        nemesisCode = code;
      }
    });
    
    if (nemesisCode != null && maxStudyTime >= 3) {
      final name = allMarks.firstWhere((m) => m.subjectCode == nemesisCode).subjectName;
      return AdvisorMessage("Kẻ thù truyền kiếp", "Môn '$name' đã hành hạ bạn tới lần học thứ $maxStudyTime. Lần này phải phục thù dứt điểm nhé!");
    } else if (nemesisCode != null && maxStudyTime == 2) {
      final name = allMarks.firstWhere((m) => m.subjectCode == nemesisCode).subjectName;
      return AdvisorMessage("Oan gia ngõ hẹp", "Vấp ngã ở '$name' một lần là quá đủ rồi, lần thứ 2 này phải làm cỏ nó.");
    }
    return null;
  }

  static AdvisorMessage? _generateOverloadAdvice(List<SemesterTrend> trend) {
    if (trend.isEmpty) return null;
    
    int maxCredits = 0;
    SemesterTrend? overloadSem;
    
    for (var t in trend) {
      if (t.registeredCredits > maxCredits) {
        maxCredits = t.registeredCredits;
        overloadSem = t;
      }
    }
    
    if (overloadSem != null) {
      if (maxCredits >= 22) {
        if (overloadSem.gpa4 >= 3.2) {
          return AdvisorMessage("Máy ủi học vụ", "Từng cày tới $maxCredits tín chỉ trong kỳ ${overloadSem.semesterName} mà vẫn đạt GPA ${overloadSem.gpa4.toStringAsFixed(2)}. Sức chiến đấu của bạn thật đáng sợ!");
        } else if (overloadSem.gpa4 <= 2.0) {
          return AdvisorMessage("Ngộp thở vì tín chỉ", "Kỳ ${overloadSem.semesterName} ôm $maxCredits tín chỉ đã khiến phong độ lao dốc. Hãy biết lượng sức mình để giữ form nhé.");
        }
      } else if (maxCredits <= 15 && trend.length >= 3) {
        return AdvisorMessage("Dưỡng sinh học phái", "Chưa kỳ nào học quá 15 tín chỉ, bạn đang tận hưởng thanh xuân đại học một cách rất từ tốn.");
      }
    }
    return null;
  }

  
  static AdvisorMessage? _generateTrendAdvice(List<SemesterTrend> trend) {
    if (trend.length < 2) {
      if (trend.length == 1) {
        final gpa = trend.first.gpa4;
        if (gpa >= 3.2) {
          return AdvisorMessage("Tân binh xuất chúng", "Kỳ đầu tiên đã cán mốc GPA ${gpa.toStringAsFixed(2)}. Một khởi đầu cực kỳ ấn tượng!");
        } else if (gpa >= 2.5) {
          return AdvisorMessage("Tân binh lên đường", "Kỳ đầu ổn với GPA ${gpa.toStringAsFixed(2)}. Nền móng vững rồi, cứ thế phát huy nhé!");
        } else if (gpa >= 2.0) {
          return AdvisorMessage("Tân binh cần tăng tốc", "Kỳ đầu GPA ${gpa.toStringAsFixed(2)} — chưa nguy hiểm nhưng cần cải thiện sớm để không bị động kỳ sau.");
        } else {
          return AdvisorMessage("Cảnh báo sớm", "Kỳ đầu GPA ${gpa.toStringAsFixed(2)} đang dưới mức an toàn. Cần xem lại phương pháp học ngay từ bây giờ!");
        }
      }
      return null;
    }
    
    final last = trend.last;
    final prev = trend[trend.length - 2];
    final diff = last.gpa4 - prev.gpa4;
    final currentGpa = last.gpa4;
    
    // 3-semester streak detection (GPA-level-aware)
    if (trend.length >= 3) {
      final prev2 = trend[trend.length - 3];
      if (last.gpa4 > prev.gpa4 && prev.gpa4 > prev2.gpa4) {
        if (currentGpa < 2.0) {
          return AdvisorMessage("Đang hồi sinh!", "GPA tăng liên tục 3 kỳ — tín hiệu tích cực! Nhưng hiện tại vẫn ở mức ${currentGpa.toStringAsFixed(2)}, cần đẩy mạnh hơn nữa để thoát vùng nguy hiểm.");
        } else if (currentGpa < 2.5) {
          return AdvisorMessage("Đà tăng trưởng tốt", "3 kỳ liên tục tăng, đang hướng tới hạng Khá. Giữ vững đà này nhé!");
        } else {
          return AdvisorMessage("Chuỗi thăng hoa", "GPA tăng liên tục qua 3 kỳ, hiện đạt ${currentGpa.toStringAsFixed(2)}. Phong độ đỉnh cao!");
        }
      }
      if (last.gpa4 < prev.gpa4 && prev.gpa4 < prev2.gpa4) {
        if (currentGpa < 2.0) {
          return AdvisorMessage("KHẨN CẤP: Trượt dốc không phanh", "GPA giảm 3 kỳ liên tiếp và đang ở mức ${currentGpa.toStringAsFixed(2)} — nguy cơ cảnh báo học vụ rất cao! Cần hành động ngay lập tức.");
        } else if (currentGpa < 2.5) {
          return AdvisorMessage("Cảnh báo trượt dốc", "Phong độ giảm 3 kỳ liên tiếp, GPA hiện ${currentGpa.toStringAsFixed(2)}. Nếu không phanh lại, sẽ rơi vào vùng nguy hiểm.");
        } else {
          return AdvisorMessage("Đang mất đà", "GPA đang giảm dần đều qua 3 kỳ rồi. Dù vẫn ở mức ${currentGpa.toStringAsFixed(2)}, nhưng cần xốc lại trước khi quá muộn.");
        }
      }
    }

    // 2-semester comparison (GPA-level-aware)
    if (currentGpa < 2.0) {
      // DANGER ZONE: every message must convey urgency
      if (diff > 0.3) {
        return AdvisorMessage("Tia hy vọng!", "Tăng ${diff.toStringAsFixed(2)} điểm — bứt phá tốt! Nhưng GPA ${currentGpa.toStringAsFixed(2)} vẫn dưới mức an toàn, cần duy trì đà này.");
      } else if (diff > 0) {
        return AdvisorMessage("Chưa đủ tốc độ", "Tăng ${diff.toStringAsFixed(2)} điểm là tín hiệu tốt, nhưng GPA ${currentGpa.toStringAsFixed(2)} vẫn ở vùng đỏ. Cần nỗ lực mạnh mẽ hơn nữa.");
      } else if (diff < -0.3) {
        return AdvisorMessage("BÁO ĐỘNG ĐỎ", "GPA giảm ${diff.abs().toStringAsFixed(2)} điểm, hiện chỉ còn ${currentGpa.toStringAsFixed(2)}. Đang ở ngưỡng cảnh báo học vụ — cần hành động khẩn cấp!");
      } else if (diff < 0) {
        return AdvisorMessage("Tình hình nghiêm trọng", "GPA tiếp tục giảm, hiện ${currentGpa.toStringAsFixed(2)}. Cần tập trung toàn lực cho kỳ tới nếu không muốn bị cảnh báo.");
      } else {
        return AdvisorMessage("Giậm chân tại chỗ", "GPA đứng yên ở ${currentGpa.toStringAsFixed(2)} — dưới mức trung bình. Cần thay đổi phương pháp học để bứt lên.");
      }
    } else if (currentGpa < 2.5) {
      // STRUGGLING ZONE: encouragement + gentle push
      if (diff > 0.5) {
        return AdvisorMessage("Bứt phá ngoạn mục!", "Tăng tận ${diff.toStringAsFixed(2)} điểm! Đang tiến gần tới hạng Khá rồi, chỉ cần thêm chút nữa thôi!");
      } else if (diff > 0) {
        return AdvisorMessage("Đang đi đúng hướng", "Tăng ${diff.toStringAsFixed(2)} điểm. GPA ${currentGpa.toStringAsFixed(2)} đang dần tiệm cận hạng Khá. Cố thêm kỳ nữa!");
      } else if (diff < -0.5) {
        return AdvisorMessage("Cần phanh gấp!", "Giảm ${diff.abs().toStringAsFixed(2)} điểm, GPA ${currentGpa.toStringAsFixed(2)} đang tiến gần vùng nguy hiểm. Ưu tiên các môn dễ lấy điểm ở kỳ sau nhé.");
      } else if (diff < 0) {
        return AdvisorMessage("Hơi chững lại", "Giảm nhẹ ${diff.abs().toStringAsFixed(2)} điểm. Ở mức GPA ${currentGpa.toStringAsFixed(2)} thì không nên để giảm thêm nữa.");
      } else {
        return AdvisorMessage("Cần tạo đột phá", "GPA giậm chân ở ${currentGpa.toStringAsFixed(2)}. Muốn lên hạng Khá thì kỳ sau phải quyết liệt hơn!");
      }
    } else if (currentGpa < 3.2) {
      // SOLID ZONE: balanced feedback
      if (diff > 0.5) {
        return AdvisorMessage("Bứt phá ngoạn mục!", "Tăng ${diff.toStringAsFixed(2)} điểm, GPA đang hướng tới hạng Giỏi. Một sự lột xác thực sự!");
      } else if (diff > 0) {
        return AdvisorMessage("Phong độ đang lên", "Tăng nhẹ ${diff.toStringAsFixed(2)} điểm. GPA ${currentGpa.toStringAsFixed(2)} ổn định ở vùng Khá. Cứ giữ đà này!");
      } else if (diff < -0.5) {
        return AdvisorMessage("Sa sút đáng kể", "Giảm ${diff.abs().toStringAsFixed(2)} điểm. Kỳ này gặp khó khăn gì vậy? Vẫn ở hạng Khá nhưng cần cẩn thận.");
      } else if (diff < 0) {
        return AdvisorMessage("Hơi chững lại", "Giảm nhẹ ${diff.abs().toStringAsFixed(2)} điểm. Phong độ là nhất thời, kỳ sau gỡ lại nhé!");
      } else {
        return AdvisorMessage("Ổn định vùng Khá", "GPA giữ vững ở ${currentGpa.toStringAsFixed(2)}. Muốn lên Giỏi thì cần đẩy mạnh hơn chút nữa!");
      }
    } else {
      // HIGH ZONE (≥3.2): celebrate appropriately
      if (diff > 0.3) {
        return AdvisorMessage("Siêu sao bứt tốc!", "Ở đẳng cấp ${currentGpa.toStringAsFixed(2)} mà còn tăng thêm ${diff.toStringAsFixed(2)} điểm. Huyền thoại là đây!");
      } else if (diff > 0) {
        return AdvisorMessage("Đỉnh cao vẫn tiến", "GPA ${currentGpa.toStringAsFixed(2)} đã rất cao mà vẫn tăng thêm. Không ai cản nổi bạn!");
      } else if (diff < -0.5) {
        return AdvisorMessage("Vấp ngã ở đỉnh cao", "Giảm ${diff.abs().toStringAsFixed(2)} điểm — khá đau! Nhưng với nền tảng GPA ${currentGpa.toStringAsFixed(2)}, bạn hoàn toàn đủ sức phục hồi.");
      } else if (diff < 0) {
        return AdvisorMessage("Chỉnh phong độ", "Giảm nhẹ ${diff.abs().toStringAsFixed(2)} điểm. Ở tầm ${currentGpa.toStringAsFixed(2)} thì đây chỉ là dao động nhỏ, không đáng lo.");
      } else {
        return AdvisorMessage("Bất khả chiến bại", "GPA giữ vững ở đỉnh ${currentGpa.toStringAsFixed(2)}. Sự ổn định ở level này mới thực sự đáng nể!");
      }
    }
  }

  static AdvisorMessage? _generateFailedAdvice(List<StudentMark> failed) {
    if (failed.isEmpty) return null;
    if (failed.length == 1) {
      return AdvisorMessage("Báo động đỏ: Nợ môn", "Bạn đang nợ môn ${failed.first.subjectName}. Tai nạn nhỏ thôi, nhớ canh lúc mở lớp để đăng ký học lại dứt điểm nhé.");
    } else if (failed.length <= 3) {
      final names = failed.map((e) => e.subjectName).join(', ');
      return AdvisorMessage("Báo động đỏ: Nợ môn", "Bạn đang nợ ${failed.length} môn ($names). Chú ý đăng ký học lại sớm, để lâu là dồn đống đó nha.");
    } else {
      return AdvisorMessage("SOS: Khủng hoảng nợ môn", "Trời ơi, nợ tới ${failed.length} môn rồi! Khoan hẵng đăng ký học mới, hãy ưu tiên trả nợ môn để tránh bị cảnh báo học vụ nhé!");
    }
  }

  static AdvisorMessage? _generateTrailingAdvice(List<StudentMark> trailing, double currentGpa) {
    if (trailing.isEmpty) return null;
    final worst = trailing.first;
    if (trailing.length == 1) {
      return AdvisorMessage("Kẻ bám đuôi", "Môn ${worst.subjectName} (${worst.charMark}) đang là 'tì vết' duy nhất kéo lùi bảng điểm của bạn.");
    } else {
      final names = trailing.take(2).map((e) => e.subjectName).join(', ');
      final more = trailing.length > 2 ? " và ${trailing.length - 2} môn khác" : "";
      return AdvisorMessage("Những kẻ bám đuôi", "Các môn như $names$more đang kéo tụt điểm của bạn. Nếu có thời gian rảnh, hãy cân nhắc học cải thiện nhé.");
    }
  }

  static AdvisorMessage? _generateShiningStarAdvice(StudentMark? star) {
    if (star == null) return null;
    final name = star.subjectName.toLowerCase();
    
    // Check for infamous hard subjects
    final hardSubjects = ['triết học', 'giải tích', 'toán cao cấp', 'xác suất', 'vật lý', 'cơ học', 'lập trình c', 'thuật toán', 'pháp luật đại cương'];
    bool isHard = hardSubjects.any((hard) => name.contains(hard));
    
    if (isHard && star.charMark == 'A') {
      return AdvisorMessage("Kẻ hủy diệt trùm cuối", "Đạt điểm A môn '${star.subjectName}' không phải dạng vừa đâu! Lớp phải xin vía bạn gấp đấy.");
    } else if (star.charMark == 'A') {
      return AdvisorMessage("Ngôi sao sáng", "Môn ${star.subjectName} bạn xuất sắc đạt ${star.mark} (A). Tiếp tục phát huy thế mạnh này nhé!");
    } else {
      return AdvisorMessage("Điểm sáng", "Dù chưa đạt A, nhưng ${star.subjectName} (${star.charMark}) đang là môn cứu cánh cho bảng điểm của bạn.");
    }
  }

  static AdvisorMessage? _generateConsistencyAdvice(List<SemesterTrend> trend) {
    if (trend.length < 3) return null;
    double minSem = trend.map((t) => t.gpa4).reduce((a, b) => a < b ? a : b);
    double maxSem = trend.map((t) => t.gpa4).reduce((a, b) => a > b ? a : b);
    double avgGpa = trend.map((t) => t.gpa4).reduce((a, b) => a + b) / trend.length;
    
    if (maxSem - minSem > 1.2) {
      if (avgGpa < 2.0) {
        return AdvisorMessage("Chỉ số phong độ: Tàu lượn trong bão", "Điểm chênh lệch ${(maxSem - minSem).toStringAsFixed(2)} giữa các kỳ, và mức trung bình chỉ ${avgGpa.toStringAsFixed(2)}. Cần tìm ra nguyên nhân gây bất ổn để cải thiện.");
      }
      return AdvisorMessage("Chỉ số phong độ: Tàu lượn siêu tốc", "Điểm chênh lệch tới ${(maxSem - minSem).toStringAsFixed(2)} giữa các kỳ. Đau tim quá, cố gắng ổn định lại nhé!");
    } else if (maxSem - minSem <= 0.3) {
      if (avgGpa >= 3.2) {
        return AdvisorMessage("Chỉ số phong độ: Vững như bàn thạch", "Dao động siêu nhỏ giữa các kỳ ở đẳng cấp ${avgGpa.toStringAsFixed(2)}. Khả năng kiểm soát phong độ đỉnh cao!");
      } else if (avgGpa >= 2.5) {
        return AdvisorMessage("Chỉ số phong độ: Ổn định", "Điểm giữa các kỳ rất đều. Ổn định, nhưng cần tạo đà bứt phá để lên hạng cao hơn!");
      } else if (avgGpa >= 2.0) {
        return AdvisorMessage("Chỉ số phong độ: Ổn định ở mức thấp", "Các kỳ đều đều nhưng GPA trung bình chỉ ${avgGpa.toStringAsFixed(2)}. Ổn định chưa đủ — cần tìm cách tăng tốc!");
      } else {
        return AdvisorMessage("Chỉ số phong độ: Mắc kẹt vùng đỏ", "Phong độ rất 'ổn định'... nhưng ở mức ${avgGpa.toStringAsFixed(2)} thì đây là dấu hiệu đáng lo. Cần thay đổi chiến lược học tập ngay.");
      }
    }
    return null;
  }

  static AdvisorMessage? _generateImprovementAdvice(List<StudentMark> failed, List<StudentMark> topTrailing, double currentGpa, double sumGpa4, int totalCredits) {
    if (failed.isNotEmpty) {
      final worst = failed.first;
      double newSum = sumGpa4 + (3.0 * worst.numberOfCredit);
      double newGpa = newSum / (totalCredits + worst.numberOfCredit);
      double diff = newGpa - currentGpa;
      if (diff > 0.03) {
          return AdvisorMessage("Chiến lược nâng điểm", "Tip nhỏ: Học lại và đạt điểm B môn ${worst.subjectName}, GPA toàn khoá sẽ ngay lập tức bay từ ${currentGpa.toStringAsFixed(2)} lên ${newGpa.toStringAsFixed(2)}!");
      }
    } else if (topTrailing.isNotEmpty) {
      final worst = topTrailing.first;
      double oldGpa = charToGpa4(worst.charMark);
      double newSum = sumGpa4 - (oldGpa * worst.numberOfCredit) + (3.0 * worst.numberOfCredit);
      double newGpa = newSum / totalCredits;
      double diff = newGpa - currentGpa;
      
      // Check if it crosses a rank boundary
      List<double> thresholds = [2.0, 2.5, 3.2, 3.6];
      bool crossesBoundary = false;
      String nextRank = "";
      for (var t in thresholds) {
        if (currentGpa < t && newGpa >= t) {
          crossesBoundary = true;
          nextRank = getAcademicRanking(t);
          break;
        }
      }
      
      if (crossesBoundary) {
         return AdvisorMessage("Chiến lược lên hạng tức thì!", "Ôi! Chỉ cần cải thiện môn ${worst.subjectName} lên điểm B, bạn sẽ chính thức đặt chân lên hạng $nextRank. Một nước đi 'đổi đời'!");
      } else if (diff > 0.03) {
         return AdvisorMessage("Chiến lược nâng điểm", "Cải thiện môn ${worst.subjectName} lên B sẽ giúp GPA kéo lên ${newGpa.toStringAsFixed(2)}. Đáng để cân nhắc đấy.");
      }
    }
    return null;
  }

  static AdvisorMessage? _generateTeamCarryAdvice(RadarSkillGroup? best, RadarSkillGroup? worst) {
    if (best == null || worst == null || best.groupName == worst.groupName) return null;
    
    if (worst.groupName == 'Ngoại ngữ') {
       return AdvisorMessage("Gánh team vs Quả tạ", "Nhóm '${best.groupName}' đang gánh còng lưng, nhưng Tiếng Anh lại làm 'quả tạ'. Tranh thủ cày thêm ngoại ngữ đi, ra trường rất cần đó!");
    } else if (worst.groupName == 'Toán học') {
       return AdvisorMessage("Gánh team vs Quả tạ", "Não bạn có vẻ thiên về '${best.groupName}' hơn là tính toán. Đừng ngại hỏi bạn bè để qua ải Toán nhé.");
    } else {
       return AdvisorMessage("Gánh team vs Quả tạ", "Nhóm '${best.groupName}' gánh team cực mạnh, trong khi '${worst.groupName}' đang kéo lùi. Nhớ phân bổ lại thời gian ôn tập cho cân bằng nhé.");
    }
  }

  static AdvisorMessage _generateAchievementAdvice(double gpa, int passed, int credits) {
    String title;
    if (gpa >= 3.8) {
      title = 'Huyền thoại TLU';
    } else if (gpa >= 3.6) title = 'Chiến thần học vụ';
    else if (gpa >= 3.2) title = 'Cao thủ GPA';
    else if (gpa >= 2.5) title = 'Chiến binh ổn định';
    else if (gpa >= 2.0) title = 'Mầm non vươn lên';
    else title = 'Phượng hoàng niết bàn';
    
    return AdvisorMessage(title, "Đã càn quét $passed môn học | Bỏ túi $credits tín chỉ");
  }

  static AdvisorMessage? _generateStreakAdvice(int aStreak) {
    if (aStreak >= 4) {
      return AdvisorMessage("Chuỗi A hủy diệt", "$aStreak môn liên tiếp toàn A! Bạn đang On Fire thật sự, ai cản nổi bạn lúc này?");
    } else if (aStreak >= 2) {
      return AdvisorMessage("Chuỗi A đang cháy", "$aStreak môn liên tiếp đạt A gần đây. Giữ lửa đi nào!");
    }
    return null;
  }

  static AdvisorMessage? _generateNoFailAdvice(int noFail) {
    if (noFail >= 4) {
      return AdvisorMessage("Khiên bất tử", "$noFail kỳ liên tiếp không trượt môn nào. Khả năng né F của bạn đã đạt cảnh giới thượng thừa!");
    } else if (noFail >= 2) {
      return AdvisorMessage("Bất bại", "$noFail kỳ liên tiếp qua môn êm thấm. Cứ thế phát huy nhé!");
    }
    return null;
  }
  
  static AdvisorMessage? _generateNextRankAdvice(double gpa) {
    final thresholds = [(3.6, 'Xuất sắc'), (3.2, 'Giỏi'), (2.5, 'Khá'), (2.0, 'Trung bình')];
    for (var (t, label) in thresholds) {
      if (gpa < t) {
        double gap = t - gpa;
        if (gap <= 0.05) {
          return AdvisorMessage("Chỉ một bước nữa thôi!", "Chỉ còn thiếu ${gap.toStringAsFixed(2)} là chạm tới mốc $label. Nỗ lực chút xíu ở kỳ tới là thành công!");
        } else if (gap <= 0.2) {
          return AdvisorMessage("Mục tiêu khả thi", "Cách hạng $label ${gap.toStringAsFixed(2)} điểm. Hoàn toàn nằm trong tầm tay nếu kỳ sau bức tốc!");
        } else {
          return AdvisorMessage("Hành trình thăng hạng", "Cách hạng $label ${gap.toStringAsFixed(2)} điểm. Hành trình vạn dặm bắt đầu từ việc không có điểm C/D ở kỳ tới. Cố lên!");
        }
      }
    }
    return AdvisorMessage("Không còn đối thủ", "Bạn đã đạt đỉnh ranking! Giờ thì duy trì phong độ và đi săn học bổng thôi.");
  }


  static GradeAnalyticsResult analyze(List<StudentMark> allMarks) {
    if (allMarks.isEmpty) {
      return GradeAnalyticsResult(
        cumulativeGpa10: 0,
        cumulativeGpa4: 0,
        totalPassedCredits: 0,
        totalFailedCredits: 0,
        academicRanking: "Chưa có",
        trend: [],
        skillGroups: [],
        failedSubjects: [],
        trailingSubjects: [],
      );
    }

    final Map<String, StudentMark> bestMarks = {};
    for (var mark in allMarks) {
      if (mark.numberOfCredit > 0 && isGraduationSubject(mark)) {
        if (!bestMarks.containsKey(mark.subjectCode)) {
          bestMarks[mark.subjectCode] = mark;
        } else {
          if (mark.mark > bestMarks[mark.subjectCode]!.mark) {
            bestMarks[mark.subjectCode] = mark;
          }
        }
      }
    }

    double sumGpa4xCredit = 0;
    double sumGpa10xCredit = 0;
    int sumPassedCredits = 0;
    int sumFailedCredits = 0;
    int sumTotalCalculatedCredits = 0;

    for (var mark in bestMarks.values) {
      if (mark.charMark.toUpperCase() == 'F') {
        sumFailedCredits += mark.numberOfCredit;
      } else if (mark.charMark.isNotEmpty) {
        sumPassedCredits += mark.numberOfCredit;
        if (['A', 'B', 'C', 'D'].contains(mark.charMark.toUpperCase())) {
          sumGpa4xCredit += charToGpa4(mark.charMark) * mark.numberOfCredit;
          sumGpa10xCredit += mark.mark * mark.numberOfCredit;
          sumTotalCalculatedCredits += mark.numberOfCredit;
        }
      }
    }

    final cumulativeGpa4 = sumTotalCalculatedCredits > 0 ? sumGpa4xCredit / sumTotalCalculatedCredits : 0.0;
    final cumulativeGpa10 = sumTotalCalculatedCredits > 0 ? sumGpa10xCredit / sumTotalCalculatedCredits : 0.0;

    final Map<int, List<StudentMark>> marksBySemester = {};
    for (var mark in allMarks) {
      if (!marksBySemester.containsKey(mark.semesterId)) {
        marksBySemester[mark.semesterId] = [];
      }
      marksBySemester[mark.semesterId]!.add(mark);
    }

    final List<SemesterTrend> trend = [];
    final sortedSemesters = marksBySemester.keys.toList()..sort();

    for (var semId in sortedSemesters) {
      final semMarks = marksBySemester[semId]!;
      double semSum4 = 0;
      double semSum10 = 0;
      double semSumQT = 0;
      double semSumTHI = 0;
      int semCredits = 0;
      int semCreditsQTTHI = 0;
      int semPassedCredits = 0;
      bool hasFailed = false;
      String semName = semMarks.first.semesterName;

      for (var m in semMarks) {
        if (m.numberOfCredit > 0 && isGraduationSubject(m)) {
          if (m.charMark.isNotEmpty) {
            if (['A', 'B', 'C', 'D', 'F'].contains(m.charMark.toUpperCase())) {
              semSum4 += charToGpa4(m.charMark) * m.numberOfCredit;
              semSum10 += m.mark * m.numberOfCredit;
              semCredits += m.numberOfCredit;
              if (m.charMark.toUpperCase() == 'F') hasFailed = true;
            }
            if (m.charMark.toUpperCase() != 'F') {
              semPassedCredits += m.numberOfCredit;
            }
          }
          if (m.markQT > 0 || m.markTHI > 0) {
            semSumQT += m.markQT * m.numberOfCredit;
            semSumTHI += m.markTHI * m.numberOfCredit;
            semCreditsQTTHI += m.numberOfCredit;
          }
        }
      }
      if (semCredits > 0) {
        double avgQT = semCreditsQTTHI > 0 ? semSumQT / semCreditsQTTHI : 0;
        double avgTHI = semCreditsQTTHI > 0 ? semSumTHI / semCreditsQTTHI : 0;
        trend.add(SemesterTrend(semName, semId, semSum10 / semCredits, semSum4 / semCredits, semPassedCredits, semCredits, hasFailed, avgQT, avgTHI));
      }
    }

    final Map<String, List<StudentMark>> rawGroups = {};
    for (var mark in bestMarks.values) {
      if (mark.charMark.isNotEmpty && mark.charMark.toUpperCase() != 'F') {
        final match = RegExp(r'^([a-zA-Z]+)').firstMatch(mark.subjectCode);
        final prefix = match != null ? match.group(1)!.toUpperCase() : 'OTHER';
        if (!rawGroups.containsKey(prefix)) rawGroups[prefix] = [];
        rawGroups[prefix]!.add(mark);
      }
    }

    final Map<String, String> prefixNames = {
      // TLU K67 IT & Business
      'MATH': 'Toán học', 'CSE': 'Công nghệ TT', 'ENG': 'Ngoại ngữ', 
      'SSE': 'Kỹ năng mềm', 'GEL': 'Pháp luật', 'HPTN': 'Tốt nghiệp',
      'SCSO': 'Lý luận CT', 'MLPE': 'Lý luận CT', 'HCPV': 'Lý luận CT', 
      'MLP': 'Lý luận CT', 'HCMT': 'Lý luận CT',
      'MATHEC': 'Toán học', 'BACU': 'Quản trị', 'ACC': 'Kế toán', 
      'ECON': 'Kinh tế', 'BAEU': 'Quản trị', 'CLAW': 'Pháp luật',
      'AIEB': 'Kinh tế', 'SBDP': 'Quản trị', 'BAMA': 'Marketing', 
      'ESPP': 'Thương mại ĐT', 'ECO': 'Kinh tế', 'NS': 'Kỹ năng mềm', 
      'COS': 'Kỹ năng mềm', 'CET': 'Xây dựng', 'PJM': 'Quản lý', 
      'SMIE': 'Quản lý', 'BAEC': 'Quản trị', 'ECOP': 'Thương mại ĐT',
      'BAIB': 'Kinh doanh QT', 'FFI': 'Ngoại thương', 'EDT': 'Chuyển đổi số',
      'PSB': 'Kinh doanh', 'DV': 'Phân tích DL',
      'DRAW': 'Kỹ thuật', 'ITI': 'Tin học', 'INCN': 'Công nghệ TT', 
      'LSCU': 'Logistics', 'AICE': 'Công nghệ TT', 'ENEC': 'Ngoại ngữ',
      
      // TLU Massive Sub-dictionary (K63, K64, K65, K66)
      'INGA': 'Xây dựng', 'DATN': 'Tốt nghiệp', 'CEST': 'Xây dựng', 'CETA': 'Xây dựng',
      'IWRE': 'Tài nguyên nước', 'GIN': 'Cấp thoát nước', 'IDEO': 'Lý luận CT', 'WPHE': 'Thủy điện',
      'WAS': 'Xây dựng', 'COTE': 'Xây dựng', 'CPS': 'Xây dựng', 'RBPD': 'Xây dựng', 'CEI': 'Xây dựng',
      'DBH': 'Cầu đường', 'RDC': 'Xây dựng', 'CETT': 'Cầu đường', 'AITE': 'Công nghệ TT',
      'TCT': 'Xây dựng', 'PCIE': 'Quản lý XD', 'ETNC': 'Quản lý XD', 'URPM': 'Đô thị',
      'BACE': 'Quản trị', 'MECIP': 'Quản lý XD', 'REP': 'Bất động sản', 'PR': 'Truyền thông',
      'PROJ': 'Quản lý dự án', 'EVEN': 'Truyền thông', 'OMAN': 'Quản trị VP', 'EEBC': 'Ngoại ngữ',
      'JOUR': 'Truyền thông', 'CORR': 'Truyền thông', 'ITL': 'Pháp luật', 'HYDR': 'Thủy lực',
      'GEOT': 'Địa kỹ thuật', 'SDS': 'Cơ học', 'RCSB': 'Xây dựng', 'ART': 'Kiến trúc',
      'EGN': 'Kỹ thuật điện', 'SCTT': 'Xây dựng', 'AICON': 'Công nghệ TT', 'CECON': 'Kinh tế',
      'PCECON': 'Kinh tế', 'MAR': 'Marketing', 'ELAW': 'Pháp luật', 'IODE': 'Kinh tế',
      'ECSD': 'Công nghệ TT', 'WDI': 'Công nghệ TT', 'SSC': 'Khoa học đất', 'GRSA': 'Công nghệ TT',
      'TRANS': 'Xây dựng', 'CMWT': 'Môi trường', 'HDR': 'Thủy lực', 'READ': 'Ngoại ngữ',
      'WRIT': 'Ngoại ngữ', 'LIST': 'Ngoại ngữ', 'SPEA': 'Ngoại ngữ', 'PHON': 'Ngoại ngữ',
      'PRAG': 'Ngoại ngữ', 'LEXI': 'Ngoại ngữ', 'GRAM': 'Ngoại ngữ', 'LING': 'Ngoại ngữ',
      'Chinese': 'Ngoại ngữ', 'MHS': 'Quản lý', 'CEHS': 'Xây dựng', 'COOM': 'Quản lý XD',
      'SEWS': 'Cấp thoát nước', 'WAT': 'Cấp thoát nước', 'AIWSD': 'Công nghệ TT',
      'RPD': 'Tài nguyên nước', 'LSEU': 'Logistics', 'PEAD': 'Truyền thông', 'DMS': 'Kỹ năng mềm',

      // Semester 2 Additions
      'PDQE': 'Xây dựng', 'CTHC': 'Xây dựng', 'DDR': 'Xây dựng', 'AIHE': 'Công nghệ TT',
      'SHS': 'Xây dựng', 'PED': 'Xây dựng', 'PCD': 'Xây dựng', 'PSHS': 'Xây dựng',
      'PDR': 'Xây dựng', 'CPP': 'Quản lý XD', 'FMC': 'Tài chính', 'ACOM': 'Quản lý XD',
      'CON': 'Quản lý XD', 'SCON': 'Quản lý XD', 'POMC': 'Quản lý XD', 'MIE': 'Tài nguyên nước',
      'PSD': 'Tài nguyên nước', 'MMOI': 'Tài nguyên nước', 'IWS': 'Tài nguyên nước', 'AIT': 'Công nghệ TT',
      'WSS': 'Cấp thoát nước', 'WWT': 'Cấp thoát nước', 'PUMP': 'Cấp thoát nước', 'WSSB': 'Cấp thoát nước',
      'WSSC': 'Cấp thoát nước', 'KLTN': 'Tốt nghiệp', 'GILS': 'Logistics', 'PIEC': 'Thương mại ĐT',
      'INTE': 'Ngoại ngữ', 'IHSD': 'Xây dựng', 'FCPD': 'Xây dựng', 'DRE': 'Xây dựng',
      'FEM': 'Toán học', 'SSB': 'Xây dựng', 'COPS': 'Kỹ năng mềm', 'BUEQ': 'Cơ khí',
      'CEC': 'Ngoại ngữ', 'WRE': 'Tài nguyên nước', 'PSWE': 'Tài nguyên nước', 'MMH': 'Thủy văn',
      'PMWR': 'Tài nguyên nước', 'DSD': 'Tài nguyên nước', 'PLC': 'Đô thị', 'UTP': 'Đô thị',
      'URHYD': 'Thủy văn', 'WQA': 'Môi trường', 'ISSEC': 'Công nghệ TT', 'ELO': 'Thương mại ĐT',
      'ECL': 'Pháp luật', 'EGO': 'Thương mại ĐT', 'ONCB': 'Marketing', 'NTTE': 'Thương mại ĐT',
      'CRIT': 'Kỹ năng mềm', 'BACS': 'Ngoại ngữ', 'CROS': 'Ngoại ngữ', 'TRAN': 'Ngoại ngữ',
      'HRM': 'Quản trị', 'MATHC': 'Toán học', 'MEEG': 'Cơ học', 'LAWC': 'Pháp luật',
      'MAEC': 'Toán học', 'MITB': 'Kinh tế', 'WEBG': 'Công nghệ TT', 'INDA': 'Công nghệ TT',
      'RESE': 'Kỹ năng mềm', 'CULT': 'Lý luận CT', 'CIVI': 'Lịch sử', 'GL': 'Lý luận CT',
      'SHL': 'Pháp luật', 'CWSL': 'Pháp luật', 'CL': 'Pháp luật',
      'STEN': 'Thống kê', 'SURV': 'Trắc địa', 'FLME': 'Cơ học',
      // Common ones
      'PHYS': 'Vật lý', 'EENG': 'Kỹ thuật điện', 'MECH': 'Cơ khí', 'CIV': 'Xây dựng', 
      'ENV': 'Môi trường', 'MGT': 'Quản lý', 'MAT': 'Toán học', 
      'FL': 'Ngoại ngữ', 'THL': 'Thể chất', 'PE': 'Thể chất', 'LLC': 'Lý luận CT', 
      'POL': 'Lý luận CT', 'PHY': 'Vật lý', 'CHEM': 'Hóa học', 'LAW': 'Pháp luật',
      'FIN': 'Tài chính', 'ME': 'Cơ khí', 'CE': 'Xây dựng', 
      'EE': 'Điện tử', 'MAC': 'Triết học', 'TIN': 'Tin học', 'TOAN': 'Toán học', 
      'KT': 'Kinh tế', 'QT': 'Quản trị',
    };

    final List<RadarSkillGroup> skillGroups = [];
    for (var entry in rawGroups.entries) {
      double sum10 = 0; int credits = 0;
      for (var m in entry.value) { sum10 += m.mark * m.numberOfCredit; credits += m.numberOfCredit; }
      if (credits > 0) {
        String groupName = prefixNames[entry.key] ?? entry.key;
        if (!prefixNames.containsKey(entry.key) && entry.value.isNotEmpty) {
          final firstSubName = entry.value.first.subjectName;
          final parts = firstSubName.split(RegExp(r'\s+'));
          groupName = parts.length >= 2 ? '${parts[0]} ${parts[1]}' : firstSubName;
          if (groupName.length > 15) groupName = '${groupName.substring(0, 12)}...';
        }
        skillGroups.add(RadarSkillGroup(groupName, sum10 / credits, credits));
      }
    }
    
    if (skillGroups.length < 3) {
        skillGroups.clear();
        double sumQT = 0;
        double sumTHI = 0;
        double sumTK = 0;
        int credits = 0;
        
        for (var mark in bestMarks.values) {
           if (mark.charMark.isNotEmpty && mark.charMark.toUpperCase() != 'F' && isGraduationSubject(mark)) {
              sumQT += mark.markQT * mark.numberOfCredit;
              sumTHI += mark.markTHI * mark.numberOfCredit;
              sumTK += mark.mark * mark.numberOfCredit;
              credits += mark.numberOfCredit;
           }
        }
        if (credits > 0) {
            skillGroups.add(RadarSkillGroup("Điểm Quá Trình", sumQT / credits, credits));
            skillGroups.add(RadarSkillGroup("Điểm Thi", sumTHI / credits, credits));
            skillGroups.add(RadarSkillGroup("Điểm Tổng Kết", sumTK / credits, credits));
        }
    }
    
    skillGroups.sort((a, b) => b.totalCredits.compareTo(a.totalCredits));
    if (skillGroups.length > 6) skillGroups.removeRange(6, skillGroups.length);

    final failed = bestMarks.values.where((m) => isGraduationSubject(m) && m.charMark.toUpperCase() == 'F').toList();
    final trailing = bestMarks.values.where((m) => isGraduationSubject(m) && ['D', 'C'].contains(m.charMark.toUpperCase())).toList();
    trailing.sort((a, b) => a.mark.compareTo(b.mark));
    final topTrailing = trailing.take(3).toList();

    StudentMark? star;
    for (var m in bestMarks.values) {
      if (m.charMark.isNotEmpty && m.charMark.toUpperCase() != 'F') {
        if (star == null) {
          star = m;
        } else if (m.mark > star.mark) star = m;
        else if (m.mark == star.mark && m.numberOfCredit > star.numberOfCredit) star = m;
      }
    }
    
    RadarSkillGroup? bestGroup;
    RadarSkillGroup? worstGroup;
    if (skillGroups.isNotEmpty) {
        bestGroup = skillGroups.reduce((a, b) => a.averageScore > b.averageScore ? a : b);
        worstGroup = skillGroups.reduce((a, b) => a.averageScore < b.averageScore ? a : b);
    }

    int aStreak = 0;
    final sortedByRecent = allMarks.toList()..sort((a, b) => b.semesterId.compareTo(a.semesterId));
    for (var m in sortedByRecent) {
      if (m.numberOfCredit > 0 && isGraduationSubject(m) && m.charMark.isNotEmpty) {
        if (m.charMark.toUpperCase() == 'A') {
          aStreak++;
        } else {
          break;
        }
      }
    }

    int totalPassed = bestMarks.values.where((m) => m.charMark.isNotEmpty && m.charMark.toUpperCase() != 'F').length;

    int noFail = 0;
    for (int i = trend.length - 1; i >= 0; i--) {
      if (!trend[i].hasFailedSubject) {
        noFail++;
      } else {
        break;
      }
    }

    SemesterTrend? peak;
    if (trend.isNotEmpty) peak = trend.reduce((a, b) => a.gpa4 > b.gpa4 ? a : b);

    // GENERATE INSIGHTS
    final personaMessage = _generatePersonaAdvice(bestMarks, cumulativeGpa4);
    final nemesisMessage = _generateNemesisAdvice(allMarks);
    final overloadMessage = _generateOverloadAdvice(trend);
    final achievementMessage = _generateAchievementAdvice(cumulativeGpa4, totalPassed, sumPassedCredits);
    final trendMessage = _generateTrendAdvice(trend);
    final failedMessage = _generateFailedAdvice(failed);
    final trailingMessage = _generateTrailingAdvice(topTrailing, cumulativeGpa4);
    final shiningStarMessage = _generateShiningStarAdvice(star);
    final consistencyMessage = _generateConsistencyAdvice(trend);
    final improvementMessage = _generateImprovementAdvice(failed, topTrailing, cumulativeGpa4, sumGpa4xCredit, sumTotalCalculatedCredits);
    final teamCarryMessage = _generateTeamCarryAdvice(bestGroup, worstGroup);
    final aStreakMessage = _generateStreakAdvice(aStreak);
    final noFailMessage = _generateNoFailAdvice(noFail);
    
    AdvisorMessage? bestSemesterMessage;
    if (peak != null && trend.length >= 2) {
      bestSemesterMessage = AdvisorMessage("Kỳ học đỉnh cao", "Kỳ ${peak.semesterName} bạn chạm mốc GPA ${peak.gpa4.toStringAsFixed(2)}. Thời hoàng kim là đây!");
    }

    return GradeAnalyticsResult(
      cumulativeGpa10: cumulativeGpa10,
      cumulativeGpa4: cumulativeGpa4,
      totalPassedCredits: sumPassedCredits,
      totalFailedCredits: sumFailedCredits,
      academicRanking: getAcademicRanking(cumulativeGpa4),
      trend: trend,
      skillGroups: skillGroups,
      failedSubjects: failed,
      trailingSubjects: topTrailing,
      trendMessage: trendMessage,
      failedMessage: failedMessage,
      trailingMessage: trailingMessage,
      shiningStarMessage: shiningStarMessage,
      consistencyMessage: consistencyMessage,
      improvementMessage: improvementMessage,
      teamCarryMessage: teamCarryMessage,
      personaMessage: personaMessage,
      nemesisMessage: nemesisMessage,
      overloadMessage: overloadMessage,
      achievementMessage: achievementMessage,
      aStreakMessage: aStreakMessage,
      noFailMessage: noFailMessage,
      bestSemesterMessage: bestSemesterMessage,
      nextRankMessage: _generateNextRankAdvice(cumulativeGpa4),
    );
  }
}
