import 'package:equatable/equatable.dart';

enum DebtType {
  receivable, // Customer owes us (money to receive)
  payable; // We owe supplier (money to pay)

  static DebtType fromString(String val) {
    return val.toLowerCase() == 'payable' ? DebtType.payable : DebtType.receivable;
  }

  String get value => this == DebtType.payable ? 'payable' : 'receivable';
  String get label => this == DebtType.payable ? 'Payable (To Supplier)' : 'Receivable (From Customer)';
}

enum DebtStatus {
  active,
  paid,
  badDebt,
  cancelled;

  static DebtStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'paid':
        return DebtStatus.paid;
      case 'bad_debt':
        return DebtStatus.badDebt;
      case 'cancelled':
        return DebtStatus.cancelled;
      default:
        return DebtStatus.active;
    }
  }

  String get value {
    switch (this) {
      case DebtStatus.paid:
        return 'paid';
      case DebtStatus.badDebt:
        return 'bad_debt';
      case DebtStatus.cancelled:
        return 'cancelled';
      case DebtStatus.active:
        return 'active';
    }
  }

  String get label {
    switch (this) {
      case DebtStatus.paid:
        return 'Fully Paid';
      case DebtStatus.badDebt:
        return 'Bad Debt / Defaulted';
      case DebtStatus.cancelled:
        return 'Cancelled';
      case DebtStatus.active:
        return 'Active';
    }
  }
}

enum AgingBucket {
  current, // 0 - 29 days
  thirtyDays, // 30 - 59 days
  sixtyDays, // 60 - 89 days
  ninetyDaysPlus; // 90+ days

  String get label {
    switch (this) {
      case AgingBucket.current:
        return 'Current (< 30d)';
      case AgingBucket.thirtyDays:
        return '30 - 59 Days';
      case AgingBucket.sixtyDays:
        return '60 - 89 Days';
      case AgingBucket.ninetyDaysPlus:
        return '90+ Days (Overdue)';
    }
  }
}

class DebtEntity extends Equatable {
  const DebtEntity({
    required this.id,
    required this.businessId,
    required this.branchId,
    required this.debtType,
    this.customerId,
    this.supplierId,
    this.saleId,
    required this.personName,
    this.personPhone,
    required this.initialAmount, // minor units
    required this.remainingBalance, // minor units
    this.dueDate,
    this.status = DebtStatus.active,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String businessId;
  final String branchId;
  final DebtType debtType;
  final String? customerId;
  final String? supplierId;
  final String? saleId;
  final String personName;
  final String? personPhone;
  final int initialAmount; // in minor units
  final int remainingBalance; // in minor units
  final DateTime? dueDate;
  final DebtStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get paidAmount => initialAmount - remainingBalance;
  bool get isFullyPaid => remainingBalance <= 0 || status == DebtStatus.paid;

  bool get isOverdue {
    if (isFullyPaid) return false;
    if (dueDate != null) {
      return DateTime.now().isAfter(dueDate!);
    }
    return daysElapsed >= 30;
  }

  int get daysElapsed {
    return DateTime.now().difference(createdAt).inDays;
  }

  AgingBucket get agingBucket {
    final days = daysElapsed;
    if (days < 30) return AgingBucket.current;
    if (days < 60) return AgingBucket.thirtyDays;
    if (days < 90) return AgingBucket.sixtyDays;
    return AgingBucket.ninetyDaysPlus;
  }

  @override
  List<Object?> get props => [
        id,
        businessId,
        branchId,
        debtType,
        customerId,
        supplierId,
        saleId,
        personName,
        personPhone,
        initialAmount,
        remainingBalance,
        dueDate,
        status,
        notes,
        createdAt,
        updatedAt,
      ];
}
