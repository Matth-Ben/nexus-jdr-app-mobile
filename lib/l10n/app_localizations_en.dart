// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get profileLanguageMenuEntry => 'Language';

  @override
  String get profileLanguageScreenTitle => 'LANGUAGE';

  @override
  String get profileLanguagePhoneOption => 'Phone language';

  @override
  String get profileLanguagePhoneOptionSubtitle => 'Langue du téléphone';

  @override
  String get profileLanguagePhoneOptionDetail =>
      'Suit la langue de l\'appareil (FR/EN) ; repli sur le français si l\'appareil utilise une autre langue. / Follows the device\'s language (FR/EN); falls back to French otherwise.';

  @override
  String get profileLanguageFrenchOption => 'Français';

  @override
  String get profileLanguageEnglishOption => 'English';

  @override
  String get profileLanguageSaveError =>
      'Couldn\'t save this setting. Please try again.';

  @override
  String get authLoginBrandTitle => 'NEXUS JDR';

  @override
  String get authLoginTagline => 'The adventurers\' registry';

  @override
  String get authLoginSharedAccountNotice =>
      'Same account as the Histoires app';

  @override
  String get authLoginCardTitleSignUp => 'CREATE AN ACCOUNT';

  @override
  String get authLoginCardTitleLogin => 'ENTER THE TAVERN';

  @override
  String get authLoginEmailLabel => 'Email address';

  @override
  String get authLoginEmailHint => 'name@example.com';

  @override
  String get authLoginPasswordLabel => 'Password';

  @override
  String get authLoginPasswordHint => '••••••••';

  @override
  String get authLoginForgotPasswordLink => 'Forgot password?';

  @override
  String get authLoginConfirmPasswordLabel => 'Confirm password';

  @override
  String get authLoginPseudoLabel => 'Display name';

  @override
  String get authLoginPseudoHint => 'What would you like to be called?';

  @override
  String get authLoginPseudoHelper =>
      'Optional — you can change this later in your profile.';

  @override
  String get authLoginSubmitSignUp => 'Create account';

  @override
  String get authLoginSubmitLogin => 'Enter';

  @override
  String get authLoginOrDivider => 'OR';

  @override
  String get authLoginContinueWithApple => 'Continue with Apple';

  @override
  String get authLoginContinueWithGoogle => 'Continue with Google';

  @override
  String get authLoginSwitchModePromptLogin => 'Already have an account? ';

  @override
  String get authLoginSwitchModePromptSignUp => 'Don\'t have an account? ';

  @override
  String get authLoginSwitchModeActionLogin => 'Log in';

  @override
  String get authLoginSwitchModeActionSignUp => 'Create an account';

  @override
  String get authLoginSignUpConfirmationTitle => 'CHECK YOUR EMAIL';

  @override
  String authLoginSignUpConfirmationBody(String email) {
    return 'A confirmation email has just been sent to $email. Click the link it contains to activate your account.';
  }

  @override
  String get authLoginBackToLogin => 'Back to login';

  @override
  String get authForgotPasswordTitle => 'Forgot your password?';

  @override
  String get authForgotPasswordDescription =>
      'Enter your email address: we\'ll send you a link to set a new password.';

  @override
  String get authForgotPasswordEmailHint => 'name@example.com';

  @override
  String get authForgotPasswordCancel => 'Cancel';

  @override
  String get authForgotPasswordSubmit => 'Send link';

  @override
  String get authForgotPasswordNeutralMessage =>
      'If an account exists with this email, a reset link has just been sent.';

  @override
  String get authErrorInvalidCredentials => 'Incorrect email or password.';

  @override
  String get authErrorEmailAlreadyExists =>
      'An account already exists with this email address.';

  @override
  String authErrorWeakPassword(int minLength) {
    return 'Password must be at least $minLength characters long.';
  }

  @override
  String get authErrorEmailNotConfirmed =>
      'Confirm your email address before signing in (check your inbox).';

  @override
  String get authErrorInvalidEmail => 'Invalid email address.';

  @override
  String get authErrorTooManyRequests =>
      'Too many attempts. Please try again in a few moments.';

  @override
  String get authErrorNetwork =>
      'Couldn\'t reach the server. Check your internet connection and try again.';

  @override
  String get authErrorBrowserLaunchFailed =>
      'Couldn\'t open the browser to continue with Google. Please try again.';

  @override
  String get authErrorUnexpected =>
      'An unexpected error occurred. Please try again.';

  @override
  String get authValidationEmailRequired => 'Enter your email address.';

  @override
  String get authValidationEmailInvalid => 'Invalid email address.';

  @override
  String get authValidationPasswordRequired => 'Enter your password.';

  @override
  String authValidationPasswordTooShort(int minLength) {
    return 'Password must be at least $minLength characters long.';
  }

  @override
  String get authValidationPasswordConfirmationRequired =>
      'Confirm your password.';

  @override
  String get authValidationPasswordConfirmationMismatch =>
      'Passwords don\'t match.';

  @override
  String get profileMenuTitle => 'PROFILE';

  @override
  String get profileMenuEditProfile => 'Edit profile';

  @override
  String get profileMenuNotifications => 'Notifications';

  @override
  String get profileMenuPrivacy => 'Privacy & data';

  @override
  String get profileMenuHelp => 'Help & support';

  @override
  String get profileMenuSignOut => 'Sign out';

  @override
  String get profileCreditsScreenTitle => 'CREDITS & LICENSES';

  @override
  String get profileCreditsGameContentTitle => 'Game content';

  @override
  String get profileCreditsGameContentPara1 =>
      'Dungeons & Dragons 5e rules content (races, classes, backgrounds, spells, items, monsters...) comes from Open5e and the System Reference Document (SRD 5.1/5.2) by Wizards of the Coast, under the Creative Commons Attribution 4.0 International license (CC-BY 4.0).';

  @override
  String get profileCreditsGameContentPara2 =>
      'Dungeons & Dragons, D&D and their logos are trademarks of Wizards of the Coast LLC. Wizards of the Coast has not produced, endorsed, or authorized this application.';

  @override
  String get profileCreditsLicenseNotice =>
      'This product includes material from the System Reference Document 5.1 and 5.2, available at dndbeyond.com/srd and open5e.com, under the Creative Commons Attribution 4.0 International license (creativecommons.org/licenses/by/4.0/legalcode).';

  @override
  String get profileCreditsFontsTitle => 'Fonts';

  @override
  String get profileCreditsFontsPara1 =>
      'Press Start 2P (The Press Start 2P Project Authors) and Work Sans (The Work Sans Project Authors) are distributed under the SIL Open Font License, version 1.1 (scripts.sil.org/OFL), and bundled as-is with the application from the official Google Fonts repository (github.com/google/fonts).';

  @override
  String get profileCreditsOpenSourceTitle => 'Open source libraries';

  @override
  String get profileCreditsOpenSourcePara1 =>
      'Flutter · Riverpod · Supabase Flutter · Drift · Freezed · go_router · image_picker · file_picker · connectivity_plus · package_info_plus · share_plus · app_settings · url_launcher · Firebase (Core, Messaging) · shared_preferences';

  @override
  String get profileCreditsOpenSourcePara2 =>
      'As well as the other libraries listed in the project\'s pubspec.yaml file, each under its own original open source license.';

  @override
  String get profileCreditsLastUpdated => 'Last updated: October 14, 2026';

  @override
  String get profileDeleteAccountScreenTitle => 'DELETE ACCOUNT';

  @override
  String get profileDeleteAccountOfflineMessage =>
      'Offline: this action couldn\'t be saved. Try again once you\'re back online.';

  @override
  String get profileDeleteAccountGenericError =>
      'Couldn\'t delete the account. Please try again.';

  @override
  String get profileDeleteAccountWrongPassword => 'Incorrect password.';

  @override
  String get profileDeleteAccountWarningTitle => 'IRREVERSIBLE ACTION';

  @override
  String get profileDeleteAccountWarningMessage =>
      'This action is irreversible. It will permanently delete:\n• All your characters and their portraits\n• Your links to the stories you\'ve joined\n• All the stories you\'ve created as a GM on the Histoires app (and your players\' access to those stories)\n\nThis action cannot be undone.';

  @override
  String get profileDeleteAccountConfirmationCheckboxLabel =>
      'I understand that this action is final and that my data cannot be recovered.';

  @override
  String get profileDeleteAccountWhatWillBeDeletedTitle =>
      'WHAT WILL BE DELETED';

  @override
  String get profileDeleteAccountChecklistCharacters =>
      'All your characters and their sheets';

  @override
  String get profileDeleteAccountChecklistStories =>
      'Your access to shared stories';

  @override
  String get profileDeleteAccountChecklistProfile =>
      'Your profile and preferences';

  @override
  String get profileDeleteAccountPasswordSectionTitle =>
      'ENTER YOUR PASSWORD TO CONFIRM';

  @override
  String get profileDeleteAccountPasswordHint => '••••••••';

  @override
  String get profileDeleteAccountSubmitInProgress => 'Deleting…';

  @override
  String get profileDeleteAccountSubmitLabel => 'Delete permanently';

  @override
  String get profileDeleteAccountCancel => 'Cancel';

  @override
  String get profileEditScreenTitle => 'EDIT PROFILE';

  @override
  String get profileEditPseudoLabel => 'Nickname';

  @override
  String get profileEditPseudoHint => 'What should we call you?';

  @override
  String get profileEditEmailLabel => 'Email';

  @override
  String get profileEditEmailChangeNotice =>
      'Changing your email sends a confirmation link to the new address.';

  @override
  String get profileEditChangePassword => 'Change password';

  @override
  String get profileEditSaveButton => 'Save';

  @override
  String get profileEditSavedSnackbar => 'Nickname updated.';

  @override
  String get profileEditOfflineMessage =>
      'Offline: this action couldn\'t be saved. Try again once you\'re back online.';

  @override
  String get profileEditGenericError =>
      'Couldn\'t save the changes. Please try again.';

  @override
  String get profileEditTakePhoto => 'Take a photo';

  @override
  String get profileEditChoosePhoto => 'Choose from gallery';

  @override
  String get profileFaqScreenTitle => 'FREQUENTLY ASKED QUESTIONS';

  @override
  String get profileFaqQuestion1 =>
      'How do I import a character from aidedd.org?';

  @override
  String get profileFaqAnswer1 =>
      'On aidedd.org, open your character sheet and use its XML export (the site\'s export button). In Nexus JDR, go to Characters > \"+\" > Import an XML file, then select that file. The app automatically pre-fills the sheet (stats, class, race, spells, inventory...) and shows you a review screen before saving it, with any fields it couldn\'t recognize flagged with a badge so you can fill them in yourself.';

  @override
  String get profileFaqQuestion2 => 'How do I join my GM\'s story?';

  @override
  String get profileFaqAnswer2 =>
      'Your GM shares an invitation code or link from the Histoires app. In Nexus JDR, open that link or enter the code on the \"Join a story\" screen, then choose the character to attach (an existing one or a new one). The character then stays synced with that story until the GM revokes access.';

  @override
  String get profileFaqQuestion3 => 'Are my characters saved offline?';

  @override
  String get profileFaqAnswer3 =>
      'Yes. All your characters stay viewable and editable without a connection: changes (hit points, XP, inventory...) are queued on your device and automatically synced with the server as soon as the connection comes back. No data is lost in case of a network outage.';

  @override
  String get profileFaqQuestion4 => 'How does leveling up work?';

  @override
  String get profileFaqAnswer4 =>
      'From the character sheet, the \"Level up\" screen guides you step by step: new hit points, unlocked class features, new spell slots if your class casts spells, and an ability score increase if the level allows it. Nothing is applied until you confirm the summary screen.';

  @override
  String get profileFaqQuestion5 => 'How do I change my character\'s portrait?';

  @override
  String get profileFaqAnswer5 =>
      'Open the character sheet, tap its portrait, then choose \"Take a photo\" or \"Choose from gallery\". You can then crop the image before saving it — it\'s stored securely and linked only to that character.';

  @override
  String get profileFaqQuestion6 => 'How do I delete my account?';

  @override
  String get profileFaqAnswer6 =>
      'From Profile > Privacy & data > Delete my account, at the bottom of the screen (danger zone). This action is irreversible: it permanently deletes your characters, their portraits and all links to stories. You can export your data before confirming.';

  @override
  String get profileHelpScreenTitle => 'HELP & SUPPORT';

  @override
  String get profileHelpSectionFaq => 'FREQUENTLY ASKED QUESTIONS';

  @override
  String get profileHelpFaqQuestion1 =>
      'How do I import a character from aidedd.org?';

  @override
  String get profileHelpFaqQuestion2 => 'How do I join my GM\'s story?';

  @override
  String get profileHelpFaqQuestion3 => 'Are my characters saved offline?';

  @override
  String get profileHelpFaqSeeAll => 'See all questions';

  @override
  String get profileHelpSectionContact => 'CONTACT US';

  @override
  String get profileHelpContactSupport => 'Contact support';

  @override
  String get profileHelpReportBug => 'Report a bug';

  @override
  String get profileHelpContactFooterNote =>
      'Replies within 48h on weekdays. A snapshot of your device\'s technical info is attached automatically.';

  @override
  String get profileHelpSectionAbout => 'ABOUT';

  @override
  String get profileHelpReplayOnboarding => 'Replay the app introduction';

  @override
  String get profileHelpLegalMentions => 'Legal notice / Terms';

  @override
  String get profileHelpCredits => 'Credits & licenses';

  @override
  String get profileHelpAboutFooterNote =>
      'D&D 5e content under the Open5e / SRD license. See the full credits for details on sources.';

  @override
  String profileHelpFooterVersionWithNumber(String version) {
    return 'Nexus JDR — Personnages · v$version';
  }

  @override
  String get profileHelpFooterVersionWithoutNumber => 'Nexus JDR — Personnages';

  @override
  String get profileHelpNoMailApp =>
      'No email application is configured on this device.';

  @override
  String get profileHelpGenericMailError =>
      'Couldn\'t open the email application. Please try again.';

  @override
  String get profileLegalScreenTitle => 'LEGAL NOTICE / TERMS';

  @override
  String get profileLegalEditorTitle => 'Publisher';

  @override
  String get profileLegalEditorPara1 => 'Matthias Benoit';

  @override
  String get profileLegalEditorPara2 => 'Contact: support@nexus-jdr.app';

  @override
  String get profileLegalHostingTitle => 'Hosting';

  @override
  String get profileLegalHostingPara1 =>
      'The application and its data are hosted by Supabase (database, authentication, file storage).';

  @override
  String get profileLegalPurposeTitle => 'Purpose of the application';

  @override
  String get profileLegalPurposePara1 =>
      'Nexus JDR — Personnages lets you create, import and manage Dungeons & Dragons 5e characters, alone or synced with the \"Histoires\" app used by your Game Master.';

  @override
  String get profileLegalTermsTitle => 'Terms of use';

  @override
  String get profileLegalTermsPara1 =>
      'Using the application requires an account. You are responsible for the accuracy of the information you provide and for keeping your credentials confidential. The publisher reserves the right to suspend an account in case of abuse.';

  @override
  String get profileLegalIntellectualPropertyTitle => 'Intellectual property';

  @override
  String get profileLegalIntellectualPropertyPara1 =>
      'Dungeons & Dragons 5e rules content (races, classes, spells, items...) comes from Open5e and the System Reference Document (SRD), under the Creative Commons Attribution 4.0 license (CC-BY 4.0) — see \"Credits & licenses\" for details. The rest of the application (code, design, the \"Nexus JDR\" brand) belongs to its publisher.';

  @override
  String get profileLegalTerminationTitle => 'Termination';

  @override
  String get profileLegalTerminationPara1 =>
      'You can delete your account at any time from Profile > Privacy & data > Delete my account.';

  @override
  String get profileLegalGoverningLawTitle => 'Governing law';

  @override
  String get profileLegalGoverningLawPara1 =>
      'This notice is governed by French law.';

  @override
  String get profileLegalLastUpdated => 'Last updated: September 25, 2026';

  @override
  String get profileNotificationsScreenTitle => 'NOTIFICATIONS';

  @override
  String get profileNotificationsOsPermissionDenied =>
      'Notifications are disabled at the phone level. Enable them in your device settings to receive them.';

  @override
  String get profileNotificationsPushToggle => 'Push notifications';

  @override
  String get profileNotificationsSectionTriggers => 'TRIGGERS';

  @override
  String get profileNotificationsRestReminder =>
      'Long rest not taken in a while';

  @override
  String get profileNotificationsAccessRevoked =>
      'Access removed or changed by the GM';

  @override
  String get profileNotificationsNewVersion => 'New update available';

  @override
  String get profileNotificationsSectionEmail => 'EMAIL';

  @override
  String get profileNotificationsEmailDigest => 'Receive an email summary';

  @override
  String get profileNotificationsEmailDigestSubtitle =>
      'Weekly summary of characters who have progressed.';

  @override
  String get profileNotificationsSystemNote =>
      'System permissions (notifications) can also be managed from your phone\'s settings.';

  @override
  String get profileNotificationsGenericError =>
      'Couldn\'t save this setting. Please try again.';

  @override
  String get profileNotificationsLoadError =>
      'Couldn\'t load your notification preferences. Please try again.';

  @override
  String get profileNotificationsRetry => 'Retry';

  @override
  String get profilePrivacyPolicyScreenTitle => 'PRIVACY POLICY';

  @override
  String get profilePrivacyPolicyIntroductionTitle => 'Introduction';

  @override
  String get profilePrivacyPolicyIntroductionPara1 =>
      'This policy explains what data Nexus JDR collects, why, who it\'s shared with, and how you can access, export or delete it.';

  @override
  String get profilePrivacyPolicySection1Title =>
      '1. Who is responsible for your data';

  @override
  String get profilePrivacyPolicySection1Para1 =>
      'This policy applies to the Nexus JDR — Personnages mobile app (Android) and to the Nexus JDR \"Histoires\" web app (nexus-jdr.app), which share the same account.';

  @override
  String get profilePrivacyPolicySection1Para2 =>
      'Data controller: Matthias Benoit, publisher of Nexus JDR. Contact: support@nexus-jdr.app.';

  @override
  String get profilePrivacyPolicySection2Title => '2. Data we collect';

  @override
  String get profilePrivacyPolicySection2Para1 =>
      '• Account: email address and password (the password is stored encrypted by our authentication service, we never see it), displayed nickname and optional avatar.';

  @override
  String get profilePrivacyPolicySection2Para2 =>
      '• Game content: everything you create — characters (stats, skills, spells, inventory, appearance, backstory), journal, group notes, groups and stories you\'ve joined, character files you import.';

  @override
  String get profilePrivacyPolicySection2Para3 =>
      '• Photos: character portrait, gallery and avatar — only images you choose to take with the camera, import from your gallery, or from a web address.';

  @override
  String get profilePrivacyPolicySection2Para4 =>
      '• Voice dictation (group notes, optional): the microphone is only used while you\'re dictating. Speech recognition is handled by your phone\'s own service (for example Google on Android); we only receive the resulting text, never the audio recording.';

  @override
  String get profilePrivacyPolicySection2Para5 =>
      '• Notifications: a technical identifier for your device (notification token) and your notification preferences, to send you reminders and news about your groups.';

  @override
  String get profilePrivacyPolicySection2Para6 =>
      '• Usage statistics: screens viewed and actions taken in the app, along with technical information (device model, system, app version) and a pseudonymous identifier generated by the measurement tool. These statistics are not linked to your account or your email address.';

  @override
  String get profilePrivacyPolicySection2Para7 =>
      '• Bug reports: title, description and severity you enter, app version, platform and, if you choose, the character involved.';

  @override
  String get profilePrivacyPolicySection3Title => '3. What we don\'t collect';

  @override
  String get profilePrivacyPolicySection3Para1 =>
      'No location data, no contacts, no payment data. No ads are shown and no data is sold.';

  @override
  String get profilePrivacyPolicySection4Title => '4. Why we use this data';

  @override
  String get profilePrivacyPolicySection4Para1 =>
      '• To provide the service (account, sheets, groups, syncing with your GM, photos, notifications you enable): this is necessary to perform the service you use.';

  @override
  String get profilePrivacyPolicySection4Para2 =>
      '• To improve the app (usage statistics): legitimate interest in understanding which features are used. You can opt out at any time from Profile > Privacy & data > Share my usage data.';

  @override
  String get profilePrivacyPolicySection4Para3 =>
      '• To fix the bugs you report to us.';

  @override
  String get profilePrivacyPolicySection5Title =>
      '5. Who your data is shared with';

  @override
  String get profilePrivacyPolicySection5Para1 =>
      'With other users, only at your own initiative: the GM and members of the stories or groups you join see the characters you attach to them; if you create a sheet-sharing link, anyone with that link can view the sheet read-only, until you disable it.';

  @override
  String get profilePrivacyPolicySection5Para2 =>
      'With our technical service providers, who process data on our behalf:';

  @override
  String get profilePrivacyPolicySection5Para3 =>
      '• Supabase — hosting of the database, authentication and photos.';

  @override
  String get profilePrivacyPolicySection5Para4 =>
      '• Google Firebase — sending notifications (Firebase Cloud Messaging) and usage statistics (Firebase Analytics).';

  @override
  String get profilePrivacyPolicySection5Para5 =>
      '• Google Firebase Crashlytics — crash reports (technical error traces and information about your device), collected systematically to keep the app stable. Unlike usage statistics (Firebase Analytics/PostHog, see above), this collection cannot be disabled from the app: our legitimate interest in diagnosing and fixing app crashes prevails here.';

  @override
  String get profilePrivacyPolicySection5Para6 =>
      '• PostHog (hosted in the European Union) — usage statistics.';

  @override
  String get profilePrivacyPolicySection5Para7 =>
      '• GitHub — tracking of reported bugs: the content of a report (title, description, severity, version, platform) is published as a ticket in a public repository, without your email address or name. Please don\'t include any personal information in it.';

  @override
  String get profilePrivacyPolicySection5Para8 =>
      '• Resend — sending transactional emails (account confirmation, password reset).';

  @override
  String get profilePrivacyPolicySection5Para9 =>
      '• Vercel — hosting of the nexus-jdr.app website.';

  @override
  String get profilePrivacyPolicySection5Para10 =>
      'Some of these providers may process data outside the European Union; these transfers are governed by the safeguards required by the GDPR (European Commission standard contractual clauses or the EU–US Data Privacy Framework).';

  @override
  String get profilePrivacyPolicySection6Title => '6. Retention period';

  @override
  String get profilePrivacyPolicySection6Para1 =>
      '• Account, game content and photos: for as long as your account exists. They are permanently deleted as soon as you delete your account.';

  @override
  String get profilePrivacyPolicySection6Para2 =>
      '• Usage statistics: kept in pseudonymous form, unlinked from your account, for the retention period set in the measurement tools.';

  @override
  String get profilePrivacyPolicySection6Para3 =>
      '• Bug reports: for as long as needed to process them.';

  @override
  String get profilePrivacyPolicySection7Title => '7. Your rights';

  @override
  String get profilePrivacyPolicySection7Para1 =>
      'Under the GDPR, you have the right to access, rectify, erase, port, object to and restrict the processing of your data. Directly from the app:';

  @override
  String get profilePrivacyPolicySection7Para2 =>
      '• Export your data: Profile > Privacy & data > Export my data.';

  @override
  String get profilePrivacyPolicySection7Para3 =>
      '• Delete your account and all your data: Profile > Privacy & data > Delete my account.';

  @override
  String get profilePrivacyPolicySection7Para4 =>
      '• Disable usage statistics: Profile > Privacy & data.';

  @override
  String get profilePrivacyPolicySection7Para5 =>
      '• Disable notifications: in the app\'s or your phone\'s notification settings.';

  @override
  String get profilePrivacyPolicySection7Para6 =>
      'For any other request, write to support@nexus-jdr.app. You can also file a complaint with the CNIL (www.cnil.fr).';

  @override
  String get profilePrivacyPolicySection8Title => '8. Security';

  @override
  String get profilePrivacyPolicySection8Para1 =>
      'Exchanges with our servers are encrypted (HTTPS). Access to your data is protected by your account\'s authentication and by access rules that prevent any other user from reading or modifying what you don\'t share.';

  @override
  String get profilePrivacyPolicySection9Title => '9. Changes to this policy';

  @override
  String get profilePrivacyPolicySection9Para1 =>
      'This policy may evolve along with the application. The last update date appears at the bottom of this screen; in case of a significant change, you will be notified in the app.';

  @override
  String get profilePrivacyPolicyLastUpdated =>
      'Last updated: November 1, 2026';

  @override
  String get profilePrivacyScreenTitle => 'PRIVACY';

  @override
  String get profilePrivacyDataSectionTitle => 'MY DATA';

  @override
  String get profilePrivacyExportData => 'Export my data';

  @override
  String get profilePrivacyPolicyLink => 'Privacy policy';

  @override
  String get profilePrivacyDevicePermissions => 'Device permissions';

  @override
  String get profilePrivacyExportNote =>
      'The export contains your profile, your characters (their inventory, spells and history), your groups and your group notes (JSON, offered for sharing from your device).';

  @override
  String get profilePrivacyShareUsageData => 'Share my usage data';

  @override
  String get profilePrivacyShareUsageDataSubtitle =>
      'Anonymous usage statistics (Firebase Analytics, PostHog), to improve the app. Can be disabled at any time — crash reports always stay active for the app\'s stability (see Privacy policy).';

  @override
  String get profilePrivacyDangerZoneTitle => 'DANGER ZONE';

  @override
  String get profilePrivacyDeleteAccount => 'Delete my account';

  @override
  String get profileAvatarCropScreenTitle => 'CROP';

  @override
  String get profileAvatarCropInstructions => 'Pinch to zoom, drag to crop.';

  @override
  String get profileAvatarCropCancel => 'Cancel';

  @override
  String get profileAvatarCropConfirm => 'Confirm';

  @override
  String get profileAvatarCropOfflineMessage =>
      'Offline: this action couldn\'t be saved. Try again once you\'re back online.';

  @override
  String get profileAvatarCropGenericError =>
      'Couldn\'t update the avatar. Please try again.';

  @override
  String get profileAvatarCropPrepareImageError =>
      'Couldn\'t prepare the image. Please try again.';

  @override
  String get profileAvatarEditTakePhoto => 'Take a photo';

  @override
  String get profileAvatarEditChooseGallery => 'Choose from gallery';

  @override
  String get profileAvatarEditRemovePhoto => 'Remove photo';

  @override
  String get profileAvatarEditRemovedSnackbar => 'Photo removed.';

  @override
  String get profileAvatarEditGenericError =>
      'Couldn\'t update the avatar. Please try again.';

  @override
  String get profileAvatarEditRemoveConfirmTitle => 'Remove the photo?';

  @override
  String get profileAvatarEditRemoveConfirmCancel => 'Cancel';

  @override
  String get profileAvatarEditRemoveConfirmAction => 'Remove';

  @override
  String get profileChangeEmailTitle => 'EMAIL ADDRESS';

  @override
  String get profileChangeEmailInfoBanner =>
      'A confirmation email will be sent to this address. The change won\'t take effect until it\'s confirmed.';

  @override
  String get profileChangeEmailFieldLabel => 'NEW EMAIL ADDRESS';

  @override
  String get profileChangeEmailHint => 'name@example.com';

  @override
  String profileChangeEmailCurrentAddress(String email) {
    return 'Current address: $email';
  }

  @override
  String get profileChangeEmailCancel => 'Cancel';

  @override
  String get profileChangeEmailSave => 'Save';

  @override
  String get profileChangeEmailConfirmationSnackbar =>
      'Confirmation email sent. Check your inbox to finish the change.';

  @override
  String get profileChangeEmailOfflineMessage =>
      'Offline: this action couldn\'t be saved. Try again once you\'re back online.';

  @override
  String get profileChangeEmailGenericError =>
      'Couldn\'t send the new email. Please try again.';

  @override
  String get profileChangePasswordTitle => 'PASSWORD';

  @override
  String get profileChangePasswordNewLabel => 'NEW PASSWORD';

  @override
  String get profileChangePasswordHint => '••••••••';

  @override
  String get profileChangePasswordConfirmLabel => 'CONFIRM PASSWORD';

  @override
  String get profileChangePasswordCancel => 'Cancel';

  @override
  String get profileChangePasswordSave => 'Save';

  @override
  String get profileChangePasswordUpdatedSnackbar => 'Password updated.';

  @override
  String get profileChangePasswordOfflineMessage =>
      'Offline: this action couldn\'t be saved. Try again once you\'re back online.';

  @override
  String get profileChangePasswordGenericError =>
      'Couldn\'t update the password. Please try again.';

  @override
  String get profileDevicePermissionsTitle => 'DEVICE PERMISSIONS MANAGEMENT';

  @override
  String get profileDevicePermissionsBody =>
      'Nexus JDR only uses the camera and gallery to set your character\'s portrait or your avatar. To change these permissions, open your phone\'s settings.';

  @override
  String get profileDevicePermissionsOpenSettings => 'Open settings';

  @override
  String get profileEditDisplayNameTitle => 'NICKNAME';

  @override
  String get profileEditDisplayNameFieldLabel => 'DISPLAY NAME';

  @override
  String get profileEditDisplayNameHint => 'What should we call you?';

  @override
  String get profileEditDisplayNameCancel => 'Cancel';

  @override
  String get profileEditDisplayNameSave => 'Save';

  @override
  String get profileEditDisplayNameUpdatedSnackbar => 'Nickname updated.';

  @override
  String get profileEditDisplayNameOfflineMessage =>
      'Offline: this action couldn\'t be saved. Try again once you\'re back online.';

  @override
  String get profileEditDisplayNameGenericError =>
      'Couldn\'t save the changes. Please try again.';

  @override
  String get profileExportDataTitle => 'EXPORT MY DATA';

  @override
  String get profileExportDataDescription =>
      'Generates a JSON file containing your profile, all your characters and their related data (inventory, spells, history), as well as your groups and group notes. The file will be offered for sharing/saving from your device.';

  @override
  String get profileExportDataCancel => 'Cancel';

  @override
  String get profileExportDataGenerate => 'Generate export';

  @override
  String get profileExportDataGeneratedSnackbar => 'Export generated.';

  @override
  String get profileExportDataOfflineMessage =>
      'Offline: this action couldn\'t be saved. Try again once you\'re back online.';

  @override
  String get profileExportDataGenericError =>
      'Couldn\'t generate the export. Please try again.';

  @override
  String get profileReportBugSentSnackbar =>
      'Thanks, your report has been sent!';

  @override
  String get profileReportBugSeverityMinorTitle => 'Annoying';

  @override
  String get profileReportBugSeverityMinorSubtitle =>
      'A nuisance, but you can keep playing';

  @override
  String get profileReportBugSeverityMajorTitle => 'Problematic';

  @override
  String get profileReportBugSeverityMajorSubtitle =>
      'It complicates things, but there\'s a way around it';

  @override
  String get profileReportBugSeverityBlockingTitle => 'It blocks everything';

  @override
  String get profileReportBugSeverityBlockingSubtitle =>
      'Impossible to continue without this';

  @override
  String get profileReportBugSeverityContentTitle => 'Content to fix';

  @override
  String get profileReportBugSeverityContentSubtitle =>
      'Mistake or omission in a spell, item, rule or translation';

  @override
  String get profileReportBugOfflineMessage =>
      'Offline: this action couldn\'t be saved. Try again once you\'re back online.';

  @override
  String get profileReportBugGenericError =>
      'Couldn\'t send the report. Please try again.';

  @override
  String get profileReportBugScreenshotUploadError =>
      'Couldn\'t send the screenshot. Please try again, or remove it to send the report without it.';

  @override
  String get profileReportBugCaptureTooLarge =>
      'This image is too large (over 5 MB), even compressed. Please choose another one.';

  @override
  String get profileReportBugCaptureUnsupportedFormat =>
      'This image format isn\'t supported. Please choose another image.';

  @override
  String get profileReportBugCaptureAccessDenied =>
      'Access to your photos or camera is denied. Allow it in your phone\'s settings.';

  @override
  String get profileReportBugCapturePrivacyNotice =>
      'Optional, a single image. It stays private: only the development team sees it, it\'s never published with your report, and it\'s deleted with your account. Still, avoid leaving any personal information in it.';

  @override
  String get profileReportBugAddCaptureSemanticLabel =>
      'Add a screenshot (optional)';

  @override
  String get profileReportBugAddCapture => 'Add a screenshot';

  @override
  String get profileReportBugCaptureSectionTitle => 'SCREENSHOT';

  @override
  String get profileReportBugTitle => 'REPORT A BUG';

  @override
  String get profileReportBugFieldTitleLabel => 'TITLE';

  @override
  String get profileReportBugFieldTitleHint =>
      'One-sentence summary (e.g. \"The HP button doesn\'t respond\")';

  @override
  String get profileReportBugFieldDescriptionLabel => 'DESCRIPTION';

  @override
  String get profileReportBugFieldDescriptionHint =>
      'What happened? What were you doing when the bug occurred?';

  @override
  String get profileReportBugSeveritySectionTitle => 'WHAT KIND OF ISSUE?';

  @override
  String get profileReportBugCancel => 'Cancel';

  @override
  String get profileReportBugSend => 'Send';

  @override
  String get profileReportBugChooseGallery => 'Choose from gallery';

  @override
  String get profileReportBugTakePhoto => 'Take a photo';

  @override
  String get profileReportBugPreparingImage => 'Preparing image…';

  @override
  String get profileReportBugPreparingImageSemanticLabel => 'Preparing image';

  @override
  String get profileReportBugAttachedLabel => 'Attached screenshot';

  @override
  String get profileReportBugReplace => 'Replace';

  @override
  String get profileReportBugRemove => 'Remove';

  @override
  String get profileReportBugReplaceSemanticLabel => 'Replace the screenshot';

  @override
  String get profileReportBugRemoveSemanticLabel => 'Remove the screenshot';

  @override
  String get profileReportBugAttachedImageSemanticLabel =>
      'Attached screenshot';

  @override
  String characterLevelAbbreviation(int level) {
    return 'Lvl. $level';
  }

  @override
  String get characterOfflineNotPersistedMessage =>
      'Offline: this action couldn\'t be saved. Try again once you\'re back online.';

  @override
  String get characterAccessDeniedErrorMessage =>
      'You don\'t have access to these characters.';

  @override
  String get characterNetworkErrorMessage =>
      'Couldn\'t reach the server. Check your internet connection and try again.';

  @override
  String get characterListHeaderTitle => 'YOUR ADVENTURERS';

  @override
  String get characterListSearchHint => 'Search for a character';

  @override
  String get characterListSearchClearTooltip => 'Clear';

  @override
  String get characterListFilterButtonLabel => 'Filter characters';

  @override
  String get characterListFilterButtonActiveValue => 'Filter active';

  @override
  String get characterListSelectionModeButtonLabel =>
      'Select multiple characters';

  @override
  String get characterListCreateButton => '+ Create';

  @override
  String get characterListImportXmlButton => 'Import XML';

  @override
  String get characterListImportErrorMessage =>
      'Couldn\'t read this file. Make sure it\'s really an aidedd.org XML export.';

  @override
  String get characterListSearchEmptyTitleNoQuery => 'NO RESULTS';

  @override
  String characterListSearchEmptyTitleWithQuery(String query) {
    return 'NO RESULTS FOR “$query”';
  }

  @override
  String get characterListSearchEmptyBodyNoQuery =>
      'No character matches this filter. Reset it to see all your characters again.';

  @override
  String get characterListSearchEmptyBodyWithQuery =>
      'Check the spelling, or reset the search to see all your characters again.';

  @override
  String get characterListSearchEmptyResetButton => 'Reset';

  @override
  String get characterListEmptyTitle => 'NO ADVENTURERS YET';

  @override
  String get characterListEmptyBody =>
      'Create your first character, or import one from aidedd.org, to start the adventure.';

  @override
  String get characterListDeleteSelectionGenericError =>
      'Couldn\'t delete the selected characters. Try again.';

  @override
  String characterListDeleteSelectionSucceededLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count characters deleted',
      one: '1 character deleted',
    );
    return '$_temp0';
  }

  @override
  String characterListDeleteSelectionFailedLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count characters couldn\'t be deleted',
      one: '1 character couldn\'t be deleted',
    );
    return '$_temp0';
  }

  @override
  String get characterListFilterSheetTitle => 'FILTER';

  @override
  String get characterListFilterSheetStatusSection => 'STATUS';

  @override
  String get characterListFilterSheetClassSection => 'CLASS';

  @override
  String get characterListFilterSheetResetButton => 'Reset';

  @override
  String get characterListFilterSheetApplyButton => 'Apply';

  @override
  String get characterListFilterSheetStatusAlive => 'Alive';

  @override
  String get characterListFilterSheetStatusArchived => 'Archived';

  @override
  String get characterListFilterSheetStatusDead => 'Dead';

  @override
  String get characterCardArchivedBadge => 'ARCHIVED';

  @override
  String get characterCardDeadBadge => 'DEAD';

  @override
  String get characterCardXpLabel => 'XP';

  @override
  String get characterCardActionSheetEdit => 'Edit';

  @override
  String get characterCardActionSheetShare => 'Share';

  @override
  String get characterCardActionSheetArchive => 'Archive this character';

  @override
  String get characterCardActionSheetUnarchive => 'Unarchive';

  @override
  String get characterCardActionSheetMarkDead => 'Mark as dead';

  @override
  String get characterCardActionSheetRevive => 'Revive';

  @override
  String get characterCardActionSheetDelete => 'Delete character';

  @override
  String get characterCardActionSheetUpdateStatusGenericError =>
      'Couldn\'t update the status. Try again.';

  @override
  String get characterCardActionSheetDeleteGenericError =>
      'Couldn\'t delete the character. Try again.';

  @override
  String characterDeleteConfirmationSingleTitle(String characterName) {
    return 'Delete $characterName?';
  }

  @override
  String get characterDeleteConfirmationBody =>
      'This action is permanent: the character and all their data (spells, inventory, history...) will be permanently deleted.';

  @override
  String characterDeleteConfirmationMultipleTitle(int count) {
    return 'Delete these $count characters?';
  }

  @override
  String get characterDeleteConfirmationMultipleBody =>
      'This action is permanent: the characters and all their data (spells, inventory, history...) will be permanently deleted.';

  @override
  String get characterDeleteConfirmationCancelButton => 'Cancel';

  @override
  String get characterDeleteConfirmationConfirmButton => 'Delete';

  @override
  String characterDeleteConfirmationMultipleConfirmButton(int count) {
    return 'Delete ($count)';
  }

  @override
  String characterSelectionActionBarSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count characters selected',
      one: '1 character selected',
      zero: 'No character selected',
    );
    return '$_temp0';
  }

  @override
  String get characterSelectionActionBarCancelButton => 'Cancel';

  @override
  String get characterSelectionActionBarDeleteButton => 'Delete';

  @override
  String characterNameTagChipSemanticLabel(String name) {
    return '$name, view details';
  }

  @override
  String get connectionErrorStateBannerTitle => 'CONNECTION';

  @override
  String get connectionErrorStateTitle => 'Connection failed';

  @override
  String get connectionErrorStateBody =>
      'Check your internet connection and try again. Your characters remain available offline — changes will sync automatically once you\'re back online.';

  @override
  String get connectionErrorStateRetryButton => 'Retry';

  @override
  String get connectionErrorStateContinueOfflineLabel => 'Continue offline';

  @override
  String get connectionErrorStateContinueOfflineTooltip =>
      'Coming soon: offline reading of your characters is coming in an upcoming update. For now, a connection is required to load your characters.';
}
