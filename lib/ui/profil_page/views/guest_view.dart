import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/data_manager.dart';

class GuestView extends StatefulWidget {
  const GuestView({super.key});

  @override
  State<GuestView> createState() => _GuestViewState();
}

class _GuestViewState extends State<GuestView> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _userOrEmailCtrl = TextEditingController(); // Pour login
  final _emailCtrl = TextEditingController();       // Pour signup
  final _usernameCtrl = TextEditingController();    // Pour signup
  final _passCtrl = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _userOrEmailCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // --- LOGIQUE METIER (Conservée) ---
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      if (_isLogin) {
        await context.read<DataManager>().signIn(_userOrEmailCtrl.text, _passCtrl.text);
      } else {
        await context.read<DataManager>().signUp(_usernameCtrl.text, _emailCtrl.text, _passCtrl.text);
      }
    } catch (e) {
      String msg = e.toString().replaceAll("firebase_auth/", "").replaceAll("[", "").replaceAll("]", "");
      if (msg.contains("user-not-found")) msg = "Compte introuvable.";
      if (msg.contains("wrong-password")) msg = "Mot de passe incorrect.";
      if (msg.contains("email-already-in-use")) msg = "Cet email est déjà utilisé.";
      setState(() => _errorMessage = msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final resetCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Récupération", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Entre ton email ou pseudo pour recevoir un lien."),
            const SizedBox(height: 16),
            _ModernInput(label: "Email ou Pseudo", icon: Icons.mail_outline, controller: resetCtrl)
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
            onPressed: () async {
              try {
                Navigator.pop(ctx);
                await context.read<DataManager>().resetPassword(resetCtrl.text);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Email envoyé !"), backgroundColor: Colors.green));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur: Compte introuvable ou sans email."), backgroundColor: Colors.red));
              }
            },
            child: const Text("Envoyer"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      height: 600, // Hauteur fixe pour le look carte
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 40, offset: const Offset(0, 20)),
        ],
      ),
      child: Row(
        children: [
          // --- PARTIE GAUCHE (Design / Marketing) ---
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(48),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B), // Slate 800
                borderRadius: BorderRadius.only(topLeft: Radius.circular(32), bottomLeft: Radius.circular(32)),
                image: DecorationImage(
                  image: NetworkImage("https://img.freepik.com/free-vector/gradient-technological-background_23-2148884155.jpg"), // Texture subtile optionnelle
                  fit: BoxFit.cover,
                  opacity: 0.2,
                )
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 32),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "Rejoignez\nl'aventure.",
                    style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1, letterSpacing: -1),
                  ),
                  const SizedBox(height: 24),
                  _buildBenefit("Sauvegarde ta progression"),
                  _buildBenefit("Une expérience personnalisée"),
                  _buildBenefit("Gratuit, sans publicité"),
                ],
              ),
            ),
          ),

          // --- PARTIE DROITE (Formulaire) ---
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(60),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(_isLogin ? "Bon retour !" : "Créer un compte", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    Text("Rentre tes informations pour continuer.", style: TextStyle(color: Colors.blueGrey[400], fontSize: 16)),
                    const SizedBox(height: 40),

                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [const Icon(Icons.error_outline, color: Colors.red, size: 20), const SizedBox(width: 12), Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade800)))])
                      ),

                    if (_isLogin) ...[
                      _ModernInput(label: "Email ou Pseudo", icon: Icons.person_outline, controller: _userOrEmailCtrl),
                      Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _showForgotPasswordDialog, child: const Text("Mot de passe oublié ?", style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w600)))),
                    ] else ...[
                      _ModernInput(label: "Pseudo", icon: Icons.person, controller: _usernameCtrl),
                      const SizedBox(height: 16),
                      _ModernInput(label: "Email (facultatif)", icon: Icons.alternate_email, controller: _emailCtrl, isOptional: true),
                    ],

                    if (!_isLogin) const SizedBox(height: 16),
                    _ModernInput(label: "Mot de passe", icon: Icons.lock_outline, controller: _passCtrl, isPass: true),

                    const SizedBox(height: 32),
                    
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1), // Indigo
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                            : Text(_isLogin ? "Se connecter" : "S'inscrire", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),

                    const SizedBox(height: 24),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(_isLogin ? "Nouveau ici ?" : "Déjà un compte ?", style: TextStyle(color: Colors.blueGrey[400])),
                      TextButton(
                        onPressed: () => setState(() { _isLogin = !_isLogin; _errorMessage = null; }),
                        child: Text(_isLogin ? "Créer un compte" : "Se connecter", style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold))
                      )
                    ])
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Colors.white, size: 12),
          ),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500))
        ],
      ),
    );
  }
}

// Widget Input Réutilisable et Moderne
class _ModernInput extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool isPass;
  final bool isOptional;

  const _ModernInput({required this.label, required this.icon, required this.controller, this.isPass = false, this.isOptional = false});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPass,
      validator: (v) => (!isOptional && (v == null || v.isEmpty)) ? "Requis" : null,
      style: const TextStyle(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.blueGrey[400]),
        prefixIcon: Icon(icon, color: Colors.blueGrey[300], size: 22),
        filled: true,
        fillColor: const Color(0xFFF8FAFC), // Gris très très clair
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      ),
    );
  }
}