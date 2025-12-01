// lib/screens/theme_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/data_manager.dart';
import '../models/theme_info.dart';
import '../utils/responsive_helper.dart';
import '../widgets/theme_card.dart';
import 'sub_theme_page.dart';

// 1. On la transforme en StatefulWidget
class ThemePage extends StatefulWidget {
  const ThemePage({super.key});

  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  // --- 2. ON CRÉE UN SCROLLCONTROLLER ---
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    // On écoute les changements de la position de défilement
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
    super.build(context);
    final rh = ResponsiveHelper(context);
    
    // --- 3. ON CALCULE L'INTENSITÉ DU FLOU ---
    // On mappe la position de défilement (ex: 0 à 50 pixels)
    // à une intensité de flou (ex: 0.0 à 5.0)
    final double blurIntensity = (_scrollOffset / 50.0).clamp(0.0, 5.0);
    // On calcule l'opacité du fond de l'AppBar de la même manière
    final double backgroundOpacity = (_scrollOffset / 100.0).clamp(0.0, 0.3);

    return Consumer<DataManager>(
      builder: (context, dataManager, child) {
        final appThemes = dataManager.themes;

        return Scaffold(
          body: CustomScrollView(
            // --- 4. ON ATTACHE LE CONTROLLER À LA VUE ---
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                title: const Text('Culture Générale'),
                centerTitle: true,
                pinned: true,
                floating: false,
                toolbarHeight: rh.h(7),
                titleTextStyle: TextStyle(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontSize: rh.w(6),
                  fontWeight: FontWeight.w500,
                ),
                
                // --- 5. ON UTILISE NOS VALEURS DYNAMIQUES ---
                backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(backgroundOpacity),
                elevation: 0,
                scrolledUnderElevation: 2.0,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    // L'intensité du flou est maintenant une variable
                    filter: ImageFilter.blur(sigmaX: blurIntensity, sigmaY: blurIntensity),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),
              
              appThemes.isEmpty
                  ? const SliverFillRemaining(
                      child: Center(child: Text("Aucun thème trouvé.")))
                  : _buildThemeList(context, appThemes, rh),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeList(BuildContext context, List<ThemeInfo> themes, ResponsiveHelper rh) {
    return SliverPadding(
      padding: EdgeInsets.all(rh.w(4)),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final theme = themes[index];
            return ThemeCard(
              themeInfo: theme,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubThemePage(themeName: theme.name),
                  ),
                );
              },
            );
          },
          childCount: themes.length,
        ),
      ),
    );
  }
}