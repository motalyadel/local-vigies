// // presentation/pages/consumer/consumer_home_page.dart

// import 'package:flutter/material.dart';
// import 'package:legumes_app/core/services/consumer_local_service.dart';
// import 'package:legumes_app/core/services/unread_messages_service.dart';
// import 'package:legumes_app/data/models/product_model.dart';
// import 'package:legumes_app/data/services/product_service.dart';
// import 'package:legumes_app/presentation/screens/home/login_page.dart';
// import 'package:legumes_app/presentation/screens/vendor/vendor_chat_screen.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:flutter_chat_ui/flutter_chat_ui.dart';
// import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

// class ConsumerHomePage extends StatefulWidget {
//   const ConsumerHomePage({super.key});
//   @override
//   State<ConsumerHomePage> createState() => _ConsumerHomePageState();
// }

// class _ConsumerHomePageState extends State<ConsumerHomePage> {
//   late Future<List<Product>> _productsFuture;

//   @override
//   void initState() {
//     super.initState();
//     _productsFuture = ProductService().getAllProducts();
//   }

//   Future<void> _refresh() async {
//     setState(() => _productsFuture = ProductService().getAllProducts());
//   }

//   void _openChat(Product product) async {
//     String? consumerId = await ConsumerLocalService.getConsumerId();

