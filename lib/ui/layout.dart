import 'package:flutter/material.dart';
import '../data/data_manager.dart';
import 'quiz_page/quiz_page.dart';
import 'profil_page/profil_page.dart';
import 'stats_page/stats_page.dart';
import 'contact_page/contact_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _isSidebarCollapsed = false;
  int _selectedIndex = 0;
  ThemeInfo? _forcedThemeSelection;

  void _onMenuSelect(int index) {
    setState(() {
      _selectedIndex = index;
      _forcedThemeSelection = null;
    });
  }

  void _onThemeDirectSelect(ThemeInfo theme) {
    setState(() {
      _selectedIndex = 0;
      _forcedThemeSelection = theme;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calcul de la largeur actuelle de la sidebar pour l'animation
    final double sidebarWidth = _isSidebarCollapsed ? 80 : 280;

    return Scaffold(
      // ON REMPLACE 'ROW' PAR 'STACK' POUR GÉRER LA PROFONDEUR (Z-INDEX)
      body: Stack(
        children: [
          // --- 1. LE CONTENU (ARRIÈRE-PLAN) ---
          // On utilise AnimatedContainer pour ajuster la marge quand la sidebar bouge
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            // C'est ici la magie : on laisse de la place à gauche pour la sidebar
            padding: EdgeInsets.only(left: sidebarWidth), 
            color: const Color(0xFFF8F9FE), // Fond global de l'app
            child: _buildPageContent(),
          ),

          // --- 2. LA SIDEBAR (PREMIER PLAN) ---
          // Dessinée APRÈS le contenu, donc son ombre passe PAR DESSUS le contenu
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: sidebarWidth,
            height: double.infinity, // Prend toute la hauteur
            decoration: BoxDecoration(
              color: Colors.white,
              // L'ombre se projette maintenant proprement sur le contenu à droite
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(4, 0))
              ],
            ),
            child: Column(
              children: [
                _buildSidebarHeader(),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    children: [
                      _SidebarItem(
                        icon: Icons.grid_view_rounded,
                        label: "Catégories",
                        isCollapsed: _isSidebarCollapsed,
                        isActive: _selectedIndex == 0,
                        onTap: () => _onMenuSelect(0),
                      ),
                      if (!_isSidebarCollapsed)
                        ...DataManager.instance.themes.map((t) => _ThemeSubItem(
                          label: t.name,
                          onTap: () => _onThemeDirectSelect(t),
                        )),
                      _SidebarItem(
                        icon: Icons.bar_chart_rounded,
                        label: "Statistiques",
                        isCollapsed: _isSidebarCollapsed,
                        isActive: _selectedIndex == 1,
                        onTap: () => _onMenuSelect(1),
                      ),
                      _SidebarItem(
                        icon: Icons.person_rounded,
                        label: "Profil",
                        isCollapsed: _isSidebarCollapsed,
                        isActive: _selectedIndex == 2,
                        onTap: () => _onMenuSelect(2),
                      ),
                      _SidebarItem(
                        icon: Icons.mail_outline_rounded,
                        label: "Contact",
                        isCollapsed: _isSidebarCollapsed,
                        isActive: _selectedIndex == 3,
                        onTap: () => _onMenuSelect(3),
                      ),
                    ],
                  ),
                ),
                _buildSidebarFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return SizedBox(
      height: 80,
      child: Row(
        mainAxisAlignment: _isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
        children: [
          if (!_isSidebarCollapsed)
            const Padding(
              padding: EdgeInsets.only(left: 24),
              child: Text("CultureK", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 24, color: Colors.blueAccent)),
            ),
          IconButton(
            icon: Icon(_isSidebarCollapsed ? Icons.keyboard_double_arrow_right : Icons.keyboard_double_arrow_left, color: Colors.grey),
            onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
          ),
          if (!_isSidebarCollapsed) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildSidebarFooter() {
    // Petit fix : Gestion des débordements si le nom est long en mode réduit
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: _isSidebarCollapsed 
        ? const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white))
        : Row(
            children: [
              const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white)),
              const SizedBox(width: 12),
              // Expanded pour éviter l'overflow horizontal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Invité", style: TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    Text("Niveau 1", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              )
            ],
          ),
    );
  }

  Widget _buildPageContent() {
    if (_selectedIndex == 0) return QuizPage(initialTheme: _forcedThemeSelection);
    if (_selectedIndex == 1) {
      return StatsPage(
        onGoToLogin: () => _onMenuSelect(2), // 2 = Index de la page Profil
      );
    }
    if (_selectedIndex == 2) return const ProfilPage();
    if (_selectedIndex == 3) return const ContactPage();
    return const Center(child: Text("Page non trouvée"));
  }
}

// --- WIDGETS INTERNES ---

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isCollapsed;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem({required this.icon, required this.label, required this.isCollapsed, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? Colors.blueAccent.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              if (!isCollapsed) const SizedBox(width: 16),
              Icon(icon, color: isActive ? Colors.blueAccent : Colors.grey[600], size: 22),
              if (!isCollapsed) ...[
                const SizedBox(width: 16),
                Expanded(child: Text(label, style: TextStyle(color: isActive ? Colors.blueAccent : Colors.grey[700], fontWeight: isActive ? FontWeight.w600 : FontWeight.normal), overflow: TextOverflow.ellipsis)),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeSubItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ThemeSubItem({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 54, top: 8, bottom: 8),
        child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ),
    );
  }
}