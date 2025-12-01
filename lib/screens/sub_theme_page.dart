import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/data_manager.dart';
import '../models/sub_theme_info.dart';
import '../utils/responsive_helper.dart';
import '../widgets/theme_card.dart';
import 'difficulty_selection_page.dart';

class SubThemePage extends StatefulWidget {
  final String themeName;
  const SubThemePage({super.key, required this.themeName});

  @override
  State<SubThemePage> createState() => _SubThemePageState();
}

class _SubThemePageState extends State<SubThemePage> {
  // 2. On ajoute le ScrollController
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rh = ResponsiveHelper(context);

    // 3. On calcule le flou dynamiquement
    final double blurIntensity = (_scrollOffset / 50.0).clamp(0.0, 10.0);
    final double backgroundOpacity = (_scrollOffset / 100.0).clamp(0.0, 0.3);
    
    return Consumer<DataManager>(
      builder: (context, dataManager, child) {
        final subThemesInfo = dataManager.subThemes
            .where((st) => st.parentTheme == widget.themeName)
            .toList();

        return Scaffold(
          body: CustomScrollView(
            // 4. On attache le controller
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                title: Text(widget.themeName),
                centerTitle: true,
                
                // --- 5. ON S'ASSURE QUE L'APPBAR EST BIEN "PINNED" ---
                pinned: true,
                
                toolbarHeight: rh.h(7),
                titleTextStyle: TextStyle(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontSize: rh.w(6),
                  fontWeight: FontWeight.w500,
                ),
                
                // --- 6. ON APPLIQUE LES VALEURS DYNAMIQUES ---
                backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(backgroundOpacity),
                elevation: 0,
                scrolledUnderElevation: 2.0,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: blurIntensity, sigmaY: blurIntensity),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),
              
              subThemesInfo.isEmpty
                  ? const SliverFillRemaining(
                      child: Center(child: Text("Aucun sous-thème trouvé.")))
                  : _buildSubThemeList(context, subThemesInfo, rh),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubThemeList(BuildContext context, List<SubThemeInfo> subThemes, ResponsiveHelper rh) {
    return SliverPadding(
      padding: EdgeInsets.all(rh.w(4)),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final subThemeInfo = subThemes[index];
            return ThemeCard(
              themeInfo: subThemeInfo,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DifficultySelectionPage(
                      themeName: widget.themeName,
                      subThemeName: subThemeInfo.name,
                    ),
                  ),
                );
              },
            );
          },
          childCount: subThemes.length,
        ),
      ),
    );
  }
}