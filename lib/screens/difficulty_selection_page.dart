import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../utils/responsive_helper.dart';
import 'quiz_page.dart';

class QuizPack {
  final String id;
  final String label;
  final int averageDifficulty;
  final List<DocumentSnapshot> questions;
  int userCorrectAnswers;
  bool isPerfect;

  QuizPack({
    required this.id,
    required this.label,
    required this.averageDifficulty,
    required this.questions,
    this.userCorrectAnswers = 0,
    this.isPerfect = false,
  });

  bool get isPlayed => userCorrectAnswers > 0;
}

class DifficultyCategory {
  final String title;
  final List<QuizPack> packs;

  DifficultyCategory({
    required this.title,
    required this.packs,
  });
}

class DifficultySelectionPage extends StatefulWidget {
  final String themeName;
  final String subThemeName;
  const DifficultySelectionPage({super.key, required this.themeName, required this.subThemeName});
  @override
  State<DifficultySelectionPage> createState() => _DifficultySelectionPageState();
}


class _DifficultySelectionPageState extends State<DifficultySelectionPage> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  
  bool _isLoading = true; // Pour afficher un spinner
  List<DifficultyCategory> _categories = [];
  Set<String> _perfectQuizIds = {};
  Map<String, bool> _userAnswers = {};
  final Map<String, bool> _expandedState = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (mounted) setState(() => _scrollOffset = _scrollController.offset);
    });
    // On lance le chargement des données spécifiques à cette page
    _loadPageData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchUserProgressAndAnswers() async {
    final user = FirebaseAuth.instance.currentUser;
    // Si l'utilisateur est un invité, on retourne des données vides
    if (user == null || user.isAnonymous) {
      return {'perfectIds': <String>{}, 'answers': <String, bool>{}};
    }

    final userDoc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
    if (!userDoc.exists) {
      return {'perfectIds': <String>{}, 'answers': <String, bool>{}};
    }
    
    final userData = userDoc.data() ?? {};
    final perfectMap = Map<String, dynamic>.from(userData['perfectQuizzes'] ?? {});
    final answersMap = Map<String, bool>.from(userData['answeredQuestions'] ?? {});
    
    final perfectIds = perfectMap.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toSet();

    // On retourne une Map contenant les deux jeux de données
    return {
      'perfectIds': perfectIds,
      'answers': answersMap,
    };
  }
  
  Future<void> _loadPageData() async {
    // a. On charge les données de l'utilisateur (rapide)
    final userProgress = await _fetchUserProgressAndAnswers();
    _perfectQuizIds = userProgress['perfectIds'] as Set<String>;
    _userAnswers = userProgress['answers'] as Map<String, bool>;
    
    // b. On charge UNIQUEMENT les questions pour ce sous-thème
    final questionsForThisSubTheme = await _fetchQuestionsForSubTheme();

    // c. Une fois qu'on a les questions, on peut créer les packs
    if (mounted) {
      _createCategoriesAndPacks(questionsForThisSubTheme, _userAnswers);
      // On met à jour l'interface pour afficher le contenu
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<DocumentSnapshot>> _fetchQuestionsForSubTheme() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Questions')
        .where('theme', isEqualTo: widget.themeName)
        .where('sousTheme', isEqualTo: widget.subThemeName)
        .get();
    return snapshot.docs;
  }

  Future<void> _fetchAndProcessData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));

      final questionsSnapshot = await FirebaseFirestore.instance
          .collection('Questions')
          .where('theme', isEqualTo: widget.themeName)
          .where('sousTheme', isEqualTo: widget.subThemeName)
          .orderBy('difficulty')
          .get();

      if (!userDoc.exists) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      
      final allQuestions = questionsSnapshot.docs;
      final userData = userDoc.data() ?? {};
      final userAnswers = Map<String, bool>.from(userData['answeredQuestions'] ?? {});

      if (userData.containsKey('perfectQuizzes')) {
        final perfectMap = Map<String, dynamic>.from(userData['perfectQuizzes']);
        _perfectQuizIds = perfectMap.entries
            .where((entry) => entry.value == true)
            .map((entry) => entry.key)
            .toSet();
      } else {
        _perfectQuizIds = {};
      }

      _createCategoriesAndPacks(allQuestions, userAnswers);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _createCategoriesAndPacks(List<DocumentSnapshot> allQuestions, Map<String, bool> userAnswers) {
    const int quizSize = 10;
    final List<DifficultyCategory> finalCategories = [];

    final List<Map<String, dynamic>> difficultyBins = [
      {'title': 'Facile', 'min': 1, 'max': 3},
      {'title': 'Moyen', 'min': 4, 'max': 6},
      {'title': 'Difficile', 'min': 7, 'max': 8},
      {'title': 'Expert', 'min': 9, 'max': 10},
    ];

    for (final bin in difficultyBins) {
      final categoryQuestions = allQuestions.where((doc) {
        final difficulty = (doc.data() as Map<String, dynamic>?)?['difficulty'] as int? ?? 5;
        return difficulty >= bin['min'] && difficulty <= bin['max'];
      }).toList();

      if (categoryQuestions.isNotEmpty) {
        final List<QuizPack> packsForThisCategory = [];
        int packNumber = 1;

        for (int i = 0; i < categoryQuestions.length; i += quizSize) {
          final packQuestions = categoryQuestions.sublist(i, (i + quizSize > categoryQuestions.length) ? categoryQuestions.length : i + quizSize);
          
          int correctAnswersInPack = 0;
          for (var question in packQuestions) {
            if (userAnswers[question.id] == true) correctAnswersInPack++;
          }

          final totalDifficulty = packQuestions.fold<int>(0, (sum, doc) => sum + ((doc.data() as Map<String, dynamic>?)?['difficulty'] as int? ?? 5));
          final avgDifficulty = packQuestions.isNotEmpty ? (totalDifficulty / packQuestions.length).round() : 5;

          packsForThisCategory.add(QuizPack(
            id: '${widget.themeName}-${widget.subThemeName}-${bin['title']}-#$packNumber',
            label: '#$packNumber',
            questions: packQuestions,
            averageDifficulty: avgDifficulty,
            userCorrectAnswers: correctAnswersInPack,
            isPerfect: correctAnswersInPack == packQuestions.length && packQuestions.isNotEmpty,
          ));
          packNumber++;
        }
        
        packsForThisCategory.sort((a, b) {
          if (a.isPlayed && !b.isPlayed) return 1;
          if (!a.isPlayed && b.isPlayed) return -1;
          return a.label.compareTo(b.label);
        });

        finalCategories.add(DifficultyCategory(title: bin['title'], packs: packsForThisCategory));
        _expandedState[bin['title']] = false;
      }
    }
    
    _categories = finalCategories;
  }

  void _showDifficultyExplanationDialog() {
    final rh = ResponsiveHelper(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.psychology_alt_outlined, color: Theme.of(context).primaryColor),
              const SizedBox(width: 10),
              const Text("Difficulté Adaptative"),
            ],
          ),
          content: SingleChildScrollView( // Pour s'assurer que ça ne déborde pas
            child: Text(
              "Les questions sont classées automatiquement sur une échelle de difficulté de 1 à 10.\n\n"
              "Ce classement est dynamique : il est basé sur le pourcentage de bonnes réponses de tous les joueurs. Une question à laquelle beaucoup de monde répond bien sera considérée comme facile, et inversement.\n\n"
              "Plus il y a de joueurs, et plus les questions seront classées correctement !",
              style: TextStyle(fontSize: rh.w(3.8), color: Colors.grey.shade700),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("J'ai compris"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rh = ResponsiveHelper(context);
    final double blurIntensity = (_scrollOffset / 50.0).clamp(0.0, 5.0);
    final double backgroundOpacity = (_scrollOffset / 100.0).clamp(0.0, 0.3);

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            title: Text(widget.subThemeName),
            centerTitle: true,
            pinned: true,
            toolbarHeight: rh.h(7),
            titleTextStyle: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontSize: rh.w(6), fontWeight: FontWeight.w500),
            actions: [
              IconButton(
                icon: Icon(Icons.help_outline, color: Colors.grey.shade600),
                onPressed: _showDifficultyExplanationDialog,
                tooltip: 'Comment fonctionne la difficulté ?',
              ),
            ],
            backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(backgroundOpacity),
            elevation: 0,
            scrolledUnderElevation: 2.0,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: blurIntensity, sigmaY: blurIntensity), child: Container(color: Colors.transparent))),
          ),
          
          _isLoading
              ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              : _categories.isEmpty
                  ? const SliverFillRemaining(child: Center(child: Text("Aucune question disponible.")))
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final category = _categories[index];
                          return _buildCategorySection(category, rh);
                        },
                        childCount: _categories.length,
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(DifficultyCategory category, ResponsiveHelper rh) {
    final bool isExpanded = _expandedState[category.title] ?? false;
    
    final allPacksSorted = List<QuizPack>.from(category.packs)
      ..sort((a, b) {
        int numA = int.tryParse(a.label.replaceAll('Pack ', '')) ?? 0;
        int numB = int.tryParse(b.label.replaceAll('Pack ', '')) ?? 0;
        return numA.compareTo(numB);
      });
      
    final List<QuizPack> packsToShow;
    if (isExpanded) {
      packsToShow = allPacksSorted;
    } else {
      final unplayedPacks = allPacksSorted.where((p) => !p.isPlayed).take(3).toList();
      if (unplayedPacks.length >= 3) {
        packsToShow = unplayedPacks;
      } else {
        final playedPacks = allPacksSorted.where((p) => p.isPlayed).toList();
        final needed = 3 - unplayedPacks.length;
        final lastPlayed = playedPacks.length > needed ? playedPacks.sublist(playedPacks.length - needed) : playedPacks;
        packsToShow = [...unplayedPacks, ...lastPlayed];
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: rh.h(1)),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: rh.w(4), vertical: rh.h(1)),
            child: Row(children: [
              const Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: rh.w(2.5)),
                child: Text(category.title, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: rh.w(3.5))),
              ),
              const Expanded(child: Divider()),
            ]),
          ),
          
          // --- ON RÉINTÈGRE LES ANIMATIONS ICI ---
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _buildAnimatedGrid(category, packsToShow, rh),
          ),

          if (category.packs.length > 3)
            TextButton(
              onPressed: () => setState(() => _expandedState[category.title] = !isExpanded),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(isExpanded ? "Voir moins" : "Voir tout", style: TextStyle(fontSize: rh.w(3.5))),
                SizedBox(width: rh.w(1)),
                Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: rh.w(5)),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedGrid(DifficultyCategory category, List<QuizPack> packsToShow, ResponsiveHelper rh) {
    return AnimationLimiter(
      key: ValueKey<String>("${category.title}-${packsToShow.length}"),
      child: GridView.builder(
        padding: EdgeInsets.symmetric(horizontal: rh.w(3)),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: rh.w(2.5),
          crossAxisSpacing: rh.w(2.5),
          childAspectRatio: 1.0,
        ),
        itemCount: packsToShow.length,
        itemBuilder: (context, index) {
          final pack = packsToShow[index];
          final isPerfect = _perfectQuizIds.contains(pack.id);
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 375),
            columnCount: 2,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: _buildQuizPackCard(pack, isPerfect),
              ),
            ),
          );
        },
      ),
    );
  }


  Color _getColorForDifficulty(int difficulty) {
    if (difficulty >= 1 && difficulty <= 3) {
      return const Color(0xFFFAA03C);
    }
    else if (difficulty >= 4 && difficulty <= 6) {
      return const Color(0xFFFB7855);
    }
    else if (difficulty >= 7 && difficulty <= 8) {
      return const Color(0xFFFC506E);
    }
    else if (difficulty >= 9 && difficulty <= 10) {
      return const Color(0xFF981B9F);
    }
    else {
      return Colors.grey.shade200;
    }
  }

  Color _getPastelColorForDifficulty(int difficulty) {
    if (difficulty >= 1 && difficulty <= 3) {
      return const Color(0xFFFDD9B0);
    } 
    else if (difficulty >= 4 && difficulty <= 6) {
      return const Color(0xFFFDD0C3);
    }
    else if (difficulty >= 7 && difficulty <= 8) {
      return const Color(0xFFFEBDC9);
    }
    else if (difficulty >= 9 && difficulty <= 10) {
      return const Color(0xFFD8AADB);
    }
    else {
      return Colors.grey.shade200;
    }
  }

  Widget _buildQuizPackCard(QuizPack pack, bool isPerfect) {
    final rh = ResponsiveHelper(context);
    final double successPercentage = pack.questions.isNotEmpty
        ? (pack.userCorrectAnswers / pack.questions.length)
        : 0.0;
    
    final baseColor = _getColorForDifficulty(pack.averageDifficulty);
    final pastelColor = _getPastelColorForDifficulty(pack.averageDifficulty);
    final textColor = baseColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

    return Card(
      elevation: 4.0,
      clipBehavior: Clip.antiAlias,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rh.w(3))), // Bords proportionnels
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizPage(
                themeName: widget.themeName,
                subThemeName: widget.subThemeName,
                questionsToPlay: pack.questions,
                quizTitle: pack.label,
                quizId: pack.id,
              ),
            ),
          );
          _fetchAndProcessData();
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              color: pastelColor,
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: successPercentage,
                widthFactor: 1.0,
                child: Container(
                  color: baseColor,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    pack.label,
                    style: TextStyle(
                      fontSize: rh.w(4.5), // Police proportionnelle
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      shadows: [Shadow(blurRadius: 1, color: Colors.black.withOpacity(0.5))],
                    ),
                  ),
                  SizedBox(height: rh.h(1)), // Espace proportionnel
                  Text(
                    'Score: ${pack.userCorrectAnswers} / ${pack.questions.length}',
                    style: TextStyle(
                      color: textColor.withOpacity(0.9),
                      fontWeight: FontWeight.bold,
                      fontSize: rh.w(3.3), // Police proportionnelle
                    ),
                  ),
                  Text(
                    "(${(successPercentage * 100).toStringAsFixed(0)}%)",
                    style: TextStyle(
                      color: textColor.withOpacity(0.9),
                      fontSize: rh.w(3), // Police proportionnelle
                    ),
                  ),
                ],
              ),
            ),
            if (isPerfect)
              Positioned(
                top: rh.w(2), // Positionnement proportionnel
                right: rh.w(2),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 2, color: Colors.black.withOpacity(0.5))],
                  size: rh.w(5.5), // Icône proportionnelle
                ),
              ),
          ],
        ),
      ),
    );
  }
}