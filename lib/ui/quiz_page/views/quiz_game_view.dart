import 'dart:async';
import 'package:flutter/material.dart';
import '../../../data/data_manager.dart';

// --- ENUM ---
enum _AnswerState { neutral, correct, wrong, disabled }

class QuizGameView extends StatefulWidget {
  final Map<String, dynamic>? questionData;
  final String difficultyLabel;
  final bool hasAnswered;
  final int? selectedAnswerIndex;
  final int? correctAnswerIndex;
  final Function(int, String, List<String>) onAnswer;
  final VoidCallback onNext;
  final VoidCallback onQuit;
  
  final bool isGameOver;
  final int score;
  final int totalQuestions;
  final List<Map<String, dynamic>>? questionsHistory; 

  const QuizGameView({
    super.key,
    required this.questionData,
    required this.difficultyLabel,
    required this.hasAnswered,
    this.selectedAnswerIndex,
    this.correctAnswerIndex,
    required this.onAnswer,
    required this.onNext,
    required this.onQuit,
    this.isGameOver = false,
    this.score = 0,
    this.totalQuestions = 0,
    this.questionsHistory,
  });

  @override
  State<QuizGameView> createState() => _QuizGameViewState();
}

class _QuizGameViewState extends State<QuizGameView> {
  late List<String> shuffledProps;
  late List<int> originalIndices;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _shuffleAnswers();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant QuizGameView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.questionData != oldWidget.questionData) {
      _shuffleAnswers();
    }
    if (widget.hasAnswered && !oldWidget.hasAnswered) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent - 100,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutQuart,
          );
        }
      });
    }
  }

  void _shuffleAnswers() {
    if (widget.questionData == null) return;
    List<String> rawProps = [];
    try { rawProps = List<String>.from(widget.questionData!['propositions']); } catch (e) { rawProps = ["Erreur"]; }
    List<int> indices = List.generate(rawProps.length, (index) => index);
    if (!widget.hasAnswered) indices.shuffle();
    shuffledProps = indices.map((i) => rawProps[i]).toList();
    originalIndices = indices;
  }

  void _showReportDialog() {
    if (widget.questionData == null) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _ReportDialogEditor(
        questionId: widget.questionData!['id'] ?? 'unknown',
        initialQuestion: widget.questionData!['question'] ?? '',
        initialPropositions: List<String>.from(widget.questionData!['propositions'] ?? []),
        initialExplanation: widget.questionData!['explication'] ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isGameOver || widget.questionData == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _QuizPatternPainter())),
            _QuizResultView(
              score: widget.score, 
              total: widget.totalQuestions, 
              questions: widget.questionsHistory ?? [],
              onQuit: widget.onQuit
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _QuizPatternPainter(),
            ),
          ),
          Positioned.fill(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                      child: Column(
                        children: [
                          // --- HEADER CORRIGÉ (STACK) ---
                          // Utilisation de Stack pour forcer le centrage absolu
                          SizedBox(
                            height: 48,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // GAUCHE : Quitter
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    onPressed: widget.onQuit,
                                    icon: const Icon(Icons.close_rounded, size: 22),
                                    label: const Text("Quitter", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
                                  ),
                                ),

                                // CENTRE : Signaler (Pile au milieu)
                                Align(
                                  alignment: Alignment.center,
                                  child: TextButton.icon(
                                    onPressed: _showReportDialog,
                                    icon: const Icon(Icons.edit_note_rounded, size: 20),
                                    label: const Text("Signaler", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.orange.shade800,
                                      backgroundColor: Colors.orange.shade50,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                                    ),
                                  ),
                                ),

                                // DROITE : Niveau
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
                                    child: Text("Niveau ${widget.difficultyLabel}", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.blueGrey.shade400, letterSpacing: 0.5)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Question
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8))],
                            ),
                            child: Text(
                              widget.questionData!['question'] ?? "?",
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), height: 1.3),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Réponses
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.8, crossAxisSpacing: 16, mainAxisSpacing: 16),
                            itemCount: shuffledProps.length,
                            itemBuilder: (ctx, visualIndex) {
                              final int realIndex = originalIndices[visualIndex];
                              return _AnswerButton(
                                text: shuffledProps[visualIndex],
                                state: _getAnswerState(realIndex),
                                onTap: widget.hasAnswered ? null : () => widget.onAnswer(realIndex, shuffledProps[visualIndex], List<String>.from(widget.questionData!['propositions'])),
                              );
                            },
                          ),
                          
                          // Résultat
                          if (widget.hasAnswered) ...[
                            const SizedBox(height: 40),
                            _ResultPanel(
                              isCorrect: widget.selectedAnswerIndex == widget.correctAnswerIndex,
                              explanation: widget.questionData!['explication'],
                              stats: widget.questionData!['answerStats'] ?? {},
                              totalAnswers: widget.questionData!['timesAnswered'] ?? 0,
                              propositions: widget.questionData!['propositions'],
                              correctAnswer: widget.questionData!['reponse'] ?? "",
                              onNext: widget.onNext,
                            ),
                            const SizedBox(height: 100),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _AnswerState _getAnswerState(int realIndex) {
    if (!widget.hasAnswered) return _AnswerState.neutral;
    if (realIndex == widget.correctAnswerIndex) return _AnswerState.correct;
    if (realIndex == widget.selectedAnswerIndex) return _AnswerState.wrong;
    return _AnswerState.disabled;
  }
}

