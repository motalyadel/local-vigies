import 'package:flutter/material.dart';
import 'package:legumes_app/core/utils/navigator.dart';
import 'package:legumes_app/data/models/auth_model.dart';
import 'package:legumes_app/data/services/base_services.dart';
import 'package:legumes_app/data/services/vendor_service.dart';
import 'package:legumes_app/presentation/providers/notification_controller.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends ChangeNotifier {
  static AuthController? _instance;
  AuthController._();
  factory AuthController() {
    _instance ??= AuthController._();
    return _instance!;
  }

  final clientSpb = Supabase.instance.client;
  BaseService? _service;
  AuthModel? _user;
  bool _isRedirecting = false;

  BaseService? get service => _service;
  AuthModel? get user => _user;
  Vendor? get currentVendor => _user is Vendor ? _user as Vendor : null;
  Admin? get currentAdmin => _user is Admin ? _user as Admin : null;
  String get currentRole => _user != null ? _user!.currentRole.id : '';
  bool get isAuthenticated => _user != null;
  bool loading = true;
  String? error;

  // Future<void> redirect() async {
  //   if (_isRedirecting) {
  //     print('Redirection déjà en cours, ignorée');
  //     return;
  //   }
  //   _isRedirecting = true;
  //   try {
  //     print('Vérification de l\'utilisateur Supabase');
  //     final response = await clientSpb.auth.getUser();
  //     print('Utilisateur Supabase : ${response.user != null ? "trouvé" : "non trouvé"}');
  //     if (response.user == null) {
  //       loading = false;
  //       notifyListeners();
  //       print('Aucun utilisateur, redirection vers /login');
  //       return AppNavigator.pushReplacement('/login');
  //     }
  //     _service = VendorService();
  //     print('Appel de getUserAndPushToHome');
  //     await getUserAndPushToHome();
  //   } catch (e, s) {
  //     loading = false;
  //     error = 'Vérification utilisateur échouée : $e';
  //     print('Erreur dans redirect : $e');
  //     print('Stack trace: $s');
  //     notifyListeners();
  //     return AppNavigator.pushReplacement('/login');
  //   } finally {
  //     _isRedirecting = false;
  //   }
  // }

  Future<bool> redirect() async {
    try {
      final response = await clientSpb.auth.getUser();
      final user = response.user;

      if (user == null) {
        print("Aucun utilisateur connecté → Page publique");
        AppNavigator.pushReplacement('/consumer_home'); // Page publique
        return false;
      }

      print("Utilisateur connecté : ${user.email}");
      _service = VendorService();
      await getUserAndPushToHome();
      return true;
    } catch (e, s) {
      print("Erreur redirect(): $e\n$s");
      AppNavigator.pushReplacement(
          '/consumer_home'); // Même en cas d'erreur → page publique
      return false;
    }
  }

  // Future<void> getUserAndPushToHome() async {
  //   try {
  //     print('Appel de getUser');
  //     await getUser();
  //     if (_user != null) {
  //       print('Utilisateur trouvé, rôle : $currentRole');
  //       pushToHome();
  //     } else {
  //       print('Utilisateur non admin/vendor ou null, redirection vers /login');
  //       AppNavigator.pushReplacement('/login');
  //     }
  //   } catch (e, s) {
  //     print('Erreur dans getUserAndPushToHome : $e');
  //     print('Stack trace: $s');
  //     AppNavigator.pushReplacement('/login');
  //   }
  // }

  Future<void> getUserAndPushToHome() async {
    try {
      // if (_service == null) {
      //   print("⚠️ Aucun service défini, impossible de récupérer l'utilisateur");
      //   AppNavigator.pushReplacement('/login');
      //   return;
      // }

      await getUser();

      if (_user != null) {
        print("Utilisateur chargé : rôle = ${_user!.currentRole.id}");
        pushToHome();
      } else {
        print("⚠️ Aucune donnée utilisateur trouvée");
        AppNavigator.pushReplacement('/login');
      }
    } catch (e, s) {
      print("Erreur lors du chargement utilisateur: $e\n$s");
      AppNavigator.pushReplacement('/login');
    }
  }

  Future<void> getUser() async {
    if (_service == null) {
      throw Exception("Service non initialisé dans AuthController");
    }

    try {
      loading = true;
      notifyListeners();

      final response = await _service?.getUser();
      if (response == null) {
        throw Exception("Utilisateur introuvable sur le serveur");
      }

      _user = response;
    } catch (e) {
      error = e.toString();
      print("Erreur dans getUser(): $e");
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // void pushToHome() {
  //   print('pushToHome, rôle : $currentRole');
  //   if (_user == null) {
  //     print('Utilisateur null, redirection vers /login');
  //     AppNavigator.pushReplacement('/login');
  //     return;
  //   }
  //   switch (currentRole) {
  //     case 'admin':
  //       print('Redirection vers /admin_home');
  //       AppNavigator.pushReplacement('/admin_home');
  //       break;
  //     case 'vendor':
  //       print('Redirection vers /vendor_home');
  //       AppNavigator.pushReplacement('/vendor_home');
  //       break;
  //     default:
  //       print('Rôle inconnu ou vide : $currentRole, redirection vers /login');
  //       AppNavigator.pushReplacement('/login');
  //   }
  // }

  void pushToHome() {
    switch (currentRole) {
      case 'admin':
        AppNavigator.pushReplacement('/admin_vendors');
        break;
      case 'vendor':
        AppNavigator.pushReplacement('/vendor_home');
        break;
      case 'consumer':
        AppNavigator.pushReplacement('/consumer_home');
        break;
      default:
        // Ne jamais arriver ici car redirect() gère déjà les non-connectés
        AppNavigator.pushReplacement('/login');
    }
  }

  Future<bool> canAccessAdminFeatures() async {
    await getUser();
    return _user != null && currentRole == 'admin';
  }

  Future<bool> canAccessVendorFeatures() async {
    await getUser();
    return _user != null && currentRole == 'vendor';
  }

  Future<void> tryAccessAdminFeatures() async {
    if (await canAccessAdminFeatures()) {
      AppNavigator.push('/admin_dashboard');
    } else {
      AppNavigator.pushReplacement('/login');
    }
  }

  Future<void> tryAccessVendorFeatures() async {
    if (await canAccessVendorFeatures()) {
      AppNavigator.push('/vendor_dashboard');
    } else {
      AppNavigator.pushReplacement('/login');
    }
  }

  // Future<void> signOut() async {
  //   try {
  //     print('Déconnexion en cours');
  //     await clientSpb.auth.signOut();
  //     _user = null;
  //     _service = null;
  //     AppNavigator.pushReplacement('/login');
  //     notifyListeners();
  //   } catch (e, s) {
  //     error = 'Échec de la déconnexion : $e';
  //     print('Erreur lors de la déconnexion : $e');
  //     print('Stack trace: $s');
  //     notifyListeners();
  //   }
  // }

  Future<void> signOut() async {
  try {
    print('Déconnexion en cours');

    // 1. Déconnexion Supabase
    await clientSpb.auth.signOut();

    // 2. Nettoie ton état local
    _user = null;
    _service = null;

    // // 3. IMPORTANT : Remet à zéro les notifications (badges)
    // // Accède au NotificationController via Provider (sans contexte si possible, ou avec)
    // // Méthode propre : si tu as accès au context, ou mieux : utilise un locator si tu en as un
    // // Mais la façon la plus simple et fiable ici :
    // try {
    //   // Essaie de trouver le provider s'il existe (ne plante pas si non monté)
    //   final notiCtrl = Provider.of<NotificationController>(
    //     navigatorKey.currentContext!,
    //     listen: false,
    //   );
    //   notiCtrl.loadNotifications(); // Il détectera que l'utilisateur est déconnecté et mettra à 0
    //   // Ou plus direct : notiCtrl.refresh(); ou une méthode reset()
    // } catch (_) {
    //   // Si le contexte n'est pas disponible, ce n'est pas grave
    //   // Le listener onAuthStateChange dans NotificationController fera le job
    // }

    // 4. Redirection
    AppNavigator.pushReplacement('/login');

    // 5. Notifie les listeners (UI)
    notifyListeners();
  } catch (e, s) {
    error = 'Échec de la déconnexion : $e';
    print('Erreur lors de la déconnexion : $e');
    print('Stack trace: $s');
    notifyListeners();
  }
}

  Future<bool> isAdminOrVendor() async {
    await getUser();
    return _user != null && (currentRole == 'admin' || currentRole == 'vendor');
  }
}
