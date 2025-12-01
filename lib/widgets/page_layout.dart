import 'package:flutter/material.dart';
import 'dart:ui';
import '../utils/responsive_helper.dart';

class PageLayout extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final TextStyle? titleTextStyle;

  const PageLayout({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.titleTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    final rh = ResponsiveHelper(context); // On a besoin du helper ici aussi

    return Scaffold(
      // Cette propriété est essentielle pour l'AppBar transparente
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        centerTitle: true,
        titleTextStyle: titleTextStyle,
        // Hauteur proportionnelle
        toolbarHeight: rh.h(7),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.85),
        elevation: 0,
        scrolledUnderElevation: 2.0,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      // La SafeArea enveloppe le contenu
      body: SafeArea(
        top: true, // Applique le padding en haut
        bottom: false, // N'applique PAS le padding en bas
        child: child,
      ),
    );
  }
}