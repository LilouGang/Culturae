import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _DotGridPainter(),
            ),
          ),

          LayoutBuilder(
            builder: (context, constraints) {
              final bool useScroll = constraints.maxHeight < 600 || constraints.maxWidth < 800;

              Widget content = Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StaggeredReveal(
                      delay: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                            ),
                            child: const Icon(Icons.hub_rounded, size: 40, color: Color(0xFF6366F1)),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "Restons connectés",
                            style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -1),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Un projet ? Une question ? Retrouvez-moi ici.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),

                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: SizedBox(
                        height: 320,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _StaggeredReveal(
                                delay: 1,
                                child: _BrandCard(
                                  title: "Instagram",
                                  handle: "@killian.lcq_",
                                  url: "https://www.instagram.com/killian.lcq_/",
                                  colors: const [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFF77737)],
                                  icon: Icons.camera_alt_outlined,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _StaggeredReveal(
                                delay: 2,
                                child: _BrandCard(
                                  title: "LinkedIn",
                                  handle: "Killian Lacaque",
                                  url: "https://www.linkedin.com/in/killian-lacaque/",
                                  colors: const [Color(0xFF0077B5), Color(0xFF005E93)],
                                  icon: Icons.business_center_outlined,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _StaggeredReveal(
                                delay: 3,
                                child: _BrandCard(
                                  title: "GitHub",
                                  handle: "@LilouGang",
                                  url: "https://github.com/LilouGang",
                                  colors: const [Color(0xFF24292E), Color(0xFF000000)],
                                  icon: Icons.code_rounded,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    _StaggeredReveal(
                      delay: 4,
                      child: Text(
                        "© 2025 Culturæ • Développé avec Flutter",
                        style: TextStyle(
                          color: Colors.blueGrey.shade300, 
                          fontSize: 11,
                          fontWeight: FontWeight.w400
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (useScroll) {
                return SingleChildScrollView(child: content);
              }
              return Center(child: content);
            },
          ),
        ],
      ),
    );
  }
}

class _BrandCard extends StatefulWidget {
  final String title;
  final String handle;
  final String url;
  final List<Color> colors;
  final IconData icon;

  const _BrandCard({
    required this.title, 
    required this.handle, 
    required this.url, 
    required this.colors, 
    required this.icon
  });

  @override
  State<_BrandCard> createState() => _BrandCardState();
}

class _BrandCardState extends State<_BrandCard> {
  bool _isHovered = false;

  Future<void> _launch() async {
    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final mainColor = widget.colors.first;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _launch,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          transform: _isHovered 
              ? (Matrix4.identity()..translate(0, -12, 0)..scale(1.02)) 
              : Matrix4.identity(),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.colors,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: mainColor.withOpacity(_isHovered ? 0.4 : 0.1),
                blurRadius: _isHovered ? 40 : 20,
                offset: Offset(0, _isHovered ? 20 : 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: -20,
                right: -20,
                child: Icon(widget.icon, size: 150, color: Colors.white.withOpacity(0.1)),
              ),

              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1)
                      ),
                      child: Icon(widget.icon, size: 32, color: Colors.white),
                    ),
                    
                    const Spacer(),
                    
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 22, 
                        fontWeight: FontWeight.w900, 
                        color: Colors.white,
                        letterSpacing: -0.5
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.handle,
                      style: TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.w500, 
                        color: Colors.white.withOpacity(0.8)
                      ),
                    ),
                    
                    const Spacer(),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                        ]
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Visiter",
                            style: TextStyle(
                              color: mainColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 16, color: mainColor)
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.blueGrey.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    const double step = 24;

    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StaggeredReveal extends StatefulWidget {
  final Widget child;
  final int delay;
  const _StaggeredReveal({required this.child, required this.delay});
  @override
  State<_StaggeredReveal> createState() => _StaggeredRevealState();
}

class _StaggeredRevealState extends State<_StaggeredReveal> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.delay * 100), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _fadeAnimation, child: SlideTransition(position: _slideAnimation, child: widget.child));
  }
}