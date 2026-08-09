import 'package:freezed_annotation/freezed_annotation.dart';

part 'bill.freezed.dart';
part 'bill.g.dart';

/// Converts numeric strings like "656.00" to double.
class _DoubleConverter implements JsonConverter<double, dynamic> {
  const _DoubleConverter();

  @override
  double fromJson(dynamic json) {
    if (json == null) return 0.0;
    if (json is num) return json.toDouble();
    if (json is String) return double.tryParse(json) ?? 0.0;
    return 0.0;
  }

  @override
  dynamic toJson(double value) => value;
}

/// GST breakdown for a single tax slab on a [Bill].
@freezed
class GstSlab with _$GstSlab {
  const factory GstSlab({
    /// The GST rate for this slab (e.g. 5.0 for 5 %).
    @JsonKey(name: 'gst_rate') @_DoubleConverter() required double gstRate,

    /// The pre-tax value to which this rate applies.
    @JsonKey(name: 'taxable_value')
    @_DoubleConverter()
    required double taxableValue,

    /// The GST amount collected for this slab.
    @JsonKey(name: 'gst_amount') @_DoubleConverter() required double gstAmount,
  }) = _GstSlab;

  factory GstSlab.fromJson(Map<String, dynamic> json) =>
      _$GstSlabFromJson(json);
}

/// A single payment record against a [Bill].
@freezed
class Payment with _$Payment {
  const factory Payment({
    /// Amount paid in this transaction.
    @_DoubleConverter() required double amount,

    /// Payment mode (e.g. "cash", "upi", "card").
    String? mode,

    /// UTC timestamp when the payment was recorded.
    @JsonKey(name: 'paid_at') DateTime? paidAt,

    /// Unique identifier for the payment.
    String? id,
  }) = _Payment;

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);
}

/// A bill generated for an [Order].
@freezed
class Bill with _$Bill {
  const factory Bill({
    /// Unique identifier.
    required String id,

    /// Reference to the [Order] this bill covers.
    @JsonKey(name: 'order_id') required String orderId,

    /// Sum of all item prices before tax.
    @_DoubleConverter() required double subtotal,

    /// Per-slab GST breakdown (one entry per distinct GST rate).
    @JsonKey(name: 'gst_breakdown') required List<GstSlab> gstBreakdown,

    /// Final total including GST.
    @_DoubleConverter() required double total,

    /// Current bill status (e.g. "draft", "paid", "voided").
    required String status,

    /// Payments applied to this bill.
    @Default([]) List<Payment> payments,
  }) = _Bill;

  factory Bill.fromJson(Map<String, dynamic> json) => _$BillFromJson(json);
}
