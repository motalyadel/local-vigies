import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @connexionAuMarche.
  ///
  /// In en, this message translates to:
  /// **'Login to Vegetable Market 🥕'**
  String get connexionAuMarche;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get register;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get noAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get haveAccount;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get name;

  /// No description provided for @shopName.
  ///
  /// In en, this message translates to:
  /// **'Shop Name'**
  String get shopName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password too short (min 6 characters)'**
  String get passwordTooShort;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get invalidEmail;

  /// No description provided for @invalidNom.
  ///
  /// In en, this message translates to:
  /// **'Name too short (min 3 characters)'**
  String get invalidNom;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get invalidPhone;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @marketTitle.
  ///
  /// In en, this message translates to:
  /// **'Local Market'**
  String get marketTitle;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'The best products near you'**
  String get tagline;

  /// No description provided for @allProducts.
  ///
  /// In en, this message translates to:
  /// **'All Products'**
  String get allProducts;

  /// No description provided for @myProducts.
  ///
  /// In en, this message translates to:
  /// **'My Products'**
  String get myProducts;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @noProducts.
  ///
  /// In en, this message translates to:
  /// **'No products available'**
  String get noProducts;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get completeProfile;

  /// No description provided for @profileInfoOnce.
  ///
  /// In en, this message translates to:
  /// **'This information will only be asked once'**
  String get profileInfoOnce;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @neighborhood.
  ///
  /// In en, this message translates to:
  /// **'Neighborhood / City (optional)'**
  String get neighborhood;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @createProfile.
  ///
  /// In en, this message translates to:
  /// **'Create my profile'**
  String get createProfile;

  /// No description provided for @profileCreated.
  ///
  /// In en, this message translates to:
  /// **'Profile created successfully!'**
  String get profileCreated;

  /// No description provided for @profileReset.
  ///
  /// In en, this message translates to:
  /// **'Profile reset for testing'**
  String get profileReset;

  /// No description provided for @orderProduct.
  ///
  /// In en, this message translates to:
  /// **'Order {productName}'**
  String orderProduct(Object productName);

  /// No description provided for @pricePerKg.
  ///
  /// In en, this message translates to:
  /// **'Price: {price} MRU / kg'**
  String pricePerKg(Object price);

  /// No description provided for @quantityKg.
  ///
  /// In en, this message translates to:
  /// **'Quantity (kg)'**
  String get quantityKg;

  /// No description provided for @deliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery address'**
  String get deliveryAddress;

  /// No description provided for @fillFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields correctly'**
  String get fillFields;

  /// No description provided for @order.
  ///
  /// In en, this message translates to:
  /// **'Order Now'**
  String get order;

  /// No description provided for @orderSent.
  ///
  /// In en, this message translates to:
  /// **'Order sent! The seller will contact you soon'**
  String get orderSent;

  /// No description provided for @orderFailed.
  ///
  /// In en, this message translates to:
  /// **'Sending failed'**
  String get orderFailed;

  /// No description provided for @vendorDashboard.
  ///
  /// In en, this message translates to:
  /// **'Vendor Dashboard'**
  String get vendorDashboard;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Profile / Logout'**
  String get profileLogout;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirm;

  /// No description provided for @totalProducts.
  ///
  /// In en, this message translates to:
  /// **'Total Products'**
  String get totalProducts;

  /// No description provided for @totalStock.
  ///
  /// In en, this message translates to:
  /// **'Total Stock'**
  String get totalStock;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @marketProducts.
  ///
  /// In en, this message translates to:
  /// **'Market Products'**
  String get marketProducts;

  /// No description provided for @myConversations.
  ///
  /// In en, this message translates to:
  /// **'My Conversations'**
  String get myConversations;

  /// No description provided for @myRequests.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get myRequests;

  /// No description provided for @lastUpdate.
  ///
  /// In en, this message translates to:
  /// **'Last update'**
  String get lastUpdate;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @noMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages'**
  String get noMessages;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get typeMessage;

  /// No description provided for @noProductsAddHint.
  ///
  /// In en, this message translates to:
  /// **'No products yet\nTap + to add one'**
  String get noProductsAddHint;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price: {price} MRU'**
  String price(Object price);

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock: {quantity} K'**
  String stock(Object quantity);

  /// No description provided for @productDate.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String productDate(Object date);

  /// No description provided for @updatePrice.
  ///
  /// In en, this message translates to:
  /// **'Update Price'**
  String get updatePrice;

  /// No description provided for @updatePriceTitle.
  ///
  /// In en, this message translates to:
  /// **'New price – {productName}'**
  String updatePriceTitle(Object productName);

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @priceUpdated.
  ///
  /// In en, this message translates to:
  /// **'Price updated: {price} MRU'**
  String priceUpdated(Object price);

  /// No description provided for @priceUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get priceUpdateFailed;

  /// No description provided for @deleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Delete Product'**
  String get deleteProduct;

  /// No description provided for @deleteProductConfirm.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteProductConfirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @priceMRU.
  ///
  /// In en, this message translates to:
  /// **'Price (MRU)'**
  String get priceMRU;

  /// No description provided for @selectPhoto.
  ///
  /// In en, this message translates to:
  /// **'Select Photo'**
  String get selectPhoto;

  /// No description provided for @photoSelected.
  ///
  /// In en, this message translates to:
  /// **'Photo selected'**
  String get photoSelected;

  /// No description provided for @createProduct.
  ///
  /// In en, this message translates to:
  /// **'Create Product'**
  String get createProduct;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @invalidPrice.
  ///
  /// In en, this message translates to:
  /// **'Invalid price'**
  String get invalidPrice;

  /// No description provided for @invalidQuantity.
  ///
  /// In en, this message translates to:
  /// **'Invalid quantity'**
  String get invalidQuantity;

  /// No description provided for @productCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product created successfully!'**
  String get productCreatedSuccess;

  /// No description provided for @productCreatedFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create product'**
  String get productCreatedFailed;

  /// No description provided for @productUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product updated successfully!'**
  String get productUpdatedSuccess;

  /// No description provided for @productUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update product'**
  String get productUpdateFailed;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProduct;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get changePhoto;

  /// No description provided for @newPhotoSelected.
  ///
  /// In en, this message translates to:
  /// **'New photo selected'**
  String get newPhotoSelected;

  /// No description provided for @vendorBy.
  ///
  /// In en, this message translates to:
  /// **'By: {vendorName}'**
  String vendorBy(Object vendorName);

  /// No description provided for @unknownVendor.
  ///
  /// In en, this message translates to:
  /// **'Unknown vendor'**
  String get unknownVendor;

  /// No description provided for @noRequestsYet.
  ///
  /// In en, this message translates to:
  /// **'No requests yet'**
  String get noRequestsYet;

  /// No description provided for @requestFrom.
  ///
  /// In en, this message translates to:
  /// **'Request from {customerName}'**
  String requestFrom(Object customerName);

  /// No description provided for @unknownCustomer.
  ///
  /// In en, this message translates to:
  /// **'Unknown customer'**
  String get unknownCustomer;

  /// No description provided for @requestedAt.
  ///
  /// In en, this message translates to:
  /// **'Received at {time}'**
  String requestedAt(Object time);

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @unknownStatus.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownStatus;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'accept'**
  String get accept;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **' refuse'**
  String get reject;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address: {location}'**
  String addressLabel(Object location);

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @messagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesTitle;

  /// No description provided for @noConversations.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversations;

  /// No description provided for @messagesWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your customers\' messages will appear here'**
  String get messagesWillAppearHere;

  /// No description provided for @youPrefix.
  ///
  /// In en, this message translates to:
  /// **'You: '**
  String get youPrefix;

  /// No description provided for @unknownClient.
  ///
  /// In en, this message translates to:
  /// **'Unknown customer'**
  String get unknownClient;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @phonePrefix.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phonePrefix;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'Start the conversation!'**
  String get startConversation;

  /// No description provided for @messageSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message'**
  String get messageSendFailed;

  /// No description provided for @totalProductsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} product(s)'**
  String totalProductsCount(Object count);

  /// No description provided for @totalStockKg.
  ///
  /// In en, this message translates to:
  /// **'{kg} kg in stock'**
  String totalStockKg(Object kg);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
