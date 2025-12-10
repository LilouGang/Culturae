import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/data_manager.dart';

class UserView extends StatefulWidget {
  const UserView({super.key});

  @override
  State<UserView> createState() => _UserViewState();
}

class _UserViewState extends State<UserView> {
  // Contrôleurs Infos
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  
  // Contrôleurs MDP
  final _fakePassCtrl = TextEditingController(text: "••••••••••••"); // Visuel uniquement
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  // États
  bool _isEditingInfo = false; // Pour modifier Username/Email
  bool _isChangingPassword = false; // Pour la section MDP
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    final user = context.read<DataManager>().currentUser;
    _usernameCtrl.text = user.username;
    _emailCtrl.text = user.hasFakeEmail ? "" : user.email;
    
    // Reset MDP
    _newPassCtrl.clear();
    _confirmPassCtrl.clear();
    
    if (mounted) {
      setState(() {
        _isEditingInfo = false;
        _isChangingPassword = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      final dataManager = context.read<DataManager>();

      // 1. Sauvegarde Infos (si modifiées)
      if (_isEditingInfo) {
        if (_usernameCtrl.text != dataManager.currentUser.username || _emailCtrl.text != dataManager.currentUser.email) {
          await dataManager.updateProfile(
            newUsername: _usernameCtrl.text,
            newEmail: _emailCtrl.text.isNotEmpty ? _emailCtrl.text : null
          );
        }
      }

      // 2. Sauvegarde MDP (si activé)
      if (_isChangingPassword) {
        if (_newPassCtrl.text.isEmpty) throw "Le mot de passe est vide.";
        if (_newPassCtrl.text.length < 6) throw "6 caractères minimum requis.";
        if (_newPassCtrl.text != _confirmPassCtrl.text) throw "Les mots de passe ne correspondent pas.";
        
        await dataManager.updatePassword(_newPassCtrl.text);
      }

      if (mounted) {
        _refreshData(); // Tout remettre à zéro
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Modifications enregistrées avec succès !"), backgroundColor: Color(0xFF10B981))
        );
      }
    } catch (e) {
      if (mounted) {
        String err = e.toString();
        if (err.contains("requires-recent-login")) err = "Par sécurité, déconnecte-toi et reconnecte-toi pour changer le mot de passe.";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<DataManager>().currentUser;
    final dateStr = user.createdAt != null 
        ? "${user.createdAt!.day.toString().padLeft(2,'0')}/${user.createdAt!.month.toString().padLeft(2,'0')}/${user.createdAt!.year}" 
        : "Inconnu";

    // On affiche le bouton Sauvegarder si au moins une modification est en cours
    final bool showSaveButton = _isEditingInfo || _isChangingPassword;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Column(
        children: [
          // --- HEADER CARD ---
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 40, offset: const Offset(0, 20)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: const Color(0xFFF3F4F6),
                    child: Text(
                      user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF6366F1))
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.username, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: Text(user.hasFakeEmail ? "Compte Invité" : user.email, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.calendar_month, size: 16, color: Colors.white.withOpacity(0.8)),
                        const SizedBox(width: 8),
                        Text("Membre depuis le $dateStr", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // --- INFORMATIONS CARD ---
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 30, offset: const Offset(0, 10))],
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Mes Informations", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                    // Bouton Modifier pour les infos (pas le MDP)
                    if (!_isChangingPassword) // On évite de tout modifier en même temps pour la clarté
                      IconButton(
                        onPressed: () {
                          if (_isEditingInfo) _refreshData(); // Annuler
                          else setState(() => _isEditingInfo = true);
                        },
                        icon: Icon(_isEditingInfo ? Icons.close : Icons.edit_rounded, color: _isEditingInfo ? Colors.red : Colors.blueGrey),
                        style: IconButton.styleFrom(backgroundColor: _isEditingInfo ? Colors.red.withOpacity(0.1) : Colors.blueGrey.withOpacity(0.05)),
                      )
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Champs Infos
                _ProfileInput(label: "Nom d'utilisateur", icon: Icons.person, controller: _usernameCtrl, enabled: _isEditingInfo),
                const SizedBox(height: 24),
                _ProfileInput(label: "Adresse Email", icon: Icons.email, controller: _emailCtrl, enabled: _isEditingInfo),
                
                const SizedBox(height: 24),
                const Divider(height: 40),

                // --- SECTION MOT DE PASSE (DESIGN SPÉCIFIQUE) ---
                
                // 1. Champ Principal (Mot de passe actuel masqué OU Nouveau mot de passe)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isChangingPassword ? "NOUVEAU MOT DE PASSE" : "MOT DE PASSE", 
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey[300], letterSpacing: 1.2)
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _isChangingPassword ? _newPassCtrl : _fakePassCtrl,
                            enabled: _isChangingPassword,
                            obscureText: true,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _isChangingPassword ? Colors.black87 : Colors.blueGrey[400]),
                            decoration: InputDecoration(
                              prefixIcon: Icon(_isChangingPassword ? Icons.lock_open_rounded : Icons.lock_outline, color: _isChangingPassword ? const Color(0xFF6366F1) : Colors.blueGrey[200]),
                              filled: true,
                              fillColor: _isChangingPassword ? Colors.white : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2)),
                              disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.transparent)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),
                        
                        // LE BOUTON DISPARAÎT SI ON EST EN TRAIN DE MODIFIER
                        if (!_isChangingPassword) ...[
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 48, // HAUTEUR AJUSTÉE POUR MATCHER PARFAITEMENT LE CHAMP
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _isChangingPassword = true;
                                  _newPassCtrl.clear();
                                  _confirmPassCtrl.clear();
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF6366F1),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                              ),
                              child: const Text("Modifier", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),

                // 2. Champ Confirmation (Apparaît en dessous avec animation)
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Column(
                    children: [
                      const SizedBox(height: 16),
                      // On réutilise le widget ProfileInput pour la confirmation car il n'a pas besoin de bouton à droite
                      _ProfileInput(
                        label: "CONFIRMER LE MOT DE PASSE", 
                        icon: Icons.check_circle_outline, 
                        controller: _confirmPassCtrl, 
                        enabled: true, 
                        isPass: true
                      ),
                    ],
                  ),
                  crossFadeState: _isChangingPassword ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),

                // --- BOUTONS D'ACTION (SAUVEGARDER) ---
                // Apparaît si on modifie les infos OU le mot de passe
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  child: !showSaveButton 
                  ? const SizedBox.shrink() 
                  : Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _refreshData,
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white, // Force la transparence
                              foregroundColor: Colors.white, // Couleur du splash/texte
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: const Text("Annuler", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 8),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1), 
                              foregroundColor: Colors.white, 
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                              shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
                            ),
                            child: _isLoading 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                : const Text("Enregistrer", style: TextStyle(fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // --- LOGOUT BUTTON ---
          SizedBox(
            width: double.infinity,
            height: 60,
            child: _LogoutButton(onPressed: () => context.read<DataManager>().signOut()),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// WIDGETS LOCAUX
// ---------------------------------------------------------------------------

class _ProfileInput extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool enabled;
  final bool isPass;

  const _ProfileInput({required this.label, required this.icon, required this.controller, required this.enabled, this.isPass = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey[300], letterSpacing: 1.2)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: isPass,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: enabled ? Colors.black87 : Colors.blueGrey[400]),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: enabled ? const Color(0xFF6366F1) : Colors.blueGrey[200]),
            filled: true,
            fillColor: enabled ? Colors.white : const Color(0xFFF1F5F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2)),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.transparent)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}

class _LogoutButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _LogoutButton({required this.onPressed});
  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            // Fond ROUGE plein si survolé, sinon Transparent
            color: _isHovered ? const Color(0xFFEF4444) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône et Texte BLANCS si survolé
              Icon(Icons.logout_rounded, color: _isHovered ? Colors.white : const Color(0xFFEF4444)),
              const SizedBox(width: 12),
              Text(
                "Se déconnecter", 
                style: TextStyle(
                  color: _isHovered ? Colors.white : const Color(0xFFEF4444), 
                  fontWeight: FontWeight.bold, 
                  fontSize: 16
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}