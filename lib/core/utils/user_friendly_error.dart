import '../errors/app_exception.dart';
import '../errors/failure.dart';

/// Centralized utility to transform raw technical exceptions and database errors
/// into polite, actionable, and user-friendly messages for the UI.
class UserFriendlyError {
  UserFriendlyError._();

  /// Converts any exception, error object, or failure into a polished, user-centric message.
  static String toFriendly(dynamic error, {String? defaultMessage}) {
    if (error == null)
      return defaultMessage ??
          'An unexpected error occurred. Please try again.';

    String raw;
    if (error is Failure) {
      raw = error.message;
    } else if (error is AppException) {
      raw = error.message;
    } else {
      raw = error.toString();
    }

    final lower = raw.toLowerCase();

    // ─── Staff & Team Member Creation ───
    if (lower.contains('create_staff_user') ||
        lower.contains('sql function') ||
        lower.contains('could not create staff account')) {
      return 'Unable to create staff account right now. Please verify the email address or upgrade your plan to add more team members.';
    }

    if (lower.contains('staff account') &&
        (lower.contains('limit') || lower.contains('reached'))) {
      return "You've reached your plan's staff account limit. Please upgrade to Pro to add more team members.";
    }

    if (lower.contains('only business owners and admins') ||
        lower.contains('permission denied')) {
      return 'You do not have administrative privileges to perform this action.';
    }

    // ─── Authentication & Accounts ───
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid_grant') ||
        lower.contains('invalid_credentials')) {
      return 'Incorrect email or password. Please verify your credentials and try again.';
    }

    if (lower.contains('email not confirmed')) {
      return 'Please check your email and confirm your account before signing in.';
    }

    if (lower.contains('user already registered') ||
        lower.contains('already exists') ||
        lower.contains('profiles_email_key') ||
        lower.contains('duplicate key')) {
      return 'An account with this email address already exists. Please sign in or use a different email.';
    }

    if (lower.contains('password') &&
        (lower.contains('6') ||
            lower.contains('short') ||
            lower.contains('least'))) {
      return 'Password must be at least 6 characters long.';
    }

    if (lower.contains('jwt') ||
        lower.contains('session expired') ||
        lower.contains('token is expired')) {
      return 'Your session has expired. Please sign in again to continue.';
    }

    // ─── Network & Connectivity ───
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network unavailable') ||
        lower.contains('clientexception') ||
        lower.contains('no address associated with hostname') ||
        lower.contains('connection error') ||
        lower.contains('offline')) {
      return 'Unable to connect to the server. Please check your internet connection.';
    }

    if (lower.contains('timeoutexception') ||
        lower.contains('timed out') ||
        lower.contains('connection timeout')) {
      return 'The connection timed out. Please check your network and try again.';
    }

    // ─── Tier Quotas & Limits ───
    if (lower.contains('product limit') ||
        (lower.contains('products') && lower.contains('limit'))) {
      return "You've reached your product limit. Upgrade to Pro for an expanded product catalog.";
    }

    if (lower.contains('customer limit') ||
        (lower.contains('customers') && lower.contains('limit'))) {
      return "You've reached your customer directory limit. Upgrade to Pro to add more clients.";
    }

    if (lower.contains('branch limit') ||
        (lower.contains('branches') && lower.contains('limit'))) {
      return "You've reached your multi-branch limit. Upgrade to Enterprise to add more locations.";
    }

    // ─── Database / Internal Server ───
    if (lower.contains('pgrst') ||
        lower.contains('42883') ||
        lower.contains('syntax error') ||
        lower.contains('postgrestexception')) {
      return 'The service is temporarily unavailable. Please try again in a few moments.';
    }

    // ─── Clean up technical prefixes ───
    String cleaned = raw
        .replaceAll(RegExp(r'^AppException:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^Exception:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^AuthException:\s*', caseSensitive: false), '')
        .replaceAll(
          RegExp(r'^PostgrestException\(message:\s*', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'^ServerFailure:\s*', caseSensitive: false), '')
        .replaceAll(
          RegExp(r'^Assign Staff Role Error:\s*', caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'^Update Staff Role Error:\s*', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'^SignIn Error:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^SignUp Error:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^Error:\s*', caseSensitive: false), '')
        .trim();

    // If cleaned string still looks like an unformatted technical code, fall back to default
    if (cleaned.isEmpty ||
        cleaned.contains('Stack trace:') ||
        cleaned.length > 250) {
      return defaultMessage ??
          'Unable to complete your request. Please try again shortly.';
    }

    // Capitalize first character and ensure ending period
    if (!cleaned.endsWith('.')) {
      cleaned = '$cleaned.';
    }
    return '${cleaned[0].toUpperCase()}${cleaned.substring(1)}';
  }

  /// Returns true if the error indicates a subscription limit or upgrade requirement.
  static bool isLimitOrUpgradeError(dynamic error) {
    if (error == null) return false;
    final str = error.toString().toLowerCase();
    return str.contains('limit') ||
        str.contains('reached') ||
        str.contains('upgrade') ||
        str.contains('tier') ||
        str.contains('quota');
  }
}
