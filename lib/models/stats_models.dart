// lib/models/stats_models.dart

class ThemeStats {
  final String name;
  final String? imagePath;
  final int dynamicScore;
  final int totalQuestionsInTheme;
  final List<int> dailyActivity; // [J-6, J-s5, ..., J-0]
  
  ThemeStats({
    required this.name,
    this.imagePath,
    required this.dynamicScore,
    required this.totalQuestionsInTheme,
    required this.dailyActivity,
  });
}

class GlobalStats {
  final int totalUniqueQuestionsAnswered;
  final int totalAnswers;
    final int totalCorrectAnswers;
  final int totalQuestionsInDb;
  final String? bestTheme;
  final String? worstTheme;

  GlobalStats({
    required this.totalUniqueQuestionsAnswered,
    required this.totalAnswers,
    required this.totalCorrectAnswers,
    required this.totalQuestionsInDb,
    this.bestTheme,
    this.worstTheme,
  });

  String get completionRateString {
    if (totalQuestionsInDb == 0) return "0.00%";
    final rate = (totalUniqueQuestionsAnswered / totalQuestionsInDb) * 100;
    return "${rate.toStringAsFixed(2)}%";
  }

  String get overallSuccessRateString {
    if (totalAnswers == 0) return "0.00%";
    final rate = (totalCorrectAnswers / totalAnswers) * 100;
    return "${rate.toStringAsFixed(2)}%";
  }
}