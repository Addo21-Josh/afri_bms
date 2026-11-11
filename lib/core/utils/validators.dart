class Validators {
  static String? required(
    String? value, [
    String message = 'This field is required',
  ]) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? email(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Email is required' : null;
    }
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? phone(String? value, {bool required = true}) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return required ? 'Phone number is required' : null;
    }
    // Clean spaces and dashes
    final clean = trimmed.replaceAll(RegExp(r'[\s\-]'), '');
    // Supports international format +233..., +234..., local format 024..., etc.
    final regex = RegExp(r'^\+?[0-9]{8,15}$');
    if (!regex.hasMatch(clean)) {
      return 'Enter a valid phone number (8-15 digits)';
    }
    return null;
  }

  static String? nonNegativeNumber(
    String? value, {
    bool required = true,
    String fieldName = 'Amount',
  }) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return required ? '$fieldName is required' : null;
    }
    final num = double.tryParse(trimmed);
    if (num == null) {
      return 'Enter a valid number';
    }
    if (num < 0) {
      return '$fieldName cannot be negative';
    }
    return null;
  }

  static String? nonNegativeInteger(
    String? value, {
    bool required = false,
    String fieldName = 'Quantity',
  }) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return required ? '$fieldName is required' : null;
    }
    final num = int.tryParse(trimmed);
    if (num == null) {
      return 'Enter a valid whole number';
    }
    if (num < 0) {
      return '$fieldName cannot be negative';
    }
    return null;
  }

  static String? minLength(String? value, int min, [String? message]) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.length < min) {
      return message ?? 'Must be at least $min characters';
    }
    return null;
  }
}
