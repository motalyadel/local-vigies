import 'package:flutter/widgets.dart';

class AppNavigator {
  static final globalKey = GlobalKey<NavigatorState>();

  static push(String url) =>
      Navigator.pushReplacementNamed(globalKey.currentState!.context, url);
  static pushReplacement(String url) =>
      Navigator.pushReplacementNamed(globalKey.currentState!.context, url);
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

