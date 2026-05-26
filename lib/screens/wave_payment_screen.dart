import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_notification.dart';
import '../models/property.dart';
import '../services/api_exception.dart';
import '../services/notification_center.dart';
import '../services/paydunya_payment_api.dart';
import '../theme/app_colors.dart';
import 'receipt_screen.dart';

class WavePaymentScreen extends StatefulWidget {
  const WavePaymentScreen({super.key, required this.property});

  final Property property;

  @override
  State<WavePaymentScreen> createState() => _WavePaymentScreenState();
}

class _WavePaymentScreenState extends State<WavePaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _paymentApi = const PayDunyaPaymentApi();

  PayDunyaCheckout? _checkout;
  bool _isLoading = false;
  bool _isPaid = false;

  int get _amount {
    if (widget.property.offerType == PropertyOfferType.sale) {
      return (widget.property.price * 0.05).round();
    }

    return widget.property.price;
  }

  String get _reference {
    return _checkout?.reference ??
        'PAYDUNYA-IMMO-${widget.property.id.toUpperCase()}';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String get _purpose {
    if (widget.property.offerType == PropertyOfferType.sale) {
      return 'sale_advance';
    }
    return 'reservation';
  }

  Future<void> _startPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final checkout = await _paymentApi.createCheckout(
        propertyId: widget.property.id,
        amount: _amount,
        phone: _phoneController.text.trim(),
        purpose: _purpose,
      );
      final url = Uri.parse(checkout.checkoutUrl);
      final opened = await launchUrl(url, mode: LaunchMode.externalApplication);

      if (!opened) {
        throw const ApiException('Ouverture de PayDunya impossible.');
      }

      notificationCenter.push(
        title: 'Paiement lance',
        message:
            'La page PayDunya est ouverte pour Wave, Orange Money ou carte bancaire.',
        type: AppNotificationType.payment,
      );

      if (!mounted) return;
      setState(() => _checkout = checkout);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paiement PayDunya lance : ${checkout.reference}'),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paiement PayDunya indisponible.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyPayment() async {
    final checkout = _checkout;
    if (checkout == null) return;

    setState(() => _isLoading = true);

    try {
      final status = await _paymentApi.confirmPayment(checkout.token);
      final paid = status == 'successful';

      if (!mounted) return;
      setState(() => _isPaid = paid);

      notificationCenter.push(
        title: paid ? 'Paiement confirme' : 'Paiement en attente',
        message: paid
            ? 'Le paiement ${checkout.reference} est confirme par PayDunya.'
            : 'Le paiement ${checkout.reference} est encore en attente.',
        type: AppNotificationType.payment,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            paid ? 'Paiement confirme.' : 'Paiement encore en attente.',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paiement securise')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            key: const Key('wave_payment_form'),
            padding: const EdgeInsets.all(20),
            children: [
              const _WaveHeader(),
              const SizedBox(height: 16),
              _PaymentSummary(
                property: widget.property,
                amount: _amount,
                reference: _reference,
                isPaid: _isPaid,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telephone de paiement',
                  hintText: '+221 77 000 00 00',
                  prefixIcon: Icon(Icons.phone_iphone_rounded),
                ),
                validator: (value) {
                  final cleaned = value?.replaceAll(' ', '').trim() ?? '';
                  if (cleaned.length < 9) {
                    return 'Entrez un numero valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              const _SecurityNotice(),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _isPaid || _isLoading ? null : _startPayment,
                icon: Icon(
                  _isPaid ? Icons.check_circle_rounded : Icons.lock_rounded,
                ),
                label: Text(
                  _isLoading
                      ? 'Connexion PayDunya...'
                      : _isPaid
                      ? 'Paiement confirme'
                      : 'Payer avec PayDunya',
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _checkout == null || _isLoading
                    ? null
                    : _verifyPayment,
                icon: const Icon(Icons.verified_rounded),
                label: const Text('Verifier le statut'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _isPaid
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ReceiptScreen(
                              property: widget.property,
                              amount: _amount,
                              reference: _reference,
                              phone: _phoneController.text,
                            ),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.receipt_long_rounded),
                label: const Text('Voir le recu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaveHeader extends StatelessWidget {
  const _WaveHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.waveBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PayDunya Senegal',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontSize: 25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Paiement reel en mode test via Wave Senegal, Orange Money Senegal ou carte bancaire. La facture est creee par le backend securise.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary({
    required this.property,
    required this.amount,
    required this.reference,
    required this.isPaid,
  });

  final Property property;
  final int amount;
  final String reference;
  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    property.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _StatusBadge(isPaid: isPaid),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              property.location,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            _SummaryLine(label: 'Montant', value: '$amount FCFA'),
            const SizedBox(height: 8),
            _SummaryLine(label: 'Reference', value: reference),
            const SizedBox(height: 8),
            _SummaryLine(
              label: 'Statut',
              value: isPaid ? 'Confirme' : 'En attente',
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isPaid});

  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    final color = isPaid ? AppColors.success : AppColors.warning;
    final label = isPaid ? 'Confirme' : 'En attente';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SecurityNotice extends StatelessWidget {
  const _SecurityNotice();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.shield_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Les cles PayDunya restent sur le backend. L application ouvre seulement la page officielle de paiement et verifie ensuite le statut.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
