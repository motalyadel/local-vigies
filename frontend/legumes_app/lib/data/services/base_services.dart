import 'package:legumes_app/data/models/auth_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class BaseService<T extends AuthModel> {
  final SupabaseClient clientSpb = Supabase.instance.client;

  // Future<AuthResponse?> signIn({
  //   required String email,
  //   required String password,
  // }) async {
  //   try {
  //     final auth = await clientSpb.auth.signInWithPassword(
  //       email: email,
  //       password: password,
  //     );
  //     return auth;
  //   } catch (e) {
  //     print("❌ signIn failed: $e");
  //     rethrow; // Re-throw to handle specific errors in the UI
  //   }
  // }

  Future<bool> signIn({required String email, required String password}) async {
    try {
      final response = await clientSpb.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        print('✅ Connexion réussie pour ${response.user!.email}');
        return true;
      } else {
        print('⚠️ Échec : user est null');
        return false;
      }
    } on AuthApiException catch (e) {
      print('⚠️ AuthApiException: ${e.message}');
      return false;
    } catch (e, s) {
      print('❌ Erreur inattendue : $e\n$s');
      return false;
    }
  }

  Future<AuthResponse?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await clientSpb.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
        },
      );
      return response;
    } catch (e) {
      print("❌ signUp failed: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    await clientSpb.auth.signOut();
  }

  Future<T?> getUser();

  // Future<T?> getEmployer();
}
