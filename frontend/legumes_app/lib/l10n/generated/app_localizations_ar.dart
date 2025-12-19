import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get hello => 'مرحبا';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get connexionAuMarche => 'تسجيل في خير 🥕';

  @override
  String get register => 'إنشاء حساب';

  @override
  String get noAccount => 'ليس لديك حساب؟ اشترك الآن';

  @override
  String get haveAccount => 'لديك حساب بالفعل؟ تسجيل الدخول';

  @override
  String get name => 'الاسم الكامل';

  @override
  String get shopName => 'اسم المتجر';

  @override
  String get phone => 'رقم الهاتف';

  @override
  String get location => 'الموقع';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get passwordMismatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get passwordTooShort => 'كلمة المرور قصيرة جداً (6 أحرف على الأقل)';

  @override
  String get invalidEmail => 'أدخل بريدًا إلكترونيًا صالحًا';

  @override
  String get invalidNom => 'الاسم قصير جداً (3 أحرف على الأقل)';

  @override
  String get invalidPhone => 'رقم الهاتف غير صالح';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get marketTitle => 'سوق خير';

  @override
  String get tagline => 'أفضل المنتجات قريبة منك';

  @override
  String get allProducts => 'جميع المنتجات';

  @override
  String get myProducts => 'منتجاتي';

  @override
  String get refresh => 'تحديث';

  @override
  String get noProducts => 'لا توجد منتجات';

  @override
  String get errorOccurred => 'حدث خطأ';

  @override
  String get completeProfile => 'أكمل ملفك الشخصي';

  @override
  String get profileInfoOnce => 'هذه المعلومات ستُطلب مرة واحدة فقط';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get neighborhood => 'الحي / المدينة (اختياري)';

  @override
  String get cancel => 'إلغاء';

  @override
  String get createProfile => 'إنشاء ملفي';

  @override
  String get profileCreated => 'تم إنشاء الملف بنجاح!';

  @override
  String get profileReset => 'تم إعادة تعيين الملف للاختبار';

  @override
  String orderProduct(Object productName) {
    return 'طلب $productName';
  }

  @override
  String pricePerKg(Object price) {
    return 'السعر: $price MRU / kg';
  }

  @override
  String get quantityKg => 'الكمية (kg)';

  @override
  String get deliveryAddress => 'عنوان التوصيل';

  @override
  String get fillFields => 'يرجى ملء جميع الحقول بشكل صحيح';

  @override
  String get order => 'اطلب الآن';

  @override
  String get orderSent => 'تم إرسال الطلب! سيرد عليك البائع قريباً';

  @override
  String get orderFailed => 'فشل الإرسال';

  @override
  String get vendorDashboard => 'لوحة تحكم البائع';

  @override
  String get profileLogout => 'الملف الشخصي / تسجيل الخروج';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get logoutConfirm => 'هل تريد حقًا تسجيل الخروج؟';

  @override
  String get totalProducts => 'إجمالي المنتجات';

  @override
  String get totalStock => 'إجمالي المخزون';

  @override
  String get addProduct => 'إضافة منتج';

  @override
  String get marketProducts => 'منتجات السوق';

  @override
  String get myConversations => 'محادثاتي';

  @override
  String get myRequests => 'طلباتي';

  @override
  String get lastUpdate => 'آخر تحديث';

  @override
  String get chat => 'المحادثة';

  @override
  String get noMessages => 'لا توجد رسائل';

  @override
  String get typeMessage => 'اكتب رسالتك...';

  @override
  String get noProductsAddHint => 'لا توجد منتجات بعد\nاضغط على + لإضافة منتج';

  @override
  String price(Object price) {
    return 'السعر: $price MRU';
  }

  @override
  String stock(Object quantity) {
    return 'المخزون: $quantity kg';
  }

  @override
  String productDate(Object date) {
    return 'التاريخ: $date';
  }

  @override
  String get updatePrice => 'تحديث السعر';

  @override
  String updatePriceTitle(Object productName) {
    return 'سعر جديد – $productName';
  }

  @override
  String get update => 'تحديث';

  @override
  String priceUpdated(Object price) {
    return 'Price updated: $price MRU';
  }

  @override
  String get priceUpdateFailed => 'فشل التحديث';

  @override
  String get deleteProduct => 'حذف المنتج';

  @override
  String get deleteProductConfirm => 'هذا الإجراء لا يمكن التراجع عنه.';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get productName => 'اسم المنتج';

  @override
  String get priceMRU => 'السعر (MRU)';

  @override
  String get selectPhoto => 'اختر صورة';

  @override
  String get photoSelected => 'تم اختيار الصورة';

  @override
  String get createProduct => 'إنشاء المنتج';

  @override
  String get fieldRequired => 'هذا الحقل مطلوب';

  @override
  String get invalidPrice => 'السعر غير صالح';

  @override
  String get invalidQuantity => 'الكمية غير صالحة';

  @override
  String get productCreatedSuccess => 'تم إنشاء المنتج بنجاح!';

  @override
  String get productCreatedFailed => 'فشل إنشاء المنتج';

  @override
  String get productUpdatedSuccess => 'تم تحديث المنتج بنجاح !';

  @override
  String get productUpdateFailed => 'فشل تحديث المنتج';

  @override
  String get editProduct => 'تعديل المنتج';

  @override
  String get changePhoto => 'تغيير الصورة';

  @override
  String get newPhotoSelected => 'تم اختيار صورة جديدة';

  @override
  String vendorBy(Object vendorName) {
    return 'بواسطه: $vendorName';
  }

  @override
  String get unknownVendor => 'بائع غير معروف';

  @override
  String get noRequestsYet => 'لا توجد طلبات حالياً';

  @override
  String requestFrom(Object customerName) {
    return 'طلب من $customerName';
  }

  @override
  String get unknownCustomer => 'عميل غير معروف';

  @override
  String requestedAt(Object time) {
    return 'تم الاستلام في $time';
  }

  @override
  String get statusPending => 'قيد الانتظار';

  @override
  String get statusAccepted => 'مقبولة';

  @override
  String get statusRejected => 'مرفوض';

  @override
  String get unknownStatus => 'غير معروف';

  @override
  String get accept => 'قبول';

  @override
  String get reject => ' رفض';

  @override
  String addressLabel(Object location) {
    return 'العنوان: $location';
  }

  @override
  String get notSpecified => 'غير محدد';

  @override
  String get messagesTitle => 'الرسائل';

  @override
  String get noConversations => 'لا توجد محادثات بعد';

  @override
  String get messagesWillAppearHere => 'ستظهر رسائل عملائك هنا';

  @override
  String get youPrefix => 'أنت: ';

  @override
  String get unknownClient => 'عميل غير معروف';

  @override
  String get yesterday => 'أمس';

  @override
  String get phonePrefix => 'هاتف';

  @override
  String get noMessagesYet => 'لا توجد رسائل بعد';

  @override
  String get startConversation => 'ابدأ المحادثة!';

  @override
  String get messageSendFailed => 'فشل إرسال الرسالة';

  @override
  String totalProductsCount(Object count) {
    return '$count منتج';
  }

  @override
  String totalStockKg(Object kg) {
    return '$kg kg في المخزون';
  }

  @override
  String get clientsWillContactSoon => 'سيتواصل معك عملاؤك قريبًا!';

  @override
  String requestProduct(Object product) {
    return 'طلب $product';
  }

  @override
  String get request => 'طلب';

  @override
  String get totalPrice => 'السعر الإجمالي';

  @override
  String get minQuantityWarning => 'الكمية الدنيا للطلب هي 10 كجم';

  @override
  String get minQuantityError => 'يجب أن تكون الكمية 10 كجم على الأقل';

  @override
  String requestSentSuccess(Object product, Object quantity) {
    return 'تم إرسال طلب $quantity كجم من $product بنجاح!';
  }

  @override
  String get requestSentFailed => 'فشل إرسال الطلب';

  @override
  String get errorConsumerNotFound => 'خطأ: المستهلك غير معروف';

  @override
  String get guestUser => 'زائر';

  @override
  String get consumerMode => 'وضع المستهلك';

  @override
  String get changeLanguage => 'تغيير اللغة';

  @override
  String get loginToAccessMore => 'سجل الدخول للوصول إلى المزيد من الميزات';

  @override
  String get acceptedOrders => 'تم قبول طلباتك! 🎉';

  @override
  String acceptedOrdersCount(Object count) {
    return 'طلب واحد مقبول|طلبين مقبولين|$count طلبات مقبولة';
  }

  @override
  String get orderAcceptedMessage => 'قبل البائع طلبك. تواصل معه عبر الدردشة لإكمال العملية.';

  @override
  String get viewAllOrders => 'عرض جميع الطلبات';

  @override
  String get noAcceptedOrders => 'لا توجد طلبات مقبولة حالياً';

  @override
  String get statusInDelivery => 'في التوصيل';

  @override
  String get statusCompleted => 'تم التسليم';

  @override
  String get statusUnknown => 'غير معروف';

  @override
  String get updateStatus => 'تحديث الحالة';

  @override
  String get requestFinalized => 'تم إنهاء هذا الطلب ولا يمكن تعديله بعد الآن';

  @override
  String get errorUpdatingStatus => 'حدث خطأ أثناء تحديث الحالة';

  @override
  String get acceptedOrdersTitle => 'تم قبول طلباتك! 🎉';

  @override
  String get acceptedOrdersMessage => 'لديك طلب مقبول واحد.|لديك @count طلبات مقبولة.';

  @override
  String get availableProducts => 'المنتجات المتوفرة';

  @override
  String get viewAllSoon => 'هذه الميزة قريباً!';
}
