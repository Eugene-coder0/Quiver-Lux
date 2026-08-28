import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The signed-in customer's own rating for each product in this demo session.
class ReviewNotifier extends StateNotifier<Map<String, int>> {
  ReviewNotifier() : super(const {});

  void setRating(String productId, int rating) {
    state = {...state, productId: rating.clamp(1, 5)};
  }
}

final productReviewProvider =
    StateNotifierProvider<ReviewNotifier, Map<String, int>>(
  (ref) => ReviewNotifier(),
);
