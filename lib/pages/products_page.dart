import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/store.dart';
import '../services/product_service.dart';

class ProductsPage extends StatefulWidget {
  final Store store;
  final ProductService productService;

  const ProductsPage({
    super.key,
    required this.store,
    required this.productService,
  });

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  static const String _placeholderImg = 'images/product_placeholder.png';
  bool _loading = true;
  String? _error;

  List<Product> _all = [];
  String _search = '';
  String _category = 'Tous';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await widget.productService.fetchProducts(widget.store.id);
      setState(() {
        _all = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  List<String> get _categories {
    final set = <String>{'Tous'};
    for (final p in _all) {
      set.add(p.category);
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  List<Product> get _filtered {
    return _all.where((p) {
      final matchSearch =
          _search.isEmpty || p.name.toLowerCase().contains(_search.toLowerCase());
      final matchCat = _category == 'Tous' || p.category == _category;
      return matchSearch && matchCat;
    }).toList();
  }

  Future<void> _addNewProduct() async {
    final created = await showDialog<Product>(
      context: context,
      builder: (_) => const _CreateProductDialog(),
    );

    if (created == null) return;

    // On force storeId + placeholder ici pour être sûr
    final toSave = created.copyWith(
      storeId: widget.store.id,
      imageAssetPath: created.imageAssetPath.isEmpty ? _placeholderImg : created.imageAssetPath,
    );

    await widget.productService.addProduct(toSave);
    await _load();
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final bytes = result.files.first.bytes;
    if (bytes == null) return;

    final raw = utf8.decode(bytes, allowMalformed: true);

    // Normalise les fins de ligne Windows
    final content = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // Détecte le séparateur le plus probable via la 1ère ligne non vide
    final firstNonEmptyLine = content
        .split('\n')
        .map((l) => l.trim())
        .firstWhere((l) => l.isNotEmpty, orElse: () => '');

    if (firstNonEmptyLine.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV vide ou illisible.')),
      );
      return;
    }

    int countComma = ','.allMatches(firstNonEmptyLine).length;
    int countSemi = ';'.allMatches(firstNonEmptyLine).length;
    final delimiter = (countSemi > countComma) ? ';' : ',';

    final rows = CsvToListConverter(
      fieldDelimiter: delimiter,
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(content);

    if (rows.isEmpty) return;

    // Helpers
    String norm(String s) => s.trim().toLowerCase();

    // Mappe des noms de colonnes possibles vers nos champs internes
    int? colName;
    int? colCategory;
    int? colPrice;
    int? colQty;
    int? colUnit;

    // Détecte header si la première ligne contient du texte "name/nom/..."
    final header = rows.first.map((e) => norm(e.toString())).toList();

    bool looksLikeHeader = header.any((h) =>
    h.contains('name') ||
        h.contains('nom') ||
        h.contains('product') ||
        h.contains('produit') ||
        h.contains('category') ||
        h.contains('categorie') ||
        h.contains('prix') ||
        h.contains('price') ||
        h.contains('stock') ||
        h.contains('quantity') ||
        h.contains('qty') ||
        h.contains('unit') ||
        h.contains('unite'));

    int startIndex = looksLikeHeader ? 1 : 0;

    // Si header, on repère les colonnes par nom (dans n'importe quel ordre)
    if (looksLikeHeader) {
      for (int i = 0; i < header.length; i++) {
        final h = header[i];

        // name
        if (colName == null &&
            (h == 'name' || h == 'nom' || h.contains('product') || h.contains('produit'))) {
          colName = i;
        }

        // category
        if (colCategory == null &&
            (h == 'category' || h == 'categorie' || h.contains('categ'))) {
          colCategory = i;
        }

        // price
        if (colPrice == null &&
            (h == 'price' || h == 'prix' || h.contains('tarif'))) {
          colPrice = i;
        }

        // quantity / stock
        if (colQty == null &&
            (h == 'quantity' || h == 'qty' || h == 'stock' || h.contains('quant'))) {
          colQty = i;
        }

        // unit
        if (colUnit == null && (h == 'unit' || h == 'unite' || h.contains('uom'))) {
          colUnit = i;
        }
      }
    } else {
      // Pas de header => on suppose l'ordre:
      // name, category, price, quantity, unit
      colName = 0;
      colCategory = 1;
      colPrice = 2;
      colQty = 3;
      colUnit = 4;
    }

    // On exige au minimum un "name"
    if (colName == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'CSV invalide: colonne "name/nom" introuvable. '
                'Separateur detecte: "$delimiter".',
          ),
        ),
      );
      return;
    }

    final toAdd = <Product>[];
    int skipped = 0;

    for (int r = startIndex; r < rows.length; r++) {
      final row = rows[r];

      // Sécurise accès colonnes
      String cell(int? idx) {
        if (idx == null) return '';
        if (idx < 0 || idx >= row.length) return '';
        return row[idx].toString().trim();
      }

      final name = cell(colName);
      if (name.isEmpty) {
        skipped++;
        continue;
      }

      final category = cell(colCategory);
      final priceStr = cell(colPrice);
      final qtyStr = cell(colQty);
      final unitStr = cell(colUnit);

      final price = priceStr.isEmpty
          ? null
          : double.tryParse(priceStr.replaceAll(',', '.'));

      final qty = qtyStr.isEmpty ? 0 : int.tryParse(qtyStr) ?? 0;
      final unit = unitStr.isEmpty ? 'pcs' : unitStr;

      toAdd.add(Product(
        id: '',
        storeId: widget.store.id,
        name: name,
        category: category.isEmpty ? 'Autre' : category,
        price: price,
        quantity: qty,
        unit: unit,
        barcode: null,
        imageAssetPath: _placeholderImg,
      ));
    }

    if (toAdd.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aucun produit importable. Lignes ignorees: $skipped')),
      );
      return;
    }

    await widget.productService.addMany(toAdd);
    await _load();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Import termine: ${toAdd.length} ajoutes'
              '${skipped > 0 ? ' ($skipped ignorees)' : ''}',
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Erreur: $_error'));

    final items = _filtered;

    return Column(
      children: [
        // Barre outils
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Rechercher un produit...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _category,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? 'Tous'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _addNewProduct,
                icon: const Icon(Icons.add),
                label: const Text('Nouveau'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _importCsv,
                icon: const Icon(Icons.upload_file),
                label: const Text('Importer CSV'),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Liste
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('Aucun produit'))
              : ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final p = items[i];

              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    p.imageAssetPath,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
                title: Text(p.name),
                subtitle: Text('${p.category} • Stock: ${p.quantity} ${p.unit}'),
                trailing: p.price == null
                    ? null
                    : Text('${p.price!.toStringAsFixed(2)} €'),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CreateProductDialog extends StatefulWidget {
  const _CreateProductDialog();

  @override
  State<_CreateProductDialog> createState() => _CreateProductDialogState();
}

class _CreateProductDialogState extends State<_CreateProductDialog> {
  static const String _placeholderImg = 'images/product_placeholder.png';
  final _nameCtrl = TextEditingController();
  final _catCtrl = TextEditingController(text: 'Autre');
  final _priceCtrl = TextEditingController();

  final _qtyCtrl = TextEditingController(text: '1');
  final _unitCtrl = TextEditingController(text: 'pcs');

  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _catCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final cat = _catCtrl.text.trim();
    final priceStr = _priceCtrl.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Nom obligatoire');
      return;
    }

    final price = priceStr.isEmpty
        ? null
        : double.tryParse(priceStr.replaceAll(',', '.'));

    final qty = int.tryParse(_qtyCtrl.text.trim());
    final unit = _unitCtrl.text.trim();

    if (qty == null || qty < 0) {
      setState(() => _error = 'Quantite invalide');
      return;
    }
    if (unit.isEmpty) {
      setState(() => _error = 'Unite obligatoire');
      return;
    }

    // storeId sera forcé par ProductsPage au moment de sauvegarder
    Navigator.pop(
      context,
      Product(
        id: '',
        storeId: '',
        name: name,
        category: cat.isEmpty ? 'Autre' : cat,
        price: price,
        quantity: qty,
        unit: unit,
        barcode: null,
        imageAssetPath: _placeholderImg,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouveau produit'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _catCtrl,
              decoration: const InputDecoration(labelText: 'Categorie'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtyCtrl,
                    decoration: const InputDecoration(labelText: 'Quantite (stock)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _unitCtrl,
                    decoration: const InputDecoration(labelText: 'Unite (pcs, kg, L...)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _priceCtrl,
              decoration: const InputDecoration(labelText: 'Prix (optionnel)'),
              keyboardType: TextInputType.number,
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
