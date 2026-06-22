/// Parsing CSV minimal (RFC 4180 simplifié) pour l'import du catalogue à
/// l'onboarding (Sprint 6). Gère guillemets, virgules et retours à la ligne
/// dans les champs cités — pas de dépendance externe pour rester testable
/// hors plateforme (web/mobile/desktop).
library;

/// Découpe un contenu CSV en lignes de cellules. La première ligne est
/// l'en-tête ; les colonnes attendues pour l'import catalogue sont
/// `nom`, `code_barres`, `prix`, `dci` (optionnelle), `categorie` (optionnelle).
List<List<String>> parseCsv(String content) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  var i = 0;

  void endField() {
    row.add(field.toString());
    field.clear();
  }

  void endRow() {
    endField();
    if (row.any((c) => c.isNotEmpty)) rows.add(row);
    row = [];
  }

  while (i < content.length) {
    final c = content[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < content.length && content[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(c);
      }
    } else {
      switch (c) {
        case '"':
          inQuotes = true;
        case ',':
          endField();
        case '\n':
          endRow();
        case '\r':
          break;
        default:
          field.write(c);
      }
    }
    i++;
  }
  if (field.isNotEmpty || row.isNotEmpty) endRow();
  return rows;
}

/// Une ligne du catalogue importé, avant insertion.
class ImportedProductRow {
  const ImportedProductRow({
    required this.name,
    required this.sellingPrice,
    this.barcode,
    this.dciName,
    this.category,
    this.isDuplicate = false,
  });

  final String name;
  final double sellingPrice;
  final String? barcode;
  final String? dciName;
  final String? category;
  final bool isDuplicate;

  ImportedProductRow copyWith({bool? isDuplicate}) => ImportedProductRow(
    name: name,
    sellingPrice: sellingPrice,
    barcode: barcode,
    dciName: dciName,
    category: category,
    isDuplicate: isDuplicate ?? this.isDuplicate,
  );
}

/// Parse un CSV catalogue (en-tête : nom,code_barres,prix,dci,categorie)
/// en lignes prêtes à être prévisualisées/importées. Lignes sans nom ou
/// prix invalide sont ignorées plutôt que de faire échouer tout l'import.
List<ImportedProductRow> parseProductCsv(String content) {
  final rows = parseCsv(content);
  if (rows.isEmpty) return const [];

  final header = rows.first.map((h) => h.trim().toLowerCase()).toList();
  final nameIdx = header.indexOf('nom');
  final barcodeIdx = header.indexOf('code_barres');
  final priceIdx = header.indexOf('prix');
  final dciIdx = header.indexOf('dci');
  final categoryIdx = header.indexOf('categorie');
  if (nameIdx == -1 || priceIdx == -1) return const [];

  final result = <ImportedProductRow>[];
  for (final cells in rows.skip(1)) {
    String? cell(int idx) =>
        (idx >= 0 && idx < cells.length && cells[idx].trim().isNotEmpty)
        ? cells[idx].trim()
        : null;
    final name = cell(nameIdx);
    final price = double.tryParse(cell(priceIdx) ?? '');
    if (name == null || price == null) continue;
    result.add(
      ImportedProductRow(
        name: name,
        sellingPrice: price,
        barcode: cell(barcodeIdx),
        dciName: cell(dciIdx),
        category: cell(categoryIdx),
      ),
    );
  }
  return result;
}

/// Marque les doublons (même code-barres qu'un produit déjà existant, ou
/// répété dans le fichier importé lui-même) pour la prévisualisation.
List<ImportedProductRow> markDuplicates(
  List<ImportedProductRow> rows,
  Set<String> existingBarcodes,
) {
  final seen = <String>{};
  return rows.map((row) {
    final code = row.barcode;
    if (code == null) return row;
    final isDup = existingBarcodes.contains(code) || seen.contains(code);
    seen.add(code);
    return row.copyWith(isDuplicate: isDup);
  }).toList();
}
