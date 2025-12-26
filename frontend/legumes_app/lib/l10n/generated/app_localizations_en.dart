import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get hello => 'Hello';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get login => 'Login';

  @override
  String get connexionAuMarche => 'Login to Kheir 🥕';

  @override
  String get register => 'Sign Up';

  @override
  String get noAccount => 'Don\'t have an account? Sign up';

  @override
  String get haveAccount => 'Already have an account? Login';

  @override
  String get name => 'Full Name';

  @override
  String get shopName => 'Shop Name';

  @override
  String get phone => 'Phone';

  @override
  String get location => 'Location';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get passwordTooShort => 'Password too short (min 6 characters)';

  @override
  String get invalidEmail => 'Enter a valid email';

  @override
  String get invalidCredentials => 'Incorrect email or password';

  @override
  String get loginError => 'An error occurred during login';

  @override
  String get invalidNom => 'Name too short (min 3 characters)';

  @override
  String get invalidPhone => 'Invalid phone number';

  @override
  String get loading => 'Loading...';

  @override
  String get marketTitle => 'Kheir Market';

  @override
  String get tagline => 'The best products near you';

  @override
  String get allProducts => 'All Products';

  @override
  String get myProducts => 'My Products';

  @override
  String get refresh => 'Refresh';

  @override
  String get noProducts => 'No products available';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get completeProfile => 'Complete your profile';

  @override
  String get profileInfoOnce => 'This information will only be asked once';

  @override
  String get fullName => 'Full Name';

  @override
  String get neighborhood => 'Neighborhood / City (optional)';

  @override
  String get cancel => 'Cancel';

  @override
  String get createProfile => 'Create my profile';

  @override
  String get profileCreated => 'Profile created successfully!';

  @override
  String get profileReset => 'Profile reset for testing';

  @override
  String orderProduct(Object productName) {
    return 'Order $productName';
  }

  @override
  String get pricePerKg => 'MRU/Kg';

  @override
  String get quantityKg => 'Quantity (kg)';

  @override
  String get deliveryAddress => 'Delivery address';

  @override
  String get fillFields => 'Please fill in all fields correctly';

  @override
  String get order => 'Order Now';

  @override
  String get orderSent => 'Order sent! The seller will contact you soon';

  @override
  String get orderFailed => 'Sending failed';

  @override
  String get vendorDashboard => 'Vendor Dashboard';

  @override
  String get profileLogout => 'Profile / Logout';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirm => 'Are you sure you want to log out?';

  @override
  String get totalProducts => 'Total Products';

  @override
  String get totalStock => 'Total Stock';

  @override
  String get addProduct => 'Add Product';

  @override
  String get marketProducts => 'Market Products';

  @override
  String get myConversations => 'My Conversations';

  @override
  String get myRequests => 'My Requests';

  @override
  String get lastUpdate => 'Last update';

  @override
  String get chat => 'Chat';

  @override
  String get noMessages => 'No messages';

  @override
  String get typeMessage => 'Type your message...';

  @override
  String get noProductsAddHint => 'No products yet\nTap + to add one';

  @override
  String price(Object price) {
    return 'Price: $price MRU';
  }

  @override
  String stock(Object quantity) {
    return 'Stock: $quantity K';
  }

  @override
  String productDate(Object date) {
    return 'Date: $date';
  }

  @override
  String get updatePrice => 'Update Price';

  @override
  String updatePriceTitle(Object productName) {
    return 'New price – $productName';
  }

  @override
  String get update => 'Update';

  @override
  String priceUpdated(Object price) {
    return 'Price updated: $price MRU';
  }

  @override
  String get priceUpdateFailed => 'Update failed';

  @override
  String get deleteProduct => 'Delete Product';

  @override
  String get deleteProductConfirm => 'This action cannot be undone.';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get retry => 'Retry';

  @override
  String get productName => 'Product Name';

  @override
  String get priceMRU => 'Price (MRU)';

  @override
  String get selectPhoto => 'Select Photo';

  @override
  String get photoSelected => 'Photo selected';

  @override
  String get createProduct => 'Create Product';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get invalidPrice => 'Invalid price';

  @override
  String get invalidQuantity => 'Invalid quantity';

  @override
  String get productCreatedSuccess => 'Product created successfully!';

  @override
  String get productCreatedFailed => 'Failed to create product';

  @override
  String get productUpdatedSuccess => 'Product updated successfully!';

  @override
  String get productUpdateFailed => 'Failed to update product';

  @override
  String get editProduct => 'Edit Product';

  @override
  String get changePhoto => 'Change Photo';

  @override
  String get newPhotoSelected => 'New photo selected';

  @override
  String vendorBy(Object vendorName) {
    return 'By: $vendorName';
  }

  @override
  String get unknownVendor => 'Unknown vendor';

  @override
  String get noRequestsYet => 'No requests yet';

  @override
  String get vendorUnknown => 'Vendor unknown';

  @override
  String get totalLabel => 'Total:';

  @override
  String get kilogram => 'K';

  @override
  String get quantityRequested => 'Quantity requested: @qty Kg';

  @override
  String get insufficientStock => 'Insufficient stock for this order';

  @override
  String get stockUpdatedSuccessfully => 'Order set to delivery and stock updated';

  @override
  String get errorUpdatingStock => 'Error updating stock';

  @override
  String requestFrom(Object customerName) {
    return 'Request from $customerName';
  }

  @override
  String get unknownCustomer => 'Unknown customer';

  @override
  String requestedAt(Object time) {
    return 'Received at $time';
  }

  @override
  String get statusPending => 'Pending';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get unknownStatus => 'Unknown';

  @override
  String get accept => 'accept';

  @override
  String get reject => ' refuse';

  @override
  String addressLabel(Object location) {
    return 'Address: $location';
  }

  @override
  String get notSpecified => 'Not specified';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get noConversations => 'No conversations yet';

  @override
  String get messagesWillAppearHere => 'Your customers\' messages will appear here';

  @override
  String get youPrefix => 'You: ';

  @override
  String get unknownClient => 'Unknown customer';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get phonePrefix => 'Phone';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get startConversation => 'Start the conversation!';

  @override
  String get messageSendFailed => 'Failed to send message';

  @override
  String totalProductsCount(Object count) {
    return '$count product(s)';
  }

  @override
  String totalStockKg(Object kg) {
    return '$kg kg in stock';
  }

  @override
  String get clientsWillContactSoon => 'Your clients will contact you soon!';

  @override
  String requestProduct(Object product) {
    return 'Request $product';
  }

  @override
  String get request => 'Request';

  @override
  String get totalPrice => 'Total Price';

  @override
  String get minQuantityWarning => 'Minimum quantity for a request is 10 kg';

  @override
  String get minQuantityError => 'Quantity must be at least 10 kg';

  @override
  String requestSentSuccess(Object product, Object quantity) {
    return 'Request for $quantity kg of $product sent successfully!';
  }

  @override
  String get requestSentFailed => 'Failed to send request';

  @override
  String get errorConsumerNotFound => 'Error: Consumer not identified';

  @override
  String get guestUser => 'Guest';

  @override
  String get consumerMode => 'Consumer Mode';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get loginToAccessMore => 'Log in to access more features';

  @override
  String get acceptedOrders => 'Orders Accepted! 🎉';

  @override
  String acceptedOrdersCount(Object count) {
    return '1 accepted order|@count accepted orders';
  }

  @override
  String get orderAcceptedMessage => 'The vendor has accepted your request. Contact them via chat to finalize.';

  @override
  String get viewAllOrders => 'View all orders';

  @override
  String get noAcceptedOrders => 'No accepted orders yet';

  @override
  String get statusInDelivery => 'In delivery';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusUnknown => 'Unknown';

  @override
  String get updateStatus => 'Update status';

  @override
  String get requestFinalized => 'This request is finalized and can no longer be modified';

  @override
  String get errorUpdatingStatus => 'Error updating status';

  @override
  String get acceptedOrdersTitle => 'Your orders have been accepted! 🎉';

  @override
  String get acceptedOrdersMessage => 'You have 1 accepted order.|You have @count accepted orders.';

  @override
  String get availableProducts => 'Available products';

  @override
  String get viewAllSoon => 'Feature coming soon!';

  @override
  String get enterDeliveryAddress => 'Enter your delivery address';

  @override
  String get openInGoogleMaps => 'Open in Google Maps';

  @override
  String get enterAddressFirst => 'Please enter an address first';

  @override
  String get addressHelpText => 'Type your address and tap the icon to check it on Google Maps';

  @override
  String get addressRequired => 'Address is required';

  @override
  String get next => 'Next';

  @override
  String get pasteAddress => 'Paste your address';

  @override
  String get pasteHere => 'Paste the address copied from Google Maps here...';

  @override
  String get tapToSelectOnMap => 'Tap to open Google Maps and choose your address';

  @override
  String get mapsInstructions => 'Long-press on the map to drop a pin, then copy the displayed address';

  @override
  String get mapsHelpText => 'Open the map, long-press to drop a pin, then copy the address shown at the bottom.';

  @override
  String get confirm => 'Confirm';
}
