import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme_provider.dart';
import '../widgets/page_layout.dart';
import '../auth/auth_page.dart';
import '../utils/responsive_helper.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

// --- 1. ON AJOUTE LE MIXIN ICI ---
class _AccountPageState extends State<AccountPage> with AutomaticKeepAliveClientMixin {
  // --- 2. ON AJOUTE LA PROPRIÉTÉ OBLIGATOIRE ---
  @override
  bool get wantKeepAlive => true;

  final User? currentUser = FirebaseAuth.instance.currentUser;
  late Future<DocumentSnapshot<Map<String, dynamic>>> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    if (currentUser != null && !currentUser!.isAnonymous) {
      _userDataFuture = FirebaseFirestore.instance.collection('Users').doc(currentUser!.uid).get();
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- 3. ON AJOUTE super.build(context) ---
    super.build(context); // Obligatoire avec le mixin

    final themeProvider = Provider.of<ThemeProvider>(context);
    final rh = ResponsiveHelper(context);

    return PageLayout(
      title: 'Mon Compte',
      titleTextStyle: TextStyle(
        color: Theme.of(context).textTheme.titleLarge?.color,
        fontSize: rh.w(6),
        fontWeight: FontWeight.w500,
      ),
      child: (currentUser == null || currentUser!.isAnonymous)
          ? _buildGuestView(context)
          : _buildLoggedInView(themeProvider),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    // On instancie notre helper
    final rh = ResponsiveHelper(context);

    return Center(
      child: Padding(
        // Padding proportionnel
        padding: EdgeInsets.symmetric(horizontal: rh.w(8)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.person_add_alt_1_outlined,
              size: rh.w(20), // Taille d'icône proportionnelle
              color: Colors.grey,
            ),
            SizedBox(height: rh.h(2.5)), // Espace proportionnel
            Text(
              'Créez un compte pour sauvegarder votre progression !',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: rh.w(5), // Police proportionnelle
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: rh.h(1.2)),
            Text(
              'En créant un compte, vous pourrez retrouver vos scores et participer au classement.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: rh.w(4), // Police proportionnelle
                color: Colors.grey,
              ),
            ),
            SizedBox(height: rh.h(3.5)),
            ElevatedButton(
              onPressed: () {
                FirebaseAuth.instance.signOut().then((_) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthPage()),
                    (route) => false,
                  );
                });
              },
              style: ElevatedButton.styleFrom(
                // Padding proportionnel
                padding: EdgeInsets.symmetric(vertical: rh.h(1.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rh.w(3))), // Bords proportionnels
              ),
              child: Text(
                'Créer un compte / Se connecter',
                style: TextStyle(fontSize: rh.w(4)), // Police proportionnelle
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _requestAccountDeletion() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'killian.lacaque25@gmail.com', // Votre adresse e-mail
      query: 'subject=Demande de Suppression de Compte CultureK&body=Bonjour,%0A%0AVeuillez supprimer mon compte et toutes les données associées.%0A%0AMon pseudo : [Votre Pseudo Ici]%0AMon e-mail : ${currentUser?.email ?? '[Votre Email Ici]'}'
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      // Gérer le cas où l'utilisateur n'a pas d'app e-mail configurée
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'ouvrir l'application e-mail.")),
      );
    }
  }

  Widget _buildLoggedInView(ThemeProvider themeProvider) {
    final rh = ResponsiveHelper(context);

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _userDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("Impossible de charger le profil."));
        }
        
        final userData = snapshot.data!.data() ?? {};
        final username = userData['username'] ?? 'Pseudo non défini';
        final email = userData['email'] ?? currentUser!.email ?? 'Email non disponible';
        final createdAt = (userData['createdAt'] as Timestamp?)?.toDate();
        final memberSince = createdAt != null ? DateFormat('MMMM yyyy', 'fr_FR').format(createdAt) : 'Date inconnue';
        final initials = username.isNotEmpty ? username.substring(0, (username.length >= 2 ? 2 : 1)).toUpperCase() : "?";

        // --- ON UTILISE UNE SEULE LISTVIEW POUR TOUS LES ÉLÉMENTS ---
        return ListView(
          padding: EdgeInsets.symmetric(horizontal: rh.w(4)),
          children: [
            SizedBox(height: rh.h(5)),

            // --- SECTION 1 : PROFIL (CENTRÉ) ---
            // On utilise une Column interne pour centrer uniquement cette partie
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildProfileHeader(initials, username, email, memberSince),
              ],
            ),
            
            SizedBox(height: rh.h(4)),
            
            // --- SECTION 2 : PERSONNALISATION (ALIGNÉE À GAUCHE) ---
            _buildSectionTitle('Personnalisation'),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rh.w(3))),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.edit_outlined, size: rh.w(5.5)),
                    title: Text('Changer de pseudo', style: TextStyle(fontSize: rh.w(3.7))),
                    onTap: () => _showChangeUsernameDialog(context, username),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: rh.w(4), vertical: rh.h(0.5)),
                    child: Row(
                      children: [
                        Icon(Icons.brightness_6_outlined, size: rh.w(5.5), color: Theme.of(context).textTheme.bodySmall?.color),
                        SizedBox(width: rh.w(4)),
                        Expanded(
                          child: Text('Thème sombre', style: TextStyle(fontSize: rh.w(3.7))),
                        ),
                        Transform.scale(
                          scale: 0.8, 
                          child: Switch(
                            value: themeProvider.themeMode == ThemeMode.dark,
                            onChanged: (bool value) {
                              themeProvider.toggleTheme(value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: rh.h(3)),

            // --- SECTION 3 : COMPTE (ALIGNÉE À GAUCHE) ---
            _buildSectionTitle('Compte'),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rh.w(3))),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.lock_outline, size: rh.w(5.5)),
                    title: Text('Changer le mot de passe', style: TextStyle(fontSize: rh.w(3.7))),
                    onTap: () => _sendPasswordResetEmail(context),
                  ),
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.red, size: rh.w(5.5)),
                    title: Text('Déconnexion', style: TextStyle(color: Colors.red, fontSize: rh.w(3.7))),
                    onTap: () => FirebaseAuth.instance.signOut(),
                  ),
                ],
              ),
            ),
            SizedBox(height: rh.h(3)),
            _buildSectionTitle('Zone de danger'),
            Card(
              color: Colors.red.shade50, // Fond légèrement rouge
              child: ListTile(
                leading: Icon(Icons.delete_forever_outlined, color: Colors.red.shade800),
                title: Text('Supprimer mon compte', style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold)),
                onTap: () {
                  // On affiche une dialogue de confirmation avant d'ouvrir l'e-mail
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text("Supprimer votre compte ?"),
                      content: const Text("Cette action est irréversible. Vous perdrez toute votre progression. Un e-mail sera préparé pour confirmer votre demande."),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Annuler")),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _requestAccountDeletion();
                          },
                          child: const Text("Continuer", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileHeader(String initials, String username, String email, String memberSince) {
    final rh = ResponsiveHelper(context);

    return Column(
      children: [
        CircleAvatar(
          radius: rh.w(10), // Rayon proportionnel
          child: Text(
            initials,
            style: TextStyle(fontSize: rh.w(7)), // Police proportionnelle
          ),
        ),
        SizedBox(height: rh.h(1.5)), // Espace proportionnel
        Text(
          username,
          style: TextStyle(
            fontSize: rh.w(5.5), // Police proportionnelle
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: rh.h(0.5)),
        Text(
          email,
          style: TextStyle(
            fontSize: rh.w(4), // Police proportionnelle
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: rh.h(0.5)),
        Text(
          'Membre depuis $memberSince',
          style: TextStyle(
            fontSize: rh.w(3.5), // Police proportionnelle
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    final rh = ResponsiveHelper(context);

    return Padding(
      // Padding proportionnel
      padding: EdgeInsets.only(left: rh.w(4), bottom: rh.h(1)),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.bold,
          fontSize: rh.w(2.8), // Police proportionnelle
        ),
      ),
    );
  }

  void _showChangeUsernameDialog(BuildContext context, String currentUsername) {
    final controller = TextEditingController(text: currentUsername);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Changer de pseudo'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Nouveau pseudo"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newUsername = controller.text.trim();
                if (newUsername.isNotEmpty && newUsername != currentUsername) {
                  // Mettre à jour Firestore
                  await FirebaseFirestore.instance.collection('Users').doc(currentUser!.uid).update({'username': newUsername});
                  // Rafraîchir la page
                  setState(() {
                    _loadUserData();
                  });
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('Sauvegarder'),
            ),
          ],
        );
      },
    );
  }
  
  void _sendPasswordResetEmail(BuildContext context) {
    if (currentUser?.email != null) {
      FirebaseAuth.instance.sendPasswordResetEmail(email: currentUser!.email!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Un e-mail de réinitialisation a été envoyé.')),
      );
    }
  }
}