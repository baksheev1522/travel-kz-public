import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WishlistService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _col {
    if (_uid == null) return null;
    return _db.collection('users').doc(_uid).collection('wishlist');
  }

  // ── Stream списка ─────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> stream() {
    if (_col == null) return const Stream.empty();
    return _col!.snapshots().map(
      (snap) => snap.docs.map((d) => {...d.data(), 'id': d.id}).toList(),
    );
  }

  Stream<bool> streamContains(String tourId) {
  if (_col == null) return Stream.value(false);
  return _col!.doc(tourId).snapshots().map((doc) => doc.exists);
}

  // ── Проверить наличие ─────────────────────────────────────────
  Future<bool> contains(String tourId) async {
    if (_col == null) return false;
    final doc = await _col!.doc(tourId).get();
    return doc.exists;
  }

  // ── Добавить (сохраняем снапшот тура) ────────────────────────
  Future<void> add({
    required String tourId,
    required String hotelName,
    required String country,
    required String city,
    required String imageUrl,
    required int stars,
    required int nights,
    required String mealType,
    required double price,
    required double originalPrice,
    required bool isHot,
  }) async {
    if (_col == null) return;
    await _col!.doc(tourId).set({
      'tourId': tourId,
      'hotelName': hotelName,
      'country': country,
      'city': city,
      'imageUrl': imageUrl,
      'stars': stars,
      'nights': nights,
      'mealType': mealType,
      'price': price,
      'originalPrice': originalPrice,
      'isHot': isHot,
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Удалить ───────────────────────────────────────────────────
  Future<void> remove(String tourId) async {
    if (_col == null) return;
    await _col!.doc(tourId).delete();
  }

  // ── Переключить ───────────────────────────────────────────────
  Future<bool> toggle({
    required String tourId,
    required String hotelName,
    required String country,
    required String city,
    required String imageUrl,
    required int stars,
    required int nights,
    required String mealType,
    required double price,
    required double originalPrice,
    required bool isHot,
  }) async {
    final exists = await contains(tourId);
    if (exists) {
      await remove(tourId);
      return false; // убрали из избранного
    } else {
      await add(
        tourId: tourId,
        hotelName: hotelName,
        country: country,
        city: city,
        imageUrl: imageUrl,
        stars: stars,
        nights: nights,
        mealType: mealType,
        price: price,
        originalPrice: originalPrice,
        isHot: isHot,
      );
      return true; // добавили в избранное
    }
  }
}