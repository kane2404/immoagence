enum ContractType { rental, colocation, landSale, houseSale }

enum ContractStatus { draft, pendingSignature, signed, cancelled }

class Contract {
  const Contract({
    required this.id,
    required this.reference,
    required this.type,
    required this.status,
    required this.propertyId,
    required this.clientId,
    required this.startDate,
    required this.amount,
    required this.terms,
    this.endDate,
    this.signedAt,
  });

  final String id;
  final String reference;
  final ContractType type;
  final ContractStatus status;
  final String propertyId;
  final String clientId;
  final DateTime startDate;
  final DateTime? endDate;
  final int amount;
  final List<String> terms;
  final DateTime? signedAt;

  bool get isSigned => status == ContractStatus.signed;
}
