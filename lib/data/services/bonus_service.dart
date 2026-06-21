import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BonusService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<int> getBalance() async {
    if (_uid == null) return 0;
    final doc = await _db.collection('users').doc(_uid).get();
    if (!doc.exists) return 0;
    return (doc.data()?['bonusPoints'] ?? 0) as int;
  }

  // Начислить бонусы (5% от суммы)
  Future<int> addBonus(double tourPrice) async {
    if (_uid == null) return 0;
    final earned = (tourPrice * 0.05).round();
    await _db.collection('users').doc(_uid).update({
      'bonusPoints': FieldValue.increment(earned),
    });
    return earned;
  }

  // Списать бонусы
  Future<bool> useBonus(int amount) async {
    if (_uid == null) return false;
    final balance = await getBalance();
    if (balance < amount) return false;
    await _db.collection('users').doc(_uid).update({
      'bonusPoints': FieldValue.increment(-amount),
    });
    return true;
  }
}