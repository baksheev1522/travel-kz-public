import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/entities.dart';
import '../models/tour_model.dart';
import '../services/dynamic_pricing_service.dart';

class TourRepository {
  final _db = FirebaseFirestore.instance;
  final _collection = 'tours';
  final _pricing = DynamicPricingService();

  Future<void> seedToursIfEmpty() async {
    final snapshot = await _db.collection(_collection).limit(1).get();
    if (snapshot.docs.isEmpty) {
      final batch = _db.batch();
      for (final tour in TourModel.seedData) {
        final ref = _db.collection(_collection).doc(tour.id);
        batch.set(ref, TourModel.toFirestore(tour));
      }
      await batch.commit();
    }
  }

  Future<List<Tour>> getTours() async {
    return _pricing.getTodaysTours();
  }

  Future<List<Tour>> getHotTours() async {
    final tours = await _pricing.getTodaysTours();
    return tours.where((t) => t.isHot).toList();
  }

  Future<List<Tour>> getToursByCountry(String country) async {
    final tours = await _pricing.getTodaysTours();
    return tours.where((t) => t.country == country).toList();
  }

  Future<Tour?> getTourById(String id) async {
    final doc = await _db.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return TourModel.fromFirestore(doc.data()!, doc.id);
  }
}