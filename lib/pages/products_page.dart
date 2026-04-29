import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/store.dart';
import '../services/product_service.dart';

// Page de gestion des produits d'un magasin

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
  static const String _apiHost = 'http://localhost:8000';
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
    final action = await showDialog<_ProductDialogAction>(
      context: context,
      builder: (_) => const _ProductDialog(),
    );

    final created = action?.product;
    if (created == null) return;

    // On force storeId + placeholder ici pour être sûr
    final toSave = created.copyWith(
      storeId: widget.store.id,
      imageAssetPath: created.imageAssetPath.isEmpty ? _placeholderImg : created.imageAssetPath,
    );

    try {
      await widget.productService.addProduct(toSave);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur ajout produit: $e')),
      );
    }
  }

  Future<void> _editProduct(Product product) async {
    final action = await showDialog<_ProductDialogAction>(
      context: context,
      builder: (_) => _ProductDialog(product: product),
    );

    if (action == null) return;

    if (action.delete) {
      try {
        await widget.productService.deleteProduct(widget.store.id, product.id);
        await _load();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur suppression produit: $e')),
        );
      }
      return;
    }

    final updated = action.product;
    if (updated == null) return;

    final toSave = updated.copyWith(
      id: product.id,
      storeId: widget.store.id,
      imageAssetPath: updated.imageAssetPath.isEmpty
          ? _placeholderImg
          : updated.imageAssetPath,
    );

    try {
      await widget.productService.updateProduct(toSave);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur modification produit: $e')),
      );
    }
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

  Widget _productImage(Product product) {
    final path = product.imageAssetPath.trim();

    Widget fallback() => Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported),
    );

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback(),
      );
    }

    if (path.startsWith('/')) {
      return Image.network(
        '$_apiHost$path',
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback(),
      );
    }

    return Image.asset(
      path.isEmpty ? _placeholderImg : path,
      width: 48,
      height: 48,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback(),
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
                  child: _productImage(p),
                ),
                title: Text(p.name),
                onTap: () => _editProduct(p),
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

class _ProductDialogAction {
  final Product? product;
  final bool delete;

  const _ProductDialogAction.save(this.product) : delete = false;
  const _ProductDialogAction.delete()
      : product = null,
        delete = true;
}

class _ProductDialog extends StatefulWidget {
  final Product? product;

  const _ProductDialog({this.product});

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  static const String _placeholderImg = 'images/product_placeholder.png';
  late final TextEditingController _nameCtrl;
  late final TextEditingController _catCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _unitCtrl;

  String? _error;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameCtrl = TextEditingController(text: product?.name ?? '');
    _catCtrl = TextEditingController(text: product?.category ?? 'Autre');
    _priceCtrl = TextEditingController(
      text: product?.price == null ? '' : product!.price!.toString(),
    );
    _qtyCtrl = TextEditingController(text: product?.quantity.toString() ?? '1');
    _unitCtrl = TextEditingController(text: product?.unit ?? 'pcs');
  }

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

    Navigator.pop(
      context,
      _ProductDialogAction.save(
        Product(
          id: widget.product?.id ?? '',
          storeId: widget.product?.storeId ?? '',
          name: name,
          category: cat.isEmpty ? 'Autre' : cat,
          price: price,
          quantity: qty,
          unit: unit,
          barcode: widget.product?.barcode,
          imageAssetPath: widget.product?.imageAssetPath ?? _placeholderImg,
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer le produit'),
        content: Text('Supprimer "${widget.product?.name ?? 'ce produit'}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;
    Navigator.pop(context, const _ProductDialogAction.delete());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Modifier produit' : 'Nouveau produit'),
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
        if (_isEdit)
          TextButton(
            onPressed: _confirmDelete,
            child: const Text('Supprimer'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(_isEdit ? 'Enregistrer' : 'Ajouter'),
        ),
      ],
    );
  }
}
