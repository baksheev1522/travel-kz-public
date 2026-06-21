import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String tourId;
  final String userName;
  final String rating;
  final String ratingLabel;
  final String pros;
  final String cons;
  final DateTime date;

  const Review({
    required this.id,
    required this.tourId,
    required this.userName,
    required this.rating,
    required this.ratingLabel,
    required this.pros,
    required this.cons,
    required this.date,
  });

  factory Review.fromFirestore(Map<String, dynamic> data, String id) {
    return Review(
      id: id,
      tourId: data['tourId'] ?? '',
      userName: data['userName'] ?? '',
      rating: data['rating'] ?? 'Отлично',
      ratingLabel: data['ratingLabel'] ?? 'Отлично',
      pros: data['pros'] ?? '',
      cons: data['cons'] ?? '',
      date: data['date'] != null
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

class ReviewService {
  final _db = FirebaseFirestore.instance;

  static final _mockReviews = {
    'tour_1': [
      {'userName': 'Айгерим', 'rating': '9.0', 'ratingLabel': 'Отлично', 'pros': 'Всё включено на высшем уровне, анимация отличная, пляж чистый', 'cons': 'Далеко от города', 'daysAgo': 5},
      {'userName': 'Данияр', 'rating': '8.5', 'ratingLabel': 'Отлично', 'pros': 'Огромная территория, много бассейнов, вкусная еда', 'cons': 'Очереди на завтрак', 'daysAgo': 12},
      {'userName': 'Светлана', 'rating': '7.0', 'ratingLabel': 'Хорошо', 'pros': 'Хороший сервис, красивые номера', 'cons': 'Пляж немного переполнен в высокий сезон', 'daysAgo': 20},
    ],
    'tour_2': [
      {'userName': 'Алмас', 'rating': '9.2', 'ratingLabel': 'Отлично', 'pros': 'Красное море восхитительно, кораллы великолепны', 'cons': 'Трансфер групповой', 'daysAgo': 3},
      {'userName': 'Зарина', 'rating': '8.0', 'ratingLabel': 'Хорошо', 'pros': 'Всё включено, дайвинг центр рядом', 'cons': 'Номер маловат', 'daysAgo': 15},
    ],
    'tour_3': [
      {'userName': 'Нурлан', 'rating': '9.5', 'ratingLabel': 'Отлично', 'pros': 'Лучший отдых в жизни! Вилла над водой — мечта', 'cons': 'Дорогие экскурсии', 'daysAgo': 7},
      {'userName': 'Мадина', 'rating': '9.0', 'ratingLabel': 'Отлично', 'pros': 'Сервис на высшем уровне, еда вкусная', 'cons': 'Далеко лететь', 'daysAgo': 30},
    ],
    'tour_4': [
      {'userName': 'Тимур', 'rating': '9.8', 'ratingLabel': 'Отлично', 'pros': 'Это просто нереально роскошно! Сервис как в сказке', 'cons': 'Очень дорого, но оно того стоит', 'daysAgo': 10},
    ],
    'tour_5': [
      {'userName': 'Аружан', 'rating': '10.0', 'ratingLabel': 'Отлично', 'pros': 'Рай на земле! Подводный ресторан — незабываемо', 'cons': 'Только цена кусается', 'daysAgo': 2},
      {'userName': 'Серик', 'rating': '9.5', 'ratingLabel': 'Отлично', 'pros': 'Бунгало над водой, закаты фантастические', 'cons': 'Долгий перелёт с пересадкой', 'daysAgo': 25},
    ],
  };

  Future<void> seedReviewsIfEmpty() async {
    final snapshot = await _db.collection('reviews').limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final batch = _db.batch();
    _mockReviews.forEach((tourId, reviews) {
      for (int i = 0; i < reviews.length; i++) {
        final r = reviews[i];
        final ref = _db.collection('reviews').doc('${tourId}_review_$i');
        batch.set(ref, {
          'tourId': tourId,
          'userName': r['userName'],
          'rating': r['rating'],
          'ratingLabel': r['ratingLabel'],
          'pros': r['pros'],
          'cons': r['cons'],
          'date': Timestamp.fromDate(
            DateTime.now().subtract(Duration(days: r['daysAgo'] as int)),
          ),
        });
      }
    });
    await batch.commit();
  }

  Future<List<Review>> getReviewsForTour(String tourId) async {
    final snapshot = await _db
        .collection('reviews')
        .where('tourId', isEqualTo: tourId)
        .get();
    return snapshot.docs
        .map((doc) => Review.fromFirestore(doc.data(), doc.id))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}