
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackService {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static Future<void> sendFeedback({
    required int rating,
    required String category,
    required String message,
  }) async {
    // Garante que o usuário esteja autenticado.
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }

    await _firestore.collection('feedbacks').add({
      'rating': rating,
      'category': category,
      'message': message.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
