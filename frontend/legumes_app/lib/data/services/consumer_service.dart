import 'package:legumes_app/data/models/auth_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConsumateurService {
  static final _client = Supabase.instance.client;

  /// Récupère TOUS les consommateurs qui ont déjà fait une demande à CE vendeur
  static Future<List<Consumateur>> getAllConsumateursForVendor() async {
    try {
      final vendorId = _client.auth.currentUser!.id;

      print('Récupération des consommateurs pour le vendor: $vendorId');

      // 1. On récupère tous les Consumateur_id uniques depuis les demandes
      final requestsResponse = await _client
          .from('product_requests')
          .select('Consumateur_id')
          .eq('vendor_id', vendorId);

      if (requestsResponse.isEmpty) {
        print('Aucune demande trouvée pour ce vendeur.');
        return [];
      }

      final ConsumateurIds = (requestsResponse as List)
          .map((r) => r['Consumateur_id'] as String)
          .where((id) => id != null)
          .toSet()
          .toList();

      print('Consumateur IDs trouvés: $ConsumateurIds');

      if (ConsumateurIds.isEmpty) return [];

      // 2. On récupère les infos des consommateurs
      final ConsumateursResponse = await _client
          .from('Consumateurs')
          .select('id, name, phone')
          .inFilter('id', ConsumateurIds);

      print('Réponse Consumateurs: $ConsumateursResponse');

      final Consumateurs = (ConsumateursResponse as List)
          .map((data) => Consumateur.fromMap(data as Map<String, dynamic>))
          .toList();

      print('Récupéré ${Consumateurs.length} consommateurs uniques');
      return Consumateurs;
    } catch (e, s) {
      print('Erreur getAllConsumateursForVendor(): $e');
      print(s);
      return [];
    }
  }
}