// --- POP-UP ÉDITEUR "PRO" CORRIGÉE ---
class _ReportDialogEditor extends StatefulWidget {
  final String questionId;
  final String initialQuestion;
  final List<String> initialPropositions;
  final String initialExplanation;

  const _ReportDialogEditor({
    required this.questionId,
    required this.initialQuestion,
    required this.initialPropositions,
    required this.initialExplanation,
  });

  @override
  State<_ReportDialogEditor> createState() => _ReportDialogEditorState();
}

class _ReportDialogEditorState extends State<_ReportDialogEditor> {
  late TextEditingController _questionCtrl;
  late TextEditingController _propsBlockCtrl; // UN SEUL CONTROLEUR POUR TOUTES LES REPONSES
  late TextEditingController _explanationCtrl;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _questionCtrl = TextEditingController(text: widget.initialQuestion);
    _explanationCtrl = TextEditingController(text: widget.initialExplanation);
    
    // On joint les propositions par un saut de ligne
    _propsBlockCtrl = TextEditingController(text: widget.initialPropositions.join('\n'));
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _explanationCtrl.dispose();
    _propsBlockCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendDetailedReport() async {
    setState(() => _isSending = true);
    try {
      // On récupère simplement le texte des contrôleurs
      await DataManager.instance.reportQuestionDetailed(
        questionId: widget.questionId,
        question: _questionCtrl.text.trim(),
        propositions: _propsBlockCtrl.text.trim(), // On envoie le bloc tel quel
        explanation: _explanationCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Suggestion envoyée. Merci pour votre contribution !"), 
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.handyman_rounded, color: Colors.orange.shade800, size: 24)
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Suggérer une correction", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF1E293B))),
                        Text("Modifiez directement les champs ci-dessous.", style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              _EditorLabel(label: "La Question"),
              _EditorTextField(controller: _questionCtrl, maxLines: 3),
              const SizedBox(height: 24),

              // UN SEUL BLOC POUR LES RÉPONSES
              _EditorLabel(label: "Les 4 Propositions (une par ligne)"),
              _EditorTextField(controller: _propsBlockCtrl, maxLines: 6),
              const SizedBox(height: 12),

              _EditorLabel(label: "L'Explication"),
              _EditorTextField(controller: _explanationCtrl, maxLines: 5),
              
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(foregroundColor: Colors.blueGrey, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
                    child: const Text("Annuler", style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSending ? null : _sendDetailedReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: _isSending 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, size: 18),
                    label: Text(_isSending ? "Envoi..." : "Envoyer la suggestion", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widgets utilitaires pour l'éditeur
class _EditorLabel extends StatelessWidget {
  final String label;
  const _EditorLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF64748B), letterSpacing: 0.5)),
    );
  }
}

class _EditorTextField extends StatelessWidget {
  final TextEditingController controller;
  final int maxLines;

  const _EditorTextField({required this.controller, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B), fontWeight: FontWeight.w500, height: 1.3),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        prefixStyle: TextStyle(color: Colors.blueGrey.shade400, fontWeight: FontWeight.w600),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blueGrey.shade300, width: 1.5)),
      ),
    );
  }
}

