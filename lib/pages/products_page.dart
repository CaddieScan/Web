import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/store.dart';
import '../services/product_service.dart';
import '../utils/error_handler.dart';

// URL où l'API sert les images des produits
const apiHost = 'http://localhost:8000';
// image par défaut pour les produits sans image précisée
const placeholderImg = 'images/product_placeholder.png';

// page pour gérer les produits d'un magasin
// tu peux en ajouter, modifier, supprimer, ou importer un tas via CSV
// t'as aussi une recherche et un filtre par catégorie
class ProductsPage extends StatefulWidget {
  final Store store;
  final ProductService productService;

  const ProductsPage({
    super.key,
    required this.store,
    required this.productService,
  });

  @override
  State<ProductsPage> createState() => ProductsPageState();
}

class ProductsPageState extends State<ProductsPage> {
  bool loading = true;
  String error = '';
  List<Product> all = [];
  String search = '';
  String category = 'Tous';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final items = await widget.productService.fetchProducts(widget.store.id);
      setState(() {
        all = items;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = '$e';
        loading = false;
      });
    }
  }

  List<String> get categories {
    // récupère les catégories uniques avec "Tous" en premier
    // comme ça tu peux filtrer les produits par catégorie
    final set = <String>{'Tous'};
    for (final p in all) {
      set.add(p.category);
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  List<Product> get filtered {
    // filtre en fonction de ta recherche ET la catégorie sélectionnée
    // tu modifies la recherche ou la catégorie, la liste se rafraîchit direct
    return all.where((p) {
      final matchSearch = search.isEmpty || p.name.toLowerCase().contains(search.toLowerCase());
      final matchCat = category == 'Tous' || p.category == category;
      return matchSearch && matchCat;
    }).toList();
  }

  // ouvre un dialog pour créer un nouveau produit
  Future<void> addNewProduct() async {
    final action = await showDialog<ProductDialogAction>(
      context: context,
      builder: (dialogContext) => const ProductDialog(),
    );

    final created = action?.product;
    if (created == null) return;

    final toSave = created.copyWith(
      storeId: widget.store.id,
      imageAssetPath: created.imageAssetPath.isEmpty ? placeholderImg : created.imageAssetPath,
    );

    try {
      await widget.productService.addProduct(toSave);
      await load();
    } catch (e) {
      if (!mounted) return;
    }
  }

  Future<void> editProduct(Product product) async {
    final action = await showDialog<ProductDialogAction>(
      context: context,
      builder: (dialogContext) => ProductDialog(product: product),
    );

    if (action == null) return;

    if (action.delete) {
      try {
        await widget.productService.deleteProduct(widget.store.id, product.id);
        await load();
      } catch (e) {
        if (!mounted) return;
      }
      return;
    }

    final updated = action.product;
    if (updated == null) return;

    final toSave = updated.copyWith(
      id: product.id,
      storeId: widget.store.id,
      imageAssetPath: updated.imageAssetPath.isEmpty ? placeholderImg : updated.imageAssetPath,
    );

    try {
      await widget.productService.updateProduct(toSave);
      await load();
    } catch (e) {
      if (!mounted) return;
    }
  }

  Future<void> importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final bytes = result.files.first.bytes;
    if (bytes == null) return;

    final raw = utf8.decode(bytes, allowMalformed: true);
    final content = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    final firstNonEmptyLine = content
        .split('\n')
        .map((l) => l.trim())
        .firstWhere((l) => l.isNotEmpty, orElse: () => '');

    if (firstNonEmptyLine.isEmpty) {
      if (!mounted) return;
      ErrorHandler.showError('CSV vide ou illisible.');
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

    String norm(String s) => s.trim().toLowerCase();

    int? colName, colCategory, colPrice, colQty, colUnit;
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

    if (looksLikeHeader) {
      for (int i = 0; i < header.length; i++) {
        final h = header[i];

        if (colName == null && (h == 'name' || h == 'nom' || h.contains('product') || h.contains('produit'))) {
          colName = i;
        }

        if (colCategory == null && (h == 'category' || h == 'categorie' || h.contains('categ'))) {
          colCategory = i;
        }

        if (colPrice == null && (h == 'price' || h == 'prix' || h.contains('tarif'))) {
          colPrice = i;
        }

        if (colQty == null && (h == 'quantity' || h == 'qty' || h == 'stock' || h.contains('quant'))) {
          colQty = i;
        }

        if (colUnit == null && (h == 'unit' || h == 'unite' || h.contains('uom'))) {
          colUnit = i;
        }
      }
    }

    colName ??= 0;
    colCategory ??= 1;
    colPrice ??= 2;
    colQty ??= 3;
    colUnit ??= 4;

    final toAdd = <Product>[];
    int skipped = 0;

    for (int i = startIndex; i < rows.length; i++) {
      final row = rows[i];

      if (row.isEmpty) {
        skipped++;
        continue;
      }

      final nameStr = colName < row.length ? row[colName].toString().trim() : '';
      final catStr = colCategory < row.length ? row[colCategory].toString().trim() : '';
      final priceStr = colPrice < row.length ? row[colPrice].toString().trim() : '';
      final qtyStr = colQty < row.length ? row[colQty].toString().trim() : '';
      final unitStr = colUnit < row.length ? row[colUnit].toString().trim() : '';

      if (nameStr.isEmpty) {
        skipped++;
        continue;
      }

      final name = nameStr;
      final category_ = catStr.isEmpty ? 'Autre' : catStr;
      final price = priceStr.isEmpty ? null : double.tryParse(priceStr.replaceAll(',', '.'));
      final qty = qtyStr.isEmpty ? 0 : int.tryParse(qtyStr) ?? 0;
      final unit = unitStr.isEmpty ? 'pcs' : unitStr;

      toAdd.add(Product(
        id: '',
        storeId: widget.store.id,
        name: name,
        category: category_,
        price: price,
        quantity: qty,
        unit: unit,
        barcode: null,
        imageAssetPath: placeholderImg,
      ));
    }

    if (toAdd.isEmpty) {
      if (!mounted) return;
      ErrorHandler.showError('Aucun produit importable. Lignes ignorees: $skipped');
      return;
    }

    try {
      await widget.productService.addMany(toAdd);
      await load();

      if (!mounted) return;
      final msg = 'Import termine: ${toAdd.length} ajoutes'
          '${skipped > 0 ? ' ($skipped ignorees)' : ''}';
      ErrorHandler.showSuccess(msg);
    } catch (e) {
      if (!mounted) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error.isNotEmpty) return Center(child: Text('Erreur: $error'));

    final items = filtered;

    return Column(
      children: [
        ProductToolbar(
          categories: categories,
          search: search,
          category: category,
          onSearchChanged: (v) => setState(() => search = v),
          onCategoryChanged: (v) => setState(() => category = v),
          onAddProduct: addNewProduct,
          onImportCsv: importCsv,
        ),
        const Divider(height: 1),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('Aucun produit'))
              : ProductList(
                  products: items,
                  onEditProduct: editProduct,
                ),
        ),
      ],
    );
  }
}

