// Feature: rms-flutter-frontend, Property 1: Model round-trip
//
// Validates: Requirements 1.5
//
// For any valid domain model instance, serializing to JSON and then
// deserializing from that JSON produces a value equal to the original.

import 'package:flutter_test/flutter_test.dart';
import 'package:models/models.dart';

import 'helpers/fast_check.dart';

// ---------------------------------------------------------------------------
// Arbitraries for enum types
// ---------------------------------------------------------------------------

final _arbOrderStatus = Arbitrary.oneOf(OrderStatus.values);
final _arbTableStatus = Arbitrary.oneOf(TableStatus.values);
final _arbKdsItemStatus = Arbitrary.oneOf(KdsItemStatus.values);
final _arbDietaryType = Arbitrary.oneOf(DietaryType.values);
final _arbStaffRole = Arbitrary.oneOf(StaffRole.values);
final _arbOrderType = Arbitrary.oneOf(OrderType.values);

// ---------------------------------------------------------------------------
// Arbitraries for nested value types
// ---------------------------------------------------------------------------

Arbitrary<ItemVariant> _buildItemVariantArb() {
  return Arbitrary<ItemVariant>(
    (rng) => ItemVariant(
      id: Arbitrary.string().generate(rng),
      sizeLabel: Arbitrary.string().generate(rng),
      priceDelta: Arbitrary.doubleInRange(-999.99, 9999.99).generate(rng),
    ),
  );
}

Arbitrary<ModifierOption> _buildModifierOptionArb() {
  return Arbitrary<ModifierOption>(
    (rng) => ModifierOption(
      id: Arbitrary.string().generate(rng),
      modifierName: Arbitrary.string().generate(rng),
      priceDelta: Arbitrary.nonNegativeDouble(max: 9999.99).generate(rng),
    ),
  );
}

Arbitrary<ModifierGroup> _buildModifierGroupArb() {
  return Arbitrary<ModifierGroup>(
    (rng) {
      final minSel = Arbitrary.nonNegativeInt(max: 20).generate(rng);
      final maxSel = minSel + Arbitrary.nonNegativeInt(max: 20).generate(rng);
      return ModifierGroup(
        id: Arbitrary.string().generate(rng),
        groupName: Arbitrary.string().generate(rng),
        minSelect: minSel,
        maxSelect: maxSel,
        options: Arbitrary.list(_buildModifierOptionArb(), minLen: 0, maxLen: 5)
            .generate(rng),
      );
    },
  );
}

Arbitrary<MenuItem> _buildMenuItemArb() {
  return Arbitrary<MenuItem>(
    (rng) => MenuItem(
      id: Arbitrary.string().generate(rng),
      name: Arbitrary.string().generate(rng),
      categoryId: Arbitrary.string().generate(rng),
      basePrice: Arbitrary.nonNegativeDouble(max: 9999.99).generate(rng),
      gstRate: Arbitrary.nonNegativeDouble(max: 28.0).generate(rng),
      dietaryType: _arbDietaryType.generate(rng),
      isAvailable: Arbitrary.boolean().generate(rng),
      variants: Arbitrary.list(_buildItemVariantArb(), minLen: 0, maxLen: 5)
          .generate(rng),
      modifierGroups:
          Arbitrary.list(_buildModifierGroupArb(), minLen: 0, maxLen: 3)
              .generate(rng),
      imageUrl: Arbitrary.nullable(Arbitrary.string()).generate(rng),
    ),
  );
}

Arbitrary<OrderItem> _buildOrderItemArb() {
  return Arbitrary<OrderItem>(
    (rng) => OrderItem(
      id: Arbitrary.string().generate(rng),
      menuItemId: Arbitrary.string().generate(rng),
      name: Arbitrary.string().generate(rng),
      quantity: Arbitrary.positiveInt(max: 50).generate(rng),
      unitPrice: Arbitrary.nonNegativeDouble(max: 9999.99).generate(rng),
      totalPrice: Arbitrary.nonNegativeDouble(max: 99999.99).generate(rng),
      variantId: Arbitrary.nullable(Arbitrary.string()).generate(rng),
      selectedModifiers:
          Arbitrary.list(Arbitrary.string(), minLen: 0, maxLen: 5)
              .generate(rng),
    ),
  );
}