class _QuizPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paintStroke = Paint()
      ..color = Colors.blueGrey.withOpacity(0.2)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final Paint paintFill = Paint()
      ..color = Colors.blueGrey.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    const double gridSize = 50.0;

    final int cols = (size.width / gridSize).ceil();
    final int rows = (size.height / gridSize).ceil();

    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        final double x = i * gridSize;
        final double y = j * gridSize;
        final Offset center = Offset(x + gridSize / 2, y + gridSize / 2);

        final int hash = ((i * 13) ^ (j * 7) + (i * j)).abs();
        final int shapeType = hash % 7; 

        switch (shapeType) {
          case 0: 
          case 1: 
            const double s = 4.0;
            canvas.drawLine(center.translate(-s, 0), center.translate(s, 0), paintStroke);
            canvas.drawLine(center.translate(0, -s), center.translate(0, s), paintStroke);
            break;
          case 2:
          case 3:
            canvas.drawCircle(center, 1.5, paintFill);
            break;
          case 4:
            canvas.drawCircle(center, 3.0, paintStroke);
            break;
          case 5:
            const double s = 3.0;
            canvas.drawLine(center.translate(-s, s), center.translate(s, -s), paintStroke);
            break;
          default:
            break;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- BOUTON DE RÉPONSE (Inchangé) ---
class _AnswerButton extends StatefulWidget {
  final String text; final _AnswerState state; final VoidCallback? onTap;
  const _AnswerButton({required this.text, required this.state, this.onTap});
  @override
  State<_AnswerButton> createState() => _AnswerButtonState();
}
class _AnswerButtonState extends State<_AnswerButton> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.white; Color textColor = const Color(0xFF1E293B); Color borderColor = Colors.transparent;
    double scale = _hover && widget.state == _AnswerState.neutral ? 1.02 : 1.0;
    switch (widget.state) {
      case _AnswerState.correct: bgColor = const Color(0xFF10B981); textColor = Colors.white; break;
      case _AnswerState.wrong: bgColor = const Color(0xFFF43F5E); textColor = Colors.white; break;
      case _AnswerState.disabled: bgColor = Colors.grey.shade50; textColor = Colors.grey.shade300; break;
      case _AnswerState.neutral: bgColor = Colors.white; borderColor = _hover ? const Color(0xFF6366F1) : Colors.transparent; break;
    }
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true), onExit: (_) => setState(() => _hover = false), cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150), transform: Matrix4.identity().scaled(scale), padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor, width: 2), boxShadow: [if (widget.state == _AnswerState.neutral) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]),
          child: Center(child: Text(widget.text, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis)),
        ),
      ),
    );
  }
}

// --- PANNEAU RÉSULTAT QUESTION (Inchangé) ---
class _ResultPanel extends StatelessWidget {
  final bool isCorrect; final String? explanation; final dynamic stats; final int totalAnswers; final List<dynamic> propositions; final String correctAnswer; final VoidCallback onNext;
  const _ResultPanel({required this.isCorrect, required this.explanation, required this.stats, required this.totalAnswers, required this.propositions, required this.correctAnswer, required this.onNext});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded, color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFF43F5E), size: 32), const SizedBox(width: 12), Text(isCorrect ? "Bien joué !" : "Oups...", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFF43F5E)))]),
            const SizedBox(height: 24),
            ...propositions.map((prop) {
              String pStr = prop.toString(); int votes = 0; if (stats is Map && stats[pStr] != null) votes = int.tryParse(stats[pStr].toString()) ?? 0;
              double percent = totalAnswers > 0 ? (votes / totalAnswers) : 0.0; bool isThisAnswerCorrect = pStr == correctAnswer;
              String percentStr = "${(percent * 100).toInt().toString().padLeft(2, '0')}%";
              return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [Expanded(flex: 4, child: Text(pStr, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 17, color: isThisAnswerCorrect ? const Color(0xFF10B981) : Colors.grey.shade600, fontWeight: isThisAnswerCorrect ? FontWeight.bold : FontWeight.normal))), Expanded(flex: 3, child: Stack(children: [Container(height: 10, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(5))), FractionallySizedBox(widthFactor: percent, child: Container(height: 10, decoration: BoxDecoration(color: isThisAnswerCorrect ? const Color(0xFF10B981) : Colors.grey.shade300, borderRadius: BorderRadius.circular(5))))])), const SizedBox(width: 12), Text(percentStr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace'))]));
            }).toList()
          ]),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("L'explication", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)), const SizedBox(height: 12), Text(explanation ?? "Pas d'explication disponible.", style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 16, height: 1.0)), const SizedBox(height: 30), SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: onNext, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0), child: const Text("Suivant", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))))]),
        ),
      ],
    );
  }
}

