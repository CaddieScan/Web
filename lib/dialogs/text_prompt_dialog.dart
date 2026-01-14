import 'package:flutter/material.dart';

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
  State<TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<TextPromptDialog> {
  late final TextEditingController ctrl;
  String? error;

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
                errorText: error,
              ),
              onSubmitted: (_) => submit(),
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
