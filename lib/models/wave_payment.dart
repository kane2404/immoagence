enum PaymentStatus { pending, successful, failed, cancelled }

enum PaymentPurpose { reservation, deposit, rent, saleAdvance, fullPurchase }

class WavePayment {
  const WavePayment({
    required this.id,
    required this.reference,
    required this.clientId,
    required this.propertyId,
    required this.amount,
    required this.phone,
    required this.purpose,
    required this.status,
    required this.createdAt,
    this.confirmedAt,
  });

  final String id;
  final String reference;
  final String clientId;
  final String propertyId;
  final int amount;
  final String phone;
  final PaymentPurpose purpose;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? confirmedAt;

  bool get isConfirmed => status == PaymentStatus.successful;
}
