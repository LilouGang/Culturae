// lib/auth/auth_page.dart
import '../utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  bool isLogin = true;
  bool _isLoading = false;

  final _identifierController = TextEditingController(); // Nouveau contrôleur unifié
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailControllerForSignup = TextEditingController(); // Spécifique pour l'inscription

  final _auth = FirebaseAuth.instance;

  Future<void> _submitAuthForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      if (isLogin) {
        String identifier = _identifierController.text.trim();
        String email;

        if (identifier.contains('@')) {
          email = identifier;
        } else {
          final userQuery = await FirebaseFirestore.instance
              .collection('Users')
              .where('username', isEqualTo: identifier)
              .limit(1)
              .get();

          if (userQuery.docs.isEmpty) {
            throw FirebaseAuthException(code: 'user-not-found');
          }
          
          final userData = userQuery.docs.first.data();
          if (userData.containsKey('email')) {
             email = userData['email'];
          } else {
             throw Exception("Données utilisateur corrompues.");
          }
        }

        // On se connecte avec l'email trouvé
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: _passwordController.text.trim(),
        );

      } else {
        final usernameSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .where('username', isEqualTo: _usernameController.text.trim())
            .get();

        if (usernameSnapshot.docs.isNotEmpty) {
          _showError("Ce pseudo est déjà utilisé. Veuillez en choisir un autre.");
          setState(() => _isLoading = false);
          return;
        }

        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailControllerForSignup.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (userCredential.user != null) {
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(userCredential.user!.uid)
              .set({
                'username': _usernameController.text.trim(),
                'email': _emailControllerForSignup.text.trim(),
                'createdAt': Timestamp.now(),
                'scores': {},
              });
        }
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (error) {
      _showError("Une erreur inattendue est survenue.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- TRADUCTEUR D'ERREURS ---
  void _handleAuthError(FirebaseAuthException e) {
    String message = "Une erreur inconnue est survenue. Veuillez réessayer.";
    switch (e.code) {
      case 'user-not-found': message = "Aucun utilisateur trouvé avec cet identifiant."; break;
      case 'wrong-password': message = "Le mot de passe est incorrect."; break;
      case 'email-already-in-use': message = "Cette adresse e-mail est déjà utilisée."; break;
      case 'invalid-email': message = "L'adresse e-mail n'est pas valide."; break;
      case 'weak-password': message = "Le mot de passe doit contenir au moins 6 caractères."; break;
      case 'too-many-requests': message = "Trop de tentatives. Veuillez réessayer plus tard."; break;
    }
    _showError(message);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _emailControllerForSignup.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rh = ResponsiveHelper(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          // Padding proportionnel
          padding: EdgeInsets.all(rh.w(4)),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isLogin ? 'Connexion' : 'Inscription',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: rh.w(7), // Police proportionnelle
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: rh.h(3.5)), // Espace proportionnel
                
                if (isLogin)
                  TextFormField(
                    controller: _identifierController,
                    key: const ValueKey('identifier'),
                    decoration: InputDecoration(
                      labelText: 'Email ou Pseudo',
                      labelStyle: TextStyle(fontSize: rh.w(3.5)),
                    ),
                    style: TextStyle(fontSize: rh.w(4)), // Police proportionnelle
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer votre email ou votre pseudo.';
                      }
                      return null;
                    },
                  ),
                
                if (!isLogin) ...[
                  TextFormField(
                    controller: _usernameController,
                    key: const ValueKey('username'),
                    decoration: InputDecoration(
                      labelText: 'Pseudo',
                      labelStyle: TextStyle(fontSize: rh.w(3.5)),
                    ),
                    style: TextStyle(fontSize: rh.w(4)),
                    validator: (value) {
                      if (value == null || value.trim().length < 4) return 'Le pseudo doit contenir au moins 4 caractères.';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _emailControllerForSignup,
                    key: const ValueKey('email_signup'),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(fontSize: rh.w(3.5)),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(fontSize: rh.w(4)),
                    validator: (value) {
                      if (value == null || !value.contains('@')) return 'Veuillez entrer une adresse email valide.';
                      return null;
                    },
                  ),
                ],

                TextFormField(
                  controller: _passwordController,
                  key: const ValueKey('password'),
                  decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      labelStyle: TextStyle(fontSize: rh.w(3.5)),
                    ),
                  obscureText: true,
                  style: TextStyle(fontSize: rh.w(4)),
                  validator: (value) {
                    if (value == null || value.length < 7) return 'Le mot de passe doit contenir au moins 7 caractères.';
                    return null;
                  },
                ),
                SizedBox(height: rh.h(2.5)),
                
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _submitAuthForm,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: rh.h(1.5)), // Padding proportionnel
                    ),
                    child: Text(
                      isLogin ? 'Se connecter' : 'Créer mon compte',
                      style: TextStyle(fontSize: rh.w(3.5)), // Police proportionnelle
                    ),
                  ),
                
                TextButton(
                  onPressed: () => setState(() => isLogin = !isLogin),
                  child: Text(
                    isLogin ? 'Pas encore de compte ? S\'inscrire' : 'J\'ai déjà un compte',
                    style: TextStyle(fontSize: rh.w(3.5)), // Police proportionnelle
                  ),
                ),

                SizedBox(height: rh.h(2.5)),
                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: rh.w(2)), // Padding proportionnel
                    child: Text(
                      "OU",
                      style: TextStyle(fontSize: rh.w(3)), // Police proportionnelle
                    ),
                  ),
                  const Expanded(child: Divider()),
                ]),
                SizedBox(height: rh.h(2.5)),
                
                Center(
                  child: TextButton(
                    onPressed: () async {
                      setState(() => _isLoading = true);
                      try { await _auth.signInAnonymously(); } finally { if(mounted) setState(() => _isLoading = false); }
                    },
                    child: Text(
                      'Continuer sans compte',
                      style: TextStyle(fontSize: rh.w(3.5)), // Police proportionnelle
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}