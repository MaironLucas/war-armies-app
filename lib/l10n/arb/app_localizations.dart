import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'arb/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('pt'),
  ];

  /// The application title.
  ///
  /// In en, this message translates to:
  /// **'War Armies'**
  String get appTitle;

  /// Button label to host a new game.
  ///
  /// In en, this message translates to:
  /// **'Host Game'**
  String get hostGame;

  /// Button label to join an existing game.
  ///
  /// In en, this message translates to:
  /// **'Join Game'**
  String get joinGame;

  /// Label for the room name text field.
  ///
  /// In en, this message translates to:
  /// **'Room Name'**
  String get roomName;

  /// Label for the player name text field.
  ///
  /// In en, this message translates to:
  /// **'Player Name'**
  String get playerName;

  /// Button label to create a new room.
  ///
  /// In en, this message translates to:
  /// **'Create Room'**
  String get createRoom;

  /// Button label to start the match.
  ///
  /// In en, this message translates to:
  /// **'Start Match'**
  String get startMatch;

  /// Button label to destroy the room and disconnect all players.
  ///
  /// In en, this message translates to:
  /// **'Kill Room'**
  String get killRoom;

  /// Confirmation message when killing a room.
  ///
  /// In en, this message translates to:
  /// **'This will disconnect all players'**
  String get killRoomConfirm;

  /// Button label to join a room.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinRoom;

  /// Button label to leave the current room.
  ///
  /// In en, this message translates to:
  /// **'Leave Room'**
  String get leaveRoom;

  /// Label for territory count.
  ///
  /// In en, this message translates to:
  /// **'Territories'**
  String get territories;

  /// Button label for the host to end the match.
  ///
  /// In en, this message translates to:
  /// **'End Match'**
  String get endMatch;

  /// Button label for the guest to leave the match.
  ///
  /// In en, this message translates to:
  /// **'Leave Match'**
  String get leaveMatch;

  /// Message shown while discovering rooms on the network.
  ///
  /// In en, this message translates to:
  /// **'Searching for rooms…'**
  String get discoveringRooms;

  /// Message shown while hosting a room.
  ///
  /// In en, this message translates to:
  /// **'Creating room…'**
  String get hostingRoom;

  /// Message shown while joining a room.
  ///
  /// In en, this message translates to:
  /// **'Joining room…'**
  String get joiningRoom;

  /// Message shown to guests while waiting in the lobby.
  ///
  /// In en, this message translates to:
  /// **'Waiting for host to start match…'**
  String get waitingForHost;

  /// Message shown when no rooms are discovered.
  ///
  /// In en, this message translates to:
  /// **'No rooms found on the network'**
  String get noRoomsFound;

  /// Generic error message.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorGeneric;

  /// Label for the player list section.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get players;

  /// Button label to set a territory count.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get set;
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
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
