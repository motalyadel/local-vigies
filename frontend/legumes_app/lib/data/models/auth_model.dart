abstract class AuthModel {
  final String id;
  final String? name;
  final List<AppRole> roles;

  AppRole get currentRole => roles[0];

  AuthModel({
    required this.id,
    this.name,
    required this.roles,
  });

  Map<String, dynamic> toMap();

  AuthModel copyWith();

  static String get usersTableName => "users";

  get token => null;
}

// enum Status {
//   active('Active'),
//   inactive('Inactive');

//   final String value;
//   const Status(this.value);

//   static Status fromString(String value) {
//     return Status.values.firstWhere(
//       (status) => status.value == value,
//       orElse: () => Status.active,
//     );
//   }
// }


class Admin extends AuthModel {
  Admin({
    required super.id,
    required super.roles,
    super.name,
  });

  static String get tableName => "admin";

  factory Admin.fromMap(Map<String, dynamic> map) {
    return Admin(
      id: map['id'] as String,
      name: map['name'] as String?,
      roles: List<Map<String, dynamic>>.from(map['roles'] ?? [])
          .map((item) => AppRole.fromMap(item['app_role']))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'name': name,
      };

  @override
  Admin copyWith({
    String? name,
  }) {
    return Admin(
      id: id,
      roles: roles,
      name: name ?? this.name,
    );
  }
}


class Vendor extends AuthModel {
  final String shopName;
  final String? phone;
  final String? location;
  final String? photoUrl;
  final DateTime? createdAt;

  Vendor({
    required super.id,
    required super.roles,
    super.name,
    required this.shopName,
    this.phone,
    this.location,
    this.photoUrl,
    this.createdAt,
  });

  static String get tableName => "vendors";

  factory Vendor.fromMap(Map<String, dynamic> map) {
    final vendorData = map['vendor'] as Map<String, dynamic>? ?? {};
    final roleList = List<Map<String, dynamic>>.from(map['roles'] ?? []);
    final roles = roleList.map((item) => AppRole.fromMap(item['app_role'])).toList();

    return Vendor(
      id: map['id'] ?? '',
      name: map['name'],
      roles: roles.isNotEmpty ? roles : [AppRole(id: 'vendor')],
      shopName: vendorData['shop_name'] ?? '',
      phone: vendorData['phone'],
      location: vendorData['location'],
      photoUrl: vendorData['photo_url'],
      createdAt: vendorData['created_at'] != null
          ? DateTime.tryParse(vendorData['created_at'])
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'shop_name': shopName,
        'phone': phone,
        'location': location,
        'photo_url': photoUrl,
        'created_at': createdAt?.toIso8601String(),
      };

  @override
  Vendor copyWith({
    String? id,
    String? name,
    String? shopName,
    String? phone,
    String? location,
    String? photoUrl,
    DateTime? createdAt,
    List<AppRole>? roles,
  }) {
    return Vendor(
      id: id ?? this.id,
      roles: roles ?? this.roles,
      name: name ?? this.name,
      shopName: shopName ?? this.shopName,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}


class AppRole {
  final String id;

  AppRole({required this.id});

  factory AppRole.fromMap(Map<String, dynamic> map) {
    return AppRole(
      id: map['id'] as String,
    );
  }
}