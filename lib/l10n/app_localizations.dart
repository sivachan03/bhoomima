import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ml.dart';

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
    Locale('ml'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'BhoomiMa'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'A farmer\'s ally. A mother\'s touch.'**
  String get tagline;

  /// No description provided for @global_filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get global_filter;

  /// No description provided for @global_search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get global_search;

  /// No description provided for @menu_top.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu_top;

  /// No description provided for @menu_properties.
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get menu_properties;

  /// No description provided for @menu_groups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get menu_groups;

  /// No description provided for @menu_workers.
  ///
  /// In en, this message translates to:
  /// **'Workers / Parties'**
  String get menu_workers;

  /// No description provided for @menu_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get menu_settings;

  /// No description provided for @line2_temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get line2_temperature;

  /// No description provided for @line2_weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get line2_weather;

  /// No description provided for @line2_property.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get line2_property;

  /// No description provided for @line2_gps.
  ///
  /// In en, this message translates to:
  /// **'GPS'**
  String get line2_gps;

  /// No description provided for @gps_disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get gps_disabled;

  /// No description provided for @gps_accuracy.
  ///
  /// In en, this message translates to:
  /// **'Acc'**
  String get gps_accuracy;

  /// No description provided for @gps_stability.
  ///
  /// In en, this message translates to:
  /// **'Stab'**
  String get gps_stability;

  /// No description provided for @tab_map.
  ///
  /// In en, this message translates to:
  /// **'Map View'**
  String get tab_map;

  /// No description provided for @tab_list.
  ///
  /// In en, this message translates to:
  /// **'List View'**
  String get tab_list;

  /// No description provided for @tab_diary.
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get tab_diary;

  /// No description provided for @tab_farm_log.
  ///
  /// In en, this message translates to:
  /// **'Farm Log'**
  String get tab_farm_log;

  /// No description provided for @bottom_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get bottom_add;

  /// No description provided for @bottom_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get bottom_refresh;

  /// No description provided for @bottom_tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get bottom_tools;

  /// No description provided for @add_point.
  ///
  /// In en, this message translates to:
  /// **'Add Point'**
  String get add_point;

  /// No description provided for @add_log.
  ///
  /// In en, this message translates to:
  /// **'Add Log'**
  String get add_log;

  /// No description provided for @add_diary.
  ///
  /// In en, this message translates to:
  /// **'Add Diary Task'**
  String get add_diary;
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
      <String>['en', 'ml'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ml':
      return AppLocalizationsMl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
