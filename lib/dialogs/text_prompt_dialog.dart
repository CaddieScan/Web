import 'package:flutter/material.dart';

// un simple dialog pour demander un texte à l'utilisateur
// utilisé pour renommer des catégories, des étages, ou créer une nouvelle catégorie avec un nom
class TextPromptDialog extends StatefulWidget {
  final String title;
  final String hint;
  final String? initial;

  const TextPromptDialog({
    super.key,
    required this.title,
    required this.hint,
    this.initial,
  });

  @override
  State<TextPromptDialog> createState() => TextPromptDialogState();
}

class TextPromptDialogState extends State<TextPromptDialog> {
  late TextEditingController ctrl;
  String error = '';

  @override
  void initState() {
    super.initState();
    ctrl = TextEditingController(text: widget.initial ?? '');
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  void submit() {
    // valide le texte et ferme le dialog en le retournant
    final v = ctrl.text.trim();
    if (v.isEmpty) {
      setState(() => error = 'Champ obligatoire');
      return;
    }
    Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              decoration: InputDecoration(
                labelText: widget.hint,
                errorText: error.isEmpty ? null : error,
              ),
              onSubmitted: (submittedValue) => submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(onPressed: submit, child: const Text('OK')),
      ],
    );
  }
}
