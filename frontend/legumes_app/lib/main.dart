import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:legumes_app/core/utils/navigator.dart';
import 'package:legumes_app/l10n/generated/app_localizations.dart';
import 'package:legumes_app/presentation/providers/auth_controller.dart';
import 'package:legumes_app/presentation/providers/local_provider.dart';
import 'package:legumes_app/presentation/screens/admin/admin_home_page.dart';
import 'package:legumes_app/presentation/screens/home/login_page.dart';
import 'package:legumes_app/presentation/screens/home/register_page.dart';
import 'package:legumes_app/presentation/screens/home/splash_screen.dart';
import 'package:legumes_app/presentation/screens/vendor/vendor_home_page.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://krzzcqziohmvbjylcokx.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtyenpjcXppb2htdmJqeWxjb2t4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE0MjM5ODIsImV4cCI6MjA3Njk5OTk4Mn0.7X0zE6T6KZm2KsRvE2iY2M786pnAG-DcM_PUKHxDC2M',
  );

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => LocaleProvider()),
    ChangeNotifierProvider.value(value: AuthController()),
  ], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(builder: (context, localeProvider, child) {
      return MaterialApp(
        title: 'LOCAL VIGGIES',
        debugShowCheckedModeBanner: false,
        supportedLocales: const [
          Locale('en'),
          Locale('ar'),
        ],
        locale: localeProvider.locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        navigatorKey: AppNavigator.globalKey,
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/login': (_) => const LoginPage(),
          '/signup': (_) => const RegisterPage(),
          '/admin_home': (_) => AdminHomePage(),
          '/vendor_home': (_) => VendorHomePage(),
        },

        onUnknownRoute: (settings) {
          print('Route inconnue : ${settings.name}');
          return MaterialPageRoute(builder: (context) => const LoginPage());
        },
      );
    });
  }
}