Arbitrary<Order> _buildOrderArb() {
  return Arbitrary<Order>(
    (rng) => Order(
      id: Arbitrary.string().generate(rng),
      orderNumber: Arbitrary.string().generate(rng),
      orderType: _arbOrderType.generate(rng),
      status: _arbOrderStatus.generate(rng),
      items: Arbitrary.list(_buildOrderItemArb(), minLen: 1, maxLen: 5)
          .generate(rng),
      createdAt: Arbitrary.dateTime().generate(rng),
      totalAmount: Arbitrary.nonNegativeDouble(max: 999999.99).generate(rng),
      tableId: Arbitrary.nullable(Arbitrary.string()).generate(rng),
    ),
  );
}

Arbitrary<GstSlab> _buildGstSlabArb() {
  return Arbitrary<GstSlab>(
    (rng) => GstSlab(
      gstRate: Arbitrary.nonNegativeDouble(max: 28.0).generate(rng),
      taxableValue: Arbitrary.nonNegativeDouble(max: 99999.99).generate(rng),
      gstAmount: Arbitrary.nonNegativeDouble(max: 9999.99).generate(rng),
    ),
  );
}

Arbitrary<Payment> _buildPaymentArb() {
  return Arbitrary<Payment>(
    (rng) => Payment(
      id: Arbitrary.string().generate(rng),
      mode: Arbitrary.oneOf(['cash', 'upi', 'card']).generate(rng),
      amount: Arbitrary.nonNegativeDouble(max: 99999.99).generate(rng),
      paidAt: Arbitrary.dateTime().generate(rng),
    ),
  );
}

Arbitrary<Bill> _buildBillArb() {
  return Arbitrary<Bill>(
    (rng) => Bill(
      id: Arbitrary.string().generate(rng),
      orderId: Arbitrary.string().generate(rng),
      subtotal: Arbitrary.nonNegativeDouble(max: 99999.99).generate(rng),
      gstBreakdown: Arbitrary.list(_buildGstSlabArb(), minLen: 0, maxLen: 4)
          .generate(rng),
      total: Arbitrary.nonNegativeDouble(max: 99999.99).generate(rng),
      status: Arbitrary.oneOf(['draft', 'paid', 'voided']).generate(rng),
      payments: Arbitrary.list(_buildPaymentArb(), minLen: 0, maxLen: 3)
          .generate(rng),
    ),
  );
}

Arbitrary<KdsItem> _buildKdsItemArb() {
  return Arbitrary<KdsItem>(
    (rng) => KdsItem(
      orderItemId: Arbitrary.string().generate(rng),
      orderId: Arbitrary.string().generate(rng),
      orderNumber: Arbitrary.string().generate(rng),
      itemName: Arbitrary.string().generate(rng),
      quantity: Arbitrary.positiveInt(max: 50).generate(rng),
      status: _arbKdsItemStatus.generate(rng),
      stationId: Arbitrary.string().generate(rng),
      createdAt: Arbitrary.dateTime().generate(rng),
    ),
  );
}

Arbitrary<Staff> _buildStaffArb() {
  return Arbitrary<Staff>(
    (rng) => Staff(
      id: Arbitrary.string().generate(rng),
      name: Arbitrary.string().generate(rng),
      email: Arbitrary.string().generate(rng),
      role: _arbStaffRole.generate(rng),
      isActive: Arbitrary.boolean().generate(rng),
    ),
  );
}