class ProductToolbar extends StatelessWidget {
  final List<String> categories;
  final String search;
  final String category;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onAddProduct;
  final VoidCallback onImportCsv;

  const ProductToolbar({
    super.key,
    required this.categories,
    required this.search,
    required this.category,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onAddProduct,
    required this.onImportCsv,
  });

  // barre du haut avec la recherche, le filtre catégorie et les boutons ajouter/importer
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: onSearchChanged,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Rechercher un produit...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: category,
            items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => onCategoryChanged(v ?? 'Tous'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: onAddProduct,
            icon: const Icon(Icons.add),
            label: const Text('Nouveau'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onImportCsv,
            icon: const Icon(Icons.upload_file),
            label: const Text('Importer CSV'),
          ),
        ],
      ),
    );
  }
}

class ProductList extends StatelessWidget {
  final List<Product> products;
  final Function(Product) onEditProduct;

  const ProductList({
    super.key,
    required this.products,
    required this.onEditProduct,
  });

  // affiche les produits dans une liste avec séparateurs
  // tu cliques sur un produit pour l'éditer
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: products.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final p = products[i];
        return ProductListItem(product: p, onTap: () => onEditProduct(p));
      },
    );
  }
}

class ProductListItem extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductListItem({
    super.key,
    required this.product,
    required this.onTap,
  });

  // un seul produit avec sa photo, nom, catégorie et prix
  // elle gère les différentes sources d'images (asset, réseau, etc.)
  Widget buildImage() {
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
        errorBuilder: (context, error, stackTrace) => fallback(),
      );
    }

    if (path.startsWith('/')) {
      return Image.network(
        '$apiHost$path',
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback(),
      );
    }

    return Image.asset(
      path.isEmpty ? placeholderImg : path,
      width: 48,
      height: 48,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => fallback(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: buildImage(),
      ),
      title: Text(product.name),
      subtitle: Text('${product.category} • Stock: ${product.quantity} ${product.unit}'),
      trailing: product.price == null ? null : Text('${product.price!.toStringAsFixed(2)} €'),
      onTap: onTap,
    );
  }
}