//     // Si on a déjà les infos → on ouvre direct le chat
//     if (consumerId != null) {
//       if (!mounted) return;
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => ConsumerChatScreen(
//             product: product,
//             consumerId: consumerId!,
//           ),
//         ),
//       );
//       return;
//     }

//     // Sinon → on demande une seule fois
//     final nameCtrl = TextEditingController();
//     final phoneCtrl = TextEditingController();

//     final result = await showDialog<String>(
//       context: context,
//       barrierDismissible: false,
//       builder: (ctx) => AlertDialog(
//         title: const Text("Bienvenue ! Entrez vos coordonnées"),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//                 "Ces informations ne seront demandées qu'une seule fois"),
//             const SizedBox(height: 16),
//             TextField(
//                 controller: nameCtrl,
//                 decoration: const InputDecoration(labelText: "Nom")),
//             TextField(
//               controller: phoneCtrl,
//               keyboardType: TextInputType.phone,
//               decoration: const InputDecoration(labelText: "Téléphone"),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.pop(ctx),
//               child: const Text("Annuler")),
//           ElevatedButton(
//             onPressed: () {
//               if (nameCtrl.text.trim().isNotEmpty &&
//                   phoneCtrl.text.trim().isNotEmpty) {
//                 Navigator.pop(ctx, "ok");
//               }
//             },
//             child: const Text("Continuer"),
//           ),
//         ],
//       ),
//     );

//     if (result != "ok") return;

//     try {
//       final consumerRes = await Supabase.instance.client
//           .from('consumers')
//           .insert({
//             'name': nameCtrl.text.trim(),
//             'phone': phoneCtrl.text.trim(),
//           })
//           .select()
//           .single();

//       consumerId = consumerRes['id'].toString();

//       // SAUVEGARDE EN LOCAL POUR NE PLUS JAMAIS DEMANDER
//       await ConsumerLocalService.saveConsumerInfo(
//         name: nameCtrl.text.trim(),
//         phone: phoneCtrl.text.trim(),
//         consumerId: consumerId,
//       );

//       if (!mounted) return;
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => ConsumerChatScreen(
//             product: product,
//             consumerId: consumerId!,
//           ),
//         ),
//       );
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Erreur : $e")),
//         );
//       }
//     }
//   }

//   Future<void> _showOrderDialog(Product product) async {
//     // 1. On essaie de récupérer les infos déjà sauvegardées
//     final localInfo = await ConsumerLocalService.getConsumerInfo();
//     String? consumerId = await ConsumerLocalService.getConsumerId();

//     final nameCtrl = TextEditingController(text: localInfo?['name'] ?? '');
//     final phoneCtrl = TextEditingController(text: localInfo?['phone'] ?? '');
//     final locationCtrl = TextEditingController();
//     final quantityCtrl = TextEditingController();

//     // Si on n'a PAS encore les infos → on force le dialog complet (première fois)
//     if (localInfo == null || consumerId == null) {
//       final result = await showDialog<String>(
//         context: context,
//         barrierDismissible: false,
//         builder: (ctx) => AlertDialog(
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//           title: const Text("Commander en quelques secondes",
//               textAlign: TextAlign.center),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 CircleAvatar(
//                   radius: 30,
//                   backgroundImage: product.imageUrl != null
//                       ? NetworkImage(product.imageUrl!)
//                       : null,
//                   child: product.imageUrl == null
//                       ? const Icon(Icons.shopping_basket, size: 30)
//                       : null,
//                 ),
//                 const SizedBox(height: 12),
//                 Text(product.name,
//                     style: const TextStyle(
//                         fontSize: 18, fontWeight: FontWeight.bold)),
//                 Text("${product.price.toStringAsFixed(0)} MRU/kg",
//                     style: const TextStyle(
//                         fontSize: 20,
//                         color: Colors.teal,
//                         fontWeight: FontWeight.bold)),
//                 const Divider(height: 32),
//                 const Text("Vos coordonnées (une seule fois)",
//                     style: TextStyle(fontWeight: FontWeight.w600)),
//                 const SizedBox(height: 12),
//                 TextField(
//                     controller: nameCtrl,
//                     decoration: const InputDecoration(
//                         labelText: "Nom complet",
//                         prefixIcon: Icon(Icons.person))),
//                 TextField(
//                     controller: phoneCtrl,
//                     keyboardType: TextInputType.phone,
//                     decoration: const InputDecoration(
//                         labelText: "Téléphone", prefixIcon: Icon(Icons.phone))),
//                 TextField(
//                     controller: locationCtrl,
//                     decoration: const InputDecoration(
//                         labelText: "Quartier / Adresse",
//                         prefixIcon: Icon(Icons.location_on))),
//                 const SizedBox(height: 12),
//                 TextField(
//                     controller: quantityCtrl,
//                     keyboardType: TextInputType.number,
//                     decoration: const InputDecoration(
//                         labelText: "Quantité (kg)",
//                         prefixIcon: Icon(Icons.scale))),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//                 onPressed: () => Navigator.pop(ctx),
//                 child: const Text("Annuler")),
//             ElevatedButton(
//               onPressed: () {
//                 if (nameCtrl.text.trim().isNotEmpty &&
//                     phoneCtrl.text.trim().isNotEmpty &&
//                     locationCtrl.text.trim().isNotEmpty &&
//                     quantityCtrl.text.trim().isNotEmpty) {
//                   Navigator.pop(ctx, "ok");
//                 }
//               },
//               child: const Text("Commander"),
//             ),
//           ],
//         ),
//       );

//       if (result != "ok") return;

//       // Créer le consommateur dans Supabase + sauvegarde locale
//       try {
//         final consumerRes = await Supabase.instance.client
//             .from('consumers')
//             .insert({
//               'name': nameCtrl.text.trim(),
//               'phone': phoneCtrl.text.trim(),
//             })
//             .select()
//             .single();

//         consumerId = consumerRes['id'].toString();

//         // SAUVEGARDE EN LOCAL → plus jamais demandé !
//         await ConsumerLocalService.saveConsumerInfo(
//           name: nameCtrl.text.trim(),
//           phone: phoneCtrl.text.trim(),
//           consumerId: consumerId,
//         );
//       } catch (e) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text("Erreur création consommateur : $e")));
//         }
//         return;
//       }
//     } else {
//       // CAS 2 : Infos déjà sauvegardées → dialog rapide (seulement quantité + adresse)
//       final quickResult = await showDialog<bool>(
//         context: context,
//         builder: (ctx) => AlertDialog(
//           title: Text("Commander ${product.name}"),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text("Connecté comme : ${localInfo['name']}"),
//               Text("Téléphone : ${localInfo['phone']}"),
//               const Divider(),
//               TextField(
//                 controller: quantityCtrl,
//                 keyboardType: TextInputType.number,
//                 decoration:
//                     const InputDecoration(labelText: "Quantité désirée (kg)"),
//                 autofocus: true,
//               ),
//               TextField(
//                 controller: locationCtrl,
//                 decoration:
//                     const InputDecoration(labelText: "Adresse de livraison"),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//                 onPressed: () => Navigator.pop(ctx, false),
//                 child: const Text("Annuler")),
//             ElevatedButton(
//               onPressed: () {
//                 if (quantityCtrl.text.trim().isNotEmpty &&
//                     locationCtrl.text.trim().isNotEmpty) {
//                   Navigator.pop(ctx, true);
//                 }
//               },
//               child: const Text("Envoyer la demande"),
//             ),
//           ],
//         ),
//       );

//       if (quickResult != true) return;
//     }

//     // ENVOI DE LA COMMANDE (les deux cas arrivent ici)
//     try {
//       await Supabase.instance.client.from('product_requests').insert({
//         'product_id': product.id,
//         'product_name': product.name,
//         'vendor_id': product.vendorId,
//         'consumer_id': consumerId,
//         'quantity': double.tryParse(quantityCtrl.text) ?? 1,
//         'price_at_request': product.price,
//         // 'customer_name': nameCtrl.text.trim(),
//         // 'customer_phone': phoneCtrl.text.trim(),
//         'vendor_shop_name': product.vendorShopName ?? 'Boutique',
//         'customer_location': locationCtrl.text.trim(),
//         'status': 'pending',
//       });

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text(
//                 "Demande envoyée avec succès ! Le vendeur vous répondra bientôt"),
//             backgroundColor: Colors.teal,
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//               content: Text("Échec de l'envoi : $e"),
//               backgroundColor: Colors.red),
//         );
//         print("error : $e");
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Marché Local"),
//         backgroundColor: AppColors.primary,
//         foregroundColor: Colors.white,
//         actions: [
//           TextButton.icon(
//             onPressed: () => Navigator.of(context).pushNamed('/login'),
//             icon: const Icon(Icons.login, color: Colors.white),
//             label: const Text('Se connecter',
//                 style: TextStyle(color: Colors.white)),
//           ),
//           IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
//         ],
//       ),
//       body: FutureBuilder<List<Product>>(
//         future: _productsFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           final products = snapshot.data ?? [];
//           if (products.isEmpty) {
//             return const Center(child: Text("Aucun produit"));
//           }

//           return GridView.builder(
//             padding: const EdgeInsets.all(12),
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 2,
//               childAspectRatio: 0.62,
//               crossAxisSpacing: 12,
//               mainAxisSpacing: 12,
//             ),
//             itemCount: products.length,
//             itemBuilder: (_, i) {
//               final p = products[i];
//               final phone = p.vendorPhone ?? "Non renseigné";

//               return Card(
//                 elevation: 8,
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12)),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     Expanded(
//                       flex: 3,
//                       child: ClipRRect(
//                         borderRadius: const BorderRadius.vertical(
//                             top: Radius.circular(12)),
//                         child: p.imageUrl != null
//                             ? Image.network(p.imageUrl!, fit: BoxFit.cover)
//                             : Container(
//                                 color: Colors.grey[300],
//                                 child: const Icon(Icons.image, size: 60)),
//                       ),
//                     ),
//                     Expanded(
//                       flex: 2,
//                       child: Padding(
//                         padding: const EdgeInsets.all(8),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(p.name,
//                                 style: const TextStyle(
//                                     fontWeight: FontWeight.bold, fontSize: 15),
//                                 maxLines: 1),
//                             Text("${p.price.toStringAsFixed(0)} MRU",
//                                 style: const TextStyle(
//                                     color: Colors.teal,
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.bold)),
//                             // const SizedBox(height: 6),
//                             // Text(p.vendorShopName ?? "Boutique",
//                             //     style: const TextStyle(
//                             //         fontSize: 13, fontWeight: FontWeight.w600)),
//                             // Text("Tel: $phone",
//                             //     style: TextStyle(
//                             //         fontSize: 12, color: Colors.grey[700])),
//                             // const Spacer(),
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: ElevatedButton.icon(
//                                     onPressed: () => _showOrderDialog(p),
//                                     icon: const Icon(
//                                         Icons.shopping_cart_outlined,
//                                         size: 16),
//                                     label: const Text("Commander",
//                                         style: TextStyle(fontSize: 8)),
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: Colors.orange,
//                                       padding: const EdgeInsets.symmetric(
//                                           vertical: 4),
//                                       shape: RoundedRectangleBorder(
//                                           borderRadius:
//                                               BorderRadius.circular(12)),
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Stack(
//                                   children: [
//                                     ElevatedButton.icon(
//                                       onPressed: () => _openChat(p),
//                                       icon: const Icon(
//                                           Icons.chat_bubble_outline,
//                                           size: 16),
//                                       label: const Text("Chat",
//                                           style: TextStyle(fontSize: 11)),
//                                       style: ElevatedButton.styleFrom(
//                                         backgroundColor: Colors.teal,
//                                         padding: const EdgeInsets.symmetric(
//                                             vertical: 8),
//                                         shape: RoundedRectangleBorder(
//                                             borderRadius:
//                                                 BorderRadius.circular(12)),
//                                       ),
//                                     ),
//                                     // Badge pour le consommateur
//                                     FutureBuilder<int>(
//                                       future:
//                                           ConsumerLocalService.getConsumerId()
//                                               .then((id) async {
//                                         if (id == null) return 0;
//                                         return await UnreadMessagesService
//                                             .getUnreadCountForConsumer(id);
//                                       }),
//                                       builder: (context, snapshot) {
//                                         final count = snapshot.data ?? 0;
//                                         if (count == 0) return const SizedBox();
//                                         return Positioned(
//                                           right: 6,
//                                           top: 6,
//                                           child: Container(
//                                             padding: const EdgeInsets.all(4),
//                                             decoration: const BoxDecoration(
//                                               color: Colors.red,
//                                               shape: BoxShape.circle,
//                                             ),
//                                             constraints: const BoxConstraints(
//                                                 minWidth: 18, minHeight: 18),
//                                             child: Text(
//                                               count > 99
//                                                   ? "99+"
//                                                   : count.toString(),
//                                               style: const TextStyle(
//                                                   color: Colors.white,
//                                                   fontSize: 10),
//                                               textAlign: TextAlign.center,
//                                             ),
//                                           ),
//                                         );
//                                       },
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// class ConsumerChatScreen extends StatefulWidget {
//   final Product product;
//   final String consumerId;

//   const ConsumerChatScreen({
//     super.key,
//     required this.product,
//     required this.consumerId,
//   });

//   @override
//   State<ConsumerChatScreen> createState() => _ConsumerChatScreenState();
// }

// class _ConsumerChatScreenState extends State<ConsumerChatScreen> {
//   List<types.Message> _messages = [];
//   late final types.User _consumer;
//   late final types.User _vendor;

//   @override
//   void initState() {
//     super.initState();
//     _consumer = types.User(id: widget.consumerId);
//     _vendor = types.User(
//       id: widget.product.vendorId,
//       firstName: widget.product.vendorShopName ?? "Vendeur",
//     );
//     _markVendorMessagesAsRead();
//     _loadMessages();
//     _listenToRealtime();
//   }

//   Future<void> _loadMessages() async {
//     try {
//       final response = await Supabase.instance.client
//           .from('messages')
//           .select()
//           .eq('consumer_id',
//               widget.consumerId) // .eq() marche pour select() (pas stream)
//           .eq('vendor_id', widget.product.vendorId)
//           .order('created_at', ascending: true);

//       final List<types.Message> loaded = response.map<types.TextMessage>((messages) {
//         return types.TextMessage(
//           author: messages['sender_type'] == 'vendor' ? _vendor : _consumer,
//           createdAt: DateTime.parse(messages['created_at']).millisecondsSinceEpoch,
//           id: messages['id'].toString(),
//           text: messages['text'],
//         );
//       }).toList();

//       if (mounted) {
//         setState(() {
//           _messages = loaded.reversed.toList();
//         });
//       }
//     } catch (e) {
//       debugPrint("Erreur chargement messages: $e");
//     }
//   }

//   void _listenToRealtime() {
//     Supabase.instance.client
//         .from('messages')
//         .stream(primaryKey: ['id'])
//         .order('created_at', ascending: true)
//         .listen((List<Map<String, dynamic>> data) {
//           // Filtre en mémoire : seulement les messages de cette conversation
//           final filteredData = data
//               .where((messages) =>
//                   messages['vendor_id'] == widget.product.vendorId &&
//                   messages['consumer_id'] == widget.consumerId)
//               .toList();

//           if (mounted) {
//             _loadMessagesFromData(
//                 filteredData); // Nouvelle fonction pour charger depuis data filtré
//             _markVendorMessagesAsRead();
//           }
//         });
//   }

// // Nouvelle fonction pour charger depuis data filtré (appelle _loadMessages mais avec data)
//   void _loadMessagesFromData(List<Map<String, dynamic>> filteredData) {
//     final List<types.Message> loaded =
//         filteredData.map<types.TextMessage>((messages) {
//       return types.TextMessage(
//         author: messages['sender_type'] == 'vendor' ? _vendor : _consumer,
//         createdAt: DateTime.parse(messages['created_at']).millisecondsSinceEpoch,
//         id: messages['id'].toString(),
//         text: messages['text'],
//       );
//     }).toList();

//     setState(() {
//       _messages = loaded.reversed.toList();
//     });
//   }

//   void _handleSendPressed(types.PartialText message) async {
//     final tempMessage = types.TextMessage(
//       author: _consumer,
//       createdAt: DateTime.now().millisecondsSinceEpoch,
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       text: message.text,
//     );

//     // Affichage IMMÉDIAT du message envoyé
//     setState(() {
//       _messages = [tempMessage, ..._messages]; // nouveau en haut
//     });

//     try {
//       await Supabase.instance.client.from('messages').insert({
//         'text': message.text,
//         'sender_type': 'consumer',
//         'consumer_id': widget.consumerId,
//         'vendor_id': widget.product.vendorId,
//         'product_id': widget.product.id,
//       });
//       // Le stream rechargera automatiquement → pas besoin de faire plus
//     } catch (e) {
//       setState(() {
//         _messages.removeWhere((m) => m.id == tempMessage.id);
//       });
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//               content: Text("Échec de l'envoi"), backgroundColor: Colors.red),
//         );
//       }
//     }
//   }

//   Future<void> _markVendorMessagesAsRead() async {
//     try {
//       await Supabase.instance.client
//           .from('messages')
//           .update({'read': true})
//           .eq('consumer_id', widget.consumerId)
//           .eq('vendor_id', widget.product.vendorId)
//           .eq('sender_type', 'vendor')
//           .eq('read',
//               false); // seulement les non lus (mais même si déjà lus, ça ne change rien)
//     } catch (e) {
//       debugPrint("Erreur marquage messages comme lus (consommateur): $e");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(widget.product.vendorShopName ?? "Vendeur"),
//             Text(
//               "Tel: ${widget.product.vendorPhone ?? 'Non renseigné'}",
//               style: const TextStyle(fontSize: 12),
//             ),
//           ],
//         ),
//         backgroundColor: Colors.teal,
//         foregroundColor: Colors.white,
//       ),
//       body: Chat(
//         messages: _messages,
//         onSendPressed: _handleSendPressed,
//         user: _consumer,
//         theme: const DefaultChatTheme(
//           primaryColor: Colors.teal,
//           inputBackgroundColor: Colors.black,
//           sendButtonIcon:
//               Icon(Icons.send, color: Colors.white), // PLUS BESOIN D'ASSETS !
//           sentMessageBodyTextStyle: TextStyle(color: Colors.white),
//           receivedMessageBodyTextStyle: TextStyle(color: Colors.black87),
//         ),
//       ),
//     );
//   }
// }

// presentation/pages/consumer/consumer_home_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:legumes_app/core/network/api_fetcher.dart';
import 'package:legumes_app/core/services/consumer_local_service.dart';
import 'package:legumes_app/l10n/generated/app_localizations.dart';
import 'package:legumes_app/presentation/providers/local_provider.dart';
import 'package:legumes_app/presentation/screens/consumer/consumer_orders_page.dart';
import 'package:legumes_app/presentation/screens/home/login_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:legumes_app/data/models/product_model.dart';
import 'package:legumes_app/data/services/product_service.dart';

class ConsumerHomePage extends StatefulWidget {
  const ConsumerHomePage({super.key});
  @override
  State<ConsumerHomePage> createState() => _ConsumerHomePageState();
}

class _ConsumerHomePageState extends State<ConsumerHomePage> {
  late Future<List<Product>> _productsFuture;
  final locationCtrl = TextEditingController();

  String? _consumerId;
  late final ApiFetcher _apiFetcher;

  @override
  void initState() {
    super.initState();
    _productsFuture = ProductService().getAllProducts();

    // Récupère l'accessToken depuis Supabase Auth
    final accessToken =
        Supabase.instance.client.auth.currentSession?.accessToken;

    // Initialise ApiFetcher avec le token
    _apiFetcher = ApiFetcher(
      baseUrl: 'http://10.0.2.2:4000',
      accessToken: accessToken, // Token envoyé automatiquement dans les headers
    );

    _loadConsumerId();
  }

  Future<void> _loadConsumerId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('consumer_id');
    setState(() => _consumerId = id);
  }

  Future<void> _resetConsumerId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('consumer_id');
    setState(() => _consumerId = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.profileReset)),
    );
  }

  Future<void> _createConsumer({
    required String name,
    required String phone,
    String? location,
  }) async {
    try {
      final response = await _apiFetcher.post(
        'consumer', // nouvel endpoint
        body: {
          "name": name,
          "phone": phone,
          "location": location ?? "",
        },
      );

      if (!mounted) return;

      if (response.isSuccess && response.data['success'] == true) {
        final consumerId = response.data['user']['id'] as String;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('consumer_id', consumerId);
        setState(() => _consumerId = consumerId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.profileCreated),
            backgroundColor: Colors.teal,
          ),
        );
      } else {
        throw Exception(response.error ?? "Erreur inconnue");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.orderFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showConsumerForm(VoidCallback onComplete) async {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final locationCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.completeProfile),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.profileInfoOnce),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: l10n.fullName),
              ),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: l10n.phone),
              ),
              TextField(
                controller: locationCtrl,
                decoration: InputDecoration(labelText: l10n.neighborhood),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty &&
                  phoneCtrl.text.trim().isNotEmpty) {
                Navigator.pop(ctx, true);
              }
            },
            child: Text(l10n.createProfile),
          ),
        ],
      ),
    );

    if (result == true) {
      await _createConsumer(
        name: nameCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        location: locationCtrl.text.trim(),
      );
      onComplete();
    }
  }

  void _openChat(Product product) async {
    if (_consumerId == null) {
      await _showConsumerForm(() => _openChat(product));
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConsumerChatScreen(
          product: product,
          consumerId: _consumerId!,
        ),
      ),
    );
  }

  Future<void> _sendRequest(
      Product product, int quantity, String address) async {
    final l10n = AppLocalizations.of(context)!;

    // Récupérer l'ID du consommateur depuis le stockage local
    final String? consumerId = await ConsumerLocalService.getConsumerId();

    if (consumerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorConsumerNotFound),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Insérer la demande dans la table product_requests
      final response =
          await Supabase.instance.client.from('product_requests').insert({
        'consumer_id': consumerId,
        'vendor_id': product.vendorId,
        'product_id': product.id,
        'product_name': product.name,
        'quantity': quantity,
        'price_at_request': product.price,
        'customer_location':
            address.trim().isEmpty ? 'Non précisée' : address.trim(),
        'vendor_shop_name': product.vendorShopName ?? 'Boutique',
      });

      // CORRECTION : Supabase insert() retourne null en succès, ou lance une exception en erreur
      // Donc on ne fait pas response.error → on catch l'exception
      // Si on arrive ici → succès !

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.requestSentSuccess(product.name, quantity)),
          backgroundColor: Colors.teal,
        ),
      );

      // Optionnel : ouvrir le chat directement après la demande
      // Navigator.push(...);
    } on PostgrestException catch (e) {
      print("Erreur Supabase envoi demande : ${e.message}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.requestSentFailed),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      print("Erreur inattendue envoi demande : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.requestSentFailed),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showOrderDialog(Product product) async {
    final l10n = AppLocalizations.of(context)!;
    // Si le consumer n'est pas encore créé → on le force à remplir ses infos
    if (_consumerId == null) {
      await _showConsumerForm(() => _showOrderDialog(product));
      return;
    }

    final quantityController = TextEditingController();
    final addressCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // State pour forcer le rebuild quand la quantité change
    int currentQuantity = 10; // valeur initiale

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l10n.requestProduct(product.name)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message quantité minimale
                Text(
                  l10n.minQuantityWarning,
                  style: const TextStyle(
                      color: Colors.orange, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                // Affichage du prix total (dynamique)
                Text(
                  "${l10n.totalPrice}: ${(currentQuantity * product.price).toStringAsFixed(0)} MRU",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 16),

                // Champ quantité
                TextFormField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.quantityKg,
                    suffixText: l10n.kilogram,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (value) {
                    final qty = int.tryParse(value) ?? 10;
                    setStateDialog(() {
                      currentQuantity = qty < 10
                          ? 10
                          : qty; // ne descend pas en dessous de 10
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return l10n.fieldRequired;
                    final qty = int.tryParse(value);
                    if (qty == null || qty < 10) return l10n.minQuantityError;
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Adresse
                TextFormField(
                  controller: addressCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.deliveryAddress,
                    hintText: "",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: Text(l10n.request),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final quantity = int.tryParse(quantityController.text) ?? 10;
      final address = addressCtrl.text;
      await _sendRequest(product, quantity, address);
    }
  }

  void _refresh() {
    setState(() {
      _productsFuture = ProductService().getAllProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.marketTitle),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          actions: [
            // === NOUVEAU BOUTON : Accès à Mes commandes ===
            IconButton(
              icon: const Icon(Icons
                  .shopping_bag_outlined), // ou Icons.receipt_long, Icons.list_alt
              tooltip: l10n.myRequests ?? "Mes commandes",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ConsumerOrdersPage()),
                );
              },
            ),
            // On enlève tout ici → tout passe dans le Drawer
            // Tu peux garder un simple refresh si tu veux le garder visible
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refresh,
              tooltip: 'Actualiser',
            ),
          ],
          // Ajoute l'icône du menu pour ouvrir le Drawer
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        drawer: Drawer(
          backgroundColor: Colors.white,
          child: Consumer<LocaleProvider>(
            builder: (context, localeProvider, child) {
              final l10n = AppLocalizations.of(context)!;
              final currentLang = localeProvider.locale.languageCode;

              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  // // En-tête du Drawer
                  // DrawerHeader(
                  //   decoration: BoxDecoration(
                  //     gradient: LinearGradient(
                  //       colors: [Colors.teal.shade700, Colors.teal.shade500],
                  //       begin: Alignment.topLeft,
                  //       end: Alignment.bottomRight,
                  //     ),
                  //   ),
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     mainAxisAlignment: MainAxisAlignment.end,
                  //     children: [
                  //       const CircleAvatar(
                  //         radius: 30,
                  //         backgroundColor: Colors.white,
                  //         child: Icon(Icons.person, size: 40, color: Colors.teal),
                  //       ),
                  //       const SizedBox(height: 12),
                  //       Text(
                  //         l10n.guestUser, // ou récupère le nom si connecté
                  //         style: const TextStyle(
                  //           color: Colors.white,
                  //           fontSize: 20,
                  //           fontWeight: FontWeight.bold,
                  //         ),
                  //       ),
                  //       Text(
                  //         l10n.consumerMode,
                  //         style: TextStyle(
                  //           color: Colors.white.withOpacity(0.8),
                  //           fontSize: 14,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),

                  // === Changer la langue ===
                  ListTile(
                    leading: const Icon(Icons.language, color: Colors.teal),
                    title: Text(l10n.changeLanguage),
                    // trailing: Text(
                    //   currentLang == 'fr' ? 'Français' : 'العربية',
                    //   style: const TextStyle(fontWeight: FontWeight.w600),
                    // ),
                    onTap: () {
                      final newLocale = currentLang == 'fr'
                          ? const Locale('ar')
                          : const Locale('fr');
                      localeProvider.changeLocale(newLocale);
                      Navigator.pop(context); // Ferme le drawer
                    },
                  ),

                  // === Actualiser ===
                  ListTile(
                    leading: const Icon(Icons.refresh, color: Colors.blue),
                    title: Text(l10n.refresh),
                    onTap: () {
                      _refresh();
                      Navigator.pop(context);
                    },
                  ),
                  // const SizedBox(height: 30,),

                  // === Connexion / Inscription ===
                  ListTile(
                    leading: const Icon(Icons.login, color: Colors.orange),
                    title: Text(l10n.login),
                    subtitle: Text(l10n.loginToAccessMore),
                    onTap: () {
                      Navigator.pop(context); // Ferme le drawer
                      Navigator.of(context).pushNamed('/login');
                    },
                  ),

                  // === Optionnel : Effacer les données locales (décommenter si besoin) ===
                  // ListTile(
                  //   leading: const Icon(Icons.delete_forever, color: Colors.red),
                  //   title: const Text("Effacer mes données locales"),
                  //   onTap: () async {
                  //     await ConsumerLocalService.clear();
                  //     if (mounted) {
                  //       ScaffoldMessenger.of(context).showSnackBar(
                  //         const SnackBar(content: Text("Données locales effacées")),
                  //       );
                  //     }
                  //     Navigator.pop(context);
                  //   },
                  // ),

                  const Divider(),

                  // Pied de page
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      AppLocalizations.of(context)!.marketTitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        body: FutureBuilder<List<Product>>(
          future: _productsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final products = snapshot.data ?? [];
            if (products.isEmpty) {
              return Center(
                  child: Text(AppLocalizations.of(context)!.noProducts));
            }

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.62,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: products.length,
              itemBuilder: (_, i) {
                final p = products[i];
                return Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                          child: p.imageUrl != null
                              ? Image.network(p.imageUrl!, fit: BoxFit.cover)
                              : Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image, size: 60)),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              Text("${p.price.toStringAsFixed(0)} MRU/kg",
                                  style: const TextStyle(
                                      color: Colors.teal,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _showOrderDialog(p),
                                      icon: const Icon(
                                          Icons.shopping_cart_outlined,
                                          size: 14,
                                          color: Colors.white),
                                      label: Text(
                                          AppLocalizations.of(context)!.order,
                                          style: const TextStyle(
                                              fontSize: 9,
                                              color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () => _openChat(p),
                                          icon: const Icon(
                                              Icons.chat_bubble_outline,
                                              size: 14),
                                          label: Text(
                                              AppLocalizations.of(context)!
                                                  .chat,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white)),
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.teal,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8)),
                                        ),
                                        // Badge non-lus (optionnel)
                                        if (_consumerId != null)
                                          FutureBuilder<int>(
                                            future: Supabase.instance.client
                                                .from('messages')
                                                .count()
                                                .eq('consumer_id', _consumerId!)
                                                .eq('vendor_id', p.vendorId)
                                                .eq('sender_type', 'vendor')
                                                .eq('read', false),
                                            builder: (context, snap) {
                                              final count = snap.data ?? 0;
                                              if (count == 0)
                                                return const SizedBox();
                                              return Positioned(
                                                right: 4,
                                                top: 4,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  decoration:
                                                      const BoxDecoration(
                                                          color: Colors.red,
                                                          shape:
                                                              BoxShape.circle),
                                                  child: Text(count.toString(),
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10)),
                                                ),
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ========================================
// CONSUMER CHAT SCREEN (inchangée, mais avec _consumerId dynamique)
// ========================================
// presentation/pages/chat/consumer_chat_screen.dart

// presentation/pages/chat/consumer_chat_screen.dart

class ConsumerChatScreen extends StatefulWidget {
  final Product product;
  final String consumerId;

  const ConsumerChatScreen({
    super.key,
    required this.product,
    required this.consumerId,
  });

  @override
  State<ConsumerChatScreen> createState() => _ConsumerChatScreenState();
}

class _ConsumerChatScreenState extends State<ConsumerChatScreen> {
  final List<types.Message> _messages = [];

  late final types.User _consumer;
  late final types.User _vendor;

  late final RealtimeChannel _channel;

  @override
  void initState() {
    super.initState();

    _consumer = types.User(id: widget.consumerId);
    _vendor = types.User(
      id: widget.product.vendorId,
      firstName: widget.product.vendorShopName ?? 'Vendeur',
    );

    _loadMessages();
    _subscribeRealtime();
  }

  // ---------------------------
  // LOAD HISTORY (WhatsApp order)
  // ---------------------------
  Future<void> _loadMessages() async {
    final data = await Supabase.instance.client
        .from('messages')
        .select()
        .eq('consumer_id', widget.consumerId)
        .eq('vendor_id', widget.product.vendorId)
        .order('created_at', ascending: true);

    final messages = data.map<types.TextMessage>(_mapRowToMessage).toList();

    if (mounted) {
      setState(() {
        _messages
          ..clear()
          ..addAll(messages.reversed);
      });
    }

    _markVendorMessagesAsRead();
  }

  // ---------------------------
  // REALTIME
  // ---------------------------
  void _subscribeRealtime() {
    _channel = Supabase.instance.client
        .channel(
          'consumer_chat_${widget.consumerId}_${widget.product.vendorId}',
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final msg = payload.newRecord;

            if (!_isForThisChat(msg)) return;

            final newMessage = _mapRowToMessage(msg);

            if (mounted) {
              setState(() {
                _messages.insert(0, newMessage);
              });
            }

            if (msg['sender_type'] == 'vendor') {
              _markVendorMessagesAsRead();
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final msg = payload.newRecord;

            if (!_isForThisChat(msg)) return;

            final index = _messages.indexWhere(
              (m) => m.id == msg['id'].toString(),
            );

            if (index != -1 && mounted) {
              setState(() {
                _messages[index] =
                    (_messages[index] as types.TextMessage).copyWith(
                  status: types.Status.seen,
                );
              });
            }
          },
        )
        .subscribe();
  }

  bool _isForThisChat(Map<String, dynamic> msg) {
    return msg['consumer_id'] == widget.consumerId &&
        msg['vendor_id'] == widget.product.vendorId;
  }

  // ---------------------------
  // SEND MESSAGE (Realtime handles UI)
  // ---------------------------
  Future<void> _handleSendPressed(types.PartialText message) async {
    await Supabase.instance.client.from('messages').insert({
      'text': message.text,
      'sender_type': 'consumer',
      'consumer_id': widget.consumerId,
      'vendor_id': widget.product.vendorId,
      'product_id': widget.product.id,
      'read': false,
    });
  }

  // ---------------------------
  // MARK VENDOR MESSAGES AS READ
  // ---------------------------
  Future<void> _markVendorMessagesAsRead() async {
    await Supabase.instance.client
        .from('messages')
        .update({'read': true})
        .eq('consumer_id', widget.consumerId)
        .eq('vendor_id', widget.product.vendorId)
        .eq('sender_type', 'vendor')
        .eq('read', false);
  }

  // ---------------------------
  // MAP DB → CHAT MESSAGE
  // ---------------------------
  types.TextMessage _mapRowToMessage(Map<String, dynamic> msg) {
    final isVendor = msg['sender_type'] == 'vendor';
    final isRead = msg['read'] == true;

    return types.TextMessage(
      id: msg['id'].toString(),
      text: msg['text'],
      author: isVendor ? _vendor : _consumer,
      createdAt: DateTime.parse(msg['created_at']).millisecondsSinceEpoch,
      status: isVendor
          ? (isRead ? types.Status.seen : types.Status.delivered)
          : types.Status.sent,
    );
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(_channel);
    super.dispose();
  }

  // ---------------------------
  // UI
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.product.vendorShopName ?? l10n.unknownVendor),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        body: Chat(
          messages: _messages,
          onSendPressed: _handleSendPressed,
          user: _consumer,
          showUserAvatars: true,
          showUserNames: true,
          // scrollToBottom: true,
          theme: DefaultChatTheme(
            primaryColor: Colors.teal,
            inputBackgroundColor: Colors.white,
            inputTextColor: Colors.black87,
            sentMessageBodyTextStyle: const TextStyle(color: Colors.white),
            receivedMessageBodyTextStyle:
                const TextStyle(color: Colors.black87),
            backgroundColor: const Color(0xFFF1F3F5),
            inputMargin: const EdgeInsets.all(12),
            inputBorderRadius: BorderRadius.circular(30),
            inputElevation: 8,
          ),
          emptyState: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline,
                    size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                Text(l10n.noMessagesYet),
                Text(
                  l10n.startConversation,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
