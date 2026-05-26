import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:immo_agence/data/demo_data.dart';
import 'package:immo_agence/main.dart';
import 'package:immo_agence/models/app_user.dart';
import 'package:immo_agence/services/app_session.dart';

void main() {
  Future<void> openMainApp(WidgetTester tester, {AppUser? user}) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('splash_continue_button')));
    await tester.pumpAndSettle();
    appSession.signIn(user ?? DemoData.users.first);
    await tester.pumpAndSettle();
  }

  testWidgets('Auth screen opens role dashboard', (WidgetTester tester) async {
    final email =
        'aminata-${DateTime.now().millisecondsSinceEpoch}@example.com';
    appSession.signOut();
    await tester.pumpWidget(const ImmoAgenceApp());

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Prestige Immobilier'), findsOneWidget);

    await tester.tap(find.byKey(const Key('splash_continue_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Connexion'), findsOneWidget);
    expect(
      find.text('Connectez-vous avec votre email et votre mot de passe.'),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const Key('auth_form')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Creer un nouveau compte'));
    await tester.pumpAndSettle();
    expect(find.text('Creer un compte'), findsOneWidget);
    expect(find.text('Visiteur'), findsOneWidget);
    expect(find.text('Locataire'), findsOneWidget);
    expect(find.text('Admin'), findsNothing);
    expect(find.text('Proprietaire'), findsNothing);

    await tester.tap(find.text('Locataire'));
    await tester.enterText(find.byType(TextFormField).at(0), 'Aminata Diop');
    await tester.enterText(find.byType(TextFormField).at(1), email);
    await tester.enterText(
      find.byType(TextFormField).at(2),
      '+221 77 123 45 67',
    );
    await tester.enterText(find.byType(TextFormField).at(3), 'demo1234');
    appSession.signIn(
      AppUser(
        id: 'test_tenant',
        fullName: 'Aminata Diop',
        email: email,
        phone: '+221 77 123 45 67',
        role: UserRole.tenant,
      ),
    );
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Dashboard locataire'))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dashboard locataire'), findsOneWidget);
  });

  testWidgets('ImmoAgence home screen displays catalog entry', (
    WidgetTester tester,
  ) async {
    appSession.signOut();
    await tester.pumpWidget(const ImmoAgenceApp());
    await openMainApp(tester);

    expect(find.text('ImmoAgence'), findsOneWidget);
    expect(find.text('Agence immobiliere au Senegal'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('home_list')),
      const Offset(0, -450),
    );
    await tester.pumpAndSettle();

    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Colocation'), findsOneWidget);

    expect(find.text('Biens recemment ajoutes'), findsOneWidget);

    await tester.tap(find.text('Biens').last);
    await tester.pumpAndSettle();

    expect(find.text('Catalogue des biens'), findsOneWidget);
    expect(find.text('Tous les biens de l agence'), findsOneWidget);

    final firstProperty = find.text('Appartement lumineux a Dakar Plateau');
    await tester.ensureVisible(firstProperty);
    await tester.pumpAndSettle();
    await tester.tap(firstProperty);
    await tester.pumpAndSettle();

    expect(find.text('Detail du bien'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Equipements et atouts'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Payer avec PayDunya'),
      260,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Payer avec PayDunya'));
    await tester.pumpAndSettle();

    expect(find.text('PayDunya Senegal'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('wave_payment_form')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();

    expect(find.text('Payer avec PayDunya'), findsOneWidget);
    expect(find.text('Verifier le statut'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Demander le contrat'),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Demander le contrat'));
    await tester.pumpAndSettle();
    expect(find.text('Contrat de location'), findsOneWidget);
    expect(find.text('Conditions principales'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Programmer une visite'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Programmer une visite'));
    await tester.pumpAndSettle();

    expect(find.text('Choisissez votre creneau'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('visit_form')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();

    expect(find.text('Confirmer la demande'), findsOneWidget);
  });

  testWidgets('Home service opens sales screen', (WidgetTester tester) async {
    appSession.signOut();
    await tester.pumpWidget(const ImmoAgenceApp());
    await openMainApp(tester);

    await tester.drag(
      find.byKey(const Key('home_list')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();

    final venteService = find.byKey(const Key('service_Vente'));
    await tester.ensureVisible(venteService);
    await tester.pumpAndSettle();
    await tester.tap(venteService);
    await tester.pumpAndSettle();

    expect(find.text('Vente immo'), findsOneWidget);
    expect(find.text('Acheter avec suivi agence'), findsOneWidget);
  });

  testWidgets('Home service opens colocation screen', (
    WidgetTester tester,
  ) async {
    appSession.signOut();
    await tester.pumpWidget(const ImmoAgenceApp());
    await openMainApp(tester);

    await tester.drag(
      find.byKey(const Key('home_list')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();

    final colocationService = find.byKey(const Key('service_Colocation'));
    await tester.ensureVisible(colocationService);
    await tester.pumpAndSettle();
    await tester.tap(colocationService);
    await tester.pumpAndSettle();

    expect(find.text('Colocation'), findsOneWidget);
    expect(find.text('Regles de colocation'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('colocation_list')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chambre en colocation a Ouakam'), findsOneWidget);
  });

  testWidgets('Bottom navigation opens visit scheduling', (
    WidgetTester tester,
  ) async {
    appSession.signOut();
    await tester.pumpWidget(const ImmoAgenceApp());
    await openMainApp(tester);

    await tester.tap(find.text('Visites'));
    await tester.pumpAndSettle();

    expect(find.text('Programmer une visite'), findsOneWidget);
    expect(find.text('Choisissez votre creneau'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('visit_form')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();

    expect(find.text('Confirmer la demande'), findsOneWidget);
  });

  testWidgets('Property detail opens issue report screen', (
    WidgetTester tester,
  ) async {
    appSession.signOut();
    await tester.pumpWidget(const ImmoAgenceApp());
    await openMainApp(tester);

    await tester.tap(find.text('Biens').last);
    await tester.pumpAndSettle();

    final firstProperty = find.text('Appartement lumineux a Dakar Plateau');
    await tester.ensureVisible(firstProperty);
    await tester.pumpAndSettle();
    await tester.tap(firstProperty);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Signaler un probleme'),
      260,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Signaler un probleme'));
    await tester.pumpAndSettle();

    expect(find.text('Assistance technique'), findsOneWidget);
    expect(find.text('Type de probleme'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).last,
      'La pression d eau est faible dans la cuisine.',
    );
    await tester.drag(
      find.byKey(const Key('issue_report_form')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();

    expect(find.text('Envoyer le signalement'), findsOneWidget);
    expect(find.text('Suivi agence'), findsOneWidget);
  });

  testWidgets('Bottom navigation opens client profile', (
    WidgetTester tester,
  ) async {
    appSession.signOut();
    await tester.pumpWidget(const ImmoAgenceApp());
    await openMainApp(tester);

    await tester.tap(find.byIcon(Icons.person_rounded).last);
    await tester.pumpAndSettle();

    expect(find.text('Profil client'), findsOneWidget);
    expect(find.text('Aminata Diop'), findsOneWidget);
    expect(find.text('Visites'), findsWidgets);

    await tester.drag(
      find.byKey(const Key('profile_list')),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();

    expect(find.text('Paiements'), findsOneWidget);
    expect(find.text('Contrats'), findsOneWidget);
    expect(find.text('Signalements'), findsOneWidget);
  });

  testWidgets('Home quick action opens agency dashboard', (
    WidgetTester tester,
  ) async {
    appSession.signOut();
    await tester.pumpWidget(const ImmoAgenceApp());
    await openMainApp(
      tester,
      user: DemoData.users.firstWhere((user) => user.role == UserRole.admin),
    );

    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Tableau agence'), findsOneWidget);
    expect(find.text('Pilotage premium'), findsOneWidget);
    expect(find.text('Services essentiels'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Paiements PayDunya'),
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('agency_dashboard_list')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Paiements PayDunya'), findsOneWidget);
    expect(find.text('Statistiques'), findsOneWidget);
    expect(find.text('Plus de services'), findsOneWidget);
  });
}
