import 'package:flutter_test/flutter_test.dart';
import 'package:afri_bms/features/debts/domain/entities/debt_entity.dart';

void main() {
  group('DebtEntity', () {
    final now = DateTime.now();

    test('calculates paidAmount and isFullyPaid accurately', () {
      final partialDebt = DebtEntity(
        id: 'debt-1',
        businessId: 'biz-1',
        branchId: 'branch-1',
        debtType: DebtType.receivable,
        personName: 'Kofi Mensah',
        initialAmount: 10000, // 100.00 GHS
        remainingBalance: 4000, // 40.00 GHS remaining
        createdAt: now,
        updatedAt: now,
      );

      expect(partialDebt.paidAmount, equals(6000));
      expect(partialDebt.isFullyPaid, isFalse);

      final settledDebt = DebtEntity(
        id: 'debt-2',
        businessId: 'biz-1',
        branchId: 'branch-1',
        debtType: DebtType.receivable,
        personName: 'Ama Serwaa',
        initialAmount: 5000,
        remainingBalance: 0,
        status: DebtStatus.paid,
        createdAt: now,
        updatedAt: now,
      );

      expect(settledDebt.paidAmount, equals(5000));
      expect(settledDebt.isFullyPaid, isTrue);
      expect(settledDebt.isOverdue, isFalse);
    });

    test('isOverdue evaluates correctly with specific dueDate', () {
      final overdueDebt = DebtEntity(
        id: 'debt-3',
        businessId: 'biz-1',
        branchId: 'branch-1',
        debtType: DebtType.receivable,
        personName: 'Kwame Tech',
        initialAmount: 20000,
        remainingBalance: 20000,
        dueDate: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now,
      );

      expect(overdueDebt.isOverdue, isTrue);

      final futureDebt = DebtEntity(
        id: 'debt-4',
        businessId: 'biz-1',
        branchId: 'branch-1',
        debtType: DebtType.receivable,
        personName: 'Akosua Store',
        initialAmount: 15000,
        remainingBalance: 15000,
        dueDate: now.add(const Duration(days: 7)),
        createdAt: now,
        updatedAt: now,
      );

      expect(futureDebt.isOverdue, isFalse);
    });

    test(
      'agingBucket classifies debts across 0-29, 30-59, 60-89, and 90+ days',
      () {
        DebtEntity createDebt(int daysAgo) {
          final created = now.subtract(Duration(days: daysAgo));
          return DebtEntity(
            id: 'aging-$daysAgo',
            businessId: 'biz-1',
            branchId: 'branch-1',
            debtType: DebtType.receivable,
            personName: 'Customer',
            initialAmount: 10000,
            remainingBalance: 10000,
            createdAt: created,
            updatedAt: created,
          );
        }

        expect(createDebt(10).agingBucket, equals(AgingBucket.current));
        expect(createDebt(45).agingBucket, equals(AgingBucket.thirtyDays));
        expect(createDebt(75).agingBucket, equals(AgingBucket.sixtyDays));
        expect(createDebt(120).agingBucket, equals(AgingBucket.ninetyDaysPlus));
      },
    );

    test('enum parsing from strings behaves robustly', () {
      expect(DebtType.fromString('payable'), equals(DebtType.payable));
      expect(DebtType.fromString('receivable'), equals(DebtType.receivable));
      expect(DebtType.fromString('UNKNOWN'), equals(DebtType.receivable));

      expect(DebtStatus.fromString('paid'), equals(DebtStatus.paid));
      expect(DebtStatus.fromString('bad_debt'), equals(DebtStatus.badDebt));
      expect(DebtStatus.fromString('cancelled'), equals(DebtStatus.cancelled));
      expect(DebtStatus.fromString('active'), equals(DebtStatus.active));
    });
  });
}
