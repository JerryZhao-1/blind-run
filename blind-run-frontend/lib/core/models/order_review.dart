class OrderReview {
  const OrderReview({
    required this.orderId,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  final int orderId;
  final int rating;
  final String comment;
  final DateTime? createdAt;
}
