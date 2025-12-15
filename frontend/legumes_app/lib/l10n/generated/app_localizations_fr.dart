import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get hello => 'Bonjour';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mot de passe';

  @override
  String get login => 'Se connecter';

  @override
  String get connexionAuMarche => 'Connexion au Marché Légumes 🥕';

  @override
  String get register => 'S\'inscrire';

  @override
  String get noAccount => 'Pas encore de compte ? S’inscrire';

  @override
  String get haveAccount => 'Vous avez déjà un compte ? Se connecter';

  @override
  String get name => 'Nom complet';

  @override
  String get shopName => 'Nom de la boutique';

  @override
  String get phone => 'Téléphone';

  @override
  String get location => 'Localisation';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get passwordMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get passwordTooShort => 'Mot de passe trop court (minimum 6 caractères)';

  @override
  String get invalidEmail => 'Entrez un email valide';

  @override
  String get invalidNom => 'Nom trop court (minimum 3 caractères)';

  @override
  String get invalidPhone => 'Numéro de téléphone invalide';

  @override
  String get loading => 'Chargement...';

  @override
  String get marketTitle => 'Marché Local';

  @override
  String get tagline => 'Les meilleurs produits près de chez vous';

  @override
  String get allProducts => 'Tous les produits';

  @override
  String get myProducts => 'Mes produits';

  @override
  String get refresh => 'Actualiser';

  @override
  String get noProducts => 'Aucun produit disponible';

  @override
  String get errorOccurred => 'Une erreur est survenue';

  @override
  String get completeProfile => 'Complétez votre profil';

  @override
  String get profileInfoOnce => 'Ces informations ne seront demandées qu\'une seule fois';

  @override
  String get fullName => 'Nom complet';

  @override
  String get neighborhood => 'Quartier / Ville (optionnel)';

  @override
  String get cancel => 'Annuler';

  @override
  String get createProfile => 'Créer mon profil';

  @override
  String get profileCreated => 'Profil créé avec succès !';

  @override
  String get profileReset => 'Profil réinitialisé pour test';

  @override
  String orderProduct(Object productName) {
    return 'Commander $productName';
  }

  @override
  String pricePerKg(Object price) {
    return 'Prix : $price MRU / kg';
  }

  @override
  String get quantityKg => 'Quantité (kg)';

  @override
  String get deliveryAddress => 'Adresse de livraison';

  @override
  String get fillFields => 'Veuillez remplir tous les champs correctement';

  @override
  String get order => 'Commander';

  @override
  String get orderSent => 'Demande envoyée ! Le vendeur vous répondra bientôt';

  @override
  String get orderFailed => 'Échec de l\'envoi';

  @override
  String get vendorDashboard => 'Tableau de bord vendeur';

  @override
  String get profileLogout => 'Profil / Déconnexion';

  @override
  String get logout => 'Déconnexion';

  @override
  String get logoutConfirm => 'Voulez-vous vraiment vous déconnecter ?';

  @override
  String get totalProducts => 'Produits totaux';

  @override
  String get totalStock => 'Stock total';

  @override
  String get addProduct => 'Ajouter un produit';

  @override
  String get marketProducts => 'Produits du marché';

  @override
  String get myConversations => 'Mes conversations';

  @override
  String get myRequests => 'Mes demandes';

  @override
  String get lastUpdate => 'Dernière mise à jour';

  @override
  String get chat => 'Messagerie';

  @override
  String get noMessages => 'Aucun message';

  @override
  String get typeMessage => 'Écrivez votre message...';

  @override
  String get noProductsAddHint => 'Aucun produit\nAppuyez sur + pour ajouter';

  @override
  String price(Object price) {
    return 'Prix : $price MRU';
  }

  @override
  String stock(Object quantity) {
    return 'Stock : $quantity K';
  }

  @override
  String productDate(Object date) {
    return 'Date : $date';
  }

  @override
  String get updatePrice => 'Mettre à jour le prix';

  @override
  String updatePriceTitle(Object productName) {
    return 'Nouveau prix – $productName';
  }

  @override
  String get update => 'Mettre à jour';

  @override
  String priceUpdated(Object price) {
    return 'Prix mis à jour : $price MRU';
  }

  @override
  String get priceUpdateFailed => 'Échec de la mise à jour';

  @override
  String get deleteProduct => 'Supprimer le produit';

  @override
  String get deleteProductConfirm => 'Cette action est irréversible.';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get retry => 'Réessayer';

  @override
  String get productName => 'Nom du produit';

  @override
  String get priceMRU => 'Prix (MRU)';

  @override
  String get selectPhoto => 'Sélectionner une photo';

  @override
  String get photoSelected => 'Photo sélectionnée';

  @override
  String get createProduct => 'Créer le produit';

  @override
  String get fieldRequired => 'Champ obligatoire';

  @override
  String get invalidPrice => 'Prix invalide';

  @override
  String get invalidQuantity => 'Quantité invalide';

  @override
  String get productCreatedSuccess => 'Produit créé avec succès !';

  @override
  String get productCreatedFailed => 'Échec de la création du produit';

  @override
  String get productUpdatedSuccess => 'Produit mis à jour avec succès !';

  @override
  String get productUpdateFailed => 'Échec de la mise à jour du produit';

  @override
  String get editProduct => 'Modifier le produit';

  @override
  String get changePhoto => 'Changer la photo';

  @override
  String get newPhotoSelected => 'Nouvelle photo sélectionnée';

  @override
  String vendorBy(Object vendorName) {
    return 'Par : $vendorName';
  }

  @override
  String get unknownVendor => 'Vendeur inconnu';

  @override
  String get noRequestsYet => 'Aucune demande pour le moment';

  @override
  String requestFrom(Object customerName) {
    return 'Demande de $customerName';
  }

  @override
  String get unknownCustomer => 'Client inconnu';

  @override
  String requestedAt(Object time) {
    return 'Reçue le $time';
  }

  @override
  String get statusPending => 'En attente';

  @override
  String get statusAccepted => 'Acceptée';

  @override
  String get statusRejected => 'Refusée';

  @override
  String get unknownStatus => 'Inconnu';

  @override
  String get accept => 'Accepter';

  @override
  String get reject => 'Refuser';

  @override
  String addressLabel(Object location) {
    return 'Adresse : $location';
  }

  @override
  String get notSpecified => 'Non précisée';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get noConversations => 'Aucune conversation';

  @override
  String get messagesWillAppearHere => 'Les messages de vos clients apparaîtront ici';

  @override
  String get youPrefix => 'Vous : ';

  @override
  String get unknownClient => 'Client inconnu';

  @override
  String get yesterday => 'Hier';

  @override
  String get phonePrefix => 'Tél';

  @override
  String get noMessagesYet => 'Aucun message pour le moment';

  @override
  String get startConversation => 'Commencez la conversation !';

  @override
  String get messageSendFailed => 'Échec de l\'envoi du message';

  @override
  String totalProductsCount(Object count) {
    return '$count produit(s)';
  }

  @override
  String totalStockKg(Object kg) {
    return '$kg kg en stock';
  }

  @override
  String get clientsWillContactSoon => 'Vos clients vous contacteront bientôt !';
}
