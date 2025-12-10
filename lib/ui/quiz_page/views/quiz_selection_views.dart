import 'package:flutter/material.dart';
import '../../../data/data_manager.dart';

// --- 1. VUE SÉLECTION THÈME ---
class ThemeSelectionView extends StatelessWidget {
  final List<ThemeInfo> themes;
  final Function(ThemeInfo) onSelect;

  const ThemeSelectionView({super.key, required this.themes, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _HeaderTitle(title: "EXPLORATION", subtitle: "Choisissez une catégorie pour commencer."),
        const SizedBox(height: 40),
        Expanded(
          child: GridView.builder(
            clipBehavior: Clip.none,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 240,
              childAspectRatio: 1.1,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: themes.length,
            itemBuilder: (ctx, index) {
              final t = themes[index];
              return _SelectionCard(
                title: t.name,
                subtitle: "JOUER",
                icon: Icons.category_rounded, // Tu pourrais mapper des icônes spécifiques ici
                color: _getColorForTheme(t.name),
                onTap: () => onSelect(t),
              );
            },
          ),
        ),
      ],
    );
  }
}

// --- 2. VUE SÉLECTION SOUS-THÈME ---
class SubThemeSelectionView extends StatelessWidget {
  final ThemeInfo theme;
  final List<SubThemeInfo> subThemes;
  final Function(SubThemeInfo) onSelect;
  final VoidCallback onBack;

  const SubThemeSelectionView({super.key, required this.theme, required this.subThemes, required this.onSelect, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded, color: Colors.blueGrey)),
            const SizedBox(width: 8),
            _HeaderTitle(title: theme.name.toUpperCase(), subtitle: "Sélectionnez un sujet spécifique."),
          ],
        ),
        const SizedBox(height: 40),
        Expanded(
          child: GridView.builder(
            clipBehavior: Clip.none,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              childAspectRatio: 2.5, // Format liste large
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: subThemes.length,
            itemBuilder: (ctx, index) {
              return _ListSelectionCard(
                title: subThemes[index].name,
                color: _getColorForTheme(theme.name),
                onTap: () => onSelect(subThemes[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

// --- 3. VUE SÉLECTION DIFFICULTÉ ---
class DifficultySelectionView extends StatelessWidget {
  final ThemeInfo theme;
  final SubThemeInfo subTheme;
  final Function(String, int, int) onSelect;
  final VoidCallback onBack;

  const DifficultySelectionView({super.key, required this.theme, required this.subTheme, required this.onSelect, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded, color: Colors.blueGrey)),
            const SizedBox(width: 8),
            _HeaderTitle(title: subTheme.name.toUpperCase(), subtitle: "Choisissez votre niveau de défi."),
          ],
        ),
        const SizedBox(height: 60),
        Center(
          child: Wrap(
            spacing: 30, runSpacing: 30,
            alignment: WrapAlignment.center,
            children: [
              _DifficultyCard("FACILE", Colors.green, "Niv. 1-3", () => onSelect("Facile", 1, 3)),
              _DifficultyCard("MOYEN", Colors.orange, "Niv. 4-6", () => onSelect("Moyen", 4, 6)),
              _DifficultyCard("DIFFICILE", Colors.red, "Niv. 7-8", () => onSelect("Difficile", 7, 8)),
              _DifficultyCard("EXTRÊME", Colors.purple, "Niv. 9-10", () => onSelect("Impossible", 9, 10)),
            ],
          ),
        )
      ],
    );
  }
}

// --- WIDGETS LOCAUX ---

class _HeaderTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _HeaderTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.blueGrey.shade400, letterSpacing: 2.0)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
      ],
    );
  }
}

class _SelectionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SelectionCard({required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap});
  @override
  State<_SelectionCard> createState() => _SelectionCardState();
}

class _SelectionCardState extends State<_SelectionCard> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: _hover ? Matrix4.identity().scaled(1.05) : Matrix4.identity(),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _hover ? widget.color : Colors.transparent, width: 2),
            boxShadow: [
              BoxShadow(color: _hover ? widget.color.withOpacity(0.3) : Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: widget.color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(widget.icon, color: widget.color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListSelectionCard extends StatefulWidget {
  final String title;
  final Color color;
  final VoidCallback onTap;
  const _ListSelectionCard({required this.title, required this.color, required this.onTap});
  @override
  State<_ListSelectionCard> createState() => _ListSelectionCardState();
}

class _ListSelectionCardState extends State<_ListSelectionCard> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _hover ? widget.color : Colors.grey.shade200, width: _hover ? 2 : 1),
            boxShadow: [if (_hover) BoxShadow(color: widget.color.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _hover ? widget.color : const Color(0xFF1E293B))),
              Icon(Icons.arrow_forward_rounded, color: _hover ? widget.color : Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyCard extends StatefulWidget {
  final String title;
  final Color color;
  final String subtitle;
  final VoidCallback onTap;
  const _DifficultyCard(this.title, this.color, this.subtitle, this.onTap);
  @override
  State<_DifficultyCard> createState() => _DifficultyCardState();
}

class _DifficultyCardState extends State<_DifficultyCard> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 200, height: 160,
          decoration: BoxDecoration(
            color: _hover ? widget.color : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: _hover ? widget.color.withOpacity(0.4) : Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _hover ? Colors.white : widget.color)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: _hover ? Colors.white24 : widget.color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(widget.subtitle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _hover ? Colors.white : widget.color)),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// Fonction utilitaire pour les couleurs (Copie de ActivityChart pour cohérence)
Color _getColorForTheme(String theme) {
  final Map<String, Color> themeColors = {
    'Animaux': const Color(0xFFF97316), 'Art': const Color(0xFFEC4899), 'Divers': const Color(0xFF64748B),
    'Divertissement': const Color(0xFF8B5CF6), 'Géographie': const Color(0xFF0EA5E9), 'Histoire': const Color(0xFFEAB308),
    'Nature': const Color(0xFF22C55E), 'Science': const Color(0xFF06B6D4), 'Société': const Color(0xFFF43F5E),
    'Technologie': const Color(0xFF3B82F6), 'Test': const Color(0xFF9CA3AF),
  };
  return themeColors[theme] ?? Colors.blueAccent;
}