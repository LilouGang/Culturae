import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../data/data_manager.dart';
import 'theme_stats_detail_page.dart';
import '../widgets/page_layout.dart';
import '../models/stats_models.dart';
import '../utils/responsive_helper.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});
  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // L'état de cette page ne gère plus les données, seulement l'UI
  late PageController _pageController;
  double _currentPage = 0.0;
  
  // On utilise un Future pour le chargement initial des données utilisateur
  Future<Map<String, dynamic>>? _userDataFuture;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    _pageController.addListener(() {
      if (mounted && _pageController.page != null) {
        setState(() {
          _currentPage = _pageController.page!;
        });
      }
    });
    // On lance le chargement des données utilisateur une seule fois
    _loadUserData();
  }

  void _loadUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      _userDataFuture = FirebaseFirestore.instance.collection('Users').doc(user.uid).get().then((doc) => doc.data() ?? {});
    } else {
      _userDataFuture = Future.value({}); // Données vides pour les invités
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  void _showStatsExplanationDialog(BuildContext context) {
    final rh = ResponsiveHelper(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.help_outline, color: Theme.of(context).primaryColor),
              const SizedBox(width: 10),
              const Text("Aide des Statistiques"),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                _buildExplanationTile(
                  icon: Icons.check_circle_outline_rounded,
                  title: "Progression Totale",
                  subtitle: "Affiche le nombre de questions uniques auxquelles vous avez répondu par rapport au total disponible dans l'application.",
                  rh: rh,
                ),
                _buildExplanationTile(
                  icon: Icons.repeat,
                  title: "Total des Réponses",
                  subtitle: "Compte chaque réponse que vous avez donnée, même si vous répondez plusieurs fois à la même question.",
                  rh: rh,
                ),
                _buildExplanationTile(
                  icon: Icons.pie_chart_outline_rounded,
                  title: "Complétion",
                  subtitle: "Le pourcentage de votre progression totale. Atteignez 100% quand vous aurez répondu au moins une fois à chaque question.",
                  rh: rh,
                ),
                _buildExplanationTile(
                  icon: Icons.star_half_rounded,
                  title: "Réussite",
                  subtitle: "Votre pourcentage global de bonnes réponses sur le total de vos réponses.",
                  rh: rh,
                ),
                _buildExplanationTile(
                  icon: Icons.emoji_events_outlined,
                  title: "Meilleur Thème",
                  subtitle: "Le thème où votre score dynamique (ratio bonnes réponses / total de questions) est le plus élevé.",
                  rh: rh,
                ),
                _buildExplanationTile(
                  icon: Icons.trending_up_rounded,
                  title: "Thème à Améliorer",
                  subtitle: "Le thème où votre score dynamique est le plus bas. Un bon point de départ pour progresser !",
                  rh: rh,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Compris !"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExplanationTile({required IconData icon, required String title, required String subtitle, required ResponsiveHelper rh}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade600, size: rh.w(6)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: rh.w(4))),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade700, fontSize: rh.w(3.5))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final rh = ResponsiveHelper(context);
    // On récupère les données statiques depuis le DataManager (Provider)
    final dataManager = Provider.of<DataManager>(context);

    return PageLayout(
      title: 'Mes Statistiques',
      titleTextStyle: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontSize: rh.w(6), fontWeight: FontWeight.w500),
      actions: [IconButton(icon: Icon(Icons.help_outline, color: Colors.grey.shade600), onPressed: () => _showStatsExplanationDialog(context), tooltip: 'Aide')],
      child: FutureBuilder<Map<String, dynamic>>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Erreur de chargement des statistiques."));
          }
          
          // --- TOUTE LA LOGIQUE DE CALCUL EST MAINTENANT DANS LE BUILDER ---
          // C'est instantané car toutes les données sont déjà chargées.
          final userData = snapshot.data ?? {};
          final rawScores = Map<String, dynamic>.from(userData['scores'] ?? {});
          final userAnswers = Map<String, bool>.from(userData['answeredQuestions'] ?? {});
          
          final themeStyles = {for (var theme in dataManager.themes) theme.name: theme};
          
          final allDailyActivity = Map<String, dynamic>.from(userData['dailyActivityByTheme'] ?? {});
          final Map<String, List<int>> dailyActivityPerTheme = {};
          final now = DateTime.now();

          for (var themeName in themeStyles.keys) {
            final themeActivityList = List.filled(7, 0);
            final themeActivityData = Map<String, int>.from(allDailyActivity[themeName] ?? {});
            themeActivityData.forEach((dateString, count) {
              final date = DateTime.tryParse(dateString);
              if (date != null) {
                final dayIndex = 6 - now.difference(date).inDays;
                if (dayIndex >= 0 && dayIndex < 7) themeActivityList[dayIndex] = count;
              }
            });
            dailyActivityPerTheme[themeName] = themeActivityList;
          }
          
          final Map<String, int> aggregatedDynamicScores = {};
          rawScores.forEach((key, value) {
            if (value is Map) {
              final themeName = key.split('-')[0];
              aggregatedDynamicScores[themeName] = (aggregatedDynamicScores[themeName] ?? 0) + (value['dynamicScore'] as int? ?? 0);
            }
          });

          final Map<String, int> totalQuestionsPerTheme = {};
          for (var questionDoc in dataManager.allQuestions) {
            final theme = (questionDoc.data() as Map<String, dynamic>)['theme'] as String?;
            if (theme != null) totalQuestionsPerTheme[theme] = (totalQuestionsPerTheme[theme] ?? 0) + 1;
          }

          final List<ThemeStats> themeStatsList = [];
          for (var themeName in themeStyles.keys) {
            themeStatsList.add(ThemeStats(
              name: themeName,
              dynamicScore: aggregatedDynamicScores[themeName] ?? 0,
              totalQuestionsInTheme: totalQuestionsPerTheme[themeName] ?? 0,
              imagePath: themeStyles[themeName]?.imagePath,
              dailyActivity: dailyActivityPerTheme[themeName] ?? List.filled(7, 0),
            ));
          }
          
          int totalUniqueAnswered = userAnswers.length;
          int totalAnswersCount = userData['totalAnswers'] as int? ?? 0;
          int totalCorrectAnswersCount = userData['totalCorrectAnswers'] as int? ?? 0;
          String? bestThemeName;
          String? worstThemeName;
          double bestRate = -1.0;
          double worstRate = 2.0;

          for (final stats in themeStatsList) {
            if (stats.totalQuestionsInTheme > 0) {
              final currentRate = stats.dynamicScore / stats.totalQuestionsInTheme;
              if (currentRate > bestRate) {
                bestRate = currentRate;
                bestThemeName = stats.name;
              }
              if (currentRate < worstRate) {
                worstRate = currentRate;
                worstThemeName = stats.name;
              }
            }
          }

          final globalStatsObject = GlobalStats(
            totalUniqueQuestionsAnswered: totalUniqueAnswered,
            totalAnswers: totalAnswersCount,
            totalCorrectAnswers: totalCorrectAnswersCount,
            totalQuestionsInDb: dataManager.allQuestions.length,
            bestTheme: bestThemeName,
            worstTheme: worstThemeName,
          );

          // On passe les données calculées aux widgets d'affichage
          return Column(
            children: [
              SizedBox(height: rh.h(1.2)),
              _buildThemeCarousel(rh, themeStatsList, rawScores, userAnswers),
              _buildSeparator(rh),
              Expanded(child: _buildGlobalStats(globalStatsObject, rh)),
            ],
          );
        },
      ),
    );
  }

   Widget _buildThemeCarousel(ResponsiveHelper rh, List<ThemeStats> themeStats, Map<String, dynamic> rawScores, Map<String, bool> userAnswers) {
    final screenWidth = rh.screenWidth;
    final cardWidth = screenWidth * _pageController.viewportFraction;
    const desiredAspectRatio = 3 / 2;
    final cardHeight = cardWidth / desiredAspectRatio;

    return SizedBox(
      height: cardHeight,
      child: PageView.builder(
        clipBehavior: Clip.none, 
        controller: _pageController,
        itemCount: themeStats.length,
        itemBuilder: (context, index) {
          double page = 0.0;
          if (_pageController.position.haveDimensions) {
            page = _pageController.page ?? 0.0;
          }
          final double pageOffset = page - index;
          double scale = max(0.9, 1 - (_currentPage - index).abs() * 0.3);
          final double alignmentX = (pageOffset).clamp(-0.7, 0.7);
          
          return Transform.scale(
            scale: scale,
            alignment: Alignment(alignmentX, 0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 200),
                    pageBuilder: (_, __, ___) => ThemeStatsDetailPage(
                      themeStats: themeStats[index],
                      rawScores: rawScores,
                      userAnswers: userAnswers,
                    ),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                );
              },
              child: Hero(
                tag: 'theme-card-${themeStats[index].name}',
                
                // --- ON AJOUTE LE flightShuttleBuilder ICI ---
                flightShuttleBuilder: (
                  BuildContext flightContext,
                  Animation<double> animation,
                  HeroFlightDirection flightDirection,
                  BuildContext fromHeroContext,
                  BuildContext toHeroContext,
                ) {
                  // Le "widget de vol" est la page de destination elle-même...
                  final Hero toHero = toHeroContext.widget as Hero;
                  // ...enveloppée dans une transition de fondu.
                  return FadeTransition(
                    opacity: animation,
                    child: toHero.child,
                  );
                },

                child: _buildThemeCard(themeStats[index], rh),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildThemeCard(ThemeStats stats, ResponsiveHelper rh) {
    return Card(
      elevation: 8,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rh.w(5))),
      child: Container(
        decoration: BoxDecoration(
          image: stats.imagePath != null
              ? DecorationImage(image: AssetImage(stats.imagePath!), fit: BoxFit.cover)
              : null,
          color: stats.imagePath == null ? Colors.deepPurple.shade400 : null,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Container(color: Colors.white.withOpacity(0.5)),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: rh.h(1.2), horizontal: rh.w(4)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stats.name,
                    style: TextStyle(
                      fontSize: rh.w(5.5),
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      shadows: [
                        Shadow(
                          color: Colors.white.withOpacity(0.5), // Ombre blanche semi-transparente
                          blurRadius: 10.0, // Un léger flou
                          offset: const Offset(0, 1), // Un léger décalage vers le bas
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 1),
                  _buildFrostedGlassContainer(
                    rh: rh,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(rh.w(2), rh.h(2), rh.w(2), rh.h(1)),
                      child: SizedBox(
                        height: rh.h(12),
                        child: _buildActivityChart(stats.dailyActivity, rh),
                      ),
                    ),
                  ),
                  const Spacer(flex: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${stats.dynamicScore} / ${stats.totalQuestionsInTheme}",
                        style: TextStyle(
                          fontSize: rh.w(4.5),
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          shadows: [
                            Shadow(
                              color: Colors.white.withOpacity(0.5), // Ombre blanche semi-transparente
                              blurRadius: 10.0, // Un léger flou
                              offset: const Offset(0, 1), // Un léger décalage vers le bas
                            ),
                          ]
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityChart(List<int> dailyActivity, ResponsiveHelper rh) {
    final int maxVal = dailyActivity.isEmpty ? 0 : dailyActivity.reduce(max);
    final int bestDayIndex = maxVal > 0 ? dailyActivity.lastIndexOf(maxVal) : -1;
    final double maxY = max(10, (maxVal * 1.2)).toDouble();
    const int todayIndex = 6;

    double interval = (maxY / 4).ceil().toDouble();
    if (maxY <= 10) {
      interval = 2;
    } else if (maxY <= 20) interval = 5;

    if (maxVal == 0) return Center(child: Text("Aucune activité récente.", style: TextStyle(color: Colors.black54, fontSize: rh.w(3))));

    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(
          touchCallback: (event, response) {},
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (BarChartGroupData group) => Colors.black.withOpacity(0.7),
            tooltipBorderRadius: BorderRadius.circular(rh.w(2)),
            tooltipMargin: 8,
            fitInsideVertically: false,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                rod.toY.toInt().toString(),
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: rh.w(3.5)),
              );
            },
          ),
        ),
        maxY: maxY,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: rh.w(8),
              interval: interval,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == meta.max) return const SizedBox.shrink();
                if (value != value.toInt()) return const SizedBox.shrink();
                return Text(value.toInt().toString(), style: TextStyle(color: Colors.black54, fontSize: rh.w(2.5)));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: rh.h(3),
              getTitlesWidget: (value, meta) {
                final day = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                String dayText = DateFormat.E('fr_FR').format(day).substring(0, 1).toUpperCase();
                return Padding(
                  padding: EdgeInsets.only(top: rh.h(0.5)),
                  child: Text(dayText, style: TextStyle(color: Colors.black54, fontSize: rh.w(3), fontWeight: FontWeight.bold)),
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
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.black.withOpacity(0.2), strokeWidth: 1, dashArray: [4, 4]),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (index) {
          Color barColor;
          if (index == bestDayIndex) {
            barColor = const Color(0xFF87D189);
          } else if (index == todayIndex) barColor = Colors.cyan.shade200;
          else barColor = Colors.white;
          return BarChartGroupData(x: index, barRods: [
            BarChartRodData(toY: dailyActivity[index].toDouble(), color: barColor, width: rh.w(2), borderRadius: BorderRadius.all(Radius.circular(rh.w(1.5)))),
          ]);
        }),
      ),
      swapAnimationDuration: const Duration(milliseconds: 300),
      swapAnimationCurve: Curves.easeInOut,
    );
  }

  Widget _buildSeparator(ResponsiveHelper rh) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: rh.w(5), vertical: rh.h(1.8)),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: rh.w(2.5)),
            child: Text("Statistiques Globales", style: TextStyle(color: Colors.grey.shade600, fontSize: rh.w(3.5))),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _buildGlobalStats(GlobalStats stats, ResponsiveHelper rh) {
    final Color bestColor = Colors.green.shade800;
    final Color worstColor = Colors.red.shade800;
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 2.0,
      padding: EdgeInsets.all(rh.w(4)),
      mainAxisSpacing: rh.w(2.5),
      crossAxisSpacing: rh.w(2.5),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatTile('Progression totale', '${stats.totalUniqueQuestionsAnswered} / ${stats.totalQuestionsInDb}', Icons.check_circle_outline_rounded, rh: rh),
        _buildStatTile('Total des réponses', '${stats.totalAnswers}', Icons.repeat, rh: rh),
        _buildStatTile('Complétion', stats.completionRateString, Icons.percent, rh: rh),
        _buildStatTile('Réussite', stats.overallSuccessRateString, Icons.star_half_rounded, rh: rh),
        _buildStatTile('Meilleur thème', stats.bestTheme ?? '-', Icons.emoji_events_outlined, backgroundColor: Colors.green.shade100, textColor: bestColor, rh: rh),
        _buildStatTile('Thème à améliorer', stats.worstTheme ?? '-', Icons.trending_up_rounded, backgroundColor: Colors.red.shade100, textColor: worstColor, rh: rh),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, {Color? backgroundColor, Color? textColor, required ResponsiveHelper rh}) {
    final bgColor = backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHighest;
    final fgColor = textColor ?? Theme.of(context).textTheme.bodyLarge!.color!;
    final greyColor = textColor?.withOpacity(0.7) ?? Colors.grey.shade600;
    return Container(
      padding: EdgeInsets.all(rh.w(3)),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(rh.w(4))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(label, style: TextStyle(fontSize: rh.w(3.2), color: greyColor))),
              Icon(icon, color: greyColor, size: rh.w(4.5)),
            ],
          ),
          Expanded(
            child: Center(
              child: Text(value, textAlign: TextAlign.center, style: TextStyle(fontSize: rh.w(5), fontWeight: FontWeight.bold, color: fgColor)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrostedGlassContainer({required Widget child, required ResponsiveHelper rh}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(rh.w(4)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(rh.w(4)),
            border: Border.all(color: Colors.white30.withOpacity(0.8), width: 1.0),
          ),
          child: child,
        ),
      ),
    );
  }
}