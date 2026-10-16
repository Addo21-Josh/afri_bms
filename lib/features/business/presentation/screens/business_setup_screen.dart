import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/validators.dart';
import '../providers/business_provider.dart';
import '../../../users/domain/entities/staff_user_entity.dart';
import '../../../users/presentation/providers/staff_provider.dart';

class BusinessSetupScreen extends ConsumerStatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  ConsumerState<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends ConsumerState<BusinessSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bizNameController = TextEditingController();
  final _currencyController = TextEditingController(text: 'GHS');
  final _branchNameController = TextEditingController(text: 'Main Branch');

  @override
  void dispose() {
    _bizNameController.dispose();
    _currencyController.dispose();
    _branchNameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        ref.read(businessControllerProvider.notifier).createBusiness(
          ownerId: user.id,
          name: _bizNameController.text.trim(),
          defaultCurrency: _currencyController.text.trim().toUpperCase(),
          firstBranchName: _branchNameController.text.trim(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessState = ref.watch(businessControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final userRole = ref.watch(currentUserRoleProvider).value;
    final isStaff = userRole == UserRoleType.salesperson || userRole == UserRoleType.cashier;

    ref.listen(businessControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: colorScheme.error,
          ),
        );
      } else if (next.value != null && !next.isLoading) {
        context.go('/dashboard');
      }
    });

    if (isStaff) {
      return Scaffold(
        appBar: AppBar(title: const Text('Setup Business')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 64, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Permission Denied',
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Staff accounts (salespersons and cashiers) are not authorized to create new businesses. Please log in with an administrator or business owner account.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.tonal(
                  onPressed: () => context.go('/dashboard'),
                  child: const Text('Return to Dashboard'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Business'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.store,
                  size: 80,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Create Your First Business',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                TextFormField(
                  controller: _bizNameController,
                  decoration: const InputDecoration(
                    labelText: 'Business Name',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                  validator: (val) => Validators.required(val, 'Business name is required'),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _currencyController,
                  decoration: const InputDecoration(
                    labelText: 'Base Currency (e.g., NGN, GHS)',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (val) => Validators.required(val, 'Currency is required'),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _branchNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Branch Name',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (val) => Validators.required(val, 'Branch name is required'),
                ),
                const SizedBox(height: 48),
                
                FilledButton(
                  onPressed: businessState.isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: businessState.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Complete Setup'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
