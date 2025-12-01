import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/stats_models.dart';
import '../data/data_manager.dart';
import '../widgets/score_gauge.dart';
import '../utils/responsive_helper.dart';

class SubThemeDetail {
  final String name;
  final int dynamicScore;
  final int totalQuestions;
  final int questionsSeen;

  SubThemeDetail({
    required this.name,
    required this.dynamicScore,
    required this.totalQuestions,
    required this.questionsSeen,
  });

  double get successRate {
    if (totalQuestions == 0) return 0.0;
    final score = max(0, dynamicScore); 
    return score / totalQuestions;
  }

  double get discoveryRate {
    if (totalQuestions == 0) return 0.0;
    return questionsSeen / totalQuestions;
  }
}

class ThemeStatsDetailPage extends StatefulWidget {
  final ThemeStats themeStats;
  final Map<String, dynamic> rawScores;
  final Map<String, bool> userAnswers;

  const ThemeStatsDetailPage({
    super.key,
    required this.themeStats,
    required this.rawScores,
    required this.userAnswers,
  });

  @override
  // Cette ligne est maintenant valide car c'est un StatefulWidget
  State<ThemeStatsDetailPage> createState() => _ThemeStatsDetailPageState();
}

class _ThemeStatsDetailPageState extends State<ThemeStatsDetailPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isExiting = false;

  // --- ASSUREZ-VOUS QUE CETTE MÉTHODE EST PRÉSENTE ET CORRECTE ---
  @override
  void initState() {
    super.initState();
    
    // 1. On initialise le contrôleur d'animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // 2. On définit nos animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    // 3. On lance l'animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleExit() async {
    // Si on est déjà en train de sortir, on ne fait rien
    if (_isExiting) return;
    
    setState(() {
      _isExiting = true;
    });
    
    _controller.duration = const Duration(milliseconds: 250);
    // On joue l'animation en sens inverse
    await _controller.reverse();
    
    // SEULEMENT APRÈS la fin de l'animation, on quitte la page
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rh = ResponsiveHelper(context);

    final allSubThemesForThisTheme = DataManager.instance.subThemes
        .where((st) => st.parentTheme == widget.themeStats.name)
        .toList();

    final themeQuestions = DataManager.instance.allQuestions
        .where((doc) => (doc.data() as Map<String, dynamic>)['theme'] == widget.themeStats.name)
        .toList();
    final Map<String, int> questionsPerSubTheme = {};
    for (var questionDoc in themeQuestions) {
      final subTheme = (questionDoc.data() as Map<String, dynamic>)['sousTheme'] as String?;
      if (subTheme != null) {
        questionsPerSubTheme[subTheme] = (questionsPerSubTheme[subTheme] ?? 0) + 1;
      }
    }

    // 3. On construit la liste finale en bouclant sur TOUS les sous-thèmes
    final List<SubThemeDetail> subThemeDetails = [];
    for (var subTheme in allSubThemesForThisTheme) {
      final subThemeName = subTheme.name;
      
      // On génère la clé de score (ex: "Géographie-France")
      final scoreKey = '${widget.themeStats.name}-$subThemeName';
      
      // On cherche les données de score pour cette clé. Si elles n'existent pas, c'est null.
      final scoreData = widget.rawScores[scoreKey] as Map<String, dynamic>?;

      // On calcule le nombre de questions vues
      final subThemeQuestionIds = DataManager.instance.allQuestions
          .where((q) => (q.data() as Map<String, dynamic>)['sousTheme'] == subThemeName)
          .map((q) => q.id)
          .toList();
      int seenCount = 0;
      for (var qId in subThemeQuestionIds) {
        if (widget.userAnswers.containsKey(qId)) {
          seenCount++;
        }
      }

      // On ajoute le détail du sous-thème à la liste
      subThemeDetails.add(SubThemeDetail(
        name: subThemeName,
        // On utilise les données de score si elles existent, sinon 0
        dynamicScore: scoreData?['dynamicScore'] ?? 0,
        questionsSeen: seenCount,
        totalQuestions: questionsPerSubTheme[subThemeName] ?? 0,
      ));
    }

    // 4. On trie la liste par score dynamique, comme avant
    subThemeDetails.sort((a, b) => b.dynamicScore.compareTo(a.dynamicScore));

    return Scaffold(
      // --- ON UTILISE WillPopScope POUR INTERCEPTER LE "RETOUR" ANDROID ---
      body: WillPopScope(
        onWillPop: () async {
          _handleExit();
          // On retourne 'false' pour dire au système de ne PAS gérer le retour lui-même.
          // Notre _handleExit s'en occupe.
          return false;
        },
        child: Stack(
        children: [
          // L'image de fond (Hero) est maintenant le widget racine du contenu
          Positioned.fill(
            child: Hero(
              tag: 'theme-card-${widget.themeStats.name}',
              // On enveloppe tout dans un Material pour éviter les bugs de texte
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  decoration: BoxDecoration(
                    image: widget.themeStats.imagePath != null
                        ? DecorationImage(image: AssetImage(widget.themeStats.imagePath!), fit: BoxFit.cover)
                        : null,
                    color: widget.themeStats.imagePath == null ? Colors.deepPurple : Colors.black,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ListView(
                  // Padding proportionnel
                  padding: EdgeInsets.symmetric(horizontal: rh.w(5)),
                  children: [
                    // Espace proportionnel (le padding.top est déjà géré par SafeArea)
                    SizedBox(height: rh.h(8)),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.themeStats.name,
                                style: TextStyle(
                                  fontSize: rh.w(8), // Police proportionnelle
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '${widget.themeStats.totalQuestionsInTheme} questions au total',
                                style: TextStyle(fontSize: rh.w(4), color: Colors.black54), // Police proportionnelle
                              ),
                            ],
                          ),
                        ),
                        ScoreGauge(
                          score: widget.themeStats.dynamicScore,
                          total: widget.themeStats.totalQuestionsInTheme,
                          radius: rh.w(12), // Rayon proportionnel
                        ),
                      ],
                    ),
                    SizedBox(height: rh.h(4)),
                    Text("Activité", style: TextStyle(color: Colors.black87, fontSize: rh.w(4.2), fontWeight: FontWeight.bold)),
                    Divider(color: Colors.grey.shade200, height: rh.h(3)),
                    _buildFrostedGlassContainer(
                      child: Padding(
                        padding: EdgeInsets.all(rh.w(4)),
                        child: SizedBox(
                          height: rh.h(16), // Hauteur proportionnelle
                          child: _buildActivityChart(widget.themeStats.dailyActivity),
                        ),
                      ),
                    ),
                    SizedBox(height: rh.h(4)),
                    Text('Détails par Sous-Thème', style: TextStyle(fontSize: rh.w(4.2), fontWeight: FontWeight.bold, color: Colors.black87)),
                    Divider(color: Colors.grey.shade200, height: rh.h(3)),
                    ...subThemeDetails.map((detail) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: rh.h(0.5)),
                        child: _buildFrostedGlassContainer(
                          child: _buildSubThemeTileContent(detail),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: rh.w(2.5),
            child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
                onPressed: _handleExit, // On appelle notre fonction de sortie
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityChart(List<int> dailyActivity) {
    final rh = ResponsiveHelper(context);
    final int maxVal = dailyActivity.isEmpty ? 0 : dailyActivity.reduce(max);
    final int bestDayIndex = maxVal > 0 ? dailyActivity.lastIndexOf(maxVal) : -1;
    final double maxY = max(10, (maxVal * 1.2)).toDouble();
    const int todayIndex = 6;

    double interval = (maxY / 5).ceil().toDouble();
    if (maxY <= 10) {
      interval = 2;
    } else if (maxY <= 20) interval = 4;

    if (maxVal == 0) return Center(child: Text("Aucune activité récente.", style: TextStyle(color: Colors.black54, fontSize: rh.w(3.5))));

    return BarChart(
      BarChartData(
        maxY: maxY,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: rh.w(8), // Espace proportionnel
              interval: interval,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == meta.max) return const SizedBox.shrink();
                if (value != value.toInt()) return const SizedBox.shrink();
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(color: Colors.black54, fontSize: rh.w(2.8)), // Police proportionnelle
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: rh.h(2), // Espace proportionnel
              getTitlesWidget: (value, meta) {
                final day = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                String dayText = DateFormat.E('fr_FR').format(day).substring(0, 1).toUpperCase();
                return Padding(
                  padding: EdgeInsets.only(top: rh.h(0.5)),
                  child: Text(
                    dayText,
                    style: TextStyle(color: Colors.black54, fontSize: rh.w(2.8), fontWeight: FontWeight.bold), // Police proportionnelle
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.black.withOpacity(0.2),
              strokeWidth: 1,
              dashArray: [4, 4],
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (index) {
          Color barColor;
          if (index == bestDayIndex) {
            barColor = const Color(0xFF87D189);
          } else if (index == todayIndex) {
            barColor = Colors.cyan.shade200;
          } else {
            barColor = Colors.white;
          }
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: dailyActivity[index].toDouble(),
                color: barColor,
                width: rh.w(2.5), // Largeur de barre proportionnelle
                borderRadius: BorderRadius.all(Radius.circular(rh.w(1.5))), // Bords proportionnels
              ),
            ],
          );
        }),
        alignment: BarChartAlignment.spaceBetween,
      ),
      swapAnimationDuration: const Duration(milliseconds: 400),
      swapAnimationCurve: Curves.easeInOut,
    );
  }

  Widget _buildSubThemeTileContent(SubThemeDetail detail) {
    final String discoveryPercentage = (detail.discoveryRate * 100).toStringAsFixed(0);
    final IconData subThemeIcon = Icons.keyboard_arrow_right_rounded;

    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(subThemeIcon, color: Colors.black87, size: 19),
                  const SizedBox(width: 4),
                  Text(detail.name, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14.5)),
                ],
              ),
              Text('${detail.dynamicScore} / ${detail.totalQuestions}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF449C47))),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              LinearProgressIndicator(
                value: detail.discoveryRate,
                backgroundColor: const Color(0x1F000000),
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF87D189)),
                minHeight: 7,
                borderRadius: BorderRadius.circular(4),
              ),
              LinearProgressIndicator(
                value: detail.successRate,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF449C47)),
                minHeight: 7,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$discoveryPercentage% exploré',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrostedGlassContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: Colors.white30.withOpacity(0.8),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}