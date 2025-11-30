// presentation/screens/splash/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:legumes_app/presentation/providers/auth_controller.dart';
import 'package:legumes_app/presentation/screens/home/login_page.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Animation fluide
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    // Lancer la vérification d'authentification après un léger délai
    Future.delayed(const Duration(milliseconds: 800), () {
      _checkAuthAndRedirect();
    });
  }

  Future<void> _checkAuthAndRedirect() async {
    if (!mounted) return;

    final authController = Provider.of<AuthController>(context, listen: false);

    try {
      print('SplashScreen : Vérification de la session en cours...');
      await authController.redirect(); // Cette fonction gère TOUT maintenant
    } catch (e, s) {
      print('Erreur critique dans SplashScreen : $e\n$s');
      // En cas d'erreur grave → on va quand même à la page publique (sécurisé)
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/consumer_home');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône du marché
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_grocery_store_outlined,
                    size: 90,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),

                // Titre
                const Text(
                  'Marché Local',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Les meilleurs produits près de chez vous',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 48),

                // Indicateur de chargement
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}