import 'package:flutter/material.dart';

class QuizGameView extends StatelessWidget {
  final Map<String, dynamic> questionData;
  final String difficultyLabel;
  final bool hasAnswered;
  final int? selectedAnswerIndex;
  final int? correctAnswerIndex;
  final Function(int, String, List<String>) onAnswer;
  final VoidCallback onNext;
  final VoidCallback onQuit;

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
  });

  @override
  Widget build(BuildContext context) {
    List<String> props = [];
    try { props = List<String>.from(questionData['propositions']); } catch (e) { props = ["Erreur de données"]; }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- COLONNE GAUCHE : QUESTION + RÉPONSES ---
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    // Header Jeu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: onQuit, 
                          icon: const Icon(Icons.close_rounded, size: 20), 
                          label: const Text("Quitter", style: TextStyle(fontWeight: FontWeight.bold)),
                          style: TextButton.styleFrom(foregroundColor: Colors.grey),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
                          child: Text("Niveau $difficultyLabel", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.blueGrey.shade400, letterSpacing: 1.0)),
                        )
                      ],
                    ),
                    const Spacer(),
                    
                    // La Question
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 10))],
                      ),
                      child: Text(
                        questionData['question'] ?? "?",
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), height: 1.3),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    const SizedBox(height: 40),

                    // Les Réponses
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, childAspectRatio: 3.5, crossAxisSpacing: 20, mainAxisSpacing: 20
                      ),
                      itemCount: props.length,
                      itemBuilder: (ctx, idx) {
                        return _AnswerButton(
                          text: props[idx],
                          state: _getAnswerState(idx),
                          onTap: hasAnswered ? null : () => onAnswer(idx, props[idx], props),
                        );
                      },
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              // --- COLONNE DROITE : RÉSULTAT & STATS (Apparaît après réponse) ---
              if (hasAnswered) ...[
                const SizedBox(width: 40),
                Expanded(
                  flex: 3,
                  child: _ResultPanel(
                    isCorrect: selectedAnswerIndex == correctAnswerIndex,
                    explanation: questionData['explication'],
                    stats: questionData['answerStats'] ?? {},
                    totalAnswers: questionData['timesAnswered'] ?? 0,
                    totalCorrect: questionData['timesCorrect'] ?? 0,
                    propositions: props,
                    correctAnswer: questionData['reponse'] ?? "",
                    onNext: onNext,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  _AnswerState _getAnswerState(int index) {
    if (!hasAnswered) return _AnswerState.neutral;
    if (index == correctAnswerIndex) return _AnswerState.correct;
    if (index == selectedAnswerIndex) return _AnswerState.wrong;
    return _AnswerState.disabled;
  }
}

// --- WIDGETS DU JEU ---

enum _AnswerState { neutral, correct, wrong, disabled }

class _AnswerButton extends StatefulWidget {
  final String text;
  final _AnswerState state;
  final VoidCallback? onTap;
  const _AnswerButton({required this.text, required this.state, this.onTap});
  @override
  State<_AnswerButton> createState() => _AnswerButtonState();
}

class _AnswerButtonState extends State<_AnswerButton> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.white;
    Color textColor = const Color(0xFF1E293B);
    Color borderColor = Colors.transparent;
    double scale = _hover && widget.state == _AnswerState.neutral ? 1.02 : 1.0;

    switch (widget.state) {
      case _AnswerState.correct:
        bgColor = const Color(0xFF10B981); // Vert
        textColor = Colors.white;
        break;
      case _AnswerState.wrong:
        bgColor = const Color(0xFFF43F5E); // Rouge
        textColor = Colors.white;
        break;
      case _AnswerState.disabled:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade400;
        break;
      case _AnswerState.neutral:
        bgColor = Colors.white;
        borderColor = _hover ? const Color(0xFF6366F1) : Colors.transparent; // Bordure au survol
        break;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity().scaled(scale),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              if (widget.state == _AnswerState.neutral)
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Center(
            child: Text(
              widget.text,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  final bool isCorrect;
  final String? explanation;
  final dynamic stats;
  final int totalAnswers;
  final int totalCorrect;
  final List<String> propositions;
  final String correctAnswer;
  final VoidCallback onNext;

  const _ResultPanel({
    required this.isCorrect, 
    required this.explanation, 
    required this.stats,
    required this.totalAnswers,
    required this.totalCorrect,
    required this.propositions,
    required this.correctAnswer,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    // Calcul % réussite global
    double successRate = totalAnswers > 0 ? (totalCorrect / totalAnswers) : 0.0;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 40, offset: const Offset(0, 20))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête résultat
          Row(
            children: [
              Icon(isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded, color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFF43F5E), size: 32),
              const SizedBox(width: 12),
              Text(isCorrect ? "Excellent !" : "Aïe...", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFF43F5E))),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(8)),
            child: Text("${(successRate * 100).toInt()}% des joueurs ont réussi", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade600)),
          ),
          
          const Divider(height: 40),

          // Stats Barres
          ...propositions.map((prop) {
            int votes = 0;
            if (stats is Map && stats[prop] != null) votes = int.tryParse(stats[prop].toString()) ?? 0;
            double percent = totalAnswers > 0 ? (votes / totalAnswers) : 0.0;
            bool isAnswerCorrect = prop == correctAnswer;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(prop, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: isAnswerCorrect ? FontWeight.bold : FontWeight.normal, color: isAnswerCorrect ? const Color(0xFF10B981) : Colors.grey))),
                      Text("${(percent * 100).toInt()}%", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation(isAnswerCorrect ? const Color(0xFF10B981) : Colors.grey.shade300),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 24),
          const Text("Explication", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 8),
          Expanded(child: SingleChildScrollView(child: Text(explanation ?? "Pas d'info.", style: TextStyle(color: Colors.blueGrey.shade600, height: 1.5)))),
          
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1), 
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: const Color(0xFF6366F1).withOpacity(0.4)
              ),
              child: const Text("Question Suivante", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}