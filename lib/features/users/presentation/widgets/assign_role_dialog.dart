import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/staff_user_entity.dart';
import '../providers/staff_provider.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../../core/utils/user_friendly_error.dart';
import '../../../../core/subscription/domain/models/subscription_tier.dart';
import '../../../../core/subscription/presentation/providers/subscription_provider.dart';
import '../../../../core/subscription/presentation/widgets/upgrade_prompt_sheet.dart';

class AssignRoleDialog extends ConsumerStatefulWidget {
  const AssignRoleDialog({super.key, this.existingStaff});

  final StaffUserEntity? existingStaff;

  @override
  ConsumerState<AssignRoleDialog> createState() => _AssignRoleDialogState();
}

class _AssignRoleDialogState extends ConsumerState<AssignRoleDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _phoneController;
  late UserRoleType _selectedRole;
  String? _selectedBranchId;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingStaff?.fullName ?? '');
    _emailController = TextEditingController(text: widget.existingStaff?.email ?? '');
    _passwordController = TextEditingController(text: 'AfriBMS@123');
    _phoneController = TextEditingController(text: widget.existingStaff?.phone ?? '');
    _selectedRole = widget.existingStaff?.role ?? UserRoleType.salesperson;
    _selectedBranchId = widget.existingStaff?.branchId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      // Check feature gate tier limit before assigning a new staff member
      if (widget.existingStaff == null) {
        final staffList = ref.read(businessStaffListProvider).value ?? [];
        final gate = ref.read(featureGateProvider);
        final limitCheck = gate.checkStaffLimit(staffList.length);
        if (limitCheck.isBlocked) {
          UpgradePromptSheet.show(
            context,
            featureName: limitCheck.featureName ?? 'Staff Accounts',
            customMessage: limitCheck.reason,
            currentTier: gate.tier,
            suggestedTier: limitCheck.requiredTier,
          );
          return;
        }
      }

      bool success = false;
      if (widget.existingStaff == null) {
        success = await ref.read(staffControllerProvider.notifier).assignStaff(
          userEmail: _emailController.text.trim(),
          role: _selectedRole,
          fullName: _nameController.text.trim(),
          password: _passwordController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          branchId: _selectedBranchId,
        );
      } else {
        success = await ref.read(staffControllerProvider.notifier).updateStaff(
          roleId: widget.existingStaff!.roleId,
          newRole: _selectedRole,
          newBranchId: _selectedBranchId,
        );
      }

      if (mounted && success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingStaff == null ? 'Staff member added successfully' : 'Role updated successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(businessBranchesProvider);
    final staffState = ref.watch(staffControllerProvider);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.existingStaff == null ? 'Add Staff Member' : 'Edit Staff Role'),
      actionsOverflowButtonSpacing: 8,
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (staffState.hasError) ...[
                  Builder(
                    builder: (context) {
                      final friendlyMsg = UserFriendlyError.toFriendly(staffState.error);
                      final isLimit = UserFriendlyError.isLimitOrUpgradeError(staffState.error);

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline, size: 18, color: theme.colorScheme.error),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    friendlyMsg,
                                    style: TextStyle(
                                      color: theme.colorScheme.onErrorContainer,
                                      fontSize: 13,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (isLimit) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    foregroundColor: theme.colorScheme.error,
                                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  icon: const Icon(Icons.upgrade, size: 16),
                                  label: const Text('Upgrade Plan'),
                                  onPressed: () {
                                    final gate = ref.read(featureGateProvider);
                                    UpgradePromptSheet.show(
                                      context,
                                      featureName: 'Staff Accounts',
                                      currentTier: gate.tier,
                                      suggestedTier: SubscriptionTier.pro,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                if (widget.existingStaff == null) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'e.g. Kwame Mensah',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Full name is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                ],
                TextFormField(
                  controller: _emailController,
                  enabled: widget.existingStaff == null,
                  decoration: const InputDecoration(
                    labelText: 'Staff Email Address',
                    hintText: 'e.g. staff@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Email is required';
                    if (!val.contains('@') || !val.contains('.')) return 'Invalid email';
                    return null;
                  },
                ),
                if (widget.existingStaff == null) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Temporary Password',
                      hintText: 'Set a temporary login password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number (Optional)',
                      hintText: 'e.g. +233 50 123 4567',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
                const SizedBox(height: 14),
                DropdownButtonFormField<UserRoleType>(
                  initialValue: _selectedRole,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Assigned Role',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: [
                    UserRoleType.branchManager,
                    UserRoleType.salesperson,
                    UserRoleType.cashier,
                    UserRoleType.admin,
                  ].map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(
                        role.displayName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRole = val);
                  },
                ),
                const SizedBox(height: 14),
                branchesAsync.when(
                  data: (branches) => DropdownButtonFormField<String?>(
                    initialValue: _selectedBranchId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Branch Assignment',
                      prefixIcon: Icon(Icons.store_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'All Branches (HQ / Floating)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ...branches.map((b) => DropdownMenuItem<String?>(
                            value: b.id,
                            child: Text(
                              b.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedBranchId = val);
                    },
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (err, stack) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: staffState.isLoading ? null : _submit,
          child: staffState.isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.existingStaff == null ? 'Create & Assign' : 'Save Changes'),
        ),
      ],
    );
  }
}
