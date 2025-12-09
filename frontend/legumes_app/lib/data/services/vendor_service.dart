import 'dart:io';

import 'package:image_picker/image_picker.dart';
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
            consumers(*)
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
          .select('id, shop_name, phone, location, photo_url, created_at')
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

  Future<bool> registerAndConfirmVendor({
    required String name,
    required String email,
    required String password,
    required String shopName,
    String? phone,
    String? location,
  }) async {
    try {
      // 1. Vérifier si l'email existe déjà
      final checkResponse = await apiFetcher.get('/check-email?email=$email');

      if (checkResponse.isSuccess && checkResponse.data['exists'] == true) {
        print('Email déjà utilisé : $email');
        // Tu peux retourner un message spécifique
        return false;
      }

      // 2. Si l'email est libre → on continue
      final body = {
        'name': name,
        'email': email,
        'password': password,
        'shop_name': shopName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (location != null && location.isNotEmpty) 'location': location,
      };

      final response = await apiFetcher.post('/register-public', body: body);

      if (response.isSuccess &&
          response.data is Map &&
          response.data['success'] == true) {
        print('Vendor inscrit avec succès via API');
        return true;
      } else {
        print('Erreur backend: ${response.error ?? response.data}');
        return false;
      }
    } catch (e, s) {
      print('registerAndConfirmVendor() failed: $e');
      print('Stack: $s');
      return false;
    }
  }

  // Dans ton VendorService ou ClientService
  Future<bool> createUser({
    required String email,
    required String password,
    required String name,
    String? shopName,
    String? phone,
    String? location,
    XFile? photoUrl,
    List<String>? roles,
    // List<String> roles = const ['vendor'], // par défaut vendor
  }) async {
    try {
      final body = {
        'email': email.trim(),
        'password': password,
        'name': name.trim(),
        if (shopName != null && shopName.trim().isNotEmpty)
          'shop_name': shopName.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (location != null && location.trim().isNotEmpty)
          'location': location.trim(),
        // if (photoUrl != null && photoUrl.isNotEmpty) 'photo_url': photoUrl,
        'roles': roles ?? ['vendor'],
      };

      print('Envoi vers /user : $body');

      final response = await apiFetcher.post('/user', body: body, file: photoUrl
          // Pas de fichier ici car photo_url est déjà uploadé avant
          );

      print('Réponse /user : ${response.status} - ${response.data}');

      if (response.status == 200 || response.status == 201) {
        final data = response.data as Map<String, dynamic>?;
        return data?['success'] == true;
      }

      // Erreur détaillée
      final errorMsg = response.data?['error'] ?? 'Erreur inconnue';
      print('Erreur création utilisateur : $errorMsg');
      return false;
    } catch (e) {
      print('Exception lors de createUser : $e');
      return false;
    }
  }

  // === CREATE VENDOR (Admin or Public) ===
  Future<bool> createVendor({
    required String name,
    required String email,
    required String password,
    required String shopName,
    String? phone,
    String? location,
    String? photoUrl,
  }) async {
    try {
      final currentUser = clientSpb.auth.currentUser;
      final isAdmin = currentUser != null &&
          (await clientSpb
                  .from('user_roles')
                  .select('app_role(id)')
                  .eq('user_id', currentUser.id)
                  .single())['app_role']['id'] ==
              'admin';

      if (isAdmin) {
        // Admin crée le compte + vendor
        print("_createUserAndVendor....");
        return await _createUserAndVendor(
          name: name,
          email: email,
          password: password,
          shopName: shopName,
          phone: phone,
          location: location,
          photoUrl: photoUrl,
        );
      } else {
        // Inscription publique
        print("registerAndConfirmVendor....");
        return await registerAndConfirmVendor(
          name: name,
          email: email,
          password: password,
          shopName: shopName,
          phone: phone,
          location: location,
        );
      }
    } catch (e) {
      print('createVendor failed: $e');
      return false;
    }
  }

  Future<bool> _createUserAndVendor({
    required String name,
    required String email,
    required String password,
    required String shopName,
    String? phone,
    String? location,
    String? photoUrl,
  }) async {
    try {
      final authResponse = await clientSpb.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      if (authResponse.user == null) return false;

      final userId = authResponse.user!.id;

      // Insérer dans users
      await clientSpb.from('users').insert({
        'id': userId,
        'name': name,
        'email': email,
      });

      // Insérer dans vendors
      await clientSpb.from('vendors').insert({
        'id': userId,
        'shop_name': shopName,
        'phone': phone,
        'location': location,
        'photo_url': photoUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Ajouter rôle
      await clientSpb
          .from('user_roles')
          .insert({'user_id': userId, 'role_id': 'vendor'});

      return true;
    } catch (e) {
      print('_createUserAndVendor failed: $e');
      return false;
    }
  }

  // === UPDATE VENDOR ===
  Future<bool> updateVendor({
    required String userId,
    String? name,
    String? shopName,
    String? phone,
    String? location,
    String? photoUrl,
  }) async {
    try {
      final userUpdates = <String, dynamic>{};
      final vendorUpdates = <String, dynamic>{};

      if (name != null && name.trim().isNotEmpty) {
        userUpdates['name'] = name.trim();
      }

      if (shopName != null && shopName.trim().isNotEmpty) {
        vendorUpdates['shop_name'] = shopName.trim();
      }
      if (phone != null && phone.trim().isNotEmpty) {
        vendorUpdates['phone'] = phone.trim();
      }
      if (location != null && location.trim().isNotEmpty) {
        vendorUpdates['location'] = location.trim();
      }
      if (photoUrl != null && photoUrl.isNotEmpty) {
        vendorUpdates['photo_url'] = photoUrl;
      }

      bool userSuccess = true;
      if (userUpdates.isNotEmpty) {
        try {
          await clientSpb.from('users').update(userUpdates).eq('id', userId);
        } catch (e) {
          print('User update failed: $e');
          userSuccess = false;
        }
      }

      bool vendorSuccess = true;
      if (vendorUpdates.isNotEmpty) {
        vendorUpdates['id'] = userId;
        try {
          await clientSpb
              .from('vendors')
              .upsert(vendorUpdates, onConflict: 'id');
        } catch (e) {
          print('Vendor upsert failed: $e');
          vendorSuccess = false;
        }
      }

      return userSuccess && vendorSuccess;
    } catch (e) {
      print("updateVendor() failed: $e");
      return false;
    }
  }

  Future<String?> uploadPhoto(XFile photo, String path) async {
    try {
      print('Uploading photo');
      final fileBytes = await photo.readAsBytes();
      await clientSpb.storage.from('avatars').uploadBinary(
            path,
            fileBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: photo.mimeType ?? 'image/jpeg',
            ),
          );
      print("Photo uploaded to avatars");
      final publicUrl = clientSpb.storage.from('avatars').getPublicUrl(path);
      print('Photo URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      print("Photo upload failed: $e");
      return null;
    }
  }

  Future<bool> deleteVendor(String id) async {
    try {
      final response = await apiFetcher.post(
        '/vendor/delete',
        body: {'id': id},
      );

      if (response.status == 200 && response.data['success'] == true) {
        return true;
      } else {
        print('Erreur API: ${response.data}');
        return false;
      }
    } catch (e) {
      print('Exception lors de la suppression: $e');
      return false;
    }
  }
}
