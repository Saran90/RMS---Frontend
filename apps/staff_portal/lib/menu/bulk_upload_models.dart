/// Models for the Menu Bulk Upload API responses.

// ── Template schema ───────────────────────────────────────────────────────────

/// The shape returned by `GET /api/v1/tenant/menu/bulk-upload/template`.
class BulkUploadTemplate {
  const BulkUploadTemplate({required this.sheets});

  final List<BulkUploadSheetDef> sheets;

  factory BulkUploadTemplate.fromJson(Map<String, dynamic> json) {
    final rawSheets = json['sheets'] as List<dynamic>? ?? [];
    return BulkUploadTemplate(
      sheets: rawSheets
          .map((s) => BulkUploadSheetDef.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Describes a single sheet within the upload template.
class BulkUploadSheetDef {
  const BulkUploadSheetDef({
    required this.sheet,
    required this.required,
    required this.columns,
  });

  final String sheet;
  final bool required;
  final List<Map<String, dynamic>> columns;

  factory BulkUploadSheetDef.fromJson(Map<String, dynamic> json) {
    final rawCols = json['columns'] as List<dynamic>? ?? [];
    return BulkUploadSheetDef(
      sheet: json['sheet'] as String,
      required: json['required'] as bool? ?? false,
      columns: rawCols.cast<Map<String, dynamic>>(),
    );
  }
}

// ── Upload result ─────────────────────────────────────────────────────────────

/// The shape returned by a successful `POST /api/v1/tenant/menu/bulk-upload`.
class BulkUploadResult {
  const BulkUploadResult({
    required this.message,
    required this.summary,
  });

  final String message;
  final BulkUploadSummary summary;

  factory BulkUploadResult.fromJson(Map<String, dynamic> json) {
    return BulkUploadResult(
      message: json['message'] as String? ?? 'Import complete',
      summary: BulkUploadSummary.fromJson(
          json['summary'] as Map<String, dynamic>? ?? {}),
    );
  }
}

/// Counts of created records and non-fatal warnings from a bulk upload.
class BulkUploadSummary {
  const BulkUploadSummary({
    required this.categoriesCreated,
    required this.itemsCreated,
    required this.variantsCreated,
    required this.modifierGroupsCreated,
    required this.modifiersCreated,
    required this.warnings,
  });

  final int categoriesCreated;
  final int itemsCreated;
  final int variantsCreated;
  final int modifierGroupsCreated;
  final int modifiersCreated;
  final List<String> warnings;

  factory BulkUploadSummary.fromJson(Map<String, dynamic> json) {
    final rawWarnings = json['warnings'] as List<dynamic>? ?? [];
    return BulkUploadSummary(
      categoriesCreated: (json['categories_created'] as num?)?.toInt() ?? 0,
      itemsCreated: (json['items_created'] as num?)?.toInt() ?? 0,
      variantsCreated: (json['variants_created'] as num?)?.toInt() ?? 0,
      modifierGroupsCreated:
          (json['modifier_groups_created'] as num?)?.toInt() ?? 0,
      modifiersCreated: (json['modifiers_created'] as num?)?.toInt() ?? 0,
      warnings: rawWarnings.cast<String>(),
    );
  }
}
