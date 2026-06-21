import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/entities.dart';
import '../models/tour_model.dart';

class DynamicPricingService {
  final _db = FirebaseFirestore.instance;

  // Ключ дня — меняется каждые 24 часа
  String get _dayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<void> updateDailyPrices() async {
    final docRef = _db.collection('daily_prices').doc(_dayKey);
    final doc = await docRef.get();

    // Если сегодня уже обновляли — не трогаем
    if (doc.exists) return;

    final allTours = await _db.collection('tours').get();
    if (allTours.docs.isEmpty) return;

    // Seed на основе даты — одинаковый для всех
    final seed = int.parse(_dayKey.replaceAll('-', ''));
    final rand = Random(seed);

    // Выбираем 3-4 случайных тура как горящие
    final tourIds = allTours.docs.map((d) => d.id).toList();
    tourIds.shuffle(rand);
    final hotCount = rand.nextInt(2) + 3; // 3 или 4
    final hotTourIds = tourIds.take(hotCount).toSet();

    final batch = _db.batch();

    for (final doc in allTours.docs) {
      final data = doc.data();
      final basePrice = (data['basePrice'] ?? data['price'] ?? 0).toDouble();

      // Сохраняем базовую цену если ещё нет
      if (data['basePrice'] == null) {
        batch.update(doc.reference, {'basePrice': basePrice});
      }

      final isHot = hotTourIds.contains(doc.id);

      // Колебание цены от -15% до +10% от базовой
      double priceMultiplier;
      if (isHot) {
        // Горящие — скидка от 10% до 25%
        priceMultiplier = 0.75 + rand.nextDouble() * 0.15;
      } else {
        // Обычные — ±10% от базы
        priceMultiplier = 0.90 + rand.nextDouble() * 0.20;
      }

      final newPrice = (basePrice * priceMultiplier).roundToDouble();
      final discountPercent = isHot
          ? ((1 - priceMultiplier) * 100).round()
          : 0;

      batch.update(doc.reference, {
        'price': newPrice,
        'isHot': isHot,
        'discountPercent': discountPercent,
        'lastUpdated': _dayKey,
      });
    }

    // Сохраняем запись что сегодня уже обновили
    batch.set(docRef, {
      'updatedAt': FieldValue.serverTimestamp(),
      'hotTours': hotTourIds.toList(),
      'dayKey': _dayKey,
    });

    await batch.commit();
  }

  // Получить туры с актуальными ценами
  Future<List<Tour>> getTodaysTours() async {
    final snapshot = await _db.collection('tours').get();
    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          // Используем originalPrice = basePrice если есть
          final basePrice = (data['basePrice'] ?? data['price'] ?? 0).toDouble();
          final currentPrice = (data['price'] ?? 0).toDouble();
          
          return Tour(
            id: doc.id,
            title: data['title'] ?? '',
            hotelName: data['hotelName'] ?? '',
            hotelId: data['hotelId'] ?? doc.id,
            country: data['country'] ?? '',
            city: data['city'] ?? '',
            description: data['description'] ?? '',
            imageUrl: data['imageUrl'] ?? '',
            imageUrls: List<String>.from(data['imageUrls'] ?? []),
            price: currentPrice,
            originalPrice: basePrice,
            rating: (data['rating'] ?? 0).toDouble(),
            reviewsCount: data['reviewsCount'] ?? 0,
            stars: data['stars'] ?? 0,
            nights: data['nights'] ?? 0,
            mealType: data['mealType'] ?? '',
            departureCity: data['departureCity'] ?? 'Алматы',
            departureDate: data['departureDate'] != null
                ? DateTime.parse(data['departureDate'])
                : DateTime.now().add(const Duration(days: 14)),
            flightInfo: data['flightInfo'] ?? '',
            isHot: data['isHot'] ?? false,
            availableSeats: data['availableSeats'] ?? 10,
            included: List<String>.from(data['included'] ?? []),
            notIncluded: List<String>.from(data['notIncluded'] ?? []),
          );
        })
        .toList();
  }
}