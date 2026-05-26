class Receipt {
  const Receipt({
    required this.id,
    required this.reference,
    required this.paymentId,
    required this.clientId,
    required this.propertyId,
    required this.amount,
    required this.issuedAt,
    required this.label,
  });

  final String id;
  final String reference;
  final String paymentId;
  final String clientId;
  final String propertyId;
  final int amount;
  final DateTime issuedAt;
  final String label;
}
