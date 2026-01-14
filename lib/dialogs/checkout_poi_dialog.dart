import 'package:flutter/material.dart';
import '../models/store_poi_models.dart';

class CheckoutPoiDialog extends StatefulWidget {
  final StorePoi poi;

  const CheckoutPoiDialog({super.key, required this.poi});

  @override
  State<CheckoutPoiDialog> createState() => _CheckoutPoiDialogState();
}

class _CheckoutPoiDialogState extends State<CheckoutPoiDialog> {
  late CheckoutKind kind;
  late PaymentMode payment;
  late bool accessible;
  late TextEditingController labelCtrl;

  @override
  void initState() {
    super.initState();
    kind = widget.poi.checkoutKind;
    payment = widget.poi.paymentMode;
    accessible = widget.poi.isAccessible;
    labelCtrl = TextEditingController(text: widget.poi.label);
  }

  @override
  void dispose() {
    labelCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.poi.checkoutKind = kind;
    widget.poi.paymentMode = payment;
    widget.poi.isAccessible = accessible;
    widget.poi.label = labelCtrl.text.trim().isEmpty ? 'Caisse' : labelCtrl.text.trim();
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configurer la caisse'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(labelText: 'Titre (optionnel)'),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<CheckoutKind>(
              value: kind,
              items: const [
                DropdownMenuItem(value: CheckoutKind.selfCheckout, child: Text('Caisse automatique')),
                DropdownMenuItem(value: CheckoutKind.cashier, child: Text('Caisse avec caissiere')),
              ],
              onChanged: (v) => setState(() => kind = v!),
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<PaymentMode>(
              value: payment,
              items: const [
                DropdownMenuItem(value: PaymentMode.cardOnly, child: Text('Carte uniquement')),
                DropdownMenuItem(value: PaymentMode.cardAndCash, child: Text('Carte + especes')),
              ],
              onChanged: (v) => setState(() => payment = v!),
              decoration: const InputDecoration(labelText: 'Paiement'),
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              value: accessible,
              onChanged: (v) => setState(() => accessible = v),
              title: const Text('Caisse accessible (PMR)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
        ElevatedButton(onPressed: _save, child: const Text('Enregistrer')),
      ],
    );
  }
}
