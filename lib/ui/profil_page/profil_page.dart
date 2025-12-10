import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/data_manager.dart';
import 'views/guest_view.dart';
import 'views/user_view.dart';

class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Écoute les changements d'utilisateur en temps réel
    final user = context.watch<DataManager>().currentUser;
    final isGuest = user.id == "guest";

    return Scaffold(
      body: BackgroundPattern( // <--- ON ENTOURE ICI
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.05),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: isGuest
                  ? const GuestView(key: ValueKey('Guest'))
                  : const UserView(key: ValueKey('User')),
            ),
          ),
        ),
      ),
    );
  }
}

class BackgroundPattern extends StatelessWidget {
  final Widget child;
  const BackgroundPattern({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. La couleur de fond unie (Gris très clair/Bleuté)
        Container(color: const Color(0xFFF8FAFC)), 

        // 2. Le motif dessiné par-dessus
        Positioned.fill(
          child: CustomPaint(
            painter: StripePainter(), // Change ici par StripePainter() pour des rayures
          ),
        ),

        // 3. Le contenu de ta page par-dessus tout
        child,
      ],
    );
  }
}

class StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.blueGrey.withOpacity(0.03) // Très très léger
      ..strokeWidth = 2;

    const double step = 10; // Espace entre les lignes

    // On dessine des diagonales
    for (double i = -size.height; i < size.width; i += step) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}