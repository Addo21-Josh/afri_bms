import 'package:flutter_test/flutter_test.dart';
import 'package:afri_bms/core/utils/user_friendly_error.dart';
import 'package:afri_bms/core/errors/app_exception.dart';
import 'package:afri_bms/core/errors/failure.dart';

void main() {
  group('UserFriendlyError', () {
    test(
      'sanitizes the exact staff assignment database SQL error reported by user',
      () {
        const rawUserError =
            'Assign Staff Role Error: AppException: Could not create staff account for "kwaku@gmail.com". Please ensure the staff management SQL function is created in your Supabase project.';

        final friendly = UserFriendlyError.toFriendly(rawUserError);
        expect(
          friendly,
          'Unable to create staff account right now. Please verify the email address or upgrade your plan to add more team members.',
        );
      },
    );

    test(
      'sanitizes login failure messages to match wrong credentials standard',
      () {
        expect(
          UserFriendlyError.toFriendly('Invalid login credentials'),
          'Incorrect email or password. Please verify your credentials and try again.',
        );
        expect(
          UserFriendlyError.toFriendly(
            'AuthException: invalid_grant: Invalid login credentials',
          ),
          'Incorrect email or password. Please verify your credentials and try again.',
        );
      },
    );

    test(
      'sanitizes network and socket exceptions into clear connectivity messages',
      () {
        expect(
          UserFriendlyError.toFriendly(
            'SocketException: Failed host lookup: xyz.supabase.co',
          ),
          'Unable to connect to the server. Please check your internet connection.',
        );
        expect(
          UserFriendlyError.toFriendly(
            'TimeoutException after 0:00:10.000000: Future not completed',
          ),
          'The connection timed out. Please check your network and try again.',
        );
      },
    );

    test('sanitizes subscription tier limits into friendly upgrade messages', () {
      expect(
        UserFriendlyError.toFriendly(
          'Staff account limit reached for current tier',
        ),
        "You've reached your plan's staff account limit. Please upgrade to Pro to add more team members.",
      );
      expect(
        UserFriendlyError.toFriendly('Product limit reached'),
        "You've reached your product limit. Upgrade to Pro for an expanded product catalog.",
      );
    });

    test(
      'isLimitOrUpgradeError correctly detects limit and upgrade errors',
      () {
        expect(
          UserFriendlyError.isLimitOrUpgradeError('Staff limit reached'),
          isTrue,
        );
        expect(
          UserFriendlyError.isLimitOrUpgradeError('Please upgrade to Pro'),
          isTrue,
        );
        expect(
          UserFriendlyError.isLimitOrUpgradeError('Invalid login credentials'),
          isFalse,
        );
      },
    );

    test('handles AppException and Failure objects properly', () {
      final appEx = AppException(
        'duplicate key value violates unique constraint',
      );
      expect(
        UserFriendlyError.toFriendly(appEx),
        'An account with this email address already exists. Please sign in or use a different email.',
      );

      const serverFailure = ServerFailure(
        'permission denied for table staff_roles',
      );
      expect(
        UserFriendlyError.toFriendly(serverFailure),
        'You do not have administrative privileges to perform this action.',
      );
    });

    test('cleans generic prefixes and capitalizes properly', () {
      expect(
        UserFriendlyError.toFriendly(
          'AppException: customer record is archived',
        ),
        'Customer record is archived.',
      );
    });
  });
}
