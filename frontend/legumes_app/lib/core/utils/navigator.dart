// import 'package:flutter/widgets.dart';

// class AppNavigator {
//   static final globalKey = GlobalKey<NavigatorState>();

//   static push(String url) =>
//       Navigator.pushReplacementNamed(globalKey.currentState!.context, url);
//   static pushReplacement(String url) =>
//       Navigator.pushReplacementNamed(globalKey.currentState!.context, url);
// }


// lib/core/utils/navigator.dart

import 'package:flutter/material.dart';

class AppNavigator {
  // Clé globale du Navigator
  static final GlobalKey<NavigatorState> globalKey = GlobalKey<NavigatorState>();

  // Contexte actuel (sûr)
  static BuildContext? get context => globalKey.currentContext;

  // === Méthodes sécurisées (avec vérification du contexte) ===

  static void push(String routeName, {Object? arguments}) {
    if (context != null && globalKey.currentState != null) {
      globalKey.currentState!.pushNamed(routeName, arguments: arguments);
    }
  }

  static void pushReplacement(String routeName, {Object? arguments}) {
    if (context != null && globalKey.currentState != null) {
      globalKey.currentState!.pushReplacementNamed(routeName, arguments: arguments);
    }
  }

  static void pushAndRemoveUntil(String routeName, {Object? arguments}) {
    if (context != null && globalKey.currentState != null) {
      globalKey.currentState!.pushNamedAndRemoveUntil(
        routeName,
        (route) => false, // Supprime tout l’historique
        arguments: arguments,
      );
    }
  }

  static void pop([Object? result]) {
    if (context != null && globalKey.currentState?.canPop() == true) {
      globalKey.currentState!.pop(result);
    }
  }

  static void popUntil(String routeName) {
    if (context != null && globalKey.currentState != null) {
      globalKey.currentState!.popUntil(ModalRoute.withName(routeName));
    }
  }

  // === Raccourcis pratiques ===
  static void goToLogin() => pushReplacement('/login');
  static void goToVendorHome() => pushAndRemoveUntil('/vendor_home');
  static void goToConsumerHome() => pushAndRemoveUntil('/consumer_home');
}

// import 'package:flutter/material.dart';

// // import 'package:flutter/material.dart';

// class AppNavigator {
//   static final GlobalKey<NavigatorState> navigatorKey =
//       GlobalKey<NavigatorState>();

//   static Future pushReplacement(String route) async {
//     final currentState = navigatorKey.currentState;
//     if (currentState == null) {
//       print("⚠️ Navigator non prêt, on ignore la navigation");
//       return;
//     }
//     await currentState.pushReplacementNamed(route);
//   }

//   static Future push(String route) async {
//     final currentState = navigatorKey.currentState;
//     if (currentState == null) {
//       print("⚠️ Navigator non prêt, on ignore la navigation");
//       return;
//     }
//     await currentState.pushNamed(route);
//   }
// }

