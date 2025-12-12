import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../data/data_manager.dart';
import 'widgets/activity_chart.dart';
import 'widgets/stat_card.dart';

class StatsPage extends StatefulWidget {
  // Callback pour rediriger vers la page de connexion
  final VoidCallback? onGoToLogin;

  const StatsPage({super.key, this.onGoToLogin});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  bool _isInit = false;
  void _update() => setState(() {});

  @override
  void initState() {
    super.initState();
    DataManager.instance.addListener(_update);
    initializeDateFormatting('fr_FR', null).then((_) {
      if (mounted) setState(() => _isInit = true);
    });
  }

  @override
  void dispose() {
    DataManager.instance.removeListener(_update);
    super.dispose();
  }

  // --- LOGIQUE DE TRI ---
  Map<String, dynamic> _calculateInsights() {
    final user = DataManager.instance.currentUser;
    final Map<String, dynamic> rawScores = user.scores; 

    Map<String, int> themeTotals = {};

    rawScores.forEach((key, value) {
      String mainTheme = key.contains('-') ? key.split('-')[0].trim() : key;
      int score = 0;
      if (value is int) {
        score = value;
      } else if (value is Map) {
        score = (value['dynamicScore'] as num?)?.toInt() ?? 0;
      }
      themeTotals[mainTheme] = (themeTotals[mainTheme] ?? 0) + score;
    });

    if (themeTotals.isEmpty) return {};

    var sorted = themeTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'bestName': sorted.first.key,
      'bestScore': sorted.first.value,
      'worstName': sorted.last.key,
      'worstScore': sorted.last.value,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final user = DataManager.instance.currentUser;

    // --- VUE INVITÉ ---
    if (user.id == 'guest') {
      return _GuestStatsView(onGoToLogin: widget.onGoToLogin);
    }

    // --- DASHBOARD CONNECTÉ (LOGIQUE MISE À JOUR) ---
    final totalQuestionsDb = DataManager.instance.totalQuestionsInDb > 0 ? DataManager.instance.totalQuestionsInDb : 1;
    
    // 1. VOLUME (Compteur bête et méchant)
    final int volumeReponses = user.totalAnswers;

    // 2. PROGRESSION (Questions uniques découvertes)
    final int questionsUniquesVues = user.seenQuestionIds.length;
    
    // 3. COMPLÉTION (% de la base de données découverte)
    double completionPercent = (questionsUniquesVues / totalQuestionsDb) * 100;
    if (completionPercent > 100) completionPercent = 100;

    // 4. PRÉCISION (Maîtrise / Découverte)
    // Combien de questions je maîtrise PARMI celles que j'ai vues ?
    double accuracyPercent = 0.0;
    if (questionsUniquesVues > 0) {
      accuracyPercent = (user.answeredQuestions.length / questionsUniquesVues) * 100;
    }

    final activityData = user.getLast7DaysStackedStats();
    final insights = _calculateInsights();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      // 1. Le ScrollView est maintenant LE PARENT PRINCIPAL
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: Container(
          // 2. On force la largeur à l'infini pour que les côtés vides soient scrollables
          width: double.infinity,
          alignment: Alignment.center, // Remplace le widget Center
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 60.0),
          
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StaggeredReveal(
                  delay: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("TABLEAU DE BORD", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.blueGrey.shade400, letterSpacing: 2.0)),
                      const SizedBox(height: 12),
                      Text("Vos Performances", style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF111827), letterSpacing: -1.0, height: 1.1)),
                      const SizedBox(height: 8),
                      Text("Suivez votre évolution et analysez vos points forts.", style: TextStyle(fontSize: 16, color: Colors.blueGrey.shade500, height: 1.5)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 50),

                LayoutBuilder(builder: (context, constraints) {
                    int columns = constraints.maxWidth > 800 ? 4 : 2;
                    double ratio = constraints.maxWidth > 800 ? 1.5 : 1.4; 
                    return GridView.count(
                      crossAxisCount: columns, crossAxisSpacing: 24, mainAxisSpacing: 24, shrinkWrap: true, childAspectRatio: ratio, physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _StaggeredReveal(delay: 1, child: StatCard(
                          title: "Progression", 
                          value: "$questionsUniquesVues", // Utilise seenQuestionIds.length
                          suffix: "/ $totalQuestionsDb", 
                          description: "Questions uniques.", // Texte mis à jour
                          icon: Icons.auto_graph_rounded, 
                          color: const Color(0xFF6366F1)
                        )),
                        _StaggeredReveal(delay: 2, child: StatCard(
                          title: "Complétion", 
                          value: "${completionPercent.toStringAsFixed(1)}%", 
                          description: "Contenu exploré.", 
                          icon: Icons.pie_chart_rounded, 
                          color: const Color(0xFFEC4899)
                        )),
                        _StaggeredReveal(delay: 3, child: StatCard(
                          title: "Volume", 
                          value: "$volumeReponses", // Utilise totalAnswers
                          description: "Total clics.", 
                          icon: Icons.layers_rounded, 
                          color: const Color(0xFF8B5CF6)
                        )),
                        _StaggeredReveal(delay: 4, child: StatCard(
                          title: "Maîtrise", // Renommé de Précision à Maîtrise pour être plus clair
                          value: "${accuracyPercent.toStringAsFixed(1)}%", 
                          description: "Acquis / Vus.", 
                          icon: Icons.verified_rounded, 
                          color: const Color(0xFF10B981)
                        )),
                      ],
                    );
                }),

                const SizedBox(height: 60),

                _StaggeredReveal(
                  delay: 5,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(width: 4, height: 24, decoration: BoxDecoration(color: Colors.blueGrey.shade800, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 12),
                      Text("Analyse Hebdomadaire", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.blueGrey.shade800)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),

                SizedBox(
                  height: 420,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 68,
                        child: _StaggeredReveal(
                          delay: 6,
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFF64748B).withOpacity(0.06), blurRadius: 30, offset: const Offset(0, 15)),
                                BoxShadow(color: Colors.white, blurRadius: 0, offset: const Offset(0, 0))
                              ],
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: ActivityChart(data: activityData),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 24),

                      if (insights.isNotEmpty)
                        Expanded(
                          flex: 32,
                          child: Column(
                            children: [
                              Expanded(
                                child: _StaggeredReveal(
                                  delay: 7,
                                  child: StatCard.insight(title: "Meilleur Thème", value: insights['bestName'], scoreText: "Score cumulé : ${insights['bestScore']}", isPositive: true),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Expanded(
                                child: _StaggeredReveal(
                                  delay: 8,
                                  child: StatCard.insight(title: "À Améliorer", value: insights['worstName'], scoreText: "Score cumulé : ${insights['worstScore']}", isPositive: false),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// VUE INVITÉ (DESIGN ÉPURÉ & ACTIONABLE)
// ---------------------------------------------------------------------------
class _GuestStatsView extends StatelessWidget {
  final VoidCallback? onGoToLogin;
  const _GuestStatsView({this.onGoToLogin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Center(
        child: _StaggeredReveal(
          delay: 0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icone propre sur fond blanc
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
                    ],
                  ),
                  child: const Icon(Icons.bar_chart_rounded, size: 64, color: Color(0xFF6366F1)),
                ),
                const SizedBox(height: 40),
                
                // Titre
                const Text(
                  "Vos statistiques vous attendent",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Texte descriptif (Sans cadre, direct sur fond)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Connectez-vous pour sauvegarder votre progression et analyser vos points forts.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.blueGrey,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                
                // Bouton de connexion
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (onGoToLogin != null) {
                        onGoToLogin!(); // Déclenche la navigation
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez aller dans l'onglet Profil pour vous connecter.")));
                      }
                    },
                    icon: const Icon(Icons.login_rounded),
                    label: const Text("Se connecter maintenant"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ANIMATION CASCADE (Inchangée)
// ---------------------------------------------------------------------------
class _StaggeredReveal extends StatefulWidget {
  final Widget child;
  final int delay;
  const _StaggeredReveal({required this.child, required this.delay});
  @override
  State<_StaggeredReveal> createState() => _StaggeredRevealState();
}

class _StaggeredRevealState extends State<_StaggeredReveal> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.delay * 100), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _fadeAnimation, child: SlideTransition(position: _slideAnimation, child: widget.child));
  }
}