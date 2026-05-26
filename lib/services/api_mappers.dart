import '../core/app_assets.dart';
import '../models/app_user.dart';
import '../models/property.dart';

AppUser userFromApi(Map<String, dynamic> json) {
  return AppUser(
    id: json['id'].toString(),
    fullName: json['full_name']?.toString() ?? '',
    email: json['email']?.toString(),
    phone: json['phone']?.toString() ?? '',
    role: roleFromApi(json['role']?.toString()),
    isBlocked: json['is_blocked'] == true,
  );
}

UserRole roleFromApi(String? value) {
  return switch (value) {
    'tenant' => UserRole.tenant,
    'owner' => UserRole.owner,
    'admin' => UserRole.admin,
    'agent' => UserRole.agent,
    'client' => UserRole.client,
    _ => UserRole.visitor,
  };
}

String roleToApi(UserRole role) {
  return switch (role) {
    UserRole.visitor => 'visitor',
    UserRole.tenant || UserRole.client => 'tenant',
    UserRole.owner => 'owner',
    UserRole.admin => 'admin',
    UserRole.agent => 'agent',
  };
}

Property propertyFromApi(Map<String, dynamic> json) {
  return Property(
    id: json['id'].toString(),
    title: json['title']?.toString() ?? '',
    type: propertyTypeFromApi(json['type']?.toString()),
    offerType: offerTypeFromApi(json['offer_type']?.toString()),
    status: propertyStatusFromApi(json['status']?.toString()),
    price: int.tryParse(json['price']?.toString() ?? '') ?? 0,
    location: json['location']?.toString() ?? '',
    imagePaths: [
      if ((json['image_url']?.toString() ?? '').isNotEmpty)
        json['image_url'].toString()
      else
        AppAssets.appartementDakar,
    ],
    description: json['description']?.toString() ?? '',
    features: _stringList(json['features']),
    rooms: int.tryParse(json['rooms']?.toString() ?? ''),
    bathrooms: int.tryParse(json['bathrooms']?.toString() ?? ''),
    surfaceArea: double.tryParse(json['surface_area']?.toString() ?? ''),
    isFurnished: json['is_furnished'] == true,
  );
}

PropertyType propertyTypeFromApi(String? value) {
  return switch (value) {
    'apartment' => PropertyType.apartment,
    'villa' => PropertyType.villa,
    'studio' => PropertyType.studio,
    'land' => PropertyType.land,
    'shared_room' => PropertyType.sharedRoom,
    _ => PropertyType.house,
  };
}

String propertyTypeToApi(PropertyType type) {
  return switch (type) {
    PropertyType.apartment => 'apartment',
    PropertyType.house => 'house',
    PropertyType.villa => 'villa',
    PropertyType.studio => 'studio',
    PropertyType.land => 'land',
    PropertyType.sharedRoom => 'shared_room',
  };
}

PropertyOfferType offerTypeFromApi(String? value) {
  return switch (value) {
    'sale' => PropertyOfferType.sale,
    'colocation' => PropertyOfferType.colocation,
    _ => PropertyOfferType.rent,
  };
}

String offerTypeToApi(PropertyOfferType offer) {
  return switch (offer) {
    PropertyOfferType.rent => 'rent',
    PropertyOfferType.sale => 'sale',
    PropertyOfferType.colocation => 'colocation',
  };
}

PropertyStatus propertyStatusFromApi(String? value) {
  return switch (value) {
    'reserved' => PropertyStatus.reserved,
    'rented' => PropertyStatus.rented,
    'sold' => PropertyStatus.sold,
    _ => PropertyStatus.available,
  };
}

String propertyStatusToApi(PropertyStatus status) {
  return switch (status) {
    PropertyStatus.available => 'available',
    PropertyStatus.reserved => 'reserved',
    PropertyStatus.rented => 'rented',
    PropertyStatus.sold => 'sold',
  };
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const [];
}
