// presentation/pages/consumer/consumer_home_page.dart

import 'package:flutter/material.dart';
import 'package:legumes_app/core/services/consumer_local_service.dart';
import 'package:legumes_app/core/services/unread_messages_service.dart';
import 'package:legumes_app/data/models/product_model.dart';
import 'package:legumes_app/data/services/product_service.dart';
import 'package:legumes_app/presentation/screens/home/login_page.dart';
import 'package:legumes_app/presentation/screens/vendor/vendor_chat_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class ConsumerHomePage extends StatefulWidget {
  const ConsumerHomePage({super.key});
  @override
  State<ConsumerHomePage> createState() => _ConsumerHomePageState();
}

class _ConsumerHomePageState extends State<ConsumerHomePage> {
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = ProductService().getAllProducts();
  }

  Future<void> _refresh() async {
    setState(() => _productsFuture = ProductService().getAllProducts());
  }

  void _openChat(Product product) async {
    String? consumerId = await ConsumerLocalService.getConsumerId();

    // Si on a déjà les infos → on ouvre direct le chat
    if (consumerId != null) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConsumerChatScreen(
            product: product,
            consumerId: consumerId!,
          ),
        ),
      );
      return;
    }

    // Sinon → on demande une seule fois
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Bienvenue ! Entrez vos coordonnées"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                "Ces informations ne seront demandées qu'une seule fois"),
            const SizedBox(height: 16),
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Nom")),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Téléphone"),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty &&
                  phoneCtrl.text.trim().isNotEmpty) {
                Navigator.pop(ctx, "ok");
              }
            },
            child: const Text("Continuer"),
          ),
        ],
      ),
    );

    if (result != "ok") return;

    try {
      final consumerRes = await Supabase.instance.client
          .from('consumers')
          .insert({
            'name': nameCtrl.text.trim(),
            'phone': phoneCtrl.text.trim(),
          })
          .select()
          .single();

      consumerId = consumerRes['id'].toString();

      // SAUVEGARDE EN LOCAL POUR NE PLUS JAMAIS DEMANDER
      await ConsumerLocalService.saveConsumerInfo(
        name: nameCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        consumerId: consumerId,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConsumerChatScreen(
            product: product,
            consumerId: consumerId!,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : $e")),
        );
      }
    }
  }

  Future<void> _showOrderDialog(Product product) async {
    // 1. On essaie de récupérer les infos déjà sauvegardées
    final localInfo = await ConsumerLocalService.getConsumerInfo();
    String? consumerId = await ConsumerLocalService.getConsumerId();

    final nameCtrl = TextEditingController(text: localInfo?['name'] ?? '');
    final phoneCtrl = TextEditingController(text: localInfo?['phone'] ?? '');
    final locationCtrl = TextEditingController();
    final quantityCtrl = TextEditingController();

    // Si on n'a PAS encore les infos → on force le dialog complet (première fois)
    if (localInfo == null || consumerId == null) {
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Commander en quelques secondes",
              textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: product.imageUrl != null
                      ? NetworkImage(product.imageUrl!)
                      : null,
                  child: product.imageUrl == null
                      ? const Icon(Icons.shopping_basket, size: 30)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(product.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text("${product.price.toStringAsFixed(0)} MRU/kg",
                    style: const TextStyle(
                        fontSize: 20,
                        color: Colors.green,
                        fontWeight: FontWeight.bold)),
                const Divider(height: 32),
                const Text("Vos coordonnées (une seule fois)",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: "Nom complet",
                        prefixIcon: Icon(Icons.person))),
                TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                        labelText: "Téléphone", prefixIcon: Icon(Icons.phone))),
                TextField(
                    controller: locationCtrl,
                    decoration: const InputDecoration(
                        labelText: "Quartier / Adresse",
                        prefixIcon: Icon(Icons.location_on))),
                const SizedBox(height: 12),
                TextField(
                    controller: quantityCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: "Quantité (kg)",
                        prefixIcon: Icon(Icons.scale))),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Annuler")),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty &&
                    phoneCtrl.text.trim().isNotEmpty &&
                    locationCtrl.text.trim().isNotEmpty &&
                    quantityCtrl.text.trim().isNotEmpty) {
                  Navigator.pop(ctx, "ok");
                }
              },
              child: const Text("Commander"),
            ),
          ],
        ),
      );

      if (result != "ok") return;

      // Créer le consommateur dans Supabase + sauvegarde locale
      try {
        final consumerRes = await Supabase.instance.client
            .from('consumers')
            .insert({
              'name': nameCtrl.text.trim(),
              'phone': phoneCtrl.text.trim(),
            })
            .select()
            .single();

        consumerId = consumerRes['id'].toString();

        // SAUVEGARDE EN LOCAL → plus jamais demandé !
        await ConsumerLocalService.saveConsumerInfo(
          name: nameCtrl.text.trim(),
          phone: phoneCtrl.text.trim(),
          consumerId: consumerId,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Erreur création consommateur : $e")));
        }
        return;
      }
    } else {
      // CAS 2 : Infos déjà sauvegardées → dialog rapide (seulement quantité + adresse)
      final quickResult = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("Commander ${product.name}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Connecté comme : ${localInfo['name']}"),
              Text("Téléphone : ${localInfo['phone']}"),
              const Divider(),
              TextField(
                controller: quantityCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: "Quantité désirée (kg)"),
                autofocus: true,
              ),
              TextField(
                controller: locationCtrl,
                decoration:
                    const InputDecoration(labelText: "Adresse de livraison"),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Annuler")),
            ElevatedButton(
              onPressed: () {
                if (quantityCtrl.text.trim().isNotEmpty &&
                    locationCtrl.text.trim().isNotEmpty) {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text("Envoyer la demande"),
            ),
          ],
        ),
      );

      if (quickResult != true) return;
    }

    // ENVOI DE LA COMMANDE (les deux cas arrivent ici)
    try {
      await Supabase.instance.client.from('product_requests').insert({
        'product_id': product.id,
        'product_name': product.name,
        'vendor_id': product.vendorId,
        'consumer_id': consumerId,
        'quantity': double.tryParse(quantityCtrl.text) ?? 1,
        'price_at_request': product.price,
        // 'customer_name': nameCtrl.text.trim(),
        // 'customer_phone': phoneCtrl.text.trim(),
        'vendor_shop_name': product.vendorShopName ?? 'Boutique',
        'customer_location': locationCtrl.text.trim(),
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Demande envoyée avec succès ! Le vendeur vous répondra bientôt"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Échec de l'envoi : $e"),
              backgroundColor: Colors.red),
        );
        print("error : $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Marché Local"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pushNamed('/login'),
            icon: const Icon(Icons.login, color: Colors.white),
            label: const Text('Se connecter',
                style: TextStyle(color: Colors.white)),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(child: Text("Aucun produit"));
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
              final phone = p.vendorPhone ?? "Non renseigné";

              return Card(
                elevation: 8,
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
                                    fontWeight: FontWeight.bold, fontSize: 15),
                                maxLines: 1),
                            Text("${p.price.toStringAsFixed(0)} MRU",
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            // const SizedBox(height: 6),
                            // Text(p.vendorShopName ?? "Boutique",
                            //     style: const TextStyle(
                            //         fontSize: 13, fontWeight: FontWeight.w600)),
                            // Text("Tel: $phone",
                            //     style: TextStyle(
                            //         fontSize: 12, color: Colors.grey[700])),
                            // const Spacer(),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showOrderDialog(p),
                                    icon: const Icon(
                                        Icons.shopping_cart_outlined,
                                        size: 16),
                                    label: const Text("Commander",
                                        style: TextStyle(fontSize: 8)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Stack(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _openChat(p),
                                      icon: const Icon(
                                          Icons.chat_bubble_outline,
                                          size: 16),
                                      label: const Text("Chat",
                                          style: TextStyle(fontSize: 11)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                    ),
                                    // Badge pour le consommateur
                                    FutureBuilder<int>(
                                      future:
                                          ConsumerLocalService.getConsumerId()
                                              .then((id) async {
                                        if (id == null) return 0;
                                        return await UnreadMessagesService
                                            .getUnreadCountForConsumer(id);
                                      }),
                                      builder: (context, snapshot) {
                                        final count = snapshot.data ?? 0;
                                        if (count == 0) return const SizedBox();
                                        return Positioned(
                                          right: 6,
                                          top: 6,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            constraints: const BoxConstraints(
                                                minWidth: 18, minHeight: 18),
                                            child: Text(
                                              count > 99
                                                  ? "99+"
                                                  : count.toString(),
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
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
    );
  }
}

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
  List<types.Message> _messages = [];
  late final types.User _consumer;
  late final types.User _vendor;

  @override
  void initState() {
    super.initState();
    _consumer = types.User(id: widget.consumerId);
    _vendor = types.User(
      id: widget.product.vendorId,
      firstName: widget.product.vendorShopName ?? "Vendeur",
    );
    _markVendorMessagesAsRead();
    _loadMessages();
    _listenToRealtime();
  }

  Future<void> _loadMessages() async {
    try {
      final response = await Supabase.instance.client
          .from('messages')
          .select()
          .eq('consumer_id', widget.consumerId)
          .eq('vendor_id', widget.product.vendorId)
          .order('created_at', ascending: true);

      final List<types.Message> loaded = response.map<types.TextMessage>((msg) {
        return types.TextMessage(
          author: msg['sender_type'] == 'vendor' ? _vendor : _consumer,
          createdAt: DateTime.parse(msg['created_at']).millisecondsSinceEpoch,
          id: msg['id'].toString(),
          text: msg['text'],
        );
      }).toList();

      if (mounted) {
        setState(() {
          _messages = loaded.reversed.toList(); // WhatsApp style
        });
      }
    } catch (e) {
      debugPrint("Erreur chargement messages: $e");
    }
  }

  void _listenToRealtime() {
    Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('vendor_id', widget.product.vendorId)
        .listen((_) => _loadMessages());
  }

  void _handleSendPressed(types.PartialText message) async {
    final tempMessage = types.TextMessage(
      author: _consumer,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: message.text,
    );

    // Affichage IMMÉDIAT du message envoyé
    setState(() {
      _messages = [tempMessage, ..._messages]; // nouveau en haut
    });

    try {
      await Supabase.instance.client.from('messages').insert({
        'text': message.text,
        'sender_type': 'consumer',
        'consumer_id': widget.consumerId,
        'vendor_id': widget.product.vendorId,
        'product_id': widget.product.id,
      });
      // Le stream rechargera automatiquement → pas besoin de faire plus
    } catch (e) {
      setState(() {
        _messages.removeWhere((m) => m.id == tempMessage.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Échec de l'envoi"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _markVendorMessagesAsRead() async {
    try {
      await Supabase.instance.client
          .from('messages')
          .update({'read': true})
          .eq('consumer_id', widget.consumerId)
          .eq('vendor_id', widget.product.vendorId)
          .eq('sender_type', 'vendor')
          .eq('read',
              false); // seulement les non lus (mais même si déjà lus, ça ne change rien)
    } catch (e) {
      debugPrint("Erreur marquage messages comme lus (consommateur): $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.product.vendorShopName ?? "Vendeur"),
            Text(
              "Tel: ${widget.product.vendorPhone ?? 'Non renseigné'}",
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Chat(
        messages: _messages,
        onSendPressed: _handleSendPressed,
        user: _consumer,
        theme: const DefaultChatTheme(
          primaryColor: Colors.green,
          inputBackgroundColor: Colors.black,
          sendButtonIcon:
              Icon(Icons.send, color: Colors.white), // PLUS BESOIN D'ASSETS !
          sentMessageBodyTextStyle: TextStyle(color: Colors.white),
          receivedMessageBodyTextStyle: TextStyle(color: Colors.black87),
        ),
      ),
    );
  }
}