Arbitrary<Subscription> _buildSubscriptionArb() {
  return Arbitrary<Subscription>(
    (rng) => Subscription(
      id: Arbitrary.string().generate(rng),
      planId: Arbitrary.string().generate(rng),
      planName: Arbitrary.string().generate(rng),
      status: Arbitrary.oneOf(['active', 'expired', 'cancelled']).generate(rng),
      expiresAt: Arbitrary.dateTime().generate(rng),
    ),
  );
}

Arbitrary<BusinessHours> _buildBusinessHoursArb() {
  return Arbitrary<BusinessHours>(
    (rng) => BusinessHours(
      dayOfWeek: 1 + Arbitrary.nonNegativeInt(max: 7).generate(rng),
      openTime:
          '${Arbitrary.nonNegativeInt(max: 24).generate(rng).toString().padLeft(2, '0')}:00',
      closeTime:
          '${Arbitrary.nonNegativeInt(max: 24).generate(rng).toString().padLeft(2, '0')}:00',
      isClosed: Arbitrary.boolean().generate(rng),
    ),
  );
}

Arbitrary<Restaurant> _buildRestaurantArb() {
  return Arbitrary<Restaurant>(
    (rng) => Restaurant(
      id: Arbitrary.string().generate(rng),
      name: Arbitrary.string().generate(rng),
      address: Arbitrary.string().generate(rng),
      phone: Arbitrary.string().generate(rng),
      gstNumber: Arbitrary.string().generate(rng),
      logoUrl: Arbitrary.nullable(Arbitrary.string()).generate(rng),
      businessHours:
          Arbitrary.list(_buildBusinessHoursArb(), minLen: 0, maxLen: 7)
              .generate(rng),
    ),
  );
}

Arbitrary<Table> _buildTableArb() {
  return Arbitrary<Table>(
    (rng) => Table(
      id: Arbitrary.string().generate(rng),
      tableNumber: Arbitrary.string().generate(rng),
      status: _arbTableStatus.generate(rng),
      currentOrderId: Arbitrary.nullable(Arbitrary.string()).generate(rng),
      qrUrl: Arbitrary.nullable(Arbitrary.string()).generate(rng),
    ),
  );
}

