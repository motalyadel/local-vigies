// presentation/screens/home/login_page.dart

import 'package:flutter/material.dart';
import 'package:legumes_app/core/utils/navigator.dart';
import 'package:legumes_app/data/services/vendor_service.dart';
import 'package:legumes_app/l10n/generated/app_localizations.dart';
import 'package:legumes_app/presentation/providers/auth_controller.dart';
import 'package:legumes_app/presentation/providers/local_provider.dart';
import 'package:provider/provider.dart';

class AppColors {
  static const Color primary = Color(0xFF4CAF50);
  static const Color secondary = Color(0xFFFF9800);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF2E2E2E);
  static const Color error = Color(0xFFE53935);
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final VendorService _authService = VendorService();
  bool _isLoading = false;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null; // Réinitialise l'erreur précédente
    });

    try {
      print('Tentative de connexion avec email: ${_email.text}');

      final success = await _authService.signIn(
        email: _email.text.trim(),
        password: _password.text,
      );

      if (success) {
        print('Connexion réussie !');

        // Seulement en cas de succès → on redirige via AuthController
        final authController =
            Provider.of<AuthController>(context, listen: false);
        await authController.redirect();
      } else {
        // Échec de connexion → on reste sur la page login et on affiche un message
        setState(() {
          _error = "invalidCredentials"; // Message localisé
        });
      }
    } catch (e, s) {
      print('Erreur lors de la connexion : $e');
      print('Stack trace: $s');

      // Erreur technique → message générique mais on reste sur la page
      setState(() {
        _error = "Une erreur est survenue. Réessayez.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_grocery_store,
                          size: 80, color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text(
                        l10n.connexionAuMarche,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall!.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),

                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: l10n.email,
                          prefixIcon: const Icon(Icons.email),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) => val != null && val.contains('@')
                            ? null
                            : l10n.invalidEmail,
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: l10n.password,
                          prefixIcon: const Icon(Icons.lock),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) => val != null && val.length >= 6
                            ? null
                            : l10n.passwordTooShort,
                      ),

                      // Affichage de l'erreur (email/mot de passe incorrect ou erreur technique)
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.error.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppColors.error, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primary))
                            : ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(l10n.login),
                              ),
                      ),

                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          AppNavigator.pushReplacement('/signup');
                        },
                        child: Text(
                          l10n.noAccount,
                          style: const TextStyle(color: AppColors.secondary),
                        ),
                      ),

                      IconButton(
                        onPressed: () {
                          final current = localeProvider.locale.languageCode;
                          localeProvider.changeLocale(current == 'fr'
                              ? const Locale('ar')
                              : const Locale('fr'));
                        },
                        icon: const Icon(Icons.language,
                            color: AppColors.secondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
