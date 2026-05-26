enum VisitStatus { pending, confirmed, completed, cancelled }

class Visit {
  const Visit({
    required this.id,
    required this.propertyId,
    required this.clientId,
    required this.scheduledAt,
    required this.status,
    this.agentId,
    this.message,
  });

  final String id;
  final String propertyId;
  final String clientId;
  final DateTime scheduledAt;
  final VisitStatus status;
  final String? agentId;
  final String? message;

  bool get canBeCancelled =>
      status == VisitStatus.pending || status == VisitStatus.confirmed;
}
