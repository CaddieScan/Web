import 'package:flutter/material.dart';

// un widget pour afficher une tooltip personnalisée sur le plan du magasin
// par exemple pour afficher le nom d'une zone ou d'un point d'intérêt lorsque l'utilisateur clique dessus

class StoreMapTooltip extends StatelessWidget {
  final String text;
  final double left;
  final double top;

  const StoreMapTooltip({
    super.key,
    required this.text,
    required this.left,
    required this.top,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.78),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
