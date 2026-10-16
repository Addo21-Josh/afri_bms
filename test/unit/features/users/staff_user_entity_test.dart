import 'package:flutter_test/flutter_test.dart';
import 'package:afri_bms/features/users/domain/entities/staff_user_entity.dart';

void main() {
  group('UserRoleType', () {
    test('fromString accurately parses database roles', () {
      expect(UserRoleType.fromString('admin'), equals(UserRoleType.admin));
      expect(UserRoleType.fromString('branch_manager'), equals(UserRoleType.branchManager));
      expect(UserRoleType.fromString('branchmanager'), equals(UserRoleType.branchManager));
      expect(UserRoleType.fromString('salesperson'), equals(UserRoleType.salesperson));
      expect(UserRoleType.fromString('cashier'), equals(UserRoleType.cashier));
      expect(UserRoleType.fromString('unknown_role'), equals(UserRoleType.custom));
    });

    test('toDbString and value return snake_case database value', () {
      expect(UserRoleType.admin.toDbString(), equals('admin'));
      expect(UserRoleType.admin.value, equals('admin'));
      expect(UserRoleType.branchManager.toDbString(), equals('branch_manager'));
      expect(UserRoleType.branchManager.value, equals('branch_manager'));
      expect(UserRoleType.salesperson.toDbString(), equals('salesperson'));
      expect(UserRoleType.salesperson.value, equals('salesperson'));
      expect(UserRoleType.cashier.toDbString(), equals('cashier'));
      expect(UserRoleType.cashier.value, equals('cashier'));
      expect(UserRoleType.custom.toDbString(), equals('custom'));
      expect(UserRoleType.custom.value, equals('custom'));
    });

    test('displayName returns user-facing title', () {
      expect(UserRoleType.admin.displayName, equals('Admin'));
      expect(UserRoleType.branchManager.displayName, equals('Branch Manager'));
      expect(UserRoleType.salesperson.displayName, equals('Salesperson'));
      expect(UserRoleType.cashier.displayName, equals('Cashier'));
    });
  });

  group('StaffUserEntity', () {
    test('instantiates with active state and custom permissions', () {
      final now = DateTime.now();
      final staff = StaffUserEntity(
        roleId: 'role-123',
        userId: 'user-456',
        businessId: 'biz-789',
        branchId: 'branch-1',
        branchName: 'Accra Central',
        role: UserRoleType.cashier,
        email: 'cashier@afribms.com',
        fullName: 'Kofi Mensah',
        phone: '+233241234567',
        isActive: true,
        customPermissions: {'can_give_discount': false},
        createdAt: now,
      );

      expect(staff.fullName, equals('Kofi Mensah'));
      expect(staff.isActive, isTrue);
      expect(staff.role, equals(UserRoleType.cashier));
      expect(staff.customPermissions['can_give_discount'], isFalse);
    });
  });
}