// --- ÉCRAN DE FIN DE PARTIE (Inchangé) ---
class _QuizResultView extends StatelessWidget {
  final int score;
  final int total;
  final List<Map<String, dynamic>> questions;
  final VoidCallback onQuit;

  const _QuizResultView({required this.score, required this.total, required this.questions, required this.onQuit});

  double _calculateCommunityAverage() {
    if (questions.isEmpty) return 0.0;
    double totalRatio = 0.0;
    int validQ = 0;
    for (var q in questions) {
      int tAns = q['timesAnswered'] ?? 0;
      int tCor = q['timesCorrect'] ?? 0;
      if (tAns > 0) {
        totalRatio += (tCor / tAns);
        validQ++;
      }
    }
    if (validQ == 0) return 0.0;
    return totalRatio / validQ;
  }

  @override
  Widget build(BuildContext context) {
    double userPercent = total > 0 ? score / total : 0.0;
    double communityPercent = _calculateCommunityAverage();
    String title = "Terminé !"; String subtitle = "Voici le bilan de votre session."; Color themeColor = const Color(0xFF6366F1);
    if (userPercent == 1.0) { title = "Parfait !"; subtitle = "Un sans-faute impressionnant."; themeColor = const Color(0xFF10B981); } 
    else if (userPercent >= 0.7) { title = "Bien joué !"; subtitle = "De très bons résultats."; themeColor = const Color(0xFF10B981); } 
    else if (userPercent < 0.5) { title = "Session terminée"; subtitle = "Continuez à vous entraîner !"; themeColor = const Color(0xFFF43F5E); }
    bool sitsAboveAverage = userPercent >= communityPercent;

    return Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: themeColor, letterSpacing: -0.5)),
                const SizedBox(height: 8),
                Text(subtitle, style: TextStyle(fontSize: 16, color: Colors.blueGrey.shade500, fontWeight: FontWeight.w500)),
                const SizedBox(height: 50),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1200), curve: Curves.easeOutBack, tween: Tween(begin: 0, end: userPercent),
                  builder: (context, value, _) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(width: 180, height: 180, child: CircularProgressIndicator(value: value, strokeWidth: 12, backgroundColor: Colors.grey.shade100, valueColor: AlwaysStoppedAnimation(themeColor), strokeCap: StrokeCap.round)),
                        Column(mainAxisSize: MainAxisSize.min, children: [Text("${(value * 100).toInt()}%", style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.blueGrey.shade800)), Text("$score sur $total", style: TextStyle(fontSize: 14, color: Colors.blueGrey.shade400, fontWeight: FontWeight.w600))])
                      ],
                    );
                  },
                ),
                const SizedBox(height: 50),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(children: [
                    Row(children: [Expanded(child: _SlimStatItem(label: "Votre Score", value: "${(userPercent*100).toInt()}%", color: themeColor, isPrimary: true)), Container(width: 1, height: 40, color: Colors.grey.shade300), Expanded(child: _SlimStatItem(label: "Moyenne joueurs", value: "${(communityPercent*100).toInt()}%", color: Colors.blueGrey.shade400, isPrimary: false))]),
                    const SizedBox(height: 20),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: sitsAboveAverage ? Colors.green.shade50 : Colors.orange.shade50, borderRadius: BorderRadius.circular(12)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(sitsAboveAverage ? Icons.trending_up : Icons.trending_flat, size: 18, color: sitsAboveAverage ? Colors.green : Colors.orange), const SizedBox(width: 8), Flexible(child: Text(sitsAboveAverage ? "Vous êtes au-dessus de la moyenne !" : "Score proche de la moyenne.", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: sitsAboveAverage ? Colors.green.shade800 : Colors.orange.shade800)))]))
                  ]),
                ),
                const SizedBox(height: 40),
                SizedBox(width: double.infinity, height: 56, child: TextButton(onPressed: onQuit, style: TextButton.styleFrom(foregroundColor: Colors.blueGrey.shade700, backgroundColor: Colors.grey.shade100, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text("Retour à l'accueil", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlimStatItem extends StatelessWidget {
  final String label; final String value; final Color color; final bool isPrimary;
  const _SlimStatItem({required this.label, required this.value, required this.color, this.isPrimary = false});
  @override
  Widget build(BuildContext context) {
    return Column(children: [Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)), const SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 12, fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal, color: Colors.blueGrey.shade400))]);
  }
}