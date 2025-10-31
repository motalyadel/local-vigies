import 'package:legumes_app/core/network/api_fetcher.dart';
import 'package:legumes_app/data/models/auth_model.dart';
import 'package:legumes_app/data/services/base_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VendorService extends BaseService {
  late final SupabaseClient clientSpb;
  late final ApiFetcher apiFetcher;

  VendorService() {
    clientSpb = Supabase.instance.client;
    apiFetcher = ApiFetcher(
      accessToken: clientSpb.auth.currentSession?.accessToken,
      baseUrl: 'http://10.0.2.2:4000',
    );
  }

  @override
  Future<AuthModel?> getUser() async {
    try {
      final user = clientSpb.auth.currentUser;
      if (user == null) {
        print('Aucun utilisateur connecté');
        return null;
      }
      print('Récupération des données utilisateur pour userId: ${user.id}');

      final response = await clientSpb.from('users').select('''
            id, name,
            vendors(shop_name, phone, location, photo_url, created_at),
            roles:user_roles(*, app_role(*))
          ''').eq('id', user.id).single();

      if (response == null) {
        print('Aucun utilisateur trouvé pour ID: ${user.id}');
        return null;
      }

      print('Réponse Supabase: $response');

      // Extraction des rôles
      final roleList = List<Map<String, dynamic>>.from(response['roles'] ?? []);
      List<String> roles =
          roleList.map((item) => item['app_role']['id'] as String).toList();

      // Fallback sur userMetadata
      if (roles.isEmpty && user.userMetadata != null) {
        final metadataRoles = user.userMetadata!['roles'];
        if (metadataRoles is List) {
          roles = List<String>.from(metadataRoles);
        }
      }

      if (roles.isEmpty) {
        print('Aucun rôle trouvé pour l\'utilisateur');
        return null;
      }

      final role = roles.first;
      print('Rôle utilisateur: $role');

      switch (role) {
        case 'vendor':
          if (response['vendors'] == null) {
            print(
                'Données vendor absentes pour un utilisateur avec rôle vendor');
            return null;
          }
          return Vendor.fromMap(response);
        case 'admin':
          try {
            await clientSpb
                .from('admin')
                .upsert({'id': user.id}, onConflict: 'id')
                .select()
                .single();
          } catch (e, s) {
            print('Erreur lors de l\'upsert dans admin : $e');
            print('Stack trace: $s');
            return null;
          }
          return Admin.fromMap(response);
        default:
          print('Rôle inconnu: $role');
          return null;
      }
    } catch (e, s) {
      print("❌ Échec de getUser(): $e");
      print('Stack trace: $s');
      return null;
    }
  }

  Future<bool> createVendor({
    required String name,
    required String email,
    required String password,
    required String shopName,
    String? phone,
    String? location,
    String? photoUrl,
    DateTime? createdAt,
  }) async {
    try {
      final currentUser = clientSpb.auth.currentUser;
      final isAdmin = currentUser != null &&
          (await clientSpb
                  .from('user_roles')
                  .select('app_role(id)')
                  .eq('user_id', currentUser.id)
                  .maybeSingle())?['app_role']['id'] ==
              'admin';

      if (isAdmin) {
        final success = await createUser(
          email: email,
          password: password,
          name: name,
          shopName: shopName,
          phone: phone,
          location: location,
          photoUrl: photoUrl,
          createdAt: createdAt,
          roles: ['vendor'],
        );
        return success;
      } else {
        return await registerAndConfirmVendor(
          name: name,
          email: email,
          password: password,
          shopName: shopName,
          phone: phone ?? '',
          location: location ?? '',
          photoUrl: photoUrl,
          createdAt: createdAt ?? DateTime.now(),
        );
      }
    } catch (e, s) {
      print('❌ Échec de createVendor: $e');
      print('Stack trace: $s');
      return false;
    }
  }

  Future<bool> registerAndConfirmVendor({
    required String name,
    required String email,
    required String password,
    required String shopName,
    required String phone,
    required String location,
    String? photoUrl,
    required DateTime createdAt,
  }) async {
    try {
      final authResponse = await clientSpb.auth.signUp(
        email: email,
        password: password,
        data: {
          'roles': ['vendor']
        },
      );

      if (authResponse.user == null) {
        print('Échec de l’inscription: utilisateur null');
        return false;
      }

      final userId = authResponse.user!.id;

      final vendorResponse = await clientSpb.from('vendors').insert({
        'id': userId,
        'name': name,
        'email': email,
        'shop_name': shopName,
        'phone': phone.isNotEmpty ? phone : null,
        'location': location.isNotEmpty ? location : null,
        'photo_url': photoUrl,
        'created_at': createdAt.toIso8601String(),
      });

      if (vendorResponse.error != null) {
        print('Erreur insertion vendor: ${vendorResponse.error!.message}');
        return false;
      }

      final roleResponse = await clientSpb.from('user_roles').insert({
        'user_id': userId,
        'role_id': 'vendor',
      });

      if (roleResponse.error != null) {
        print('Erreur insertion user_roles: ${roleResponse.error!.message}');
        return false;
      }

      return true;
    } catch (e, s) {
      print('❌ Échec de registerAndConfirmVendor: $e');
      print('Stack trace: $s');
      return false;
    }
  }

  Future<bool> createUser({
    required String email,
    required String password,
    required String name,
    required String shopName,
    String? phone,
    String? location,
    String? photoUrl,
    DateTime? createdAt,
    required List<String> roles,
  }) async {
    try {
      final authResponse = await clientSpb.auth.signUp(
        email: email,
        password: password,
        data: {'roles': roles},
      );

      if (authResponse.user == null) {
        print('Échec création utilisateur: utilisateur null');
        return false;
      }

      final userId = authResponse.user!.id;

      final userResponse = await clientSpb.from('users').insert({
        'id': userId,
        'name': name,
      });

      if (userResponse.error != null) {
        print('Erreur insertion users: ${userResponse.error!.message}');
        return false;
      }

      if (roles.contains('vendor')) {
        final vendorResponse = await clientSpb.from('vendors').insert({
          'id': userId,
          'name': name,
          'email': email,
          'shop_name': shopName,
          'phone': phone,
          'location': location,
          'photo_url': photoUrl,
          'created_at':
              createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        });

        if (vendorResponse.error != null) {
          print('Erreur insertion vendor: ${vendorResponse.error!.message}');
          return false;
        }
      }

      for (final role in roles) {
        final roleResponse = await clientSpb.from('user_roles').insert({
          'user_id': userId,
          'role_id': role,
        });
        if (roleResponse.error != null) {
          print('Erreur insertion rôle $role: ${roleResponse.error!.message}');
          return false;
        }
      }

      return true;
    } catch (e, s) {
      print('❌ Échec de createUser: $e');
      print('Stack trace: $s');
      return false;
    }
  }

  Future<List<Vendor>> getAllVendors() async {
    try {
      print('Récupération de tous les vendors...');
      final roleResponse = await clientSpb
          .from('user_roles')
          .select('user_id')
          .eq('role_id', 'vendor');
      print('Utilisateurs avec rôle vendor: $roleResponse');
      if (roleResponse.isEmpty) {
        print('Aucun utilisateur avec rôle vendor trouvé.');
        return [];
      }
      final userIds =
          roleResponse.map((item) => item['user_id'] as String).toList();
      print('IDs des utilisateurs vendor: $userIds');

      final usersResponse = await clientSpb.from('users').select('''
          id, name,
          roles: user_roles(role_id, app_role!inner(id))
        ''').inFilter('id', userIds);
      print('Réponse brute users: $usersResponse');

      if (usersResponse.isEmpty) {
        print('Aucun utilisateur correspondant trouvé dans la table users.');
        return [];
      }

      final vendorsResponse = await clientSpb
          .from('vendors')
          .select(
              'id, name, email, shop_name, phone, location, photo_url, created_at')
          .inFilter('id', userIds);
      print('Réponse brute vendors: $vendorsResponse');

      final Map<String, Map<String, dynamic>> vendorMap = {
        for (var v in vendorsResponse) (v['id'] as String): v
      };

      final vendors = usersResponse.map((userMap) {
        print('Mapping utilisateur: $userMap');
        final userId = userMap['id'] as String;
        final vendorData = vendorMap[userId] ?? {};
        print('Données vendor pour $userId: $vendorData');
        return Vendor.fromMap({...userMap, 'vendor': vendorData});
      }).toList();
      print('Récupéré ${vendors.length} vendors');
      return vendors;
    } catch (e, s) {
      print("Échec de getAllVendors(): $e");
      print('Stack trace: $s');
      return [];
    }
  }
}
