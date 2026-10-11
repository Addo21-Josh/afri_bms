import 'package:equatable/equatable.dart';
import 'sale_item_entity.dart';

enum PaymentMethod {
  cash,
  mobileMoney,
  card,
  split,
  credit;

  static PaymentMethod fromString(String val) {
    switch (val.toLowerCase()) {
      case 'cash':
        return PaymentMethod.cash;
      case 'mobile_money':
      case 'momo':
        return PaymentMethod.mobileMoney;
      case 'card':
        return PaymentMethod.card;
      case 'split':
        return PaymentMethod.split;
      case 'credit':
        return PaymentMethod.credit;
      default:
        return PaymentMethod.cash;
    }
  }

  String get value {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.mobileMoney:
        return 'mobile_money';
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.split:
        return 'split';
      case PaymentMethod.credit:
        return 'credit';
    }
  }

  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.card:
        return 'Card / POS';
      case PaymentMethod.split:
        return 'Split Payment';
      case PaymentMethod.credit:
        return 'Credit / Store Debt';
    }
  }
}

enum PaymentStatus {
  paid,
  pending,
  partial,
  refunded;

  static PaymentStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'paid':
        return PaymentStatus.paid;
      case 'pending':
        return PaymentStatus.pending;
      case 'partial':
        return PaymentStatus.partial;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.paid;
    }
  }

  String get value {
    switch (this) {
      case PaymentStatus.paid:
        return 'paid';
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.partial:
        return 'partial';
      case PaymentStatus.refunded:
        return 'refunded';
    }
  }
}

class SaleEntity extends Equatable {
  final String id;
  final String businessId;
  final String branchId;
  final String cashierId;
  final String? cashierName;
  final String saleNumber;
  final int subtotal; // Minor units
  final int discountAmount; // Minor units
  final int taxAmount; // Minor units
  final int totalAmount; // Minor units
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final int amountTendered;
  final int changeGiven;
  final String? customerId;
  final String? paymentReference;
  final String? customerName;
  final String? customerPhone;
  final String? notes;
  final List<SaleItemEntity> items;
  final DateTime createdAt;

  const SaleEntity({
    required this.id,
    required this.businessId,
    required this.branchId,
    required this.cashierId,
    this.cashierName,
    required this.saleNumber,
    required this.subtotal,
    this.discountAmount = 0,
    this.taxAmount = 0,
    required this.totalAmount,
    this.paymentMethod = PaymentMethod.cash,
    this.paymentStatus = PaymentStatus.paid,
    this.amountTendered = 0,
    this.changeGiven = 0,
    this.customerId,
    this.paymentReference,
    this.customerName,
    this.customerPhone,
    this.notes,
    this.items = const [],
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        businessId,
        branchId,
        cashierId,
        saleNumber,
        subtotal,
        discountAmount,
        taxAmount,
        totalAmount,
        paymentMethod,
        paymentStatus,
        amountTendered,
        changeGiven,
        paymentReference,
        customerName,
        customerPhone,
        notes,
        items,
        createdAt,
      ];
}
