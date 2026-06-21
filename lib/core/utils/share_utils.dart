import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

abstract class ShareUtils {
  /// Поделиться туром
  static void shareTour({
    required BuildContext context,
    required String title,
    required String country,
    required String city,
    required double price,
    required int nights,
  }) {
    final text =
        '✈️ $title\n'
        '📍 $country, $city\n'
        '🌙 $nights ночей\n'
        '💰 ${_fmt(price)} ₸\n\n'
        'Смотри в приложении TravelKZ!';
    _share(context, text);
  }

  /// Поделиться отелем
  static void shareHotel({
    required BuildContext context,
    required String name,
    required String country,
    required String city,
    required int stars,
    required double rating,
  }) {
    final text =
        '🏨 $name ${'★' * stars}\n'
        '📍 $country, $city\n'
        '⭐ Рейтинг: $rating\n\n'
        'Смотри в приложении TravelKZ!';
    _share(context, text);
  }

  /// Поделиться чартером
  static void shareCharter({
    required BuildContext context,
    required String fromCity,
    required String toCity,
    required String date,
    required String price,
    required String flightNumber,
  }) {
    final text =
        '✈️ Чартер $fromCity → $toCity\n'
        '📅 $date\n'
        '🎫 Рейс: $flightNumber\n'
        '💰 $price ₸\n\n'
        'Смотри в приложении TravelKZ!';
    _share(context, text);
  }

  static void _share(BuildContext context, String text) {
  Share.share(text, subject: 'TravelKZ');
}

  static String _fmt(double p) => p
      .toInt()
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
}