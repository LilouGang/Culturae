import 'package:flutter/material.dart';
import '../models/theme_info.dart';
import '../utils/responsive_helper.dart';

class ThemeCard extends StatelessWidget {
  final ThemeInfo themeInfo;
  final VoidCallback? onTap;
  final Widget? trailingWidget;

  const ThemeCard({
    super.key,
    required this.themeInfo,
    this.onTap,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    final rh = ResponsiveHelper(context);
    final bool isClickable = onTap != null;

    return Card(
      elevation: isClickable ? 5.0 : 2.0,
      margin: EdgeInsets.only(bottom: rh.h(1.8)),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rh.w(4))),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: rh.h(14),
          decoration: BoxDecoration(
            gradient: themeInfo.imagePath == null ? themeInfo.gradient : null,
            color: themeInfo.imagePath == null && themeInfo.gradient == null
                ? themeInfo.color ?? Colors.white
                : null,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (themeInfo.imagePath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(rh.w(4)),
                  child: Image.asset(
                    themeInfo.imagePath!,
                    fit: BoxFit.cover,
                    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                      if (wasSynchronouslyLoaded) {
                        return child;
                      }
                      return AnimatedOpacity(
                        opacity: frame == null ? 0 : 1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        child: child,
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: Colors.white);
                    },
                  ),
                ),
              
              if (themeInfo.imagePath != null)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(rh.w(4)),
                    color: Colors.black.withOpacity(0.4),
                  ),
                ),

              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: rh.w(4)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // La Row prend la taille de son contenu
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (themeInfo.icon != null)
                        Icon(
                          themeInfo.icon,
                          size: rh.w(7),
                          color: themeInfo.textColor,
                          shadows: [Shadow(blurRadius: 2, color: Colors.black.withOpacity(0.5))],
                        ),
                      if (themeInfo.icon != null)
                        SizedBox(width: rh.w(3)),
                      
                      Text(
                        themeInfo.name,
                        style: TextStyle(
                          fontSize: rh.w(5.5),
                          fontWeight: FontWeight.bold,
                          color: themeInfo.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // --- COUCHE 4 : LE WIDGET SUPPLÉMENTAIRE (Positioned) ---
              if (trailingWidget != null)
                Positioned(
                  // On le positionne en haut à droite avec une marge
                  top: rh.h(1.5),
                  right: rh.w(3),
                  child: trailingWidget!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}