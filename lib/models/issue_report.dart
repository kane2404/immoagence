enum IssueCategory {
  electricity,
  water,
  plumbing,
  lock,
  painting,
  roof,
  internet,
  neighborhood,
  cleaning,
  other,
}

enum IssuePriority { low, normal, urgent }

enum IssueStatus { newReport, inProgress, resolved, rejected }

class IssueReport {
  const IssueReport({
    required this.id,
    required this.propertyId,
    required this.clientId,
    required this.category,
    required this.priority,
    required this.status,
    required this.description,
    required this.createdAt,
    this.photoPath,
    this.agencyComment,
  });

  final String id;
  final String propertyId;
  final String clientId;
  final IssueCategory category;
  final IssuePriority priority;
  final IssueStatus status;
  final String description;
  final DateTime createdAt;
  final String? photoPath;
  final String? agencyComment;

  bool get requiresFastAction => priority == IssuePriority.urgent;
}