class ProductDialog extends StatefulWidget {
  final Product? product;

  const ProductDialog({this.product});

  // un dialog soit pour créer un nouveau produit, soit pour modifier un existant
  // tu remplis tous les champs et tu appuies sur "Ajouter" ou "Enregistrer"
  @override
  State<ProductDialog> createState() => ProductDialogState();
}

class ProductDialogState extends State<ProductDialog> {
  late TextEditingController nameCtrl;
  late TextEditingController catCtrl;
  late TextEditingController priceCtrl;
  late TextEditingController qtyCtrl;
  late TextEditingController unitCtrl;
  String error = '';

  bool get isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    nameCtrl = TextEditingController(text: product?.name ?? '');
    catCtrl = TextEditingController(text: product?.category ?? 'Autre');
    priceCtrl = TextEditingController(
      text: product?.price == null ? '' : product!.price!.toString(),
    );
    qtyCtrl = TextEditingController(text: product?.quantity.toString() ?? '1');
    unitCtrl = TextEditingController(text: product?.unit ?? 'pcs');
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    catCtrl.dispose();
    priceCtrl.dispose();
    qtyCtrl.dispose();
    unitCtrl.dispose();
    super.dispose();
  }

  void submit() {
    final name = nameCtrl.text.trim();
    final cat = catCtrl.text.trim();
    final priceStr = priceCtrl.text.trim();

    if (name.isEmpty) {
      setState(() => error = 'Nom obligatoire');
      return;
    }

    final price = priceStr.isEmpty ? null : double.tryParse(priceStr.replaceAll(',', '.'));

    final qty = int.tryParse(qtyCtrl.text.trim());
    final unit = unitCtrl.text.trim();

    if (qty == null || qty < 0) {
      setState(() => error = 'Quantite invalide');
      return;
    }
    if (unit.isEmpty) {
      setState(() => error = 'Unite obligatoire');
      return;
    }

    Navigator.pop(
      context,
      ProductDialogAction.save(
        Product(
          id: widget.product?.id ?? '',
          storeId: widget.product?.storeId ?? '',
          name: name,
          category: cat.isEmpty ? 'Autre' : cat,
          price: price,
          quantity: qty,
          unit: unit,
          barcode: widget.product?.barcode,
          imageAssetPath: widget.product?.imageAssetPath ?? placeholderImg,
        ),
      ),
    );
  }

  Future<void> confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
    Navigator.pop(context, const ProductDialogAction.delete());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEdit ? 'Modifier produit' : 'Nouveau produit'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: catCtrl,
              decoration: const InputDecoration(labelText: 'Categorie'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyCtrl,
                    decoration: const InputDecoration(labelText: 'Quantite (stock)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: unitCtrl,
                    decoration: const InputDecoration(labelText: 'Unite (pcs, kg, L...)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(labelText: 'Prix (optionnel)'),
              keyboardType: TextInputType.number,
            ),
            if (error.isNotEmpty) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(error, style: const TextStyle(color: Colors.red)),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (isEdit)
          TextButton(
            onPressed: confirmDelete,
            child: const Text('Supprimer'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: submit,
          child: Text(isEdit ? 'Enregistrer' : 'Ajouter'),
        ),
      ],
    );
  }
}

class ProductDialogAction {
  // c'est l'action que le dialog retourne
  // soit tu as créé/modifié un produit, soit tu l'as supprimé
  final Product? product;
  final bool delete;

  const ProductDialogAction.save(this.product) : delete = false;
  const ProductDialogAction.delete()
      : product = null,
        delete = true;
}

