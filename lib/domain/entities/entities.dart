class Tour {
  final String id;
  final String title;
  final String country;
  final String city;
  final String imageUrl;
  final List<String> imageUrls;
  final double price;
  final double originalPrice;
  final int nights;
  final String departureCity;
  final DateTime departureDate;
  final String mealType;
  final int stars;
  final double rating;
  final int reviewsCount;
  final String hotelId;
  final String hotelName;
  final bool isHot;
  final int availableSeats;
  final String description;
  final List<String> included;
  final List<String> notIncluded;
  final String flightInfo;

  const Tour({
    required this.id,
    required this.title,
    required this.country,
    required this.city,
    required this.imageUrl,
    required this.imageUrls,
    required this.price,
    required this.originalPrice,
    required this.nights,
    required this.departureCity,
    required this.departureDate,
    required this.mealType,
    required this.stars,
    required this.rating,
    required this.reviewsCount,
    required this.hotelId,
    required this.hotelName,
    required this.isHot,
    required this.availableSeats,
    required this.description,
    required this.included,
    required this.notIncluded,
    required this.flightInfo,
  });

  int get discountPercent => originalPrice > 0
      ? ((originalPrice - price) / originalPrice * 100).round()
      : 0;

  bool get hasDiscount => price < originalPrice;
}

class Hotel {
  final String id;
  final String name;
  final String country;
  final String city;
  final String imageUrl;
  final List<String> imageUrls;
  final int stars;
  final double rating;
  final int reviewsCount;
  final String description;
  final List<String> amenities;

  const Hotel({
    required this.id,
    required this.name,
    required this.country,
    required this.city,
    required this.imageUrl,
    required this.imageUrls,
    required this.stars,
    required this.rating,
    required this.reviewsCount,
    required this.description,
    required this.amenities,
  });
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final int bonusPoints;
  final List<String> wishlistIds;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.bonusPoints,
    required this.wishlistIds,
  });

  AppUser copyWith({
    String? name,
    String? phone,
    String? avatarUrl,
    int? bonusPoints,
    List<String>? wishlistIds,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bonusPoints: bonusPoints ?? this.bonusPoints,
      wishlistIds: wishlistIds ?? this.wishlistIds,
    );
  }
}

class Booking {
  final String id;
  final String tourId;
  final String tourTitle;
  final String hotelName;
  final String imageUrl;
  final BookingStatus status;
  final double totalPrice;
  final int adultsCount;
  final int childrenCount;
  final DateTime departureDate;
  final DateTime returnDate;
  final DateTime bookedAt;

  const Booking({
    required this.id,
    required this.tourId,
    required this.tourTitle,
    required this.hotelName,
    required this.imageUrl,
    required this.status,
    required this.totalPrice,
    required this.adultsCount,
    required this.childrenCount,
    required this.departureDate,
    required this.returnDate,
    required this.bookedAt,
  });
}

enum BookingStatus { pending, confirmed, paid, completed, cancelled }

class Destination {
  final String id;
  final String country;
  final String city;
  final String imageUrl;
  final double minPrice;
  final int toursCount;

  const Destination({
    required this.id,
    required this.country,
    required this.city,
    required this.imageUrl,
    required this.minPrice,
    required this.toursCount,
  });
}

class PriceAlert {
  final String id;
  final String userId;
  final String tourId;
  final String tourTitle;
  final String imageUrl;
  final double targetPrice;
  final double currentPrice;
  final bool isActive;
  final DateTime createdAt;

  const PriceAlert({
    required this.id,
    required this.userId,
    required this.tourId,
    required this.tourTitle,
    required this.imageUrl,
    required this.targetPrice,
    required this.currentPrice,
    required this.isActive,
    required this.createdAt,
  });

  bool get isPriceDrop => currentPrice <= targetPrice;
}

class TourSearchFilter {
  final String? departureCity;
  final String? destinationCountry;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int adultsCount;
  final int childrenCount;
  final int? starsMin;
  final List<String> mealTypes;
  final double? priceMax;
  final bool? hotOnly;

  const TourSearchFilter({
    this.departureCity,
    this.destinationCountry,
    this.dateFrom,
    this.dateTo,
    this.adultsCount = 2,
    this.childrenCount = 0,
    this.starsMin,
    this.mealTypes = const [],
    this.priceMax,
    this.hotOnly,
  });

  TourSearchFilter copyWith({
    String? departureCity,
    String? destinationCountry,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? adultsCount,
    int? childrenCount,
    int? starsMin,
    List<String>? mealTypes,
    double? priceMax,
    bool? hotOnly,
  }) {
    return TourSearchFilter(
      departureCity: departureCity ?? this.departureCity,
      destinationCountry: destinationCountry ?? this.destinationCountry,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      adultsCount: adultsCount ?? this.adultsCount,
      childrenCount: childrenCount ?? this.childrenCount,
      starsMin: starsMin ?? this.starsMin,
      mealTypes: mealTypes ?? this.mealTypes,
      priceMax: priceMax ?? this.priceMax,
      hotOnly: hotOnly ?? this.hotOnly,
    );
  }
}