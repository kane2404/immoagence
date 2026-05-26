enum PropertyType { apartment, house, villa, studio, land, sharedRoom }

enum PropertyOfferType { rent, sale, colocation }

enum PropertyStatus { available, reserved, rented, sold }

class Property {
  const Property({
    required this.id,
    required this.title,
    required this.type,
    required this.offerType,
    required this.status,
    required this.price,
    required this.location,
    required this.imagePaths,
    required this.description,
    required this.features,
    this.rooms,
    this.bathrooms,
    this.surfaceArea,
    this.isFurnished = false,
  });

  final String id;
  final String title;
  final PropertyType type;
  final PropertyOfferType offerType;
  final PropertyStatus status;
  final int price;
  final String location;
  final List<String> imagePaths;
  final String description;
  final List<String> features;
  final int? rooms;
  final int? bathrooms;
  final double? surfaceArea;
  final bool isFurnished;

  String get formattedPrice => '$price FCFA';

  bool get isAvailable => status == PropertyStatus.available;
}
