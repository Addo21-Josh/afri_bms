import '../../domain/entities/sale_entity.dart';
import 'sale_item_model.dart';

class SaleModel {
  final String id;
  final String businessId;
  final String branchId;
  final String cashierId;
  final String? cashierName;
  final String saleNumber;
  final int subtotal;
  final int discountAmount;
  final int taxAmount;
  final int totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final int amountTendered;
  final int changeGiven;
  final String? paymentReference;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final String? notes;
  final List<SaleItemModel> items;
  final DateTime createdAt;

  const SaleModel({
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
    this.paymentMethod = 'cash',
    this.paymentStatus = 'paid',
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

  factory SaleModel.fromEntity(SaleEntity e) {
    return SaleModel(
      id: e.id,
      businessId: e.businessId,
      branchId: e.branchId,
      cashierId: e.cashierId,
      cashierName: e.cashierName,
      saleNumber: e.saleNumber,
      subtotal: e.subtotal,
      discountAmount: e.discountAmount,
      taxAmount: e.taxAmount,
      totalAmount: e.totalAmount,
      paymentMethod: e.paymentMethod.name,
      paymentStatus: e.paymentStatus.name,
      amountTendered: e.amountTendered,
      changeGiven: e.changeGiven,
      customerId: e.customerId,
      paymentReference: e.paymentReference,
      customerName: e.customerName,
      customerPhone: e.customerPhone,
      notes: e.notes,
      items: e.items.map((i) => SaleItemModel.fromEntity(i)).toList(),
      createdAt: e.createdAt,
    );
  }

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    // Extract cashier name if profiles join is present
    String? cName;
    if (json['profiles'] != null && json['profiles'] is Map<String, dynamic>) {
      cName = json['profiles']['full_name'] as String?;
    }

    // Extract items
    final rawItems = json['sale_items'] as List<dynamic>? ?? [];
    final itemsList = rawItems
        .map((item) => SaleItemModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return SaleModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      branchId: json['branch_id'] as String,
      cashierId: json['cashier_id'] as String,
      cashierName: cName,
      saleNumber: json['sale_number'] as String,
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toInt() ?? 0,
      taxAmount: (json['tax_amount'] as num?)?.toInt() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toInt() ?? 0,
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      paymentStatus: json['payment_status'] as String? ?? 'paid',
      amountTendered: (json['amount_tendered'] as num?)?.toInt() ?? 0,
      changeGiven: (json['change_given'] as num?)?.toInt() ?? 0,
      customerId: json['customer_id'] as String?,
      paymentReference: json['payment_reference'] as String?,
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      notes: json['notes'] as String?,
      items: itemsList,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'branch_id': branchId,
      'cashier_id': cashierId,
      'sale_number': saleNumber,
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'amount_tendered': amountTendered,
      'change_given': changeGiven,
      'customer_id': customerId,
      'payment_reference': paymentReference,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCacheJson() {
    return {
      'id': id,
      'business_id': businessId,
      'branch_id': branchId,
      'cashier_id': cashierId,
      'cashier_name': cashierName,
      'sale_number': saleNumber,
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'amount_tendered': amountTendered,
      'change_given': changeGiven,
      'customer_id': customerId,
      'payment_reference': paymentReference,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'notes': notes,
      'sale_items': items.map((i) => i.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  SaleEntity toEntity() {
    return SaleEntity(
      id: id,
      businessId: businessId,
      branchId: branchId,
      cashierId: cashierId,
      cashierName: cashierName,
      saleNumber: saleNumber,
      subtotal: subtotal,
      discountAmount: discountAmount,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
      paymentMethod: PaymentMethod.fromString(paymentMethod),
      paymentStatus: PaymentStatus.fromString(paymentStatus),
      amountTendered: amountTendered,
      changeGiven: changeGiven,
      customerId: customerId,
      paymentReference: paymentReference,
      customerName: customerName,
      customerPhone: customerPhone,
      notes: notes,
      items: items.map((i) => i.toEntity()).toList(),
      createdAt: createdAt,
    );
  }
}
