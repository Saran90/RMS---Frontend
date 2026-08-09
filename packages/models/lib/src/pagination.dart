import 'package:freezed_annotation/freezed_annotation.dart';

part 'pagination.freezed.dart';
part 'pagination.g.dart';

/// Metadata describing the current page and total dataset size.
@freezed
class PaginationMeta with _$PaginationMeta {
  const factory PaginationMeta({
    /// Total number of items across all pages.
    required int total,

    /// Current page number (1-based).
    required int page,

    /// Maximum number of items per page.
    required int limit,

    /// Total number of pages: `ceil(total / limit)`.
    required int pages,
  }) = _PaginationMeta;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) =>
      _$PaginationMetaFromJson(json);
}

/// A generic paginated API response wrapping a typed [data] list.
///
/// Example usage:
/// ```dart
/// final response = PaginatedResponse<MenuItem>(
///   data: items,
///   pagination: meta,
/// );
/// ```
///
/// Note: Because [T] is generic, [fromJson] requires a `fromJsonT`
/// converter. Use the generated helper or provide one manually.
@Freezed(genericArgumentFactories: true)
class PaginatedResponse<T> with _$PaginatedResponse<T> {
  const factory PaginatedResponse({
    /// The page's item list.
    required List<T> data,

    /// Pagination metadata for this response.
    required PaginationMeta pagination,
  }) = _PaginatedResponse<T>;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$PaginatedResponseFromJson(json, fromJsonT);
}
