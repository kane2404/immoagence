import '../core/app_assets.dart';
import '../models/app_user.dart';
import '../models/contract.dart';
import '../models/issue_report.dart';
import '../models/property.dart';
import '../models/receipt.dart';
import '../models/visit.dart';
import '../models/wave_payment.dart';

class DemoData {
  const DemoData._();

  static const users = [
    AppUser(
      id: 'user_001',
      fullName: 'Aminata Diop',
      phone: '+221 77 123 45 67',
      role: UserRole.tenant,
      email: 'aminata.diop@example.com',
    ),
    AppUser(
      id: 'user_002',
      fullName: 'Mamadou Fall',
      phone: '+221 78 222 33 44',
      role: UserRole.agent,
      email: 'mamadou.fall@immoagence.sn',
    ),
    AppUser(
      id: 'user_003',
      fullName: 'Fatou Sarr',
      phone: '+221 76 555 11 22',
      role: UserRole.owner,
    ),
    AppUser(
      id: 'user_004',
      fullName: 'Khady Ndiaye',
      phone: '+221 70 111 22 33',
      role: UserRole.admin,
      email: 'admin@immoagence.sn',
    ),
  ];

  static const properties = [
    Property(
      id: 'property_001',
      title: 'Appartement lumineux a Dakar Plateau',
      type: PropertyType.apartment,
      offerType: PropertyOfferType.rent,
      status: PropertyStatus.available,
      price: 450000,
      location: 'Dakar Plateau',
      imagePaths: [AppAssets.appartementDakar],
      description:
          'Appartement proche des services, ideal pour famille ou jeune actif.',
      features: ['3 chambres', 'Salon', 'Cuisine equipee', 'Gardiennage'],
      rooms: 3,
      bathrooms: 2,
      surfaceArea: 118,
      isFurnished: true,
    ),
    Property(
      id: 'property_002',
      title: 'Maison familiale aux Almadies',
      type: PropertyType.house,
      offerType: PropertyOfferType.sale,
      status: PropertyStatus.available,
      price: 85000000,
      location: 'Almadies',
      imagePaths: [AppAssets.maisonAlmadies],
      description:
          'Maison spacieuse avec cour, stationnement et acces rapide a la corniche.',
      features: ['4 chambres', 'Cour', 'Parking', 'Titre foncier'],
      rooms: 4,
      bathrooms: 3,
      surfaceArea: 260,
    ),
    Property(
      id: 'property_003',
      title: 'Terrain viabilise a Saly',
      type: PropertyType.land,
      offerType: PropertyOfferType.sale,
      status: PropertyStatus.available,
      price: 18500000,
      location: 'Saly',
      imagePaths: [AppAssets.terrainSaly],
      description:
          'Terrain accessible, proche de la route principale et pret pour construction.',
      features: ['500 m2', 'Acces route', 'Zone calme', 'Dossier disponible'],
      surfaceArea: 500,
    ),
    Property(
      id: 'property_004',
      title: 'Chambre en colocation a Ouakam',
      type: PropertyType.sharedRoom,
      offerType: PropertyOfferType.colocation,
      status: PropertyStatus.available,
      price: 125000,
      location: 'Ouakam',
      imagePaths: [AppAssets.colocationOuakam],
      description:
          'Chambre meublee dans appartement partage, charges organisees par l agence.',
      features: [
        'Chambre meublee',
        'Internet',
        'Cuisine partagee',
        'Eau incluse',
      ],
      rooms: 1,
      bathrooms: 1,
      surfaceArea: 18,
      isFurnished: true,
    ),
    Property(
      id: 'property_005',
      title: 'Villa avec jardin a Ngaparou',
      type: PropertyType.villa,
      offerType: PropertyOfferType.sale,
      status: PropertyStatus.reserved,
      price: 120000000,
      location: 'Ngaparou',
      imagePaths: [AppAssets.villaNgaparou],
      description:
          'Villa haut standing avec jardin, terrasse et espace familial.',
      features: ['5 chambres', 'Jardin', 'Terrasse', 'Piscine possible'],
      rooms: 5,
      bathrooms: 4,
      surfaceArea: 420,
    ),
    Property(
      id: 'property_006',
      title: 'Studio pratique a la Medina',
      type: PropertyType.studio,
      offerType: PropertyOfferType.rent,
      status: PropertyStatus.available,
      price: 180000,
      location: 'Medina',
      imagePaths: [AppAssets.studioMedina],
      description:
          'Studio simple et bien place, proche transports et commerces.',
      features: ['Studio', 'Salle d eau', 'Compteur separe', 'Acces rapide'],
      rooms: 1,
      bathrooms: 1,
      surfaceArea: 32,
    ),
  ];

  static final visits = [
    Visit(
      id: 'visit_001',
      propertyId: 'property_001',
      clientId: 'user_001',
      agentId: 'user_002',
      scheduledAt: DateTime(2026, 5, 12, 10, 30),
      status: VisitStatus.confirmed,
      message: 'Je souhaite visiter avec mon epoux.',
    ),
    Visit(
      id: 'visit_002',
      propertyId: 'property_003',
      clientId: 'user_001',
      agentId: 'user_002',
      scheduledAt: DateTime(2026, 5, 13, 16),
      status: VisitStatus.pending,
      message: 'Besoin de verifier les documents du terrain.',
    ),
  ];

  static final payments = [
    WavePayment(
      id: 'payment_001',
      reference: 'WAVE-IMMO-20260510-001',
      clientId: 'user_001',
      propertyId: 'property_004',
      amount: 125000,
      phone: '+221 77 123 45 67',
      purpose: PaymentPurpose.reservation,
      status: PaymentStatus.successful,
      createdAt: DateTime(2026, 5, 10, 11, 15),
      confirmedAt: DateTime(2026, 5, 10, 11, 16),
    ),
  ];

  static final contracts = [
    Contract(
      id: 'contract_001',
      reference: 'CTR-COL-20260510-001',
      type: ContractType.colocation,
      status: ContractStatus.pendingSignature,
      propertyId: 'property_004',
      clientId: 'user_001',
      startDate: DateTime(2026, 6, 1),
      amount: 125000,
      terms: [
        'Paiement du loyer avant le 5 de chaque mois.',
        'Respect des espaces communs.',
        'Signalement rapide des problemes d eau, electricite ou plomberie.',
      ],
    ),
  ];

  static final receipts = [
    Receipt(
      id: 'receipt_001',
      reference: 'RCU-20260510-001',
      paymentId: 'payment_001',
      clientId: 'user_001',
      propertyId: 'property_004',
      amount: 125000,
      issuedAt: DateTime(2026, 5, 10, 11, 17),
      label: 'Recu de reservation colocation',
    ),
  ];

  static final issueReports = [
    IssueReport(
      id: 'issue_001',
      propertyId: 'property_004',
      clientId: 'user_001',
      category: IssueCategory.plumbing,
      priority: IssuePriority.normal,
      status: IssueStatus.inProgress,
      description: 'Fuite legere sous le lavabo de la cuisine partagee.',
      createdAt: DateTime(2026, 5, 9, 8, 45),
      agencyComment: 'Plombier programme pour demain matin.',
    ),
  ];
}
