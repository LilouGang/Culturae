import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  final ThemeInfo? _forcedThemeSelection = null; 

  void _onMenuSelect(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double sidebarWidth = _isSidebarCollapsed ? 80 : 260;

    return Scaffold(
      body: Stack(
        children: [
          // --- 1. LE CONTENU (ARRIÈRE-PLAN) ---
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.only(left: sidebarWidth), 
            color: const Color(0xFFF8FAFC),
            child: _buildPageContent(),
          ),

          // --- 2. LA SIDEBAR (PREMIER PLAN) ---
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: sidebarWidth,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.blueGrey.withOpacity(0.08), 
                  blurRadius: 20, 
                  offset: const Offset(4, 0)
                )
              ],
            ),
            child: Column(
              children: [
                _buildSidebarHeader(),
                
                Expanded(
                  child: Consumer<DataManager>(
                    builder: (context, dataManager, child) {
                      return ListView(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
                        children: [
                          _SidebarItem(
                            icon: Icons.grid_view_rounded,
                            label: "Catégories",
                            isCollapsed: _isSidebarCollapsed,
                            isActive: _selectedIndex == 0,
                            onTap: () => _onMenuSelect(0),
                          ),
                          const SizedBox(height: 8),
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
                      );
                    },
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
    return Container(
      height: 90,
      alignment: Alignment.center,
      // CORRECTION 1 : Padding symétrique appliqué au conteneur global
      padding: EdgeInsets.symmetric(horizontal: _isSidebarCollapsed ? 0 : 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        // spaceBetween va maintenant coller les éléments aux bords du padding défini ci-dessus
        mainAxisAlignment: _isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
        children: [
          if (!_isSidebarCollapsed)
            // Le padding local a été retiré ici
            const Row(
              children: [
                Icon(Icons.flash_on_rounded, color: Color(0xFF6366F1), size: 28),
                SizedBox(width: 8),
                Text("CultureK", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF1E293B), letterSpacing: -0.5)),
              ],
            ),
          IconButton(
            // Le SizedBox(width: 8) final a été retiré ici
            icon: Icon(_isSidebarCollapsed ? Icons.menu_open_rounded : Icons.chevron_left_rounded, color: Colors.blueGrey),
            onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
            padding: EdgeInsets.zero, // Pour un alignement précis
            constraints: const BoxConstraints(), // Pour un alignement précis
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return Consumer<DataManager>(
      builder: (context, dataManager, child) {
        final user = dataManager.currentUser;
        
        // MODIFICATION ICI : On utilise la taille de la liste des questions maîtrisées
        final int currentScore = user.answeredQuestions.length; 

        // Calcul du niveau (1 niveau tous les 50 points)
        final int level = (currentScore / 50).floor() + 1;
        // Progression vers le prochain niveau
        final int progressTowardsNext = currentScore % 50;
        final double progressPercent = progressTowardsNext / 50.0;

        return InkWell(
          onTap: () => _onMenuSelect(2),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
              color: _isSidebarCollapsed ? Colors.transparent : Colors.grey.shade50.withOpacity(0.5),
            ),
            child: Row(
              mainAxisAlignment: _isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF6366F1),
                  child: Text(
                    user.username.isNotEmpty ? user.username[0].toUpperCase() : "?",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                if (!_isSidebarCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
                        
                        const SizedBox(height: 4),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Niveau $level", style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade500, fontWeight: FontWeight.w600)),
                            Text("$progressTowardsNext/50", style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade300, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        
                        const SizedBox(height: 6),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: progressPercent,
                            minHeight: 4,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.settings_rounded, size: 18, color: Colors.grey),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: KeyedSubtree(
        key: ValueKey(_selectedIndex),
        child: Builder(builder: (ctx) {
          if (_selectedIndex == 0) return QuizPage(initialTheme: _forcedThemeSelection);
          if (_selectedIndex == 1) return StatsPage(onGoToLogin: () => _onMenuSelect(2));
          if (_selectedIndex == 2) return const ProfilPage();
          if (_selectedIndex == 3) return const ContactPage();
          return const Center(child: Text("Page non trouvée"));
        }),
      ),
    );
  }
}

// --- WIDGET SIDEBAR ITEM (Inchangé) ---

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isCollapsed;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem({required this.icon, required this.label, required this.isCollapsed, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF6366F1) : Colors.blueGrey.shade600;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: const Color(0xFF6366F1).withOpacity(0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF6366F1).withOpacity(0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 22),
                if (!isCollapsed) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label, 
                      style: TextStyle(
                        color: color, 
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, 
                        fontSize: 14
                      ), 
                      overflow: TextOverflow.ellipsis
                    ),
                  ),
                  if (isActive)
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle))
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}