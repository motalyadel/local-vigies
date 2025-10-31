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
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _hasRedirected = false;
  String? _error;

  Future<void> redirect() async {
  if (_hasRedirected) return;
  setState(() => _hasRedirected = true);

  try {
    print('Début de la redirection dans SplashScreen');
    await Future.delayed(const Duration(seconds: 3)); // Splash delay

    final authController = Provider.of<AuthController>(context, listen: false);
    final success = await authController.redirect();

    if (!success) {
      print("Aucune session trouvée → Navigation vers /login");
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } else {
      print("Redirection vers home effectuée avec succès ✅");
    }
  } catch (e, s) {
    print('Erreur lors de la redirection : $e');
    print('Stack trace : $s');
    setState(() => _error = 'Erreur : $e');

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
}


  @override
  void initState() {
    super.initState();

    // Initialisation de l'animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();

    // Lancer la redirection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('Lancement de redirect() depuis initState');
      redirect();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
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
                const Icon(
                  Icons.local_grocery_store,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Marché Local',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                ],
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.surface),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}