import 'package:flutter/material.dart';
import 'package:legumes_app/core/utils/navigator.dart';
import 'package:legumes_app/presentation/providers/auth_controller.dart';
import 'package:provider/provider.dart';

class VendorHomePage extends StatelessWidget {
  const VendorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, child) {
        if (auth.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!auth.isAuthenticated || auth.currentRole != 'vendor') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppNavigator.pushReplacement('/login');
          });
          return const SizedBox();
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tableau de bord Vendors'),
            actions: [
              IconButton(
                icon: const Icon(Icons.person),
                tooltip: 'Profil / Déconnexion',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Déconnexion'),
                      content:
                          const Text('Voulez-vous vraiment vous déconnecter ?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annuler'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Déconnecter'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await auth.signOut();
                  }
                },
              ),
            ],
          ),
          body: const Center(
            child: Text(
              'Bienvenue, Vendor !',
              style: TextStyle(fontSize: 18),
            ),
          ),
        );
      },
    );
  }
}
