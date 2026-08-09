import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:models/src/enums.dart';

part 'menu_item.freezed.dart';
part 'menu_item.g.dart';

/// Parses a value that may arrive as a JSON string ("99.00") or a num (99.0).
double _parseDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.parse(value);
  throw ArgumentError('Cannot convert $value to double');
}

/// A size/variant option for a [MenuItem].
@freezed
class ItemVariant with _$ItemVariant {
  const factory ItemVariant({
    /// Unique identifier for the variant.
    required String id,

    /// Human-readable label (e.g. "Small", "Large").
    @JsonKey(name: 'size_label') required String sizeLabel,

    /// Price delta relative to the base price (can be negative).
    @JsonKey(name: 'price_delta', fromJson: _parseDouble)
    required double priceDelta,
  }) = _ItemVariant;

  factory ItemVariant.fromJson(Map<String, dynamic> json) =>
      _$ItemVariantFromJson(json);
}

/// A single selectable modifier within a [ModifierGroup].
@freezed
class ModifierOption with _$ModifierOption {
  const factory ModifierOption({
    /// Unique identifier for this modifier option.
    required String id,

    /// Name displayed to the user (e.g. "Extra Cheese").
    @JsonKey(name: 'modifier_name') required String modifierName,

    /// Additional cost for this modifier.
    @JsonKey(name: 'price_delta', fromJson: _parseDouble)
    required double priceDelta,
  }) = _ModifierOption;

  factory ModifierOption.fromJson(Map<String, dynamic> json) =>
      _$ModifierOptionFromJson(json);
}

/// A group of modifier options attached to a [MenuItem].
///
/// [minSelect] and [maxSelect] control how many options a customer must/can pick.
@freezed
class ModifierGroup with _$ModifierGroup {
  const factory ModifierGroup({
    /// Unique identifier for the modifier group.
    required String id,

    /// Display name for the group (e.g. "Add-ons", "Sauces").
    @JsonKey(name: 'group_name') required String groupName,

    /// Minimum number of options the customer must select.
    @JsonKey(name: 'min_select') required int minSelect,

    /// Maximum number of options the customer may select.
    @JsonKey(name: 'max_select') required int maxSelect,

    /// Selectable options within this group.
    required List<ModifierOption> options,
  }) = _ModifierGroup;

  factory ModifierGroup.fromJson(Map<String, dynamic> json) =>
      _$ModifierGroupFromJson(json);
}

/// A menu item available for ordering.
@freezed
class MenuItem with _$MenuItem {
  const factory MenuItem({
    /// Unique identifier.
    required String id,

    /// Display name shown to customers and staff.
    required String name,

    /// The category this item belongs to.
    @JsonKey(name: 'category_id') required String categoryId,

    /// Base price before variants and modifiers.
    @JsonKey(name: 'base_price', fromJson: _parseDouble)
    required double basePrice,

    /// GST rate applied to this item (e.g. 5.0 for 5 %).
    @JsonKey(name: 'gst_rate', fromJson: _parseDouble) required double gstRate,

    /// Dietary classification per FSSAI standard.
    @JsonKey(name: 'dietary_type') required DietaryType dietaryType,

    /// Whether this item is currently available for ordering.
    @JsonKey(name: 'is_available') required bool isAvailable,

    /// Available size/price variants; may be empty.
    @Default([]) List<ItemVariant> variants,

    /// Modifier groups (add-ons, customisations); may be empty.
    @JsonKey(name: 'modifier_groups')
    @Default([])
    List<ModifierGroup> modifierGroups,

    /// Optional URL to the item image.
    @JsonKey(name: 'photo_url') String? imageUrl,
  }) = _MenuItem;

  factory MenuItem.fromJson(Map<String, dynamic> json) =>
      _$MenuItemFromJson(json);
}
