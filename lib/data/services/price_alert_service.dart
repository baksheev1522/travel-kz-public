import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../repositories/tour_repository.dart';

class PriceAlertService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _repo = TourRepository();

  static final _notifications = FlutterLocalNotificationsPlugin();
  static bool _notificationsInitialized = false;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _col {
    if (_uid == null) return null;
    return _db.collection('users').doc(_uid).collection('priceAlerts');
  }

  // ── Инициализация уведомлений ─────────────────────────────────
  static Future<void> initNotifications() async {
    if (_notificationsInitialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Явный запрос разрешения на Android 13+
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    _notificationsInitialized = true;
  }

  static Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'price_alerts',
      'Снижение цен',
      channelDescription: 'Уведомления о снижении цен на туры',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  // ── Stream алертов ────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> stream() {
    if (_col == null) return const Stream.empty();
    return _col!
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {...d.data(), 'alertId': d.id}).toList());
  }

  // ── Добавить алерт ────────────────────────────────────────────
  Future<void> add({
    required String tourId,
    required String hotelName,
    required String country,
    required String imageUrl,
    required int nights,
    required double targetPrice,
    required double currentPrice,
  }) async {
    if (_col == null) return;
    await _col!.add({
      'tourId': tourId,
      'hotelName': hotelName,
      'country': country,
      'imageUrl': imageUrl,
      'nights': nights,
      'targetPrice': targetPrice,
      'currentPrice': currentPrice,
      'isActive': true,
      'isTriggered': false,
      'createdAt': FieldValue.serverTimestamp(),
      'triggeredAt': null,
    });
  }

  // ── Удалить алерт ─────────────────────────────────────────────
  Future<void> delete(String alertId) async {
    await _col?.doc(alertId).delete();
  }

  // ── Переключить активность ────────────────────────────────────
  Future<void> toggle(String alertId, bool isActive) async {
    await _col?.doc(alertId).update({'isActive': isActive});
  }

  // ── Проверить цены и отправить уведомления ────────────────────
  Future<int> checkPrices() async {
    if (_col == null) return 0;
    int triggered = 0;

    try {
      final snap = await _col!.where('isActive', isEqualTo: true).get();

      for (final doc in snap.docs) {
        final data = doc.data();
        final tourId = data['tourId'] as String;
        final targetPrice = (data['targetPrice'] as num).toDouble();
        final hotelName = data['hotelName'] as String;
        final wasTriggered = data['isTriggered'] as bool? ?? false;

        final tour = await _repo.getTourById(tourId);
        if (tour == null) continue;

        final currentPrice = tour.price;
        final updates = <String, dynamic>{'currentPrice': currentPrice};

        if (currentPrice <= targetPrice && !wasTriggered) {
          updates['isTriggered'] = true;
          updates['triggeredAt'] = FieldValue.serverTimestamp();

          await _showNotification(
            id: tourId.hashCode.abs() % 10000,
            title: '🎯 Цена снизилась!',
            body:
                '$hotelName — ${_fmt(currentPrice)} ₸ (цель: ${_fmt(targetPrice)} ₸)',
          );
          triggered++;
        }

        if (currentPrice > targetPrice && wasTriggered) {
          updates['isTriggered'] = false;
        }

        await doc.reference.update(updates);
      }
    } catch (_) {}

    return triggered;
  }

  String _fmt(double p) => p.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
}