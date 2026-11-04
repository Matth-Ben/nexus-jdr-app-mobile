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
  String get characterDetailTabCharacterLabel => 'CHAR.';

  @override
  String get characterDetailTabCharacterTitle => 'SHEET';

  @override
  String get characterDetailTabSkillsLabel => 'SKILLS';

  @override
  String get characterDetailTabSkillsTitle => 'SKILLS';

  @override
  String get characterDetailTabSpellsLabel => 'SPELLS';

  @override
  String get characterDetailTabSpellsTitle => 'SPELLS';

  @override
  String get characterDetailTabInventoryLabel => 'BAG';

  @override
  String get characterDetailTabInventoryTitle => 'INVENTORY';

  @override
  String get characterDetailTabStoryLabel => 'STORY';

  @override
  String get characterDetailTabStoryTitle => 'STORY';

  @override
  String get characterDetailHelpTooltip => 'Help';

  @override
  String get characterDetailMoreOptionsTooltip => 'More options';

  @override
  String get characterDetailSearchTooltip => 'Search';

  @override
  String get characterDetailFilterTooltip => 'Filter';

  @override
  String get characterDetailMenuExportXml => 'Export as XML';

  @override
  String get characterDetailLoadErrorMessage =>
      'Unable to load this character. Please try again.';

  @override
  String get characterDetailInitiativeLabel => 'Initiative';

  @override
  String get characterDetailHpUpdateErrorMessage =>
      'Unable to update HP. Please try again.';

  @override
  String get characterDetailHpSyncErrorMessage =>
      'Unable to sync HP. Please try again.';

  @override
  String characterDetailFeatureUseSuccessMessage(String featureName) {
    return '$featureName used.';
  }

  @override
  String get characterDetailFeatureUseErrorMessage =>
      'Unable to use this feature. Please try again.';

  @override
  String get characterDetailFeatureSyncErrorMessage =>
      'Unable to sync class features. Please try again.';

  @override
  String get characterDetailXpAddErrorMessage =>
      'Unable to add XP. Please try again.';

  @override
  String get characterDetailOfflineQueuedMessage =>
      'Offline: will sync once you\'re back online.';

  @override
  String get characterDetailArmorClassAdjustErrorMessage =>
      'Unable to adjust Armor Class. Please try again.';

  @override
  String get characterVitalsCardRestButton => 'Rest';

  @override
  String get characterVitalsCardHpLabel => 'HIT POINTS';

  @override
  String characterVitalsCardTemporaryHpChip(int amount) {
    return '+$amount temp. HP';
  }

  @override
  String get characterVitalsCardXpLabel => 'EXPERIENCE';

  @override
  String get characterVitalsCardAddXpButton => '+ XP';

  @override
  String characterVitalsCardLevelUpBanner(int targetLevel) {
    return 'LEVEL $targetLevel AVAILABLE';
  }

  @override
  String get characterStatPillsSpeedLabel => 'SPD.';

  @override
  String get characterStatPillsArmorClassLabel => 'AC';

  @override
  String get characterStatPillsInitiativeLabel => 'INIT.';

  @override
  String get characterStatPillsInspirationLabel => 'INSP.';

  @override
  String characterStatPillsSpeedValue(int speed) {
    return '$speed m';
  }

  @override
  String get characterAbilityAbbreviationStr => 'Str';

  @override
  String get characterAbilityAbbreviationDex => 'Dex';

  @override
  String get characterAbilityAbbreviationCon => 'Con';

  @override
  String get characterAbilityAbbreviationInt => 'Int';

  @override
  String get characterAbilityAbbreviationWis => 'Wis';

  @override
  String get characterAbilityAbbreviationCha => 'Cha';

  @override
  String get characterSavingThrowsCardTitle => 'SAVING THROWS';

  @override
  String get characterSkillsCardTitle => 'ALL 18 SKILLS';

  @override
  String get characterSkillsCardMasteredLegend => 'proficient';

  @override
  String get characterSkillsCardD20Chip => 'D20';

  @override
  String get characterAppearanceCardTitle => 'PHYSICAL APPEARANCE';

  @override
  String get characterAppearanceCardSexeLabel => 'Sex';

  @override
  String get characterAppearanceCardAgeLabel => 'Age';

  @override
  String get characterAppearanceCardHeightLabel => 'Height';

  @override
  String get characterAppearanceCardWeightLabel => 'Weight';

  @override
  String get characterAppearanceCardEyesLabel => 'Eyes';

  @override
  String get characterAppearanceCardSkinLabel => 'Skin';

  @override
  String get characterAppearanceCardHairLabel => 'Hair';

  @override
  String get characterSkillsTabBodySearchHint => 'Search for a skill';

  @override
  String characterSkillsTabBodyNoMatchMessage(String query) {
    return 'No skill matches “$query”.';
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

  @override
  String get hpAdjustmentSheetTitle => 'Adjust HP';

  @override
  String get hpAdjustmentSheetDamageOption => 'Damage';

  @override
  String get hpAdjustmentSheetHealOption => 'Healing';

  @override
  String get hpAdjustmentSheetTemporaryOption => 'Temp. HP';

  @override
  String get hpAdjustmentSheetCancelButton => 'Cancel';

  @override
  String get hpAdjustmentSheetApplyButton => 'Apply';

  @override
  String get addXpSheetTitle => 'Add XP';

  @override
  String addXpSheetCurrentXpLabel(int currentXp, int threshold) {
    return 'Current XP: $currentXp / $threshold';
  }

  @override
  String get addXpSheetGainedLabel => 'XP GAINED';

  @override
  String get addXpSheetAmountHint => 'E.g. 250';

  @override
  String get addXpSheetAmountHelper =>
      'Amount awarded by the GM at the end of a session, for example.';

  @override
  String addXpSheetNewTotalLabel(int total) {
    return 'New total: $total XP';
  }

  @override
  String get addXpSheetCancelButton => 'Cancel';

  @override
  String get addXpSheetApplyButton => 'Add';

  @override
  String get addXpSheetManualLevelUpLink => 'Level up manually';

  @override
  String get addRewardSheetTitle => 'ADD A REWARD';

  @override
  String get addRewardSheetCurrencyLabel => 'CURRENCY';

  @override
  String get addRewardSheetItemsLabel => 'ITEMS';

  @override
  String get addRewardSheetAddItemLabel => 'Add an item';

  @override
  String get addRewardSheetCancelButton => 'Cancel';

  @override
  String get addRewardSheetApplyButton => 'Add the reward';

  @override
  String addRewardSheetItemQuantityLabel(String name, int quantity) {
    return '$name × $quantity';
  }

  @override
  String get restSheetTitle => 'Rest';

  @override
  String restSheetCurrentHpLabel(int currentHp, int maxHp) {
    return 'Current HP: $currentHp / $maxHp';
  }

  @override
  String get restSheetShortOption => 'Short rest';

  @override
  String get restSheetLongOption => 'Long rest';

  @override
  String get restSheetCancelButton => 'Cancel';

  @override
  String get restSheetApplyButton => 'Apply';

  @override
  String get restSheetPreparedSpellsTitle => 'PREPARED SPELLS';

  @override
  String get restSheetKeepListOption => 'Keep my list';

  @override
  String get restSheetChangeSpellsOption => 'Change my spells';

  @override
  String get restSheetChangeSpellsHelper =>
      'After the rest, your spell list opens so you can choose which ones to prepare.';

  @override
  String get restSheetKeepListHelper =>
      'Your prepared spells stay the same after the rest.';

  @override
  String get restSheetLongHelpText =>
      'Restores HP to maximum, resets spell slots and recharges all rechargeable abilities (both short and long rest).';

  @override
  String restSheetAfterRestHpLabel(int maxHp) {
    return 'HP after rest: $maxHp / $maxHp';
  }

  @override
  String restSheetHitDiceAvailableLabel(int remaining, int total, int hitDie) {
    return 'Hit dice available: $remaining/$total (d$hitDie)';
  }

  @override
  String get restSheetDiceToSpendLabel => 'Dice to spend';

  @override
  String get restSheetNoHitDiceAvailable =>
      'No hit dice available. The short rest remains free — no further action required.';

  @override
  String get restSheetRollMethodOption => 'Roll the dice';

  @override
  String get restSheetAverageMethodOption => 'Average value';

  @override
  String get restSheetRerollLink => 'Reroll the dice';

  @override
  String get restSheetAverageFormulaHint =>
      '(half the die rounded up, +1, per die)';

  @override
  String get restSheetAlreadyMaxHpMessage =>
      'HP already at maximum: this rest won\'t restore any additional HP.';

  @override
  String get restSheetHpRestoredTitle => 'HP restored';

  @override
  String restSheetHpRestoredSubtitle(int currentHp, int newHp, int gain) {
    return '$currentHp → $newHp (+$gain)';
  }

  @override
  String restSheetPoolRolledLabel(String className, int hitDie) {
    return '$className (d$hitDie)';
  }

  @override
  String restSheetPoolStatusLabel(
    String className,
    int available,
    int total,
    int hitDie,
  ) {
    return '$className — hit dice available: $available/$total (d$hitDie)';
  }

  @override
  String restSheetRecoveredAllocationTitle(int count) {
    return 'Hit dice recovered: $count — distribute them among your classes';
  }

  @override
  String restSheetRecoveredPoolLabel(String className, int hitDie, int spent) {
    return '$className (d$hitDie) — $spent spent';
  }

  @override
  String restSheetRemainingToAllocateLabel(int remaining) {
    return 'Remaining to distribute: $remaining';
  }

  @override
  String diceRollSheetFormula(int roll, String modifier, int total) {
    return 'd20 ($roll) $modifier = $total';
  }

  @override
  String get diceRollSheetCriticalSuccess => 'CRITICAL SUCCESS';

  @override
  String get diceRollSheetCriticalFailure => 'CRITICAL FAILURE';

  @override
  String get diceRollSheetRerollButton => 'Reroll';

  @override
  String get armorClassBonusSheetTitle => 'AC Adjustment';

  @override
  String get armorClassBonusSheetBonusOption => 'Bonus';

  @override
  String get armorClassBonusSheetMalusOption => 'Penalty';

  @override
  String get armorClassBonusSheetClearButton => 'Clear';

  @override
  String get armorClassBonusSheetValidateButton => 'Confirm';

  @override
  String get levelUpScreenEyebrow => 'LEVEL UP';

  @override
  String get levelUpScreenLevelReachedEyebrow => 'LEVEL REACHED';

  @override
  String levelUpScreenLevelLabel(int level) {
    return 'LEVEL $level';
  }

  @override
  String levelUpScreenRemainingLevelsLabel(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: '$remaining more levels to validate next',
      one: '1 more level to validate next',
    );
    return '$_temp0';
  }

  @override
  String get levelUpScreenComingSoonSnackBar => 'Coming soon';

  @override
  String get levelUpScreenGenericApplyError =>
      'Couldn\'t save this level up. Please try again.';

  @override
  String get levelUpScreenGenericLoadError =>
      'Couldn\'t load level up data. Please try again.';

  @override
  String get levelUpScreenClassDecisionInstruction =>
      'Choose how this level applies.';

  @override
  String levelUpScreenContinueClassOptionTitle(String className) {
    return 'Continue as $className';
  }

  @override
  String get levelUpScreenContinueClassBlockedSubtitle =>
      'This level requires a choice not yet available in the app.';

  @override
  String levelUpScreenContinueClassSubtitle(int currentLevel, int nextLevel) {
    return 'You progress along your current path (level $currentLevel → $nextLevel).';
  }

  @override
  String levelUpScreenMulticlassOptionTitle(String className) {
    return 'Multiclass into $className';
  }

  @override
  String levelUpScreenMulticlassOptionSubtitle(String abilities) {
    return 'You start at level 1 in this class. Requirement met: $abilities.';
  }

  @override
  String levelUpScreenMulticlassInfoBanner(String className) {
    return 'New class: $className (level 1)';
  }

  @override
  String get levelUpScreenUpcomingStepsTitle => 'Coming up in the next steps';

  @override
  String levelUpScreenUpcomingChoiceStep(String choiceLabel) {
    return 'A $choiceLabel choice awaits you';
  }

  @override
  String get levelUpScreenUpcomingSpellsStep => 'Your spell slots will change';

  @override
  String get levelUpScreenUpcomingInvocationsStep =>
      'New invocations await you';

  @override
  String get levelUpScreenUpcomingElementalDisciplinesStep =>
      'New elemental disciplines await you';

  @override
  String get levelUpScreenUpcomingManeuversStep => 'New maneuvers await you';

  @override
  String get levelUpScreenUpcomingArcaneShotsStep =>
      'New arcane shots await you';

  @override
  String get levelUpScreenUpcomingRunesStep => 'New runes await you';

  @override
  String get levelUpScreenUpcomingInfusionsStep => 'Your infusions will evolve';

  @override
  String get levelUpScreenContinueButton => 'Continue';

  @override
  String get levelUpScreenBackButton => 'Back';

  @override
  String get levelUpScreenNewFeatureTitle => 'New feature';

  @override
  String get levelUpScreenNewProficiencyTitle => 'New proficiency';

  @override
  String levelUpScreenHpStepLabel(int totalSteps) {
    return 'Step 1 of $totalSteps · Hit points';
  }

  @override
  String get levelUpScreenMaxHpTitle => 'Maximum hit points';

  @override
  String levelUpScreenMaxHpDelta(int oldHp, int newHp, int gain) {
    return '$oldHp → $newHp (+$gain)';
  }

  @override
  String levelUpScreenHitDieMulticlassLabel(String className, int hitDie) {
    return 'Hit die of $className (level 1): d$hitDie';
  }

  @override
  String levelUpScreenHitDieClassLabel(int hitDie) {
    return 'Hit die of the class: d$hitDie';
  }

  @override
  String levelUpScreenRollHitDieOption(int hitDie) {
    return 'Roll the die (d$hitDie)';
  }

  @override
  String levelUpScreenAverageHitDieOption(int average) {
    return 'Average value ($average)';
  }

  @override
  String levelUpScreenConstitutionModifierLabel(String modifier) {
    return '$modifier Constitution modifier';
  }

  @override
  String get levelUpScreenRerollDieLink => 'Reroll the die';

  @override
  String get levelUpScreenAverageDieFormulaHint =>
      '(half the die rounded up, +1)';

  @override
  String get levelUpScreenLevelHistoryLink => 'View level history';

  @override
  String levelUpScreenAbilitiesStepLabel(int totalSteps) {
    return 'Step 2 of $totalSteps · Class features';
  }

  @override
  String levelUpScreenAbilitiesStepLabelWithProficiencies(int totalSteps) {
    return 'Step 2 of $totalSteps · Features & proficiencies';
  }

  @override
  String get levelUpScreenAutomaticFeaturesLabel => 'You automatically gain:';

  @override
  String get levelUpScreenMulticlassProficienciesLabel =>
      'Multiclass proficiencies:';

  @override
  String levelUpScreenChoiceStepLabel(int totalSteps, String choiceLabel) {
    return 'Step 3 of $totalSteps · $choiceLabel';
  }

  @override
  String get levelUpScreenChoiceKindAbilityScoreImprovement =>
      'Improvement or feat';

  @override
  String get levelUpScreenChoiceKindSubclass => 'Subclass';

  @override
  String get levelUpScreenChoiceKindFightingStyle => 'Fighting style';

  @override
  String get levelUpScreenChoiceKindFavoredEnemy => 'Favored enemy';

  @override
  String get levelUpScreenChoiceKindPact => 'Pact boon';

  @override
  String get levelUpScreenChooseSubclassInstruction => 'Choose a subclass.';

  @override
  String get levelUpScreenChooseFightingStyleInstruction =>
      'Choose a fighting style.';

  @override
  String get levelUpScreenChooseFavoredEnemyInstruction =>
      'Choose a favored enemy.';

  @override
  String get levelUpScreenChoosePactInstruction => 'Choose your Pact Boon.';

  @override
  String get levelUpScreenChooseProgressionInstruction =>
      'Choose how to progress.';

  @override
  String get levelUpScreenAllocateAbilityOption => 'Allocate +2';

  @override
  String get levelUpScreenChooseFeatOption => 'Choose a feat';

  @override
  String get levelUpScreenChooseFeatInstruction => 'Choose a feat.';

  @override
  String levelUpScreenFeatAbilityIncreaseLabel(String featName) {
    return 'Ability increased by $featName (+1):';
  }

  @override
  String levelUpScreenAllocateBudgetInstruction(int budget) {
    return 'Allocate $budget points among your abilities.';
  }

  @override
  String levelUpScreenPointsRemainingLabel(int remaining, int budget) {
    return 'Points remaining: $remaining/$budget';
  }

  @override
  String get levelUpScreenAllPointsAllocatedLabel =>
      'All points have been allocated.';

  @override
  String levelUpScreenAbilityScoreDelta(int oldScore, int newScore, int alloc) {
    return '$oldScore → $newScore (+$alloc)';
  }

  @override
  String levelUpScreenSpellSlotsStepLabel(int stepNumber, int totalSteps) {
    return 'Step $stepNumber of $totalSteps · Spell slots';
  }

  @override
  String get levelUpScreenSpellSlotsRecalculatedLabel =>
      'Your spell slots are recalculated:';

  @override
  String get levelUpScreenNoSpellSlotsAtThisLevel =>
      'No spell slots at this level.';

  @override
  String levelUpScreenSpellsStepLabel(int stepNumber, int totalSteps) {
    return 'Step $stepNumber of $totalSteps · Spells';
  }

  @override
  String get levelUpScreenCantripTab => 'Cantrips';

  @override
  String get levelUpScreenSpellsTab => 'Spells';

  @override
  String get levelUpScreenPactTab => 'Grimoire';

  @override
  String get levelUpScreenKnownCantripsTitle => 'KNOWN CANTRIPS';

  @override
  String get levelUpScreenShadowBookTitle => 'BOOK OF SHADOWS';

  @override
  String get levelUpScreenKnownSpellsTitle => 'NEW KNOWN SPELLS';

  @override
  String levelUpScreenQuotaBadge(int selected, int quota) {
    return '$selected / $quota';
  }

  @override
  String levelUpScreenSpellMetaLineWithLevel(String metaLine, int level) {
    return '$metaLine (level $level)';
  }

  @override
  String levelUpScreenPatronSpellSubtitle(String baseSubtitle) {
    return '$baseSubtitle · Patron';
  }

  @override
  String levelUpScreenInvocationsStepLabel(int stepNumber, int totalSteps) {
    return 'Step $stepNumber of $totalSteps · Invocations';
  }

  @override
  String get levelUpScreenKnownInvocationsTitle => 'KNOWN INVOCATIONS';

  @override
  String get levelUpScreenNoMoreInvocationsMessage =>
      'You already know all the available eldritch invocations.';

  @override
  String levelUpScreenElementalDisciplinesStepLabel(
    int stepNumber,
    int totalSteps,
  ) {
    return 'Step $stepNumber of $totalSteps · Elemental disciplines';
  }

  @override
  String get levelUpScreenKnownElementalDisciplinesTitle =>
      'KNOWN ELEMENTAL DISCIPLINES';

  @override
  String get levelUpScreenNoMoreElementalDisciplinesMessage =>
      'You already know all the elemental disciplines available at this level.';

  @override
  String levelUpScreenManeuversStepLabel(int stepNumber, int totalSteps) {
    return 'Step $stepNumber of $totalSteps · Maneuvers';
  }

  @override
  String get levelUpScreenKnownManeuversTitle => 'KNOWN MANEUVERS';

  @override
  String get levelUpScreenNoMoreManeuversMessage =>
      'You already know all the available maneuvers.';

  @override
  String levelUpScreenArcaneShotsStepLabel(int stepNumber, int totalSteps) {
    return 'Step $stepNumber of $totalSteps · Arcane shots';
  }

  @override
  String get levelUpScreenKnownArcaneShotsTitle => 'KNOWN ARCANE SHOTS';

  @override
  String get levelUpScreenNoMoreArcaneShotsMessage =>
      'You already know all the available arcane shots.';

  @override
  String levelUpScreenRunesStepLabel(int stepNumber, int totalSteps) {
    return 'Step $stepNumber of $totalSteps · Runes';
  }

  @override
  String get levelUpScreenKnownRunesTitle => 'KNOWN RUNES';

  @override
  String get levelUpScreenNoMoreRunesMessage =>
      'You already know all the available runes.';

  @override
  String levelUpScreenInfusionsStepLabel(int stepNumber, int totalSteps) {
    return 'Step $stepNumber of $totalSteps · Infusions';
  }

  @override
  String get levelUpScreenNewInfusionsTitle => 'NEW INFUSIONS';

  @override
  String get levelUpScreenNoMoreInfusionsMessage =>
      'You already know all the available infusions.';

  @override
  String get levelUpScreenReplaceInfusionOptionalTitle =>
      'REPLACE AN INFUSION (OPTIONAL)';

  @override
  String get levelUpScreenReplacedByLabel => 'REPLACED BY';

  @override
  String levelUpScreenMetamagicStepLabel(int stepNumber, int totalSteps) {
    return 'Step $stepNumber of $totalSteps · Metamagic';
  }

  @override
  String get levelUpScreenNewMetamagicOptionsTitle => 'NEW METAMAGIC OPTIONS';

  @override
  String get levelUpScreenNoMoreMetamagicMessage =>
      'You already know all the available Metamagic options.';

  @override
  String get levelUpScreenReplaceMetamagicOptionalTitle =>
      'REPLACE AN OPTION (OPTIONAL)';

  @override
  String levelUpScreenExpertiseStepLabel(int stepNumber, int totalSteps) {
    return 'Step $stepNumber of $totalSteps · Expertise';
  }

  @override
  String get levelUpScreenExpertiseSkillsTitle => 'EXPERTISE SKILLS';

  @override
  String get levelUpScreenThievesToolsLabel => 'Thieves\' tools';

  @override
  String get levelUpScreenThievesToolsSubstitutionHint =>
      'Substitutes one of your Expertise slots for proficiency with thieves\' tools.';

  @override
  String get levelUpScreenNoExpertiseCandidatesMessage =>
      'No already-proficient skill to upgrade to Expertise.';

  @override
  String levelUpScreenDraconicAncestryStepLabel(
    int stepNumber,
    int totalSteps,
  ) {
    return 'Step $stepNumber of $totalSteps · Draconic ancestry';
  }

  @override
  String get levelUpScreenDamageTypeTitle => 'DAMAGE TYPE';

  @override
  String get levelUpScreenNewSpellSlotsTitle => 'New spell slots';

  @override
  String get levelUpScreenReinforcedSpellSlotsTitle => 'Reinforced spell slots';

  @override
  String levelUpScreenSpellSlotUnlockedSubtitle(int spellLevel) {
    return 'Level $spellLevel unlocked';
  }

  @override
  String levelUpScreenSpellSlotReinforcedSubtitle(
    int spellLevel,
    int oldTotal,
    int newTotal,
    int delta,
  ) {
    return 'Level $spellLevel: $oldTotal → $newTotal (+$delta)';
  }

  @override
  String get levelUpScreenPactMagicUnlockedTitle => 'Pact magic unlocked';

  @override
  String levelUpScreenPactMagicUnlockedSubtitle(int slotLevel, int charges) {
    return 'Level $slotLevel · $charges charge(s)';
  }

  @override
  String get levelUpScreenPactChargesReinforcedTitle =>
      'Pact charges reinforced';

  @override
  String levelUpScreenPactChargesReinforcedSubtitle(
    int oldCharges,
    int newCharges,
    int slotLevel,
  ) {
    return '$oldCharges → $newCharges charges (level $slotLevel)';
  }

  @override
  String get levelUpScreenPactChargesImprovedTitle => 'Pact charges improved';

  @override
  String levelUpScreenPactChargesImprovedSubtitle(
    int oldSlotLevel,
    int newSlotLevel,
    int newCharges,
  ) {
    return 'Level $oldSlotLevel → $newSlotLevel ($newCharges charges)';
  }

  @override
  String levelUpScreenPactChargesBothSubtitle(
    int oldCharges,
    int newCharges,
    int oldSlotLevel,
    int newSlotLevel,
  ) {
    return '$oldCharges → $newCharges charges, level $oldSlotLevel → $newSlotLevel';
  }

  @override
  String get levelUpScreenFeatSummaryTitle => 'Feat';

  @override
  String levelUpScreenFeatAbilityBonusSubtitle(
    String featName,
    String abilityLabel,
  ) {
    return '$featName ($abilityLabel +1)';
  }

  @override
  String levelUpScreenAbilityAllocationSummaryItem(String label, int amount) {
    return '$label +$amount';
  }

  @override
  String get levelUpScreenAbilityScoreImprovementTitle =>
      'Ability score improvement';

  @override
  String get levelUpScreenNewCantripsTitle => 'New cantrips';

  @override
  String get levelUpScreenNewSpellsLearnedTitle => 'New spells learned';

  @override
  String get levelUpScreenShadowBookGainTitle => 'Book of Shadows';

  @override
  String get levelUpScreenFamiliarAddedTitle => 'Find Familiar added';

  @override
  String get levelUpScreenChainPactSubtitle => 'Pact of the Chain';

  @override
  String get levelUpScreenRacialInnateSpellTitle => 'Racial innate spell';

  @override
  String levelUpScreenNewInvocationsSummaryTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'New eldritch invocations',
      one: 'New eldritch invocation',
    );
    return '$_temp0';
  }

  @override
  String levelUpScreenNewElementalDisciplinesSummaryTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'New elemental disciplines',
      one: 'New elemental discipline',
    );
    return '$_temp0';
  }

  @override
  String levelUpScreenNewManeuversSummaryTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'New maneuvers',
      one: 'New maneuver',
    );
    return '$_temp0';
  }

  @override
  String levelUpScreenNewArcaneShotsSummaryTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'New arcane shots',
      one: 'New arcane shot',
    );
    return '$_temp0';
  }

  @override
  String levelUpScreenNewRunesSummaryTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'New runes',
      one: 'New rune',
    );
    return '$_temp0';
  }

  @override
  String levelUpScreenNewInfusionsSummaryTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'New infusions',
      one: 'New infusion',
    );
    return '$_temp0';
  }

  @override
  String get levelUpScreenInfusionSwapTitle => 'Infusion replaced';

  @override
  String levelUpScreenSwapSubtitle(String removedName, String addedName) {
    return '$removedName → $addedName';
  }

  @override
  String levelUpScreenNewMetamagicOptionsSummaryTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'New Metamagic options',
      one: 'New Metamagic option',
    );
    return '$_temp0';
  }

  @override
  String get levelUpScreenMetamagicSwapTitle => 'Metamagic replaced';

  @override
  String levelUpScreenExpertiseSummaryTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Expertise',
      one: 'Expertise',
    );
    return '$_temp0';
  }

  @override
  String get levelUpScreenDraconicAncestryTitle => 'Draconic ancestry';

  @override
  String get levelUpScreenNoNewFeaturesMessage =>
      'No new class feature at this level.';

  @override
  String get levelUpScreenNoOptionAvailableMessage =>
      'No option available for this choice.';

  @override
  String levelUpScreenBlockedLevelTitle(int level) {
    return 'Level $level: choice required';
  }

  @override
  String get levelUpScreenBackToSheetButton => 'Back to the sheet';

  @override
  String get levelUpScreenRetryButton => 'Retry';

  @override
  String get characterClassChoicesCardTitle => 'CLASS CHOICES';

  @override
  String get characterClassChoicesCardSubclassLabel => 'Subclass';

  @override
  String characterClassChoicesCardSubclassLabelWithClass(String className) {
    return 'Subclass ($className)';
  }

  @override
  String get characterClassFeaturesCardTitle => 'CLASS FEATURES';

  @override
  String get characterClassFeaturesCardPassiveLabel => 'Passive';

  @override
  String get characterFeatsCardTitle => 'FEATS';

  @override
  String get characterRacialTraitsCardTitle => 'RACIAL TRAITS';

  @override
  String get characterRacialTraitsCardPassiveLabel => 'Passive';

  @override
  String get characterRaceChoicesCardTitle => 'RACE CHOICES';

  @override
  String get characterRaceChoicesCardSkillLabel => 'Skill';

  @override
  String get characterRaceChoicesCardToolLabel => 'Tool';

  @override
  String get characterArmorProficienciesCardTitle => 'ARMOR PROFICIENCIES';

  @override
  String get characterWeaponProficienciesCardTitle => 'WEAPON PROFICIENCIES';

  @override
  String get characterToolProficienciesCardTitle => 'TOOL PROFICIENCIES';

  @override
  String get characterLanguagesCardTitle => 'KNOWN LANGUAGES';

  @override
  String get characterInvocationsCardTitle => 'KNOWN INVOCATIONS';

  @override
  String get characterPactWeaponCardTitle => 'PACT WEAPON';

  @override
  String get characterPactWeaponCardCursedBladeText =>
      'Hexblade: you can use your Charisma instead of Strength or Dexterity for the attack and damage rolls.';

  @override
  String get characterPactWeaponCardReminderText =>
      'Summoned as an action. Disappears if it is more than 5 feet away from you for 1 minute, or if you summon it again.';

  @override
  String get characterPactWeaponCardMagicWeaponChip => 'Magic weapon';

  @override
  String get characterPactWeaponCardProficientChip => 'Proficient';

  @override
  String get characterPactWeaponCardEmptyTitle => 'No form chosen';

  @override
  String get characterPactWeaponCardEmptyDescription =>
      'Choose the form your weapon takes when you summon it.';

  @override
  String get characterPactWeaponCardChooseFormButton => 'Choose a form';

  @override
  String get characterPactWeaponCardChangeFormButton => 'Change form';

  @override
  String characterPactWeaponCardSemanticLabel(String name) {
    return 'Pact weapon: $name';
  }

  @override
  String characterPactWeaponCardSemanticLabelWithDamage(
    String name,
    String damage,
  ) {
    return 'Pact weapon: $name, $damage';
  }

  @override
  String get classFeatureActionSheetInfoLabel => 'Info';

  @override
  String get classFeatureActionSheetUseLabel => 'Use';

  @override
  String get classFeatureActionSheetExhaustedLabel => 'Exhausted';

  @override
  String classFeatureInfoPanelObtainedAtLevel(int level) {
    return 'Obtained at level $level.';
  }

  @override
  String get classFeatureInfoPanelUsesLabel => 'Uses';

  @override
  String get classFeatureInfoPanelPassiveLabel => 'Passive';

  @override
  String get classFeatureInfoPanelDescriptionLabel => 'DESCRIPTION';

  @override
  String get classFeatureInfoPanelDescriptionUnavailable =>
      'Description unavailable.';

  @override
  String get classFeatureInfoPanelUseButton => 'Use';

  @override
  String featInfoPanelPrerequisiteLabel(String prerequisite) {
    return 'Prerequisite: $prerequisite';
  }

  @override
  String get featInfoPanelDescriptionLabel => 'DESCRIPTION';

  @override
  String get racialTraitInfoPanelDescriptionLabel => 'DESCRIPTION';

  @override
  String get racialTraitInfoPanelDescriptionUnavailable =>
      'Description unavailable.';

  @override
  String get proficiencyDetailPanelLoadErrorMessage =>
      'Unable to load the catalog. Please try again.';

  @override
  String get proficiencyDetailPanelNoNonMetallicShieldMessage =>
      'No non-metal shield available in the current catalog.';

  @override
  String get proficiencyDetailPanelNoMatchingItemMessage =>
      'No matching item available in the current catalog.';

  @override
  String get proficiencyDetailPanelPropertiesLabel => 'Properties: ';

  @override
  String get proficiencyDetailPanelAcLabel => 'AC';

  @override
  String get proficiencyDetailPanelAcBaseLabel => 'Base AC';

  @override
  String get proficiencyDetailPanelDexBonusLabel => 'Dex bonus';

  @override
  String get proficiencyDetailPanelStrengthRequirementLabel =>
      'Strength requirement';

  @override
  String get proficiencyDetailPanelStealthDisadvantageLabel =>
      'Stealth disadvantage';

  @override
  String get proficiencyDetailPanelYesLabel => 'Yes';

  @override
  String get pactWeaponPickerSheetTitle => 'WEAPON FORM';

  @override
  String get pactWeaponPickerSheetSearchHint => 'Search for a weapon...';

  @override
  String get pactWeaponPickerSheetLoadErrorMessage =>
      'Unable to load the weapons. Please try again.';

  @override
  String get pactWeaponPickerSheetEmptyMessage => 'No weapon available.';

  @override
  String get pactWeaponPickerSheetNoResultsMessage => 'No weapon found.';

  @override
  String get weaponSlotPickerSheetTitle => 'CHOOSE A SET';

  @override
  String get weaponSlotPickerSheetEmptyLabel => 'Empty';

  @override
  String characterInventoryTabBodyFilterButtonLabel(String filterLabel) {
    return 'Filter: $filterLabel';
  }

  @override
  String get characterInventoryTabBodyAddItemButtonLabel => 'Item';

  @override
  String get characterInventoryTabBodyRewardButtonLabel => 'REWARD';

  @override
  String get characterInventoryTabBodyNoFilterMatchMessage =>
      'No item in this category.';

  @override
  String get characterInventoryTabBodyEmptyTitle => 'EMPTY INVENTORY';

  @override
  String get characterInventoryTabBodyEmptyMessage =>
      'No item in this inventory yet.';

  @override
  String characterInventoryItemCardSubtitle(String category, int quantity) {
    return '$category · x$quantity';
  }

  @override
  String get characterInventoryItemCardEquippedBadge => 'EQUIPPED';

  @override
  String characterInventoryItemCardWeightValue(String weight) {
    return '$weight kg';
  }

  @override
  String get characterInventoryCapacityGaugeTitle => 'LOAD';

  @override
  String characterInventoryCapacityGaugeValueLabel(
    String weight,
    String capacity,
  ) {
    return '$weight / $capacity kg';
  }

  @override
  String get characterInventoryCapacityGaugeOverloadedWarning =>
      'Overloaded — weight exceeds carrying capacity.';

  @override
  String characterInventoryCapacityGaugeSemanticsLabel(
    String weight,
    String capacity,
  ) {
    return 'Load: $weight kilograms out of $capacity kilograms';
  }

  @override
  String characterInventoryCapacityGaugeSemanticsLabelOverloaded(
    String weight,
    String capacity,
  ) {
    return 'Load: $weight kilograms out of $capacity kilograms, overloaded';
  }

  @override
  String get characterEquippedWeaponsCardTitle => 'EQUIPPED WEAPONS';

  @override
  String get characterEquippedWeaponsCardPrimarySetTitle => 'PRIMARY SET';

  @override
  String get characterEquippedWeaponsCardSecondarySetTitle => 'SECONDARY SET';

  @override
  String get characterEquippedWeaponsCardEmptySetMessage =>
      'No weapon in this set.';

  @override
  String get characterEquippedWeaponsCardAttackLabel => 'Attack';

  @override
  String get characterEquippedWeaponsCardEmptyTitle => 'No weapon equipped';

  @override
  String get characterEquippedWeaponsCardEmptyDescription =>
      'Equip a weapon from the Inventory tab for it to appear here.';

  @override
  String characterEquippedWeaponsCardSemanticsLabel(String name) {
    return 'Equipped weapon: $name';
  }

  @override
  String characterEquippedWeaponsCardSemanticsAttackSuffix(String attackBonus) {
    return ', Attack: $attackBonus';
  }

  @override
  String characterEquippedWeaponsCardSemanticsRangeSuffix(String range) {
    return ', Range: $range';
  }

  @override
  String characterEquippedWeaponsCardRangeValue(String rangeNormal) {
    return '$rangeNormal m';
  }

  @override
  String characterEquippedWeaponsCardRangeValueWithMax(
    String rangeNormal,
    String rangeMax,
  ) {
    return '$rangeNormal m (max $rangeMax m)';
  }

  @override
  String get addItemFlowCatalogEntryLabel => 'From the catalog';

  @override
  String get addItemFlowCustomEntryLabel => 'Custom item';

  @override
  String get addItemFlowCatalogTitleSingle => 'ADD AN ITEM';

  @override
  String get addItemFlowCatalogTitleMulti => 'ADD ITEMS';

  @override
  String get addItemFlowSearchHint => 'Search for an item...';

  @override
  String get addItemFlowCatalogLoadErrorMessage =>
      'Unable to load the item catalog. Please try again.';

  @override
  String get addItemFlowAddButtonLabel => 'Add';

  @override
  String addItemFlowAddButtonLabelWithCount(int count) {
    return 'Add ($count)';
  }

  @override
  String get addItemFlowNoResultsMessage => 'No item found.';

  @override
  String addItemFlowCatalogItemSubtitleWithWeight(String cost, String weight) {
    return '$cost po · $weight kg';
  }

  @override
  String addItemFlowCatalogItemSubtitleNoWeight(String cost) {
    return '$cost po';
  }

  @override
  String addItemFlowQuantitySheetTitle(String itemName) {
    return 'Add $itemName';
  }

  @override
  String get addItemFlowQuantitySheetAddButton => 'Add';

  @override
  String get addItemFlowCustomSheetTitle => 'CUSTOM ITEM';

  @override
  String get addItemFlowCustomNameSectionLabel => 'ITEM NAME';

  @override
  String get addItemFlowCustomNameHint => 'E.g. Family amulet';

  @override
  String get addItemFlowCustomDescriptionSectionLabel => 'DESCRIPTION';

  @override
  String get addItemFlowCustomDescriptionHint =>
      'E.g. A medallion engraved with your family\'s arms.';

  @override
  String get addItemFlowCustomTypeSectionLabel => 'ITEM TYPE';

  @override
  String get addItemFlowCustomTypeSimpleOption => 'Simple item';

  @override
  String get addItemFlowCustomTypeWeaponOption => 'Weapon';

  @override
  String get addItemFlowCustomDiceSectionLabel => 'DAMAGE DIE';

  @override
  String get addItemFlowCustomDiceNotationSeparator => 'd';

  @override
  String get addItemFlowCustomDamageTypeSectionLabel => 'DAMAGE TYPE';

  @override
  String get addItemFlowCustomDamageTypeHint => 'Select';

  @override
  String get addItemFlowDamageTypeSlashingLabel => 'Slashing';

  @override
  String get addItemFlowDamageTypePiercingLabel => 'Piercing';

  @override
  String get addItemFlowDamageTypeBludgeoningLabel => 'Bludgeoning';

  @override
  String get addItemFlowCustomPropertiesSectionLabel => 'PROPERTIES';

  @override
  String get addItemFlowCustomPropertiesHint => 'E.g. light, finesse';

  @override
  String get addItemFlowCustomPropertiesCaption =>
      'Separate multiple properties with a comma.';

  @override
  String get addItemFlowCustomQuantitySectionLabel => 'QUANTITY';

  @override
  String get addItemFlowCustomCancelButton => 'Cancel';

  @override
  String get addItemFlowCustomAddButton => 'Add';

  @override
  String get itemActionSheetInfoLabel => 'Info';

  @override
  String get itemActionSheetUseLabel => 'Use';

  @override
  String get itemActionSheetEquipLabel => 'Equip';

  @override
  String get itemActionSheetChangeSetLabel => 'Change set';

  @override
  String get itemActionSheetUnequipLabel => 'Unequip';

  @override
  String get itemActionSheetAttuneLabel => 'Attune to this item';

  @override
  String get itemActionSheetStopAttuneLabel => 'Stop attuning';

  @override
  String itemActionSheetAttunementCapReachedLabel(int cap) {
    return 'Limit ($cap) reached';
  }

  @override
  String get itemActionSheetRemoveLabel => 'Remove';

  @override
  String itemActionSheetSubtitle(String category, int quantity) {
    return '$category · x$quantity';
  }

  @override
  String itemActionSheetRemoveConfirmationTitle(String itemName) {
    return 'Remove $itemName?';
  }

  @override
  String get itemActionSheetRemoveConfirmationBody =>
      'This action is permanent.';

  @override
  String get itemActionSheetRemoveConfirmationCancelButton => 'Cancel';

  @override
  String get itemActionSheetRemoveConfirmationConfirmButton => 'Remove';

  @override
  String get itemInfoPanelWeightLabel => 'Unit weight';

  @override
  String itemInfoPanelWeightValue(String weight) {
    return '$weight kg';
  }

  @override
  String get itemInfoPanelCostLabel => 'Cost';

  @override
  String itemInfoPanelCostValue(String cost) {
    return '$cost po';
  }

  @override
  String get itemInfoPanelSetLabel => 'Set';

  @override
  String get itemInfoPanelAttackLabel => 'Attack';

  @override
  String get itemInfoPanelDamageLabel => 'Damage';

  @override
  String get itemInfoPanelPropertiesLabel => 'Properties';

  @override
  String get itemInfoPanelRangeLabel => 'Range';

  @override
  String itemInfoPanelRangeValue(String rangeNormal) {
    return '$rangeNormal m';
  }

  @override
  String itemInfoPanelRangeValueWithMax(String rangeNormal, String rangeMax) {
    return '$rangeNormal m (max $rangeMax m)';
  }

  @override
  String get itemInfoPanelArmorClassLabel => 'Base AC';

  @override
  String get itemInfoPanelDexBonusLabel => 'Dex bonus';

  @override
  String get itemInfoPanelStrengthRequirementLabel => 'Strength requirement';

  @override
  String get itemInfoPanelStealthDisadvantageLabel => 'Stealth disadvantage';

  @override
  String get itemInfoPanelYesLabel => 'Yes';

  @override
  String get itemInfoPanelNoLabel => 'No';

  @override
  String get itemInfoPanelRarityLabel => 'Rarity';

  @override
  String get itemInfoPanelDescriptionSectionLabel => 'DESCRIPTION';

  @override
  String get itemInfoPanelDescriptionUnavailable => 'No description available.';

  @override
  String get itemInfoPanelUseButton => 'Use';

  @override
  String get itemInfoPanelEquipButton => 'Equip';

  @override
  String get itemInfoPanelUnequipButton => 'Unequip';

  @override
  String get itemInfoPanelAttuneLabel => 'Attune to this item';

  @override
  String get itemInfoPanelStopAttuneLabel => 'Stop attuning';

  @override
  String itemInfoPanelAttunementCapReachedCaption(int cap) {
    String _temp0 = intl.Intl.pluralLogic(
      cap,
      locale: localeName,
      other: 'Limit of $cap attuned items reached.',
      one: 'Limit of 1 attuned item reached.',
    );
    return '$_temp0';
  }

  @override
  String currencyAdjustmentSheetTitle(String currencyLabel) {
    return 'Adjust $currencyLabel';
  }

  @override
  String get currencyAdjustmentSheetAddOption => 'Add';

  @override
  String get currencyAdjustmentSheetRemoveOption => 'Remove';

  @override
  String get currencyAdjustmentSheetCancelButton => 'Cancel';

  @override
  String get currencyAdjustmentSheetApplyButton => 'Apply';

  @override
  String get inventoryCategoryFilterSheetTitle => 'FILTER BY CATEGORY';

  @override
  String get characterSpellsSectionTitle => 'SPELLS';

  @override
  String characterSpellsSectionPactLabel(int level) {
    return 'Pact magic — Level $level';
  }

  @override
  String characterSpellsSectionPactSlotsSemanticLabel(
    int remaining,
    int total,
    int level,
  ) {
    return 'Pact slots: $remaining remaining out of $total (level $level)';
  }

  @override
  String characterSpellsSectionSlotsSemanticLabel(int remaining, int total) {
    return 'Spell slots: $remaining remaining out of $total';
  }

  @override
  String characterSpellsSectionGrantBadgeSemanticLabel(String sourceLabel) {
    return 'Always prepared, granted by: $sourceLabel';
  }

  @override
  String get characterSpellsSectionInnateBadgeLabel => 'INNATE';

  @override
  String get characterSpellsSectionInnateExhaustedLabel => 'Spent';

  @override
  String characterSpellsSectionInnateAvailableSemanticLabel(
    int remaining,
    int max,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: '$remaining uses remaining',
      one: '1 use remaining',
    );
    return 'Innate spell, no slot required, $_temp0 out of $max, long rest';
  }

  @override
  String get characterSpellsSectionInnateExhaustedSemanticLabel =>
      'Innate spell, spent, available after a long rest';

  @override
  String get characterSpellsTabBodyLimitedUseFeaturesCardTitle =>
      'INVOCATIONS & LIMITED-USE FEATURES';

  @override
  String get characterSpellsTabBodySearchHint => 'Search for a spell';

  @override
  String get characterSpellsTabBodySearchClearTooltip => 'Clear';

  @override
  String get characterSpellsTabBodyNoMatchAllLabel => 'No spell';

  @override
  String get characterSpellsTabBodyNoMatchPreparedLabel => 'No prepared spell';

  @override
  String get characterSpellsTabBodyNoMatchUnpreparedLabel =>
      'No unprepared spell';

  @override
  String characterSpellsTabBodyNoMatchMessageEmpty(String kind) {
    return '$kind.';
  }

  @override
  String characterSpellsTabBodyNoMatchMessageQuery(String kind, String query) {
    return '$kind for “$query”.';
  }

  @override
  String get characterSpellsTabBodyEmptyStateTitle => 'NO SPELLS';

  @override
  String get characterSpellsTabBodyEmptyStateBody =>
      'No spell on this sheet yet. For classes that cast spells, they\'re chosen from the creation wizard or when leveling up.';

  @override
  String get characterSpellsTabBodyNonCasterTitle =>
      'This class doesn\'t cast spells';

  @override
  String get characterSpellsTabBodyNonCasterDefaultClassName => 'this class';

  @override
  String characterSpellsTabBodyNonCasterBody(
    String characterName,
    String className,
  ) {
    return '$characterName is $className — outside a dedicated archetype (e.g. Eldritch Knight), this class has no spell slots. This tab stays accessible for navigation consistency, but will remain empty for this character.';
  }

  @override
  String spellActionSheetTitle(String spellName) {
    return 'Cast $spellName';
  }

  @override
  String get spellActionSheetSubtitle => 'Choose the slot level to use.';

  @override
  String get spellActionSheetCancelButton => 'Cancel';

  @override
  String get spellActionSheetCastButton => 'Cast';

  @override
  String get spellActionSheetSlotExhaustedLabel => 'Spent';

  @override
  String spellActionSheetSlotRemainingLabel(int remaining, int total) {
    return '$remaining/$total remaining';
  }

  @override
  String spellActionSheetPactSlotLevelLabel(int level) {
    return 'Level $level (pact)';
  }

  @override
  String spellActionSheetSlotLevelLabel(int level) {
    return 'Level $level';
  }

  @override
  String get spellInfoPanelUsagesLabel => 'Uses';

  @override
  String get spellInfoPanelCastingTimeLabel => 'Casting time';

  @override
  String get spellInfoPanelRangeLabel => 'Range';

  @override
  String get spellInfoPanelDurationLabel => 'Duration';

  @override
  String get spellInfoPanelConcentrationLabel => 'Concentration';

  @override
  String get spellInfoPanelConcentrationYes => 'Yes';

  @override
  String get spellInfoPanelConcentrationNo => 'No';

  @override
  String spellInfoPanelGrantSourceNote(String sourceLabel) {
    return 'Always prepared — $sourceLabel spell (doesn\'t count toward the prepared spells limit)';
  }

  @override
  String spellInfoPanelInnateNote(int usesPerLongRest) {
    return 'Innate spell — cast without a slot, $usesPerLongRest time(s) per long rest';
  }

  @override
  String get spellInfoPanelDescriptionTitle => 'DESCRIPTION';

  @override
  String get spellInfoPanelCastButton => 'Cast';

  @override
  String get spellInfoPanelCastInnateButton => 'Cast (innate spell)';

  @override
  String get spellInfoPanelUnprepareLink => 'Stop preparing';

  @override
  String get spellInfoPanelPrepareLink => 'Prepare this spell';

  @override
  String get spellInfoPanelComponentsLabel => 'Components';

  @override
  String get spellPreparationCardTitle => 'SPELL PREPARATION';

  @override
  String get spellPreparationCardInfoTooltip =>
      'How does spell preparation work?';

  @override
  String spellPreparationCardClassLabel(String className) {
    return 'PREPARED SPELLS — $className';
  }

  @override
  String get spellPreparationCardDefaultLabel => 'PREPARED SPELLS';

  @override
  String spellPreparationCardOverLimitStatus(int overBy) {
    return 'Limit exceeded by $overBy';
  }

  @override
  String get spellPreparationCardLimitReachedStatus => 'Limit reached';

  @override
  String spellPreparationCardRemainingToPrepareStatus(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: '$remaining more spells to prepare',
      one: '1 more spell to prepare',
    );
    return '$_temp0';
  }

  @override
  String spellPreparationCardCounterSemanticLabel(
    String label,
    int count,
    int limit,
  ) {
    return '$label: $count out of $limit';
  }

  @override
  String get spellPreparationCardCounterOverLimitSuffix => ', limit exceeded';

  @override
  String get spellPreparationCardInfoEntryPrepareTitle => 'Prepare to cast';

  @override
  String get spellPreparationCardInfoEntryPrepareBody =>
      'Only prepared spells can be cast. Unprepared spells stay in the list, greyed out, after the prepared spells. Tap a spell, then “Prepare this spell” or “Stop preparing”.';

  @override
  String get spellPreparationCardInfoEntryHowManyTitle => 'How many spells?';

  @override
  String spellPreparationCardInfoEntryHowManyBody(String limitsSentence) {
    return 'Cleric, Druid and Wizard: spellcasting ability modifier + class level. Paladin and Artificer (half-casters): modifier + half the level. Minimum 1. Multiclassed with several classes that prepare: each class has its own limit, never a shared total.$limitsSentence Once the limit is reached, you can\'t prepare a new spell of that class without unpreparing another one first.';
  }

  @override
  String spellPreparationCardSingleLimitSentence(int limit) {
    return ' Your current limit: $limit.';
  }

  @override
  String spellPreparationCardMultipleLimitsSentence(String limitsList) {
    return ' Your current limits: $limitsList.';
  }

  @override
  String get spellPreparationCardInfoEntryNoPreparationTitle =>
      'No preparation needed';

  @override
  String get spellPreparationCardInfoEntryNoPreparationBody =>
      'Cantrips, innate spells, and domain or oath spells never need to be prepared and don\'t count toward the limit. An innate spell of level 1 or higher is cast without a slot, once per long rest.';

  @override
  String get spellPreparationCardInfoEntryCastDoesNotUnprepareTitle =>
      'Casting doesn\'t unprepare';

  @override
  String get spellPreparationCardInfoEntryCastDoesNotUnprepareBody =>
      'Casting a spell uses up a slot, but the spell stays prepared: you can cast it again as long as you have slots left.';

  @override
  String get spellPreparationCardInfoEntryChangeListTitle =>
      'Changing your list';

  @override
  String get spellPreparationCardInfoEntryChangeListBody =>
      'The list of prepared spells changes after a long rest: the long rest offers to keep your list or change it.';

  @override
  String get prepareSpellsSheetTitle => 'PREPARE MY SPELLS';

  @override
  String prepareSpellsSheetClassLabel(String className) {
    return 'PREPARED SPELLS — $className';
  }

  @override
  String get prepareSpellsSheetSearchHint => 'Search for a spell';

  @override
  String get prepareSpellsSheetSearchClearTooltip => 'Clear';

  @override
  String get prepareSpellsSheetNoMatchEmptyMessage => 'No spell available.';

  @override
  String prepareSpellsSheetNoMatchQueryMessage(String query) {
    return 'No spell for “$query”.';
  }

  @override
  String prepareSpellsSheetInfoTooltip(String spellName) {
    return 'Description of $spellName';
  }

  @override
  String castInnateSpellConfirmationDialogTitle(String spellName) {
    return 'Cast $spellName?';
  }

  @override
  String get castInnateSpellConfirmationDialogMessage =>
      'This uses up one use of this innate spell, recovered only on your next long rest.';

  @override
  String get castInnateSpellConfirmationDialogCancelButton => 'Cancel';

  @override
  String get castInnateSpellConfirmationDialogCastButton => 'Cast';

  @override
  String characterDetailCastSpellSuccessMessage(String spellName) {
    return '$spellName cast.';
  }

  @override
  String characterDetailCastSpellWithSlotSuccessMessage(
    String spellName,
    int slotLevel,
  ) {
    return '$spellName cast (level $slotLevel slot).';
  }

  @override
  String get characterDetailCastSpellErrorMessage =>
      'Couldn\'t cast this spell. Try again.';

  @override
  String characterDetailCastPactSpellSuccessMessage(
    String spellName,
    int pactLevel,
  ) {
    return '$spellName cast (level $pactLevel pact slot).';
  }

  @override
  String characterDetailCastInnateSpellSuccessMessage(String spellName) {
    return '$spellName cast (innate spell).';
  }

  @override
  String get characterDetailInnateSpellSyncErrorMessage =>
      'Couldn\'t sync innate spells. Try again.';
}
