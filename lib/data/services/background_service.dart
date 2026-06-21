import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

import '../../../firebase_options.dart';

const _kPriceCheckTask = 'priceCheckTask';

// ── Точка входа фонового воркера ──────────────────────────────────
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != _kPriceCheckTask) return true;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final db = FirebaseFirestore.instance;

      // Сначала обновляем цены если сегодня ещё не делали
      await _updatePricesIfNeeded(db);

      // Проверяем алерты пользователя
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return true;

      await _checkAlerts(db, uid);
    } catch (_) {
      // Не бросаем — иначе WorkManager будет ретраить
    }

    return true;
  });
}

// ── Обновление цен (точная копия логики DynamicPricingService) ────
Future<void> _updatePricesIfNeeded(FirebaseFirestore db) async {
  final dayKey = _dayKey();
  final docRef = db.collection('daily_prices').doc(dayKey);
  final doc = await docRef.get();

  // Уже обновляли сегодня — пропускаем
  if (doc.exists) return;

  final allTours = await db.collection('tours').get();
  if (allTours.docs.isEmpty) return;

  final seed = int.parse(dayKey.replaceAll('-', ''));
  final rand = Random(seed);

  final tourIds = allTours.docs.map((d) => d.id).toList();
  tourIds.shuffle(rand);
  final hotCount = rand.nextInt(2) + 3;
  final hotTourIds = tourIds.take(hotCount).toSet();

  final batch = db.batch();

  for (final tourDoc in allTours.docs) {
    final data = tourDoc.data();
    final basePrice = (data['basePrice'] ?? data['price'] ?? 0).toDouble();

    if (data['basePrice'] == null) {
      batch.update(tourDoc.reference, {'basePrice': basePrice});
    }

    final isHot = hotTourIds.contains(tourDoc.id);

    double priceMultiplier;
    if (isHot) {
      priceMultiplier = 0.75 + rand.nextDouble() * 0.15;
    } else {
      priceMultiplier = 0.90 + rand.nextDouble() * 0.20;
    }

    final newPrice = (basePrice * priceMultiplier).roundToDouble();
    final discountPercent =
        isHot ? ((1 - priceMultiplier) * 100).round() : 0;

    batch.update(tourDoc.reference, {
      'price': newPrice,
      'isHot': isHot,
      'discountPercent': discountPercent,
      'lastUpdated': dayKey,
    });
  }

  batch.set(docRef, {
    'updatedAt': FieldValue.serverTimestamp(),
    'hotTours': hotTourIds.toList(),
    'dayKey': dayKey,
  });

  await batch.commit();
}

// ── Проверка алертов и отправка уведомлений ───────────────────────
Future<void> _checkAlerts(FirebaseFirestore db, String uid) async {
  final notifications = FlutterLocalNotificationsPlugin();
  await notifications.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  final snap = await db
      .collection('users')
      .doc(uid)
      .collection('priceAlerts')
      .where('isActive', isEqualTo: true)
      .get();

  final today = _dayKey();

  for (final alertDoc in snap.docs) {
    final data = alertDoc.data();
    final tourId = data['tourId'] as String;
    final targetPrice = (data['targetPrice'] as num).toDouble();
    final hotelName = data['hotelName'] as String;
    final wasTriggered = data['isTriggered'] as bool? ?? false;
    final lastNotifiedDay = data['lastNotifiedDay'] as String?;

    // Читаем актуальную цену напрямую из Firestore
    final tourDoc = await db.collection('tours').doc(tourId).get();
    if (!tourDoc.exists) continue;

    final currentPrice =
        (tourDoc.data()?['price'] as num?)?.toDouble() ?? 0;

    final updates = <String, dynamic>{'currentPrice': currentPrice};

    if (currentPrice <= targetPrice) {
      // Уже уведомляли сегодня — не спамим
      if (lastNotifiedDay == today) {
        await alertDoc.reference.update(updates);
        continue;
      }

      // Помечаем триггер и день уведомления
      updates['isTriggered'] = true;
      updates['lastNotifiedDay'] = today;
      if (!wasTriggered) {
        updates['triggeredAt'] = FieldValue.serverTimestamp();
      }

      // Считаем процент снижения
      final dropPct = targetPrice > 0
          ? ((targetPrice - currentPrice) / targetPrice * 100).round()
          : 0;

      await notifications.show(
        tourId.hashCode.abs() % 10000,
        '🎯 Цена снизилась на $dropPct%!',
        '$hotelName — ${_fmt(currentPrice)} ₸ (цель: ${_fmt(targetPrice)} ₸)',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'price_alerts',
            'Снижение цен',
            channelDescription: 'Уведомления о снижении цен на туры',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }

    // Цена вернулась выше цели — сбрасываем
    if (currentPrice > targetPrice && wasTriggered) {
      updates['isTriggered'] = false;
      updates['lastNotifiedDay'] = null;
    }

    await alertDoc.reference.update(updates);
  }
}

// ── Helpers ───────────────────────────────────────────────────────
String _dayKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month}-${now.day}';
}

String _fmt(double p) => p.toInt().toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

// ═══════════════════════════════════════════════════════════════════
// BackgroundService
// ═══════════════════════════════════════════════════════════════════
class BackgroundService {
  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
    );
  }

  static Future<void> registerPriceCheck() async {
    // Отменяем старые задачи
    await Workmanager().cancelAll();

    // 4 проверки в день — утро, день, вечер, ночь
    final times = [
      (hour: 9,  minute: 0,  name: 'priceCheck_09'),
      (hour: 13, minute: 0,  name: 'priceCheck_13'),
      (hour: 18, minute: 0,  name: 'priceCheck_18'),
      (hour: 21, minute: 0,  name: 'priceCheck_21'),
    ];

    for (final t in times) {
      await Workmanager().registerPeriodicTask(
        t.name,
        _kPriceCheckTask,
        frequency: const Duration(hours: 24),
        initialDelay: _delayUntil(hour: t.hour, minute: t.minute),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      );
    }
  }

  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
  }

  static Duration _delayUntil({required int hour, required int minute}) {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, hour, minute);
    if (target.isBefore(now)) {
      target = target.add(const Duration(days: 1));
    }
    return target.difference(now);
  }
}