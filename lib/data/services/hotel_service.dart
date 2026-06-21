import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hotel_model.dart';

class HotelService {
  final _db = FirebaseFirestore.instance;

  Future<void> seedHotelsIfEmpty() async {
    final snap = await _db.collection('hotels').limit(1).get();
    if (snap.docs.isNotEmpty) return;
    final batch = _db.batch();
    for (final hotel in HotelModel.seedData) {
      final ref = _db.collection('hotels').doc(hotel['id']);
      batch.set(ref, hotel);
    }
    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> getHotels() async {
    final snap = await _db.collection('hotels').get();
    return snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }

  Future<Map<String, dynamic>?> getHotelById(String id) async {
    final doc = await _db.collection('hotels').doc(id).get();
    if (!doc.exists) return null;
    return {...doc.data()!, 'id': doc.id};
  }

  Future<List<Map<String, dynamic>>> getHotelsByCountry(String country) async {
    final snap = await _db
        .collection('hotels')
        .where('country', isEqualTo: country)
        .get();
    return snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }
}