Arbitrary<PaginationMeta> _buildPaginationMetaArb() {
  return Arbitrary<PaginationMeta>(
    (rng) {
      final limit = 1 + Arbitrary.nonNegativeInt(max: 99).generate(rng);
      final total = Arbitrary.nonNegativeInt(max: 500).generate(rng);
      final pages = total == 0 ? 0 : ((total - 1) ~/ limit) + 1;
      final page = pages == 0
          ? 1
          : 1 + Arbitrary.nonNegativeInt(max: pages).generate(rng);
      return PaginationMeta(
        total: total,
        page: page,
        limit: limit,
        pages: pages,
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // Feature: rms-flutter-frontend, Property 1: Model round-trip
  group('Property 1: Model Serialization Round-Trip', () {
    // Validates: Requirements 1.5

    test('ItemVariant round-trip: fromJson(toJson(x)) == x', () {
      forAll(
        _buildItemVariantArb(),
        (instance) {
          final roundTripped = ItemVariant.fromJson(instance.toJson());
          expect(roundTripped, equals(instance));
        },
        iterations: 100,
      );
    });

    test('ModifierOption round-trip: fromJson(toJson(x)) == x', () {
      forAll(
        _buildModifierOptionArb(),
        (instance) {
          final roundTripped = ModifierOption.fromJson(instance.toJson());
          expect(roundTripped, equals(instance));
        },
        iterations: 100,
      );
    });

    test('ModifierGroup round-trip: fromJson(toJson(x)) == x', () {
      forAll(
        _buildModifierGroupArb(),
        (instance) {
          final roundTripped = ModifierGroup.fromJson(instance.toJson());
          expect(roundTripped, equals(instance));
        },
        iterations: 100,
      );
    });

    test('MenuItem round-trip: fromJson(toJson(x)) == x', () {
      forAll(
        _buildMenuItemArb(),
        (instance) {
          final roundTripped = MenuItem.fromJson(instance.toJson());
          expect(roundTripped, equals(instance));
        },
        iterations: 100,
      );
    });

    test('OrderItem round-trip: fromJson(toJson(x)) == x', () {
      forAll(
        _buildOrderItemArb(),
        (instance) {
          final roundTripped = OrderItem.fromJson(instance.toJson());
          expect(roundTripped, equals(instance));
        },
        iterations: 100,
      );
    });

    test('Order round-trip: fromJson(toJson(x)) == x', () {
      forAll(
        _buildOrderArb(),
        (instance) {
          final roundTripped = Order.fromJson(instance.toJson());
          expect(roundTripped, equals(instance));
        },
        iterations: 100,
      );
    });

    test('GstSlab round-trip: fromJson(toJson(x)) == x', () {
      forAll(
        _buildGstSlabArb(),
        (instance) {
          final roundTripped = GstSlab.fromJson(instance.toJson());
          expect(roundTripped, equals(instance));
        },
        iterations: 100,
      );
    });

    test('Payment round-trip: fromJson(toJson(x)) == x', () {
      forAll(
        _buildPaymentArb(),
        (instance) {
          final roundTripped = Payment.fromJson(instance.toJson());
          expect(roundTripped, equals(instance));
        },
        iterations: 100,
      );
    });

    test('Bill round-trip: fromJson(toJson(x)) == x', () {
      forAll(
        _buildBillArb(),
        (instance) {
          final roundTripped = Bill.fromJson(instance.toJson());
          expect(roundTripped, equals(instance));
        },
        iterations: 100,
      );
    });

    test('KdsItem round-trip: fromJson(toJson(x)) == x', () {
      forAll(
        _buildKdsItemArb(),
        (instance) {
          final roundTripped = KdsItem.fromJson(instance.toJson());
          expect(roundTripped, equals(instance));
        },
        iterations: 100,
      );
    });

    test('Staff round-trip: fromJson(toJson(x)) == x', () {
      forAll(
        _buildStaffArb(),
        (instance) {
          final roundTripped = Staff.fromJson(instance.toJson());
          expect(roundTripped, equals(instance));
        },
        iterations: 100,
      );
    });

    test('Subscription round-trip: fromJson(toJson(x)) == x', () {
      forAll(
        _buildSubscriptionArb(),
        (instance) {
          final roundTripped = Subscription.fromJson(instance.toJson());
          expect(roundTripped, equals(instance));
        },
        iterations: 100,
      );
    });

    test('BusinessHours round-trip: fromJson(toJson(x)) == x', () {
      forAll(
        _buildBusinessHoursArb(),
        (instance) {
          final roundTripped = BusinessHours.fromJson(instance.toJson());
          expect(roundTripped, equals(instance));
        },
        iterations: 100,
      );
    });

    test('Restaurant round-trip: fromJson(toJson(x)) == x', () {
      forAll(
        _buildRestaurantArb(),
        (instance) {
          final roundTripped = Restaurant.fromJson(instance.toJson());
          expect(roundTripped, equals(instance));
        },
        iterations: 100,
      );
    });

    test('PaginationMeta round-trip: fromJson(toJson(x)) == x', () {
      forAll(
        _buildPaginationMetaArb(),
        (instance) {
          final roundTripped = PaginationMeta.fromJson(instance.toJson());
          expect(roundTripped, equals(instance));
        },
        iterations: 100,
      );
    });

    test('Table round-trip: fromJson(toJson(x)) == x', () {
      forAll(
        _buildTableArb(),
        (instance) {
          final roundTripped = Table.fromJson(instance.toJson());
          expect(roundTripped, equals(instance));
        },
        iterations: 100,
      );
    });
  });
}
