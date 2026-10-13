import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_sw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('sw'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Afri_BMS'**
  String get appTitle;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage your business'**
  String get loginSubtitle;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get commonUpdate;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get commonSearch;

  /// No description provided for @commonFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get commonFilter;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @commonSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get commonSuccess;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get commonError;

  /// No description provided for @commonRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get commonRequired;

  /// No description provided for @commonOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get commonOptional;

  /// No description provided for @commonAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonAll;

  /// No description provided for @commonNoData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get commonNoData;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get navInventory;

  /// No description provided for @navPOS.
  ///
  /// In en, this message translates to:
  /// **'Point of Sale'**
  String get navPOS;

  /// No description provided for @navSales.
  ///
  /// In en, this message translates to:
  /// **'Sales History'**
  String get navSales;

  /// No description provided for @navCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get navCustomers;

  /// No description provided for @navSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get navSuppliers;

  /// No description provided for @navExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get navExpenses;

  /// No description provided for @navDebts.
  ///
  /// In en, this message translates to:
  /// **'Debts & Credit'**
  String get navDebts;

  /// No description provided for @navStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff Management'**
  String get navStaff;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navSync.
  ///
  /// In en, this message translates to:
  /// **'Sync Center'**
  String get navSync;

  /// No description provided for @navBackup.
  ///
  /// In en, this message translates to:
  /// **'Cloud Backup & Restore'**
  String get navBackup;

  /// No description provided for @navAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts & Notifications'**
  String get navAlerts;

  /// No description provided for @navLogout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get navLogout;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get authForgotPassword;

  /// No description provided for @authRegister.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authRegister;

  /// No description provided for @authAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign In'**
  String get authAlreadyHaveAccount;

  /// No description provided for @authDontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign Up'**
  String get authDontHaveAccount;

  /// No description provided for @authFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get authFullName;

  /// No description provided for @authPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get authPhone;

  /// No description provided for @authLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get authLogoutConfirm;

  /// No description provided for @businessSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Settings'**
  String get businessSettingsTitle;

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get businessName;

  /// No description provided for @businessPhone.
  ///
  /// In en, this message translates to:
  /// **'Business Phone'**
  String get businessPhone;

  /// No description provided for @businessEmail.
  ///
  /// In en, this message translates to:
  /// **'Business Email'**
  String get businessEmail;

  /// No description provided for @businessAddress.
  ///
  /// In en, this message translates to:
  /// **'Business Address'**
  String get businessAddress;

  /// No description provided for @businessTaxRate.
  ///
  /// In en, this message translates to:
  /// **'Tax Rate (%)'**
  String get businessTaxRate;

  /// No description provided for @businessCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get businessCurrency;

  /// No description provided for @businessBranches.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get businessBranches;

  /// No description provided for @posNewSale.
  ///
  /// In en, this message translates to:
  /// **'New Sale'**
  String get posNewSale;

  /// No description provided for @posCart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get posCart;

  /// No description provided for @posEmptyCart.
  ///
  /// In en, this message translates to:
  /// **'Cart is empty'**
  String get posEmptyCart;

  /// No description provided for @posSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get posSubtotal;

  /// No description provided for @posDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get posDiscount;

  /// No description provided for @posTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get posTax;

  /// No description provided for @posTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get posTotal;

  /// No description provided for @posCheckout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get posCheckout;

  /// No description provided for @posPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get posPaymentMethod;

  /// No description provided for @posCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get posCash;

  /// No description provided for @posCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get posCard;

  /// No description provided for @posMobileMoney.
  ///
  /// In en, this message translates to:
  /// **'Mobile Money'**
  String get posMobileMoney;

  /// No description provided for @posSplit.
  ///
  /// In en, this message translates to:
  /// **'Split Payment'**
  String get posSplit;

  /// No description provided for @posCredit.
  ///
  /// In en, this message translates to:
  /// **'Store Credit'**
  String get posCredit;

  /// No description provided for @posAmountTendered.
  ///
  /// In en, this message translates to:
  /// **'Amount Tendered'**
  String get posAmountTendered;

  /// No description provided for @posChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get posChange;

  /// No description provided for @posCompleteSale.
  ///
  /// In en, this message translates to:
  /// **'Complete Sale'**
  String get posCompleteSale;

  /// No description provided for @posSaleSuccess.
  ///
  /// In en, this message translates to:
  /// **'Sale completed successfully!'**
  String get posSaleSuccess;

  /// No description provided for @posReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get posReceipt;

  /// No description provided for @posPrintReceipt.
  ///
  /// In en, this message translates to:
  /// **'Print Receipt'**
  String get posPrintReceipt;

  /// No description provided for @invProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get invProducts;

  /// No description provided for @invAddProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get invAddProduct;

  /// No description provided for @invEditProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get invEditProduct;

  /// No description provided for @invProductName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get invProductName;

  /// No description provided for @invBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get invBarcode;

  /// No description provided for @invSKU.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get invSKU;

  /// No description provided for @invSellingPrice.
  ///
  /// In en, this message translates to:
  /// **'Selling Price'**
  String get invSellingPrice;

  /// No description provided for @invCostPrice.
  ///
  /// In en, this message translates to:
  /// **'Cost Price'**
  String get invCostPrice;

  /// No description provided for @invStockQuantity.
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get invStockQuantity;

  /// No description provided for @invReorderLevel.
  ///
  /// In en, this message translates to:
  /// **'Reorder Level'**
  String get invReorderLevel;

  /// No description provided for @invCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get invCategories;

  /// No description provided for @invLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get invLowStock;

  /// No description provided for @invOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get invOutOfStock;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Appearance & Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get settingsThemeDark;

  /// No description provided for @settingsPrinter.
  ///
  /// In en, this message translates to:
  /// **'Receipt Printer'**
  String get settingsPrinter;

  /// No description provided for @settingsPrinterNone.
  ///
  /// In en, this message translates to:
  /// **'No printer connected'**
  String get settingsPrinterNone;

  /// No description provided for @settingsPrinterPair.
  ///
  /// In en, this message translates to:
  /// **'Pair Printer'**
  String get settingsPrinterPair;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About Afri_BMS'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get settingsSupport;

  /// No description provided for @syncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync Status'**
  String get syncStatus;

  /// No description provided for @syncOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get syncOnline;

  /// No description provided for @syncOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get syncOffline;

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'Changes pending sync'**
  String get syncPending;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud Backup & Restore'**
  String get backupTitle;

  /// No description provided for @backupCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Backup Now'**
  String get backupCreate;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore Data'**
  String get backupRestore;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr', 'sw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'sw':
      return AppLocalizationsSw();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
