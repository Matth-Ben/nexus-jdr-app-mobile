// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get profileLanguageMenuEntry => 'Langue';

  @override
  String get profileLanguageScreenTitle => 'LANGUE';

  @override
  String get profileLanguagePhoneOption => 'Langue du téléphone';

  @override
  String get profileLanguagePhoneOptionSubtitle => 'Phone language';

  @override
  String get profileLanguagePhoneOptionDetail =>
      'Suit la langue de l\'appareil (FR/EN) ; repli sur le français si l\'appareil utilise une autre langue. / Follows the device\'s language (FR/EN); falls back to French otherwise.';

  @override
  String get profileLanguageFrenchOption => 'Français';

  @override
  String get profileLanguageEnglishOption => 'English';

  @override
  String get profileLanguageSaveError =>
      'Impossible d\'enregistrer ce réglage. Réessaie.';

  @override
  String get authLoginBrandTitle => 'NEXUS JDR';

  @override
  String get authLoginTagline => 'Le registre des aventuriers';

  @override
  String get authLoginSharedAccountNotice => 'Même compte que l\'app Histoires';

  @override
  String get authLoginCardTitleSignUp => 'CRÉER UN COMPTE';

  @override
  String get authLoginCardTitleLogin => 'ENTRER DANS LA TAVERNE';

  @override
  String get authLoginEmailLabel => 'Adresse e-mail';

  @override
  String get authLoginEmailHint => 'nom@exemple.com';

  @override
  String get authLoginPasswordLabel => 'Mot de passe';

  @override
  String get authLoginPasswordHint => '••••••••';

  @override
  String get authLoginForgotPasswordLink => 'Mot de passe oublié ?';

  @override
  String get authLoginConfirmPasswordLabel => 'Confirmer le mot de passe';

  @override
  String get authLoginPseudoLabel => 'Pseudo';

  @override
  String get authLoginPseudoHint => 'Comment veux-tu qu\'on t\'appelle ?';

  @override
  String get authLoginPseudoHelper =>
      'Facultatif — tu pourras le changer plus tard dans ton profil.';

  @override
  String get authLoginSubmitSignUp => 'Créer le compte';

  @override
  String get authLoginSubmitLogin => 'Entrer';

  @override
  String get authLoginOrDivider => 'OU';

  @override
  String get authLoginContinueWithApple => 'Continuer avec Apple';

  @override
  String get authLoginContinueWithGoogle => 'Continuer avec Google';

  @override
  String get authLoginSwitchModePromptLogin => 'Déjà un compte ? ';

  @override
  String get authLoginSwitchModePromptSignUp => 'Pas encore de compte ? ';

  @override
  String get authLoginSwitchModeActionLogin => 'Se connecter';

  @override
  String get authLoginSwitchModeActionSignUp => 'Créer un compte';

  @override
  String get authLoginSignUpConfirmationTitle => 'VÉRIFIEZ VOS E-MAILS';

  @override
  String authLoginSignUpConfirmationBody(String email) {
    return 'Un e-mail de confirmation vient d\'être envoyé à $email. Cliquez sur le lien qu\'il contient pour activer votre compte.';
  }

  @override
  String get authLoginBackToLogin => 'Retour à la connexion';

  @override
  String get authForgotPasswordTitle => 'Mot de passe oublié ?';

  @override
  String get authForgotPasswordDescription =>
      'Saisissez votre adresse e-mail : nous vous enverrons un lien pour définir un nouveau mot de passe.';

  @override
  String get authForgotPasswordEmailHint => 'nom@exemple.com';

  @override
  String get authForgotPasswordCancel => 'Annuler';

  @override
  String get authForgotPasswordSubmit => 'Envoyer le lien';

  @override
  String get authForgotPasswordNeutralMessage =>
      'Si un compte existe avec cet email, un lien de réinitialisation vient d\'être envoyé.';

  @override
  String get authErrorInvalidCredentials =>
      'Adresse e-mail ou mot de passe incorrect.';

  @override
  String get authErrorEmailAlreadyExists =>
      'Un compte existe déjà avec cette adresse e-mail.';

  @override
  String authErrorWeakPassword(int minLength) {
    return 'Le mot de passe doit contenir au moins $minLength caractères.';
  }

  @override
  String get authErrorEmailNotConfirmed =>
      'Confirmez votre adresse e-mail avant de vous connecter (vérifiez votre boîte de réception).';

  @override
  String get authErrorInvalidEmail => 'Adresse e-mail invalide.';

  @override
  String get authErrorTooManyRequests =>
      'Trop de tentatives. Réessayez dans quelques instants.';

  @override
  String get authErrorNetwork =>
      'Impossible de contacter le serveur. Vérifiez votre connexion internet et réessayez.';

  @override
  String get authErrorBrowserLaunchFailed =>
      'Impossible d\'ouvrir le navigateur pour continuer avec Google. Réessayez.';

  @override
  String get authErrorUnexpected =>
      'Une erreur inattendue est survenue. Réessayez.';

  @override
  String get authValidationEmailRequired => 'Saisissez votre adresse e-mail.';

  @override
  String get authValidationEmailInvalid => 'Adresse e-mail invalide.';

  @override
  String get authValidationPasswordRequired => 'Saisissez votre mot de passe.';

  @override
  String authValidationPasswordTooShort(int minLength) {
    return 'Le mot de passe doit contenir au moins $minLength caractères.';
  }

  @override
  String get authValidationPasswordConfirmationRequired =>
      'Confirmez votre mot de passe.';

  @override
  String get authValidationPasswordConfirmationMismatch =>
      'Les mots de passe ne correspondent pas.';

  @override
  String get profileMenuTitle => 'PROFIL';

  @override
  String get profileMenuEditProfile => 'Modifier le profil';

  @override
  String get profileMenuNotifications => 'Notifications';

  @override
  String get profileMenuPrivacy => 'Confidentialité et données';

  @override
  String get profileMenuHelp => 'Aide et support';

  @override
  String get profileMenuSignOut => 'Se déconnecter';

  @override
  String get profileCreditsScreenTitle => 'CRÉDITS & LICENCES';

  @override
  String get profileCreditsGameContentTitle => 'Contenu de jeu';

  @override
  String get profileCreditsGameContentPara1 =>
      'Le contenu de règles Donjons & Dragons 5e (races, classes, historiques, sorts, objets, monstres...) provient d\'Open5e et du System Reference Document (SRD 5.1/5.2) de Wizards of the Coast, sous licence Creative Commons Attribution 4.0 International (CC-BY 4.0).';

  @override
  String get profileCreditsGameContentPara2 =>
      'Donjons & Dragons, D&D et leurs logos sont des marques de Wizards of the Coast LLC. Wizards of the Coast n\'a ni produit, ni approuvé, ni autorisé cette application.';

  @override
  String get profileCreditsLicenseNotice =>
      'Ce produit inclut des éléments du System Reference Document 5.1 et 5.2, disponibles sur dndbeyond.com/srd et open5e.com, sous licence Creative Commons Attribution 4.0 International (creativecommons.org/licenses/by/4.0/legalcode).';

  @override
  String get profileCreditsFontsTitle => 'Polices';

  @override
  String get profileCreditsFontsPara1 =>
      'Press Start 2P (The Press Start 2P Project Authors) et Work Sans (The Work Sans Project Authors) sont distribuées sous licence SIL Open Font License, version 1.1 (scripts.sil.org/OFL), et embarquées telles quelles dans l\'application depuis le dépôt officiel Google Fonts (github.com/google/fonts).';

  @override
  String get profileCreditsOpenSourceTitle => 'Bibliothèques open source';

  @override
  String get profileCreditsOpenSourcePara1 =>
      'Flutter · Riverpod · Supabase Flutter · Drift · Freezed · go_router · image_picker · file_picker · connectivity_plus · package_info_plus · share_plus · app_settings · url_launcher · Firebase (Core, Messaging) · shared_preferences';

  @override
  String get profileCreditsOpenSourcePara2 =>
      'Ainsi que les autres bibliothèques listées dans le fichier pubspec.yaml du projet, chacune sous sa licence open source d\'origine.';

  @override
  String get profileCreditsLastUpdated =>
      'Dernière mise à jour : 14 octobre 2026';

  @override
  String get profileDeleteAccountScreenTitle => 'SUPPRIMER LE COMPTE';

  @override
  String get profileDeleteAccountOfflineMessage =>
      'Hors ligne : cette action n\'a pas pu être enregistrée. Réessayez une fois reconnecté.';

  @override
  String get profileDeleteAccountGenericError =>
      'Impossible de supprimer le compte. Réessayez.';

  @override
  String get profileDeleteAccountWrongPassword => 'Mot de passe incorrect.';

  @override
  String get profileDeleteAccountWarningTitle => 'ACTION IRRÉVERSIBLE';

  @override
  String get profileDeleteAccountWarningMessage =>
      'Cette action est irréversible. Elle supprimera définitivement :\n• Tous tes personnages et leurs portraits\n• Tes rattachements aux histoires que tu as rejointes\n• Toutes les histoires que tu as créées en tant que MJ sur l\'app Histoires (et l\'accès de tes joueurs à ces histoires)\n\nCette action ne peut pas être annulée.';

  @override
  String get profileDeleteAccountConfirmationCheckboxLabel =>
      'Je comprends que cette action est définitive et que mes données ne pourront pas être récupérées.';

  @override
  String get profileDeleteAccountWhatWillBeDeletedTitle =>
      'CE QUI SERA SUPPRIMÉ';

  @override
  String get profileDeleteAccountChecklistCharacters =>
      'Tous tes personnages et leurs fiches';

  @override
  String get profileDeleteAccountChecklistStories =>
      'Ton accès aux histoires partagées';

  @override
  String get profileDeleteAccountChecklistProfile =>
      'Ton profil et tes préférences';

  @override
  String get profileDeleteAccountPasswordSectionTitle =>
      'SAISIS TON MOT DE PASSE POUR CONFIRMER';

  @override
  String get profileDeleteAccountPasswordHint => '••••••••';

  @override
  String get profileDeleteAccountSubmitInProgress => 'Suppression en cours…';

  @override
  String get profileDeleteAccountSubmitLabel => 'Supprimer définitivement';

  @override
  String get profileDeleteAccountCancel => 'Annuler';

  @override
  String get profileEditScreenTitle => 'MODIFIER LE PROFIL';

  @override
  String get profileEditPseudoLabel => 'Pseudo';

  @override
  String get profileEditPseudoHint => 'Comment veux-tu qu\'on t\'appelle ?';

  @override
  String get profileEditEmailLabel => 'E-mail';

  @override
  String get profileEditEmailChangeNotice =>
      'Modifier l\'e-mail envoie un lien de confirmation à la nouvelle adresse.';

  @override
  String get profileEditChangePassword => 'Changer le mot de passe';

  @override
  String get profileEditSaveButton => 'Enregistrer';

  @override
  String get profileEditSavedSnackbar => 'Pseudo mis à jour.';

  @override
  String get profileEditOfflineMessage =>
      'Hors ligne : cette action n\'a pas pu être enregistrée. Réessayez une fois reconnecté.';

  @override
  String get profileEditGenericError =>
      'Impossible d\'enregistrer les modifications. Réessayez.';

  @override
  String get profileEditTakePhoto => 'Prendre une photo';

  @override
  String get profileEditChoosePhoto => 'Choisir dans la galerie';

  @override
  String get profileFaqScreenTitle => 'QUESTIONS FRÉQUENTES';

  @override
  String get profileFaqQuestion1 =>
      'Comment importer un personnage depuis aidedd.org ?';

  @override
  String get profileFaqAnswer1 =>
      'Sur aidedd.org, ouvre la fiche de ton personnage puis utilise son export XML (bouton d\'export du site). Dans Nexus JDR, va dans la liste des Personnages et appuie sur « Importer XML », en bas de l\'écran à côté de « + Créer », puis sélectionne ce fichier .xml. L\'app pré-remplit automatiquement la fiche (caractéristiques, classe, race, sorts, inventaire...) et te montre un écran de vérification avant de l\'enregistrer, avec un badge sur les champs qu\'elle n\'a pas reconnus pour que tu les complètes toi-même.';

  @override
  String get profileFaqQuestion2 => 'Comment rejoindre l\'histoire de mon MJ ?';

  @override
  String get profileFaqAnswer2 =>
      'Ton MJ t\'envoie un lien d\'invitation depuis l\'app « Histoires ». Sur Android, ouvre ce lien sur ton téléphone : Nexus JDR s\'ouvre sur l\'invitation et tu choisis le personnage à rattacher. Il n\'y a pas encore de saisie manuelle du code dans l\'app, et l\'ouverture du lien dans l\'app n\'est pas encore disponible sur iPhone/iPad.';

  @override
  String get profileFaqQuestion3 =>
      'Mes personnages sont-ils sauvegardés hors ligne ?';

  @override
  String get profileFaqAnswer3 =>
      'En partie. Sans connexion, tu peux consulter ta liste et les fiches déjà ouvertes, et modifier les points de vie, l\'XP, les emplacements de sorts, les sorts innés, les aptitudes à usage limité et le repos : ces changements sont mis en attente sur ton appareil, puis envoyés automatiquement au retour du réseau. Attention, un seul repos est mis en attente à la fois par personnage : si tu enchaînes un repos court puis un repos long hors ligne, seul le dernier sera envoyé. Le reste (création de personnage, montée de niveau, inventaire, monnaies, journal, préparation des sorts, ajout d\'un objet depuis le catalogue...) demande une connexion : hors ligne, l\'action est refusée et il faut la refaire une fois reconnecté.';

  @override
  String get profileFaqQuestion4 => 'Comment fonctionne la montée de niveau ?';

  @override
  String get profileFaqAnswer4 =>
      'Depuis la fiche de personnage, l\'écran « Monter de niveau » te guide pas à pas : nouveaux points de vie, capacités de classe débloquées, nouveaux emplacements de sorts si ta classe en lance, et augmentation de caractéristique si le niveau l\'autorise. Rien n\'est appliqué avant que tu valides l\'écran récapitulatif.';

  @override
  String get profileFaqQuestion5 =>
      'Comment changer le portrait de mon personnage ?';

  @override
  String get profileFaqAnswer5 =>
      'Ouvre la fiche du personnage, appuie sur son portrait puis choisis « Prendre une photo » ou « Choisir dans la galerie ». Tu peux ensuite recadrer l\'image avant de l\'enregistrer — elle est stockée de façon sécurisée et associée uniquement à ce personnage.';

  @override
  String get profileFaqQuestion6 => 'Comment supprimer mon compte ?';

  @override
  String get profileFaqAnswer6 =>
      'Depuis Profil > Confidentialité et données > Supprimer mon compte, en bas de l\'écran (zone dangereuse). Cette action est irréversible : elle supprime définitivement tes personnages, leurs portraits et tous les rattachements à des histoires. Tu peux exporter tes données avant de confirmer.';

  @override
  String get profileHelpScreenTitle => 'AIDE ET SUPPORT';

  @override
  String get profileHelpSectionFaq => 'QUESTIONS FRÉQUENTES';

  @override
  String get profileHelpFaqQuestion1 =>
      'Comment importer un personnage aidedd.org ?';

  @override
  String get profileHelpFaqQuestion2 =>
      'Comment rejoindre l\'histoire de mon MJ ?';

  @override
  String get profileHelpFaqQuestion3 =>
      'Mes personnages sont-ils sauvegardés hors ligne ?';

  @override
  String get profileHelpFaqSeeAll => 'Voir toutes les questions';

  @override
  String get profileHelpSectionContact => 'NOUS CONTACTER';

  @override
  String get profileHelpContactSupport => 'Contacter le support';

  @override
  String get profileHelpReportBug => 'Signaler un bug';

  @override
  String get profileHelpContactFooterNote =>
      'Réponse sous 48h en semaine. Un aperçu des infos techniques de l\'appareil est joint automatiquement.';

  @override
  String get profileHelpSectionAbout => 'À PROPOS';

  @override
  String get profileHelpReplayOnboarding => 'Revoir la présentation de l\'app';

  @override
  String get profileHelpLegalMentions => 'Mentions légales / CGU';

  @override
  String get profileHelpCredits => 'Crédits & licences';

  @override
  String get profileHelpAboutFooterNote =>
      'Contenu D&D 5e sous licence Open5e / SRD. Voir les crédits complets pour le détail des sources.';

  @override
  String profileHelpFooterVersionWithNumber(String version) {
    return 'Nexus JDR — Personnages · v$version';
  }

  @override
  String get profileHelpFooterVersionWithoutNumber => 'Nexus JDR — Personnages';

  @override
  String get profileHelpNoMailApp =>
      'Aucune application e-mail n\'est configurée sur cet appareil.';

  @override
  String get profileHelpGenericMailError =>
      'Impossible d\'ouvrir l\'application e-mail. Réessayez.';

  @override
  String get profileLegalScreenTitle => 'MENTIONS LÉGALES / CGU';

  @override
  String get profileLegalEditorTitle => 'Éditeur';

  @override
  String get profileLegalEditorPara1 => 'Matthias Benoit';

  @override
  String get profileLegalEditorPara2 => 'Contact : support@nexus-jdr.app';

  @override
  String get profileLegalHostingTitle => 'Hébergement';

  @override
  String get profileLegalHostingPara1 =>
      'L\'application et ses données sont hébergées par Supabase (base de données, authentification, stockage des fichiers).';

  @override
  String get profileLegalPurposeTitle => 'Objet de l\'application';

  @override
  String get profileLegalPurposePara1 =>
      'Nexus JDR — Personnages permet de créer, importer et gérer des personnages de Donjons & Dragons 5e, seul ou synchronisé avec l\'app « Histoires » utilisée par ton Maître du Jeu.';

  @override
  String get profileLegalTermsTitle => 'Conditions d\'utilisation';

  @override
  String get profileLegalTermsPara1 =>
      'L\'usage de l\'application nécessite un compte. Tu es responsable de l\'exactitude des informations que tu y renseignes et de la confidentialité de tes identifiants. L\'éditeur se réserve le droit de suspendre un compte en cas d\'usage abusif.';

  @override
  String get profileLegalIntellectualPropertyTitle =>
      'Propriété intellectuelle';

  @override
  String get profileLegalIntellectualPropertyPara1 =>
      'Le contenu de règles Donjons & Dragons 5e (races, classes, sorts, objets...) provient d\'Open5e et du System Reference Document (SRD), sous licence Creative Commons Attribution 4.0 (CC-BY 4.0) — voir « Crédits & licences » pour le détail. Le reste de l\'application (code, design, marque « Nexus JDR ») appartient à son éditeur.';

  @override
  String get profileLegalTerminationTitle => 'Résiliation';

  @override
  String get profileLegalTerminationPara1 =>
      'Tu peux supprimer ton compte à tout moment depuis Profil > Confidentialité et données > Supprimer mon compte.';

  @override
  String get profileLegalGoverningLawTitle => 'Droit applicable';

  @override
  String get profileLegalGoverningLawPara1 =>
      'Ces mentions sont soumises au droit français.';

  @override
  String get profileLegalLastUpdated =>
      'Dernière mise à jour : 25 septembre 2026';

  @override
  String get profileNotificationsScreenTitle => 'NOTIFICATIONS';

  @override
  String get profileNotificationsOsPermissionDenied =>
      'Les notifications sont désactivées au niveau du téléphone. Active-les dans les réglages de l\'appareil pour les recevoir.';

  @override
  String get profileNotificationsPushToggle => 'Notifications push';

  @override
  String get profileNotificationsSectionTriggers => 'DÉCLENCHEURS';

  @override
  String get profileNotificationsRestReminder =>
      'Repos long non pris depuis longtemps';

  @override
  String get profileNotificationsAccessRevoked =>
      'Accès retiré ou modifié par le MJ';

  @override
  String get profileNotificationsNewVersion =>
      'Nouvelle mise à jour disponible';

  @override
  String get profileNotificationsSectionEmail => 'E-MAIL';

  @override
  String get profileNotificationsEmailDigest => 'Recevoir un résumé par e-mail';

  @override
  String get profileNotificationsEmailDigestSubtitle =>
      'Résumé hebdomadaire des personnages qui ont progressé.';

  @override
  String get profileNotificationsSystemNote =>
      'Les autorisations système (notifications) se gèrent aussi depuis les réglages du téléphone.';

  @override
  String get profileNotificationsGenericError =>
      'Impossible d\'enregistrer ce réglage. Réessaie.';

  @override
  String get profileNotificationsLoadError =>
      'Impossible de charger tes préférences de notifications. Réessaie.';

  @override
  String get profileNotificationsRetry => 'Réessayer';

  @override
  String get profilePrivacyPolicyScreenTitle => 'POLITIQUE DE CONFIDENTIALITÉ';

  @override
  String get profilePrivacyPolicyIntroductionTitle => 'Introduction';

  @override
  String get profilePrivacyPolicyIntroductionPara1 =>
      'Cette politique explique quelles données Nexus JDR collecte, pourquoi, avec qui elles sont partagées, et comment tu peux y accéder, les exporter ou les supprimer.';

  @override
  String get profilePrivacyPolicySection1Title =>
      '1. Qui est responsable de tes données';

  @override
  String get profilePrivacyPolicySection1Para1 =>
      'Cette politique s\'applique à l\'application mobile Nexus JDR — Personnages (Android) et à l\'application web Nexus JDR « Histoires » (nexus-jdr.app), qui partagent le même compte.';

  @override
  String get profilePrivacyPolicySection1Para2 =>
      'Responsable du traitement : Matthias Benoit, éditeur de Nexus JDR. Contact : support@nexus-jdr.app.';

  @override
  String get profilePrivacyPolicySection2Title => '2. Données collectées';

  @override
  String get profilePrivacyPolicySection2Para1 =>
      '• Compte : adresse e-mail et mot de passe (le mot de passe est stocké chiffré par notre service d\'authentification, nous ne le voyons jamais), pseudo affiché et avatar facultatif.';

  @override
  String get profilePrivacyPolicySection2Para2 =>
      '• Contenu de jeu : tout ce que tu crées — personnages (caractéristiques, compétences, sorts, inventaire, apparence, histoire), journal, notes de groupe, groupes et histoires rejoints, fichiers de personnage que tu importes.';

  @override
  String get profilePrivacyPolicySection2Para3 =>
      '• Photos : portrait de personnage, galerie et avatar, uniquement les images que tu choisis de prendre avec l\'appareil photo, d\'importer depuis ta galerie ou depuis une adresse web.';

  @override
  String get profilePrivacyPolicySection2Para4 =>
      '• Dictée vocale (notes de groupe, facultative) : le micro n\'est utilisé que pendant que tu dictes. La reconnaissance vocale est assurée par le service de ton téléphone (par exemple Google sur Android) ; nous ne recevons que le texte obtenu, jamais l\'enregistrement audio.';

  @override
  String get profilePrivacyPolicySection2Para5 =>
      '• Notifications : un identifiant technique de ton appareil (jeton de notification) et tes préférences de notification, pour t\'envoyer les rappels et nouvelles de tes groupes.';

  @override
  String get profilePrivacyPolicySection2Para6 =>
      '• Statistiques d\'utilisation : écrans consultés et actions réalisées dans l\'app, accompagnés d\'informations techniques (modèle d\'appareil, système, version de l\'app) et d\'un identifiant pseudonyme généré par l\'outil de mesure. Ces statistiques ne sont pas rattachées à ton compte ni à ton adresse e-mail.';

  @override
  String get profilePrivacyPolicySection2Para7 =>
      '• Signalements de bug : titre, description et gravité que tu saisis, version de l\'app, plateforme et, si tu le choisis, le personnage concerné.';

  @override
  String get profilePrivacyPolicySection3Title =>
      '3. Ce que nous ne collectons pas';

  @override
  String get profilePrivacyPolicySection3Para1 =>
      'Aucune donnée de localisation, aucun contact, aucune donnée de paiement. Aucune publicité n\'est affichée et aucune donnée n\'est vendue.';

  @override
  String get profilePrivacyPolicySection4Title =>
      '4. Pourquoi nous utilisons ces données';

  @override
  String get profilePrivacyPolicySection4Para1 =>
      '• Fournir le service (compte, fiches, groupes, synchronisation avec ton MJ, photos, notifications que tu actives) : c’est nécessaire à l\'exécution du service que tu utilises.';

  @override
  String get profilePrivacyPolicySection4Para2 =>
      '• Améliorer l\'app (statistiques d\'utilisation) : intérêt légitime à comprendre quelles fonctionnalités sont utilisées. Tu peux t\'y opposer à tout moment dans Profil > Confidentialité et données > Partager mes données d\'usage.';

  @override
  String get profilePrivacyPolicySection4Para3 =>
      '• Corriger les bugs que tu nous signales.';

  @override
  String get profilePrivacyPolicySection5Title =>
      '5. Avec qui tes données sont partagées';

  @override
  String get profilePrivacyPolicySection5Para1 =>
      'Avec d\'autres utilisateurs, uniquement à ton initiative : le MJ et les membres des histoires ou groupes que tu rejoins voient les personnages que tu y rattaches ; si tu crées un lien de partage de fiche, toute personne disposant de ce lien peut consulter la fiche en lecture seule, jusqu\'à ce que tu le désactives.';

  @override
  String get profilePrivacyPolicySection5Para2 =>
      'Avec nos prestataires techniques, qui traitent les données pour notre compte :';

  @override
  String get profilePrivacyPolicySection5Para3 =>
      '• Supabase — hébergement de la base de données, de l\'authentification et des photos.';

  @override
  String get profilePrivacyPolicySection5Para4 =>
      '• Google Firebase — envoi des notifications (Firebase Cloud Messaging) et statistiques d\'utilisation (Firebase Analytics).';

  @override
  String get profilePrivacyPolicySection5Para5 =>
      '• Google Firebase Crashlytics — rapports de plantage (traces techniques de l\'erreur et informations sur ton appareil), collectés systématiquement pour maintenir la stabilité de l\'app. Contrairement aux statistiques d\'utilisation (Firebase Analytics/PostHog, voir ci-dessus), ce recueil ne peut pas être désactivé depuis l\'app : notre intérêt légitime à diagnostiquer et corriger les plantages de l\'app prévaut ici.';

  @override
  String get profilePrivacyPolicySection5Para6 =>
      '• PostHog (hébergement dans l\'Union européenne) — statistiques d\'utilisation.';

  @override
  String get profilePrivacyPolicySection5Para7 =>
      '• GitHub — suivi des bugs signalés : le contenu d\'un signalement (titre, description, gravité, version, plateforme) est publié comme ticket dans un dépôt public, sans ton adresse e-mail ni ton nom. N\'y indique donc aucune information personnelle.';

  @override
  String get profilePrivacyPolicySection5Para8 =>
      '• Resend — envoi des e-mails transactionnels (confirmation de compte, réinitialisation de mot de passe).';

  @override
  String get profilePrivacyPolicySection5Para9 =>
      '• Vercel — hébergement du site nexus-jdr.app.';

  @override
  String get profilePrivacyPolicySection5Para10 =>
      'Certains de ces prestataires peuvent traiter des données hors de l\'Union européenne ; ces transferts sont encadrés par les garanties prévues par le RGPD (clauses contractuelles types de la Commission européenne ou cadre de protection des données UE–États-Unis).';

  @override
  String get profilePrivacyPolicySection6Title => '6. Durée de conservation';

  @override
  String get profilePrivacyPolicySection6Para1 =>
      '• Compte, contenu de jeu et photos : tant que ton compte existe. Ils sont supprimés définitivement dès que tu supprimes ton compte.';

  @override
  String get profilePrivacyPolicySection6Para2 =>
      '• Statistiques d\'utilisation : conservées sous forme pseudonyme, sans lien avec ton compte, pendant la durée de conservation paramétrée dans les outils de mesure.';

  @override
  String get profilePrivacyPolicySection6Para3 =>
      '• Signalements de bug : le temps nécessaire à leur traitement.';

  @override
  String get profilePrivacyPolicySection7Title => '7. Tes droits';

  @override
  String get profilePrivacyPolicySection7Para1 =>
      'Conformément au RGPD, tu disposes d\'un droit d\'accès, de rectification, d\'effacement, de portabilité, d\'opposition et de limitation du traitement. Directement depuis l\'app :';

  @override
  String get profilePrivacyPolicySection7Para2 =>
      '• Exporter tes données : Profil > Confidentialité et données > Exporter mes données.';

  @override
  String get profilePrivacyPolicySection7Para3 =>
      '• Supprimer ton compte et toutes tes données : Profil > Confidentialité et données > Supprimer mon compte.';

  @override
  String get profilePrivacyPolicySection7Para4 =>
      '• Désactiver les statistiques d\'utilisation : Profil > Confidentialité et données.';

  @override
  String get profilePrivacyPolicySection7Para5 =>
      '• Désactiver les notifications : dans les réglages de notification de l\'app ou de ton téléphone.';

  @override
  String get profilePrivacyPolicySection7Para6 =>
      'Pour toute autre demande, écris à support@nexus-jdr.app. Tu peux aussi introduire une réclamation auprès de la CNIL (www.cnil.fr).';

  @override
  String get profilePrivacyPolicySection8Title => '8. Sécurité';

  @override
  String get profilePrivacyPolicySection8Para1 =>
      'Les échanges avec nos serveurs sont chiffrés (HTTPS). L’accès à tes données est protégé par l\'authentification de ton compte et par des règles d\'accès qui empêchent tout autre utilisateur de lire ou modifier ce que tu ne partages pas.';

  @override
  String get profilePrivacyPolicySection9Title =>
      '9. Modifications de cette politique';

  @override
  String get profilePrivacyPolicySection9Para1 =>
      'Cette politique peut évoluer avec l\'application. La date de dernière mise à jour figure en bas de cet écran ; en cas de changement important, tu en seras informé dans l\'app.';

  @override
  String get profilePrivacyPolicyLastUpdated =>
      'Dernière mise à jour : 1er novembre 2026';

  @override
  String get profilePrivacyScreenTitle => 'CONFIDENTIALITÉ';

  @override
  String get profilePrivacyDataSectionTitle => 'MES DONNÉES';

  @override
  String get profilePrivacyExportData => 'Exporter mes données';

  @override
  String get profilePrivacyPolicyLink => 'Politique de confidentialité';

  @override
  String get profilePrivacyDevicePermissions => 'Autorisations de l\'appareil';

  @override
  String get profilePrivacyExportNote =>
      'L\'export contient ton profil, tes personnages (leur inventaire, leurs sorts et leur historique), tes groupes et tes notes de groupe (JSON, proposé au partage depuis ton appareil).';

  @override
  String get profilePrivacyShareUsageData => 'Partager mes données d\'usage';

  @override
  String get profilePrivacyShareUsageDataSubtitle =>
      'Statistiques d\'utilisation anonymes (Firebase Analytics, PostHog), pour améliorer l\'app. Désactivable à tout moment — les rapports de plantage restent toujours actifs pour la stabilité de l\'app (voir Politique de confidentialité).';

  @override
  String get profilePrivacyDangerZoneTitle => 'ZONE DANGEREUSE';

  @override
  String get profilePrivacyDeleteAccount => 'Supprimer mon compte';

  @override
  String get profileAvatarCropScreenTitle => 'RECADRAGE';

  @override
  String get profileAvatarCropInstructions =>
      'Pincez pour zoomer, glissez pour cadrer.';

  @override
  String get profileAvatarCropCancel => 'Annuler';

  @override
  String get profileAvatarCropConfirm => 'Valider';

  @override
  String get profileAvatarCropOfflineMessage =>
      'Hors ligne : cette action n\'a pas pu être enregistrée. Réessayez une fois reconnecté.';

  @override
  String get profileAvatarCropGenericError =>
      'Impossible de mettre à jour l\'avatar. Réessayez.';

  @override
  String get profileAvatarCropPrepareImageError =>
      'Impossible de préparer l\'image. Réessayez.';

  @override
  String get profileAvatarEditTakePhoto => 'Prendre une photo';

  @override
  String get profileAvatarEditChooseGallery => 'Choisir dans la galerie';

  @override
  String get profileAvatarEditRemovePhoto => 'Retirer la photo';

  @override
  String get profileAvatarEditRemovedSnackbar => 'Photo retirée.';

  @override
  String get profileAvatarEditGenericError =>
      'Impossible de mettre à jour l\'avatar. Réessayez.';

  @override
  String get profileAvatarEditRemoveConfirmTitle => 'Retirer la photo ?';

  @override
  String get profileAvatarEditRemoveConfirmCancel => 'Annuler';

  @override
  String get profileAvatarEditRemoveConfirmAction => 'Retirer';

  @override
  String get profileChangeEmailTitle => 'ADRESSE EMAIL';

  @override
  String get profileChangeEmailInfoBanner =>
      'Un email de confirmation sera envoyé à cette adresse. Le changement ne sera effectif qu\'après confirmation.';

  @override
  String get profileChangeEmailFieldLabel => 'NOUVELLE ADRESSE EMAIL';

  @override
  String get profileChangeEmailHint => 'nom@exemple.com';

  @override
  String profileChangeEmailCurrentAddress(String email) {
    return 'Adresse actuelle : $email';
  }

  @override
  String get profileChangeEmailCancel => 'Annuler';

  @override
  String get profileChangeEmailSave => 'Enregistrer';

  @override
  String get profileChangeEmailConfirmationSnackbar =>
      'Email de confirmation envoyé. Vérifie ta boîte de réception pour finaliser le changement.';

  @override
  String get profileChangeEmailOfflineMessage =>
      'Hors ligne : cette action n\'a pas pu être enregistrée. Réessayez une fois reconnecté.';

  @override
  String get profileChangeEmailGenericError =>
      'Impossible d\'envoyer le nouvel email. Réessayez.';

  @override
  String get profileChangePasswordTitle => 'MOT DE PASSE';

  @override
  String get profileChangePasswordNewLabel => 'NOUVEAU MOT DE PASSE';

  @override
  String get profileChangePasswordHint => '••••••••';

  @override
  String get profileChangePasswordConfirmLabel => 'CONFIRMER LE MOT DE PASSE';

  @override
  String get profileChangePasswordCancel => 'Annuler';

  @override
  String get profileChangePasswordSave => 'Enregistrer';

  @override
  String get profileChangePasswordUpdatedSnackbar => 'Mot de passe mis à jour.';

  @override
  String get profileChangePasswordOfflineMessage =>
      'Hors ligne : cette action n\'a pas pu être enregistrée. Réessayez une fois reconnecté.';

  @override
  String get profileChangePasswordGenericError =>
      'Impossible de mettre à jour le mot de passe. Réessayez.';

  @override
  String get profileDevicePermissionsTitle =>
      'GESTION DES AUTORISATIONS APPAREIL';

  @override
  String get profileDevicePermissionsBody =>
      'Nexus JDR utilise l\'appareil photo et la galerie uniquement pour définir le portrait de ton personnage ou ton avatar. Pour modifier ces autorisations, ouvre les réglages de ton téléphone.';

  @override
  String get profileDevicePermissionsOpenSettings => 'Ouvrir les réglages';

  @override
  String get profileEditDisplayNameTitle => 'PSEUDO';

  @override
  String get profileEditDisplayNameFieldLabel => 'NOM D\'AFFICHAGE';

  @override
  String get profileEditDisplayNameHint =>
      'Comment veux-tu qu\'on t\'appelle ?';

  @override
  String get profileEditDisplayNameCancel => 'Annuler';

  @override
  String get profileEditDisplayNameSave => 'Enregistrer';

  @override
  String get profileEditDisplayNameUpdatedSnackbar => 'Pseudo mis à jour.';

  @override
  String get profileEditDisplayNameOfflineMessage =>
      'Hors ligne : cette action n\'a pas pu être enregistrée. Réessayez une fois reconnecté.';

  @override
  String get profileEditDisplayNameGenericError =>
      'Impossible d\'enregistrer les modifications. Réessayez.';

  @override
  String get profileExportDataTitle => 'EXPORT DE MES DONNÉES';

  @override
  String get profileExportDataDescription =>
      'Génère un fichier JSON contenant ton profil, tous tes personnages et leurs données associées (inventaire, sorts, historique), ainsi que tes groupes et tes notes de groupe. Le fichier te sera proposé au partage/enregistrement depuis ton appareil.';

  @override
  String get profileExportDataCancel => 'Annuler';

  @override
  String get profileExportDataGenerate => 'Générer l\'export';

  @override
  String get profileExportDataGeneratedSnackbar => 'Export généré.';

  @override
  String get profileExportDataOfflineMessage =>
      'Hors ligne : cette action n\'a pas pu être enregistrée. Réessayez une fois reconnecté.';

  @override
  String get profileExportDataGenericError =>
      'Impossible de générer l\'export. Réessayez.';

  @override
  String get profileReportBugSentSnackbar =>
      'Merci, ton signalement a bien été envoyé !';

  @override
  String get profileReportBugSeverityMinorTitle => 'Gênant';

  @override
  String get profileReportBugSeverityMinorSubtitle =>
      'Un désagrément, mais tu peux continuer à jouer';

  @override
  String get profileReportBugSeverityMajorTitle => 'Problématique';

  @override
  String get profileReportBugSeverityMajorSubtitle =>
      'Ça complique les choses, mais il y a moyen de contourner';

  @override
  String get profileReportBugSeverityBlockingTitle => 'Ça bloque tout';

  @override
  String get profileReportBugSeverityBlockingSubtitle =>
      'Impossible de continuer sans ça';

  @override
  String get profileReportBugSeverityContentTitle => 'Contenu à corriger';

  @override
  String get profileReportBugSeverityContentSubtitle =>
      'Erreur ou oubli dans un sort, un objet, une règle ou une traduction';

  @override
  String get profileReportBugOfflineMessage =>
      'Hors ligne : cette action n\'a pas pu être enregistrée. Réessayez une fois reconnecté.';

  @override
  String get profileReportBugGenericError =>
      'Impossible d\'envoyer le signalement. Réessayez.';

  @override
  String get profileReportBugScreenshotUploadError =>
      'Impossible d\'envoyer la capture. Réessayez, ou retirez-la pour envoyer le signalement sans.';

  @override
  String get profileReportBugCaptureTooLarge =>
      'Cette image est trop lourde (plus de 5 Mo), même compressée. Choisissez-en une autre.';

  @override
  String get profileReportBugCaptureUnsupportedFormat =>
      'Ce format d\'image n\'est pas pris en charge. Choisissez une autre image.';

  @override
  String get profileReportBugCaptureAccessDenied =>
      'L\'accès à vos photos ou à l\'appareil photo est refusé. Autorisez-le dans les réglages du téléphone.';

  @override
  String get profileReportBugCapturePrivacyNotice =>
      'Facultatif, une seule image. Elle reste privée : seule l\'équipe de développement la voit, elle n\'est jamais publiée avec ton signalement et elle est supprimée avec ton compte. Évite quand même d\'y laisser des infos personnelles.';

  @override
  String get profileReportBugAddCaptureSemanticLabel =>
      'Ajouter une capture d\'écran (facultatif)';

  @override
  String get profileReportBugAddCapture => 'Ajouter une capture';

  @override
  String get profileReportBugCaptureSectionTitle => 'CAPTURE D\'ÉCRAN';

  @override
  String get profileReportBugTitle => 'SIGNALER UN BUG';

  @override
  String get profileReportBugFieldTitleLabel => 'TITRE';

  @override
  String get profileReportBugFieldTitleHint =>
      'Résumé en une phrase (ex. « Le bouton PV ne répond pas »)';

  @override
  String get profileReportBugFieldDescriptionLabel => 'DESCRIPTION';

  @override
  String get profileReportBugFieldDescriptionHint =>
      'Que s\'est-il passé ? Que faisais-tu au moment du bug ?';

  @override
  String get profileReportBugSeveritySectionTitle => 'QUEL GENRE DE SOUCI ?';

  @override
  String get profileReportBugCancel => 'Annuler';

  @override
  String get profileReportBugSend => 'Envoyer';

  @override
  String get profileReportBugChooseGallery => 'Choisir dans la galerie';

  @override
  String get profileReportBugTakePhoto => 'Prendre une photo';

  @override
  String get profileReportBugPreparingImage => 'Préparation de l\'image…';

  @override
  String get profileReportBugPreparingImageSemanticLabel =>
      'Préparation de l\'image en cours';

  @override
  String get profileReportBugAttachedLabel => 'Capture jointe';

  @override
  String get profileReportBugReplace => 'Remplacer';

  @override
  String get profileReportBugRemove => 'Retirer';

  @override
  String get profileReportBugReplaceSemanticLabel =>
      'Remplacer la capture d\'écran';

  @override
  String get profileReportBugRemoveSemanticLabel =>
      'Retirer la capture d\'écran';

  @override
  String get profileReportBugAttachedImageSemanticLabel =>
      'Capture d\'écran jointe';

  @override
  String characterLevelAbbreviation(int level) {
    return 'Niv. $level';
  }

  @override
  String get characterOfflineNotPersistedMessage =>
      'Hors ligne : cette action n\'a pas pu être enregistrée. Réessayez une fois reconnecté.';

  @override
  String get characterAccessDeniedErrorMessage =>
      'Vous n\'avez pas accès à ces personnages.';

  @override
  String get characterNetworkErrorMessage =>
      'Impossible de contacter le serveur. Vérifiez votre connexion internet et réessayez.';

  @override
  String get characterListHeaderTitle => 'TES AVENTURIERS';

  @override
  String get characterListSearchHint => 'Rechercher un personnage';

  @override
  String get characterListSearchClearTooltip => 'Effacer';

  @override
  String get characterListFilterButtonLabel => 'Filtrer les personnages';

  @override
  String get characterListFilterButtonActiveValue => 'Filtre actif';

  @override
  String get characterListSelectionModeButtonLabel =>
      'Sélectionner plusieurs personnages';

  @override
  String get characterListCreateButton => '+ Créer';

  @override
  String get characterListImportXmlButton => 'Importer XML';

  @override
  String get characterListImportErrorMessage =>
      'Impossible de lire ce fichier. Vérifiez qu\'il s\'agit bien d\'un export XML aidedd.org.';

  @override
  String get characterListSearchEmptyTitleNoQuery => 'AUCUN RÉSULTAT';

  @override
  String characterListSearchEmptyTitleWithQuery(String query) {
    return 'AUCUN RÉSULTAT POUR « $query »';
  }

  @override
  String get characterListSearchEmptyBodyNoQuery =>
      'Aucun personnage ne correspond à ce filtre. Réinitialise pour retrouver tous tes personnages.';

  @override
  String get characterListSearchEmptyBodyWithQuery =>
      'Vérifie l\'orthographe, ou réinitialise la recherche pour retrouver tous tes personnages.';

  @override
  String get characterListSearchEmptyResetButton => 'Réinitialiser';

  @override
  String get characterListEmptyTitle => 'AUCUN AVENTURIER POUR L\'INSTANT';

  @override
  String get characterListEmptyBody =>
      'Crée ton premier personnage, ou importe-le depuis aidedd.org, pour commencer l\'aventure.';

  @override
  String get characterListDeleteSelectionGenericError =>
      'Impossible de supprimer les personnages sélectionnés. Réessayez.';

  @override
  String characterListDeleteSelectionSucceededLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personnages supprimés',
      one: '1 personnage supprimé',
    );
    return '$_temp0';
  }

  @override
  String characterListDeleteSelectionFailedLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personnages n\'ont pas pu être supprimés',
      one: '1 personnage n\'a pas pu être supprimé',
    );
    return '$_temp0';
  }

  @override
  String get characterListFilterSheetTitle => 'FILTRER';

  @override
  String get characterListFilterSheetStatusSection => 'STATUT';

  @override
  String get characterListFilterSheetClassSection => 'CLASSE';

  @override
  String get characterListFilterSheetResetButton => 'Réinitialiser';

  @override
  String get characterListFilterSheetApplyButton => 'Appliquer';

  @override
  String get characterListFilterSheetStatusAlive => 'Vivants';

  @override
  String get characterListFilterSheetStatusArchived => 'Archivé';

  @override
  String get characterListFilterSheetStatusDead => 'Mort';

  @override
  String get characterCardArchivedBadge => 'ARCHIVÉ';

  @override
  String get characterCardDeadBadge => 'MORT';

  @override
  String get characterCardXpLabel => 'XP';

  @override
  String get characterCardActionSheetEdit => 'Modifier';

  @override
  String get characterCardActionSheetShare => 'Partager';

  @override
  String get characterCardActionSheetArchive => 'Archiver ce personnage';

  @override
  String get characterCardActionSheetUnarchive => 'Désarchiver';

  @override
  String get characterCardActionSheetMarkDead => 'Marquer comme mort';

  @override
  String get characterCardActionSheetRevive => 'Ressusciter';

  @override
  String get characterCardActionSheetDelete => 'Supprimer le personnage';

  @override
  String get characterCardActionSheetUpdateStatusGenericError =>
      'Impossible de mettre à jour le statut. Réessayez.';

  @override
  String get characterCardActionSheetDeleteGenericError =>
      'Impossible de supprimer le personnage. Réessayez.';

  @override
  String characterDeleteConfirmationSingleTitle(String characterName) {
    return 'Supprimer $characterName ?';
  }

  @override
  String get characterDeleteConfirmationBody =>
      'Cette action est définitive : le personnage et toutes ses données (sorts, inventaire, historique...) seront irrémédiablement supprimés.';

  @override
  String characterDeleteConfirmationMultipleTitle(int count) {
    return 'Supprimer ces $count personnages ?';
  }

  @override
  String get characterDeleteConfirmationMultipleBody =>
      'Cette action est définitive : les personnages et toutes leurs données (sorts, inventaire, historique...) seront irrémédiablement supprimés.';

  @override
  String get characterDeleteConfirmationCancelButton => 'Annuler';

  @override
  String get characterDeleteConfirmationConfirmButton => 'Supprimer';

  @override
  String characterDeleteConfirmationMultipleConfirmButton(int count) {
    return 'Supprimer ($count)';
  }

  @override
  String characterSelectionActionBarSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personnages sélectionnés',
      one: '1 personnage sélectionné',
      zero: 'Aucun personnage sélectionné',
    );
    return '$_temp0';
  }

  @override
  String get characterSelectionActionBarCancelButton => 'Annuler';

  @override
  String get characterSelectionActionBarDeleteButton => 'Supprimer';

  @override
  String characterNameTagChipSemanticLabel(String name) {
    return '$name, voir le détail';
  }

  @override
  String get characterDetailTabCharacterLabel => 'PERSO';

  @override
  String get characterDetailTabCharacterTitle => 'FICHE';

  @override
  String get characterDetailTabSkillsLabel => 'APT.';

  @override
  String get characterDetailTabSkillsTitle => 'APTITUDES';

  @override
  String get characterDetailTabSpellsLabel => 'SORTS';

  @override
  String get characterDetailTabSpellsTitle => 'SORTS';

  @override
  String get characterDetailTabInventoryLabel => 'SAC';

  @override
  String get characterDetailTabInventoryTitle => 'INVENTAIRE';

  @override
  String get characterDetailTabStoryLabel => 'HIST.';

  @override
  String get characterDetailTabStoryTitle => 'HISTOIRE';

  @override
  String get characterDetailHelpTooltip => 'Aide';

  @override
  String get characterDetailMoreOptionsTooltip => 'Plus d\'options';

  @override
  String get characterDetailSearchTooltip => 'Rechercher';

  @override
  String get characterDetailFilterTooltip => 'Filtrer';

  @override
  String get characterDetailMenuExportXml => 'Exporter en XML';

  @override
  String get characterDetailLoadErrorMessage =>
      'Impossible de charger ce personnage. Réessayez.';

  @override
  String get characterDetailInitiativeLabel => 'Initiative';

  @override
  String get characterDetailHpUpdateErrorMessage =>
      'Impossible de mettre à jour les PV. Réessayez.';

  @override
  String get characterDetailHpSyncErrorMessage =>
      'Impossible de synchroniser les PV. Réessayez.';

  @override
  String characterDetailFeatureUseSuccessMessage(String featureName) {
    return '$featureName utilisée.';
  }

  @override
  String get characterDetailFeatureUseErrorMessage =>
      'Impossible d\'utiliser cette aptitude. Réessayez.';

  @override
  String get characterDetailFeatureSyncErrorMessage =>
      'Impossible de synchroniser les aptitudes de classe. Réessayez.';

  @override
  String get characterDetailXpAddErrorMessage =>
      'Impossible d\'ajouter l\'XP. Réessayez.';

  @override
  String get characterDetailOfflineQueuedMessage =>
      'Hors ligne : sera synchronisé dès que la connexion revient.';

  @override
  String get characterDetailArmorClassAdjustErrorMessage =>
      'Impossible d\'ajuster la Classe d\'Armure. Réessayez.';

  @override
  String get characterVitalsCardRestButton => 'Repos';

  @override
  String get characterVitalsCardHpLabel => 'POINTS DE VIE';

  @override
  String characterVitalsCardTemporaryHpChip(int amount) {
    return '+$amount PV temp.';
  }

  @override
  String get characterVitalsCardZeroHpLabel => 'À 0 PV';

  @override
  String get characterVitalsCardXpLabel => 'EXPÉRIENCE';

  @override
  String get characterVitalsCardAddXpButton => '+ XP';

  @override
  String characterVitalsCardLevelUpBanner(int targetLevel) {
    return 'NIVEAU $targetLevel DISPONIBLE';
  }

  @override
  String get characterStatPillsSpeedLabel => 'VIT.';

  @override
  String get characterStatPillsArmorClassLabel => 'CA';

  @override
  String get characterStatPillsInitiativeLabel => 'INIT.';

  @override
  String get characterStatPillsInspirationLabel => 'INSP.';

  @override
  String characterStatPillsSpeedValue(double speed) {
    final intl.NumberFormat speedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String speedString = speedNumberFormat.format(speed);

    return '$speedString m';
  }

  @override
  String get characterAbilityAbbreviationStr => 'For';

  @override
  String get characterAbilityAbbreviationDex => 'Dex';

  @override
  String get characterAbilityAbbreviationCon => 'Con';

  @override
  String get characterAbilityAbbreviationInt => 'Int';

  @override
  String get characterAbilityAbbreviationWis => 'Sag';

  @override
  String get characterAbilityAbbreviationCha => 'Cha';

  @override
  String get characterSavingThrowsCardTitle => 'JETS DE SAUVEGARDE';

  @override
  String get characterSkillsCardTitle => 'LES 18 COMPÉTENCES';

  @override
  String get characterSkillsCardMasteredLegend => 'maîtrisée';

  @override
  String get characterSkillsCardD20Chip => 'D20';

  @override
  String get characterAppearanceCardTitle => 'APPARENCE PHYSIQUE';

  @override
  String get characterAppearanceCardSexeLabel => 'Sexe';

  @override
  String get characterAppearanceCardAgeLabel => 'Âge';

  @override
  String get characterAppearanceCardHeightLabel => 'Taille';

  @override
  String get characterAppearanceCardWeightLabel => 'Poids';

  @override
  String get characterAppearanceCardEyesLabel => 'Yeux';

  @override
  String get characterAppearanceCardSkinLabel => 'Peau';

  @override
  String get characterAppearanceCardHairLabel => 'Cheveux';

  @override
  String get characterSkillsTabBodySearchHint => 'Rechercher une compétence';

  @override
  String characterSkillsTabBodyNoMatchMessage(String query) {
    return 'Aucune compétence pour « $query ».';
  }

  @override
  String get connectionErrorStateBannerTitle => 'CONNEXION';

  @override
  String get connectionErrorStateTitle => 'Connexion impossible';

  @override
  String get connectionErrorStateBody =>
      'Vérifie ta connexion internet et réessaie. Tes personnages restent disponibles hors ligne — les modifications se synchroniseront automatiquement dès le retour du réseau.';

  @override
  String get connectionErrorStateRetryButton => 'Réessayer';

  @override
  String get connectionErrorStateContinueOfflineLabel => 'Continuer hors ligne';

  @override
  String get connectionErrorStateContinueOfflineTooltip =>
      'Bientôt disponible : la lecture hors ligne de tes personnages arrive avec une prochaine mise à jour. Pour l\'instant, une connexion est nécessaire pour charger tes personnages.';

  @override
  String get hpAdjustmentSheetTitle => 'Ajuster les PV';

  @override
  String get hpAdjustmentSheetDamageOption => 'Dégâts';

  @override
  String get hpAdjustmentSheetHealOption => 'Soins';

  @override
  String get hpAdjustmentSheetTemporaryOption => 'PV temp.';

  @override
  String get hpAdjustmentSheetCancelButton => 'Annuler';

  @override
  String get hpAdjustmentSheetDamageApplyButton => 'Infliger';

  @override
  String get hpAdjustmentSheetHealApplyButton => 'Soigner';

  @override
  String get hpAdjustmentSheetTemporaryApplyButton => 'Ajouter';

  @override
  String get addXpSheetTitle => 'Ajouter de l\'XP';

  @override
  String addXpSheetCurrentXpLabel(int currentXp, int threshold) {
    return 'XP actuelle : $currentXp / $threshold';
  }

  @override
  String get addXpSheetGainedLabel => 'XP GAGNÉE';

  @override
  String get addXpSheetAmountHint => 'Ex. 250';

  @override
  String get addXpSheetAmountHelper =>
      'Montant remis par le MJ en fin de séance, par exemple.';

  @override
  String addXpSheetNewTotalLabel(int total) {
    return 'Nouveau total : $total XP';
  }

  @override
  String get addXpSheetCancelButton => 'Annuler';

  @override
  String get addXpSheetApplyButton => 'Ajouter';

  @override
  String get addXpSheetManualLevelUpLink => 'Monter de niveau manuellement';

  @override
  String get addRewardSheetTitle => 'AJOUTER UNE RÉCOMPENSE';

  @override
  String get addRewardSheetCurrencyLabel => 'MONNAIE';

  @override
  String get addRewardSheetItemsLabel => 'OBJETS';

  @override
  String get addRewardSheetAddItemLabel => 'Ajouter un objet';

  @override
  String get addRewardSheetCancelButton => 'Annuler';

  @override
  String get addRewardSheetApplyButton => 'Ajouter la récompense';

  @override
  String addRewardSheetItemQuantityLabel(String name, int quantity) {
    return '$name × $quantity';
  }

  @override
  String get restSheetTitle => 'Repos';

  @override
  String restSheetCurrentHpLabel(int currentHp, int maxHp) {
    return 'PV actuels : $currentHp / $maxHp';
  }

  @override
  String get restSheetShortOption => 'Repos court';

  @override
  String get restSheetLongOption => 'Repos long';

  @override
  String get restSheetCancelButton => 'Annuler';

  @override
  String get restSheetApplyButton => 'Appliquer';

  @override
  String get restSheetPreparedSpellsTitle => 'SORTS PRÉPARÉS';

  @override
  String get restSheetKeepListOption => 'Garder ma liste';

  @override
  String get restSheetChangeSpellsOption => 'Changer mes sorts';

  @override
  String get restSheetChangeSpellsHelper =>
      'Après le repos, la liste de vos sorts s\'ouvre pour choisir ceux à préparer.';

  @override
  String get restSheetKeepListHelper =>
      'Vos sorts préparés restent les mêmes après le repos.';

  @override
  String get restSheetLongHelpText =>
      'Restaure les PV au maximum, réinitialise les emplacements de sorts et recharge toutes les aptitudes rechargeables (repos court comme repos long).';

  @override
  String restSheetAfterRestHpLabel(int maxHp) {
    return 'PV après repos : $maxHp / $maxHp';
  }

  @override
  String restSheetHitDiceAvailableLabel(int remaining, int total, int hitDie) {
    return 'Dés de vie disponibles : $remaining/$total (d$hitDie)';
  }

  @override
  String get restSheetDiceToSpendLabel => 'Dés à dépenser';

  @override
  String get restSheetNoHitDiceAvailable =>
      'Aucun dé de vie disponible. Le repos court reste gratuit — aucune action supplémentaire requise.';

  @override
  String get restSheetRollMethodOption => 'Lancer les dés';

  @override
  String get restSheetAverageMethodOption => 'Valeur moyenne';

  @override
  String get restSheetRerollLink => 'Relancer les dés';

  @override
  String get restSheetAverageFormulaHint =>
      '(moitié du dé arrondie au supérieur, +1, par dé)';

  @override
  String get restSheetAlreadyMaxHpMessage =>
      'PV déjà au maximum : ce repos ne restaurera aucun PV supplémentaire.';

  @override
  String get restSheetHpRestoredTitle => 'PV restaurés';

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
    return '$className — dés de vie disponibles : $available/$total (d$hitDie)';
  }

  @override
  String restSheetRecoveredAllocationTitle(int count) {
    return 'Dés de vie récupérés : $count — répartissez-les entre vos classes';
  }

  @override
  String restSheetRecoveredPoolLabel(String className, int hitDie, int spent) {
    return '$className (d$hitDie) — $spent dépensé(s)';
  }

  @override
  String restSheetRemainingToAllocateLabel(int remaining) {
    return 'Reste à répartir : $remaining';
  }

  @override
  String diceRollSheetFormula(int roll, String modifier, int total) {
    return 'd20 ($roll) $modifier = $total';
  }

  @override
  String get diceRollSheetCriticalSuccess => 'RÉUSSITE CRITIQUE';

  @override
  String get diceRollSheetCriticalFailure => 'ÉCHEC CRITIQUE';

  @override
  String get diceRollSheetRerollButton => 'Relancer';

  @override
  String get armorClassBonusSheetTitle => 'Ajustement de CA';

  @override
  String get armorClassBonusSheetBonusOption => 'Bonus';

  @override
  String get armorClassBonusSheetMalusOption => 'Malus';

  @override
  String get armorClassBonusSheetClearButton => 'Effacer';

  @override
  String get armorClassBonusSheetValidateButton => 'Valider';

  @override
  String get levelUpScreenEyebrow => 'MONTÉE DE NIVEAU';

  @override
  String get levelUpScreenLevelReachedEyebrow => 'NIVEAU ATTEINT';

  @override
  String levelUpScreenLevelLabel(int level) {
    return 'NIVEAU $level';
  }

  @override
  String levelUpScreenRemainingLevelsLabel(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: 'Encore $remaining niveaux à valider ensuite',
      one: 'Encore 1 niveau à valider ensuite',
    );
    return '$_temp0';
  }

  @override
  String get levelUpScreenComingSoonSnackBar => 'Bientôt disponible';

  @override
  String get levelUpScreenGenericApplyError =>
      'Impossible d\'enregistrer la montée de niveau. Réessayez.';

  @override
  String get levelUpScreenGenericLoadError =>
      'Impossible de charger les données de montée de niveau. Réessayez.';

  @override
  String get levelUpScreenClassDecisionInstruction =>
      'Choisissez comment ce niveau s\'applique.';

  @override
  String levelUpScreenContinueClassOptionTitle(String className) {
    return 'Continuer en $className';
  }

  @override
  String get levelUpScreenContinueClassBlockedSubtitle =>
      'Ce niveau nécessite un choix pas encore disponible dans l\'app.';

  @override
  String levelUpScreenContinueClassSubtitle(int currentLevel, int nextLevel) {
    return 'Vous progressez dans votre voie actuelle (niveau $currentLevel → $nextLevel).';
  }

  @override
  String levelUpScreenMulticlassOptionTitle(String className) {
    return 'Se multiclasser en $className';
  }

  @override
  String levelUpScreenMulticlassOptionSubtitle(String abilities) {
    return 'Vous débutez au niveau 1 dans cette classe. Prérequis rempli : $abilities.';
  }

  @override
  String levelUpScreenMulticlassInfoBanner(String className) {
    return 'Nouvelle classe : $className (niveau 1)';
  }

  @override
  String get levelUpScreenUpcomingStepsTitle =>
      'À venir dans les prochaines étapes';

  @override
  String levelUpScreenUpcomingChoiceStep(String choiceLabel) {
    return 'Un choix de $choiceLabel vous attendra';
  }

  @override
  String get levelUpScreenUpcomingSpellsStep =>
      'Vos emplacements de sorts vont évoluer';

  @override
  String get levelUpScreenUpcomingInvocationsStep =>
      'De nouvelles invocations vous attendront';

  @override
  String get levelUpScreenUpcomingElementalDisciplinesStep =>
      'De nouvelles disciplines élémentaires vous attendront';

  @override
  String get levelUpScreenUpcomingManeuversStep =>
      'De nouvelles manœuvres vous attendront';

  @override
  String get levelUpScreenUpcomingArcaneShotsStep =>
      'De nouveaux tirs arcaniques vous attendront';

  @override
  String get levelUpScreenUpcomingRunesStep =>
      'De nouvelles runes vous attendront';

  @override
  String get levelUpScreenUpcomingInfusionsStep => 'Vos infusions vont évoluer';

  @override
  String get levelUpScreenContinueButton => 'Continuer';

  @override
  String get levelUpScreenBackButton => 'Retour';

  @override
  String get levelUpScreenNewFeatureTitle => 'Nouvelle aptitude';

  @override
  String get levelUpScreenNewProficiencyTitle => 'Nouvelle maîtrise';

  @override
  String levelUpScreenHpStepLabel(int totalSteps) {
    return 'Étape 1 sur $totalSteps · Points de vie';
  }

  @override
  String get levelUpScreenMaxHpTitle => 'Points de vie maximum';

  @override
  String levelUpScreenMaxHpDelta(int oldHp, int newHp, int gain) {
    return '$oldHp → $newHp (+$gain)';
  }

  @override
  String levelUpScreenHitDieMulticlassLabel(String className, int hitDie) {
    return 'Dé de vie de $className (niveau 1) : d$hitDie';
  }

  @override
  String levelUpScreenHitDieClassLabel(int hitDie) {
    return 'Dé de vie de la classe : d$hitDie';
  }

  @override
  String levelUpScreenRollHitDieOption(int hitDie) {
    return 'Lancer le dé (d$hitDie)';
  }

  @override
  String levelUpScreenAverageHitDieOption(int average) {
    return 'Valeur moyenne ($average)';
  }

  @override
  String levelUpScreenConstitutionModifierLabel(String modifier) {
    return '$modifier modificateur de Constitution';
  }

  @override
  String get levelUpScreenRerollDieLink => 'Relancer le dé';

  @override
  String get levelUpScreenAverageDieFormulaHint =>
      '(moitié du dé arrondie au supérieur, +1)';

  @override
  String get levelUpScreenLevelHistoryLink => 'Voir l\'historique des niveaux';

  @override
  String levelUpScreenAbilitiesStepLabel(int totalSteps) {
    return 'Étape 2 sur $totalSteps · Aptitudes de classe';
  }

  @override
  String levelUpScreenAbilitiesStepLabelWithProficiencies(int totalSteps) {
    return 'Étape 2 sur $totalSteps · Aptitudes & maîtrises';
  }

  @override
  String get levelUpScreenAutomaticFeaturesLabel =>
      'Vous obtenez automatiquement :';

  @override
  String get levelUpScreenMulticlassProficienciesLabel =>
      'Maîtrises de multiclassage :';

  @override
  String levelUpScreenChoiceStepLabel(int totalSteps, String choiceLabel) {
    return 'Étape 3 sur $totalSteps · $choiceLabel';
  }

  @override
  String get levelUpScreenChoiceKindAbilityScoreImprovement =>
      'Amélioration ou don';

  @override
  String get levelUpScreenChoiceKindSubclass => 'Sous-classe';

  @override
  String get levelUpScreenChoiceKindFightingStyle => 'Style de combat';

  @override
  String get levelUpScreenChoiceKindFavoredEnemy => 'Ennemi juré';

  @override
  String get levelUpScreenChoiceKindPact => 'Faveur de pacte';

  @override
  String get levelUpScreenChooseSubclassInstruction =>
      'Choisissez une sous-classe.';

  @override
  String get levelUpScreenChooseFightingStyleInstruction =>
      'Choisissez un style de combat.';

  @override
  String get levelUpScreenChooseFavoredEnemyInstruction =>
      'Choisissez un ennemi juré.';

  @override
  String get levelUpScreenChoosePactInstruction =>
      'Choisissez votre Faveur de pacte.';

  @override
  String get levelUpScreenChooseProgressionInstruction =>
      'Choisissez comment progresser.';

  @override
  String get levelUpScreenAllocateAbilityOption => 'Répartir +2';

  @override
  String get levelUpScreenChooseFeatOption => 'Choisir un don';

  @override
  String get levelUpScreenChooseFeatInstruction => 'Choisissez un don.';

  @override
  String levelUpScreenFeatAbilityIncreaseLabel(String featName) {
    return 'Caractéristique augmentée par $featName (+1) :';
  }

  @override
  String levelUpScreenAllocateBudgetInstruction(int budget) {
    return 'Répartissez $budget points entre vos caractéristiques.';
  }

  @override
  String levelUpScreenPointsRemainingLabel(int remaining, int budget) {
    return 'Points restants : $remaining/$budget';
  }

  @override
  String get levelUpScreenAllPointsAllocatedLabel =>
      'Tous les points sont répartis.';

  @override
  String levelUpScreenAbilityScoreDelta(int oldScore, int newScore, int alloc) {
    return '$oldScore → $newScore (+$alloc)';
  }

  @override
  String levelUpScreenSpellSlotsStepLabel(int stepNumber, int totalSteps) {
    return 'Étape $stepNumber sur $totalSteps · Emplacements de sorts';
  }

  @override
  String get levelUpScreenSpellSlotsRecalculatedLabel =>
      'Vos emplacements de sorts sont recalculés :';

  @override
  String get levelUpScreenNoSpellSlotsAtThisLevel =>
      'Aucun emplacement de sorts à ce niveau.';

  @override
  String levelUpScreenSpellsStepLabel(int stepNumber, int totalSteps) {
    return 'Étape $stepNumber sur $totalSteps · Sorts';
  }

  @override
  String get levelUpScreenCantripTab => 'Mineurs';

  @override
  String get levelUpScreenSpellsTab => 'Sorts';

  @override
  String get levelUpScreenPactTab => 'Grimoire';

  @override
  String get levelUpScreenKnownCantripsTitle => 'SORTS MINEURS CONNUS';

  @override
  String get levelUpScreenShadowBookTitle => 'LIVRE DES OMBRES';

  @override
  String get levelUpScreenKnownSpellsTitle => 'NOUVEAUX SORTS CONNUS';

  @override
  String levelUpScreenQuotaBadge(int selected, int quota) {
    return '$selected / $quota';
  }

  @override
  String levelUpScreenSpellMetaLineWithLevel(String metaLine, int level) {
    return '$metaLine (niveau $level)';
  }

  @override
  String levelUpScreenPatronSpellSubtitle(String baseSubtitle) {
    return '$baseSubtitle · Patron';
  }

  @override
  String levelUpScreenInvocationsStepLabel(int stepNumber, int totalSteps) {
    return 'Étape $stepNumber sur $totalSteps · Invocations';
  }

  @override
  String get levelUpScreenKnownInvocationsTitle => 'INVOCATIONS CONNUES';

  @override
  String get levelUpScreenNoMoreInvocationsMessage =>
      'Vous connaissez déjà toutes les invocations occultistes disponibles.';

  @override
  String levelUpScreenElementalDisciplinesStepLabel(
    int stepNumber,
    int totalSteps,
  ) {
    return 'Étape $stepNumber sur $totalSteps · Disciplines élémentaires';
  }

  @override
  String get levelUpScreenKnownElementalDisciplinesTitle =>
      'DISCIPLINES ÉLÉMENTAIRES CONNUES';

  @override
  String get levelUpScreenNoMoreElementalDisciplinesMessage =>
      'Vous connaissez déjà toutes les disciplines élémentaires disponibles à ce niveau.';

  @override
  String levelUpScreenManeuversStepLabel(int stepNumber, int totalSteps) {
    return 'Étape $stepNumber sur $totalSteps · Manœuvres';
  }

  @override
  String get levelUpScreenKnownManeuversTitle => 'MANŒUVRES CONNUES';

  @override
  String get levelUpScreenNoMoreManeuversMessage =>
      'Vous connaissez déjà toutes les manœuvres disponibles.';

  @override
  String levelUpScreenArcaneShotsStepLabel(int stepNumber, int totalSteps) {
    return 'Étape $stepNumber sur $totalSteps · Tirs arcaniques';
  }

  @override
  String get levelUpScreenKnownArcaneShotsTitle => 'TIRS ARCANIQUES CONNUS';

  @override
  String get levelUpScreenNoMoreArcaneShotsMessage =>
      'Vous connaissez déjà tous les tirs arcaniques disponibles.';

  @override
  String levelUpScreenRunesStepLabel(int stepNumber, int totalSteps) {
    return 'Étape $stepNumber sur $totalSteps · Runes';
  }

  @override
  String get levelUpScreenKnownRunesTitle => 'RUNES CONNUES';

  @override
  String get levelUpScreenNoMoreRunesMessage =>
      'Vous connaissez déjà toutes les runes disponibles.';

  @override
  String levelUpScreenInfusionsStepLabel(int stepNumber, int totalSteps) {
    return 'Étape $stepNumber sur $totalSteps · Infusions';
  }

  @override
  String get levelUpScreenNewInfusionsTitle => 'NOUVELLES INFUSIONS';

  @override
  String get levelUpScreenNoMoreInfusionsMessage =>
      'Vous connaissez déjà toutes les infusions disponibles.';

  @override
  String get levelUpScreenReplaceInfusionOptionalTitle =>
      'REMPLACER UNE INFUSION (OPTIONNEL)';

  @override
  String get levelUpScreenReplacedByLabel => 'REMPLACÉE PAR';

  @override
  String levelUpScreenMetamagicStepLabel(int stepNumber, int totalSteps) {
    return 'Étape $stepNumber sur $totalSteps · Métamagie';
  }

  @override
  String get levelUpScreenNewMetamagicOptionsTitle =>
      'NOUVELLES OPTIONS DE MÉTAMAGIE';

  @override
  String get levelUpScreenNoMoreMetamagicMessage =>
      'Vous connaissez déjà toutes les options de Métamagie disponibles.';

  @override
  String get levelUpScreenReplaceMetamagicOptionalTitle =>
      'REMPLACER UNE OPTION (OPTIONNEL)';

  @override
  String levelUpScreenExpertiseStepLabel(int stepNumber, int totalSteps) {
    return 'Étape $stepNumber sur $totalSteps · Expertise';
  }

  @override
  String get levelUpScreenExpertiseSkillsTitle => 'COMPÉTENCES EN EXPERTISE';

  @override
  String get levelUpScreenThievesToolsLabel => 'Outils de voleur';

  @override
  String get levelUpScreenThievesToolsSubstitutionHint =>
      'Substitue une des places d\'Expertise à la maîtrise des outils de voleur.';

  @override
  String get levelUpScreenNoExpertiseCandidatesMessage =>
      'Aucune compétence déjà maîtrisée à faire passer en Expertise.';

  @override
  String levelUpScreenDraconicAncestryStepLabel(
    int stepNumber,
    int totalSteps,
  ) {
    return 'Étape $stepNumber sur $totalSteps · Ascendance draconique';
  }

  @override
  String get levelUpScreenDamageTypeTitle => 'TYPE DE DÉGÂTS';

  @override
  String get levelUpScreenNewSpellSlotsTitle =>
      'Nouveaux emplacements de sorts';

  @override
  String get levelUpScreenReinforcedSpellSlotsTitle =>
      'Emplacements de sorts renforcés';

  @override
  String levelUpScreenSpellSlotUnlockedSubtitle(int spellLevel) {
    return 'Niveau $spellLevel débloqué';
  }

  @override
  String levelUpScreenSpellSlotReinforcedSubtitle(
    int spellLevel,
    int oldTotal,
    int newTotal,
    int delta,
  ) {
    return 'Niveau $spellLevel : $oldTotal → $newTotal (+$delta)';
  }

  @override
  String get levelUpScreenPactMagicUnlockedTitle => 'Magie de pacte débloquée';

  @override
  String levelUpScreenPactMagicUnlockedSubtitle(int slotLevel, int charges) {
    return 'Niveau $slotLevel · $charges charge(s)';
  }

  @override
  String get levelUpScreenPactChargesReinforcedTitle =>
      'Charges de pacte renforcées';

  @override
  String levelUpScreenPactChargesReinforcedSubtitle(
    int oldCharges,
    int newCharges,
    int slotLevel,
  ) {
    return '$oldCharges → $newCharges charges (niveau $slotLevel)';
  }

  @override
  String get levelUpScreenPactChargesImprovedTitle =>
      'Charges de pacte améliorées';

  @override
  String levelUpScreenPactChargesImprovedSubtitle(
    int oldSlotLevel,
    int newSlotLevel,
    int newCharges,
  ) {
    return 'Niveau $oldSlotLevel → $newSlotLevel ($newCharges charges)';
  }

  @override
  String levelUpScreenPactChargesBothSubtitle(
    int oldCharges,
    int newCharges,
    int oldSlotLevel,
    int newSlotLevel,
  ) {
    return '$oldCharges → $newCharges charges, niveau $oldSlotLevel → $newSlotLevel';
  }

  @override
  String get levelUpScreenFeatSummaryTitle => 'Don';

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
      'Amélioration de caractéristique';

  @override
  String get levelUpScreenNewCantripsTitle => 'Nouveaux sorts mineurs';

  @override
  String get levelUpScreenNewSpellsLearnedTitle => 'Nouveaux sorts appris';

  @override
  String get levelUpScreenShadowBookGainTitle => 'Livre des ombres';

  @override
  String get levelUpScreenFamiliarAddedTitle => 'Appel de familier ajouté';

  @override
  String get levelUpScreenChainPactSubtitle => 'Pacte de la chaîne';

  @override
  String get levelUpScreenRacialInnateSpellTitle => 'Sort inné racial';

  @override
  String levelUpScreenNewInvocationsSummaryTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nouvelles invocations occultistes',
      one: 'Nouvelle invocation occultiste',
    );
    return '$_temp0';
  }

  @override
  String levelUpScreenNewElementalDisciplinesSummaryTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nouvelles disciplines élémentaires',
      one: 'Nouvelle discipline élémentaire',
    );
    return '$_temp0';
  }

  @override
  String levelUpScreenNewManeuversSummaryTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nouvelles manœuvres',
      one: 'Nouvelle manœuvre',
    );
    return '$_temp0';
  }

  @override
  String levelUpScreenNewArcaneShotsSummaryTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nouveaux tirs arcaniques',
      one: 'Nouveau tir arcanique',
    );
    return '$_temp0';
  }

  @override
  String levelUpScreenNewRunesSummaryTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nouvelles runes',
      one: 'Nouvelle rune',
    );
    return '$_temp0';
  }

  @override
  String levelUpScreenNewInfusionsSummaryTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nouvelles infusions',
      one: 'Nouvelle infusion',
    );
    return '$_temp0';
  }

  @override
  String get levelUpScreenInfusionSwapTitle => 'Infusion remplacée';

  @override
  String levelUpScreenSwapSubtitle(String removedName, String addedName) {
    return '$removedName → $addedName';
  }

  @override
  String levelUpScreenNewMetamagicOptionsSummaryTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nouvelles options de Métamagie',
      one: 'Nouvelle option de Métamagie',
    );
    return '$_temp0';
  }

  @override
  String get levelUpScreenMetamagicSwapTitle => 'Métamagie remplacée';

  @override
  String levelUpScreenExpertiseSummaryTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Expertises',
      one: 'Expertise',
    );
    return '$_temp0';
  }

  @override
  String get levelUpScreenDraconicAncestryTitle => 'Ascendance draconique';

  @override
  String get levelUpScreenNoNewFeaturesMessage =>
      'Aucune nouvelle aptitude de classe à ce niveau.';

  @override
  String get levelUpScreenNoOptionAvailableMessage =>
      'Aucune option disponible pour ce choix.';

  @override
  String levelUpScreenBlockedLevelTitle(int level) {
    return 'Niveau $level : choix requis';
  }

  @override
  String get levelUpScreenBackToSheetButton => 'Retour à la fiche';

  @override
  String get levelUpScreenRetryButton => 'Réessayer';

  @override
  String get characterClassChoicesCardTitle => 'CHOIX DE CLASSE';

  @override
  String get characterClassChoicesCardSubclassLabel => 'Sous-classe';

  @override
  String characterClassChoicesCardSubclassLabelWithClass(String className) {
    return 'Sous-classe ($className)';
  }

  @override
  String get characterClassFeaturesCardTitle => 'APTITUDES DE CLASSE';

  @override
  String get characterClassFeaturesCardPassiveLabel => 'Passive';

  @override
  String get characterFeatsCardTitle => 'DONS';

  @override
  String get characterRacialTraitsCardTitle => 'TRAITS RACIAUX';

  @override
  String get characterRacialTraitsCardPassiveLabel => 'Passive';

  @override
  String get characterRaceChoicesCardTitle => 'CHOIX DE RACE';

  @override
  String get characterRaceChoicesCardSkillLabel => 'Compétence';

  @override
  String get characterRaceChoicesCardToolLabel => 'Outil';

  @override
  String get characterArmorProficienciesCardTitle => 'MAÎTRISES D\'ARMURES';

  @override
  String get characterWeaponProficienciesCardTitle => 'MAÎTRISES D\'ARMES';

  @override
  String get characterToolProficienciesCardTitle => 'MAÎTRISES D\'OUTILS';

  @override
  String get characterLanguagesCardTitle => 'LANGUES CONNUES';

  @override
  String get characterInvocationsCardTitle => 'INVOCATIONS CONNUES';

  @override
  String get characterPactWeaponCardTitle => 'ARME DE PACTE';

  @override
  String get characterPactWeaponCardCursedBladeText =>
      'Lame maudite : vous pouvez utiliser le Charisme à la place de la Force ou de la Dextérité pour l\'attaque et les dégâts.';

  @override
  String get characterPactWeaponCardReminderText =>
      'Invoquée par une action. Disparaît si elle reste à plus de 1,50 m de vous pendant 1 minute, ou si vous l\'invoquez à nouveau.';

  @override
  String get characterPactWeaponCardMagicWeaponChip => 'Arme magique';

  @override
  String get characterPactWeaponCardProficientChip => 'Maîtrisée';

  @override
  String get characterPactWeaponCardEmptyTitle => 'Aucune forme choisie';

  @override
  String get characterPactWeaponCardEmptyDescription =>
      'Choisissez la forme que prend votre arme lorsque vous l\'invoquez.';

  @override
  String get characterPactWeaponCardChooseFormButton => 'Choisir une forme';

  @override
  String get characterPactWeaponCardChangeFormButton => 'Changer de forme';

  @override
  String characterPactWeaponCardSemanticLabel(String name) {
    return 'Arme de pacte : $name';
  }

  @override
  String characterPactWeaponCardSemanticLabelWithDamage(
    String name,
    String damage,
  ) {
    return 'Arme de pacte : $name, $damage';
  }

  @override
  String get classFeatureActionSheetInfoLabel => 'Infos';

  @override
  String get classFeatureActionSheetUseLabel => 'Utiliser';

  @override
  String get classFeatureActionSheetExhaustedLabel => 'Épuisée';

  @override
  String classFeatureInfoPanelObtainedAtLevel(int level) {
    return 'Obtenue au niveau $level.';
  }

  @override
  String get classFeatureInfoPanelUsesLabel => 'Utilisations';

  @override
  String get classFeatureInfoPanelPassiveLabel => 'Passive';

  @override
  String get classFeatureInfoPanelDescriptionLabel => 'DESCRIPTION';

  @override
  String get classFeatureInfoPanelDescriptionUnavailable =>
      'Description indisponible.';

  @override
  String get classFeatureInfoPanelUseButton => 'Utiliser';

  @override
  String featInfoPanelPrerequisiteLabel(String prerequisite) {
    return 'Prérequis : $prerequisite';
  }

  @override
  String get featInfoPanelDescriptionLabel => 'DESCRIPTION';

  @override
  String get racialTraitInfoPanelDescriptionLabel => 'DESCRIPTION';

  @override
  String get racialTraitInfoPanelDescriptionUnavailable =>
      'Description indisponible.';

  @override
  String get proficiencyDetailPanelLoadErrorMessage =>
      'Impossible de charger le catalogue. Réessayez.';

  @override
  String get proficiencyDetailPanelNoNonMetallicShieldMessage =>
      'Aucun bouclier non métallique disponible dans le catalogue actuel.';

  @override
  String get proficiencyDetailPanelNoMatchingItemMessage =>
      'Aucun objet correspondant disponible dans le catalogue actuel.';

  @override
  String get proficiencyDetailPanelPropertiesLabel => 'Propriétés : ';

  @override
  String get proficiencyDetailPanelAcLabel => 'CA';

  @override
  String get proficiencyDetailPanelAcBaseLabel => 'CA de base';

  @override
  String get proficiencyDetailPanelDexBonusLabel => 'Bonus Dex';

  @override
  String get proficiencyDetailPanelStrengthRequirementLabel => 'Force requise';

  @override
  String get proficiencyDetailPanelStealthDisadvantageLabel =>
      'Désavantage discrétion';

  @override
  String get proficiencyDetailPanelYesLabel => 'Oui';

  @override
  String get pactWeaponPickerSheetTitle => 'FORME DE L\'ARME';

  @override
  String get pactWeaponPickerSheetSearchHint => 'Rechercher une arme...';

  @override
  String get pactWeaponPickerSheetLoadErrorMessage =>
      'Impossible de charger les armes. Réessayez.';

  @override
  String get pactWeaponPickerSheetEmptyMessage => 'Aucune arme disponible.';

  @override
  String get pactWeaponPickerSheetNoResultsMessage => 'Aucune arme trouvée.';

  @override
  String get weaponSlotPickerSheetTitle => 'CHOISIR UN SET';

  @override
  String get weaponSlotPickerSheetEmptyLabel => 'Vide';

  @override
  String characterInventoryTabBodyFilterButtonLabel(String filterLabel) {
    return 'Filtre : $filterLabel';
  }

  @override
  String get characterInventoryTabBodyAddItemButtonLabel => 'Objet';

  @override
  String get characterInventoryTabBodyRewardButtonLabel => 'RÉCOMPENSE';

  @override
  String get characterInventoryTabBodyNoFilterMatchMessage =>
      'Aucun objet dans cette catégorie.';

  @override
  String get characterInventoryTabBodyEmptyTitle => 'INVENTAIRE VIDE';

  @override
  String get characterInventoryTabBodyEmptyMessage =>
      'Aucun objet dans cet inventaire pour l\'instant.';

  @override
  String characterInventoryItemCardSubtitle(String category, int quantity) {
    return '$category · x$quantity';
  }

  @override
  String get characterInventoryItemCardEquippedBadge => 'ÉQUIPÉ';

  @override
  String characterInventoryItemCardWeightValue(String weight) {
    return '$weight kg';
  }

  @override
  String get characterInventoryCapacityGaugeTitle => 'CHARGE';

  @override
  String characterInventoryCapacityGaugeValueLabel(
    String weight,
    String capacity,
  ) {
    return '$weight / $capacity kg';
  }

  @override
  String get characterInventoryCapacityGaugeOverloadedWarning =>
      'Surchargé — poids supérieur à la capacité de transport.';

  @override
  String characterInventoryCapacityGaugeSemanticsLabel(
    String weight,
    String capacity,
  ) {
    return 'Charge : $weight kilogrammes sur $capacity kilogrammes';
  }

  @override
  String characterInventoryCapacityGaugeSemanticsLabelOverloaded(
    String weight,
    String capacity,
  ) {
    return 'Charge : $weight kilogrammes sur $capacity kilogrammes, surchargé';
  }

  @override
  String get characterEquippedWeaponsCardTitle => 'ARMES ÉQUIPÉES';

  @override
  String get characterEquippedWeaponsCardPrimarySetTitle => 'SET PRINCIPAL';

  @override
  String get characterEquippedWeaponsCardSecondarySetTitle => 'SET SECONDAIRE';

  @override
  String get characterEquippedWeaponsCardEmptySetMessage =>
      'Aucune arme dans ce set.';

  @override
  String get characterEquippedWeaponsCardAttackLabel => 'Attaque';

  @override
  String get characterEquippedWeaponsCardEmptyTitle => 'Aucune arme équipée';

  @override
  String get characterEquippedWeaponsCardEmptyDescription =>
      'Équipez une arme depuis l\'onglet Inventaire pour qu\'elle apparaisse ici.';

  @override
  String characterEquippedWeaponsCardSemanticsLabel(String name) {
    return 'Arme équipée : $name';
  }

  @override
  String characterEquippedWeaponsCardSemanticsAttackSuffix(String attackBonus) {
    return ', Attaque : $attackBonus';
  }

  @override
  String characterEquippedWeaponsCardSemanticsRangeSuffix(String range) {
    return ', Portée : $range';
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
  String get addItemFlowCatalogEntryLabel => 'Depuis le catalogue';

  @override
  String get addItemFlowCustomEntryLabel => 'Objet personnalisé';

  @override
  String get addItemFlowCatalogTitleSingle => 'AJOUTER UN OBJET';

  @override
  String get addItemFlowCatalogTitleMulti => 'AJOUTER DES OBJETS';

  @override
  String get addItemFlowSearchHint => 'Rechercher un objet...';

  @override
  String get addItemFlowCatalogLoadErrorMessage =>
      'Impossible de charger le catalogue d\'objets. Réessayez.';

  @override
  String get addItemFlowAddButtonLabel => 'Ajouter';

  @override
  String addItemFlowAddButtonLabelWithCount(int count) {
    return 'Ajouter ($count)';
  }

  @override
  String get addItemFlowNoResultsMessage => 'Aucun objet trouvé.';

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
    return 'Ajouter $itemName';
  }

  @override
  String get addItemFlowQuantitySheetAddButton => 'Ajouter';

  @override
  String get addItemFlowCustomSheetTitle => 'OBJET PERSONNALISÉ';

  @override
  String get addItemFlowCustomNameSectionLabel => 'NOM DE L\'OBJET';

  @override
  String get addItemFlowCustomNameHint => 'Ex. Amulette de famille';

  @override
  String get addItemFlowCustomDescriptionSectionLabel => 'DESCRIPTION';

  @override
  String get addItemFlowCustomDescriptionHint =>
      'Ex. Un médaillon gravé aux armes de votre famille.';

  @override
  String get addItemFlowCustomTypeSectionLabel => 'TYPE D\'OBJET';

  @override
  String get addItemFlowCustomTypeSimpleOption => 'Objet simple';

  @override
  String get addItemFlowCustomTypeWeaponOption => 'Arme';

  @override
  String get addItemFlowCustomDiceSectionLabel => 'DÉ DE DÉGÂTS';

  @override
  String get addItemFlowCustomDiceNotationSeparator => 'd';

  @override
  String get addItemFlowCustomDamageTypeSectionLabel => 'TYPE DE DÉGÂTS';

  @override
  String get addItemFlowCustomDamageTypeHint => 'Sélectionner';

  @override
  String get addItemFlowDamageTypeSlashingLabel => 'Tranchant';

  @override
  String get addItemFlowDamageTypePiercingLabel => 'Perforant';

  @override
  String get addItemFlowDamageTypeBludgeoningLabel => 'Contondant';

  @override
  String get addItemFlowCustomPropertiesSectionLabel => 'PROPRIÉTÉS';

  @override
  String get addItemFlowCustomPropertiesHint => 'Ex. légère, finesse';

  @override
  String get addItemFlowCustomPropertiesCaption =>
      'Séparez plusieurs propriétés par une virgule.';

  @override
  String get addItemFlowCustomQuantitySectionLabel => 'QUANTITÉ';

  @override
  String get addItemFlowCustomCancelButton => 'Annuler';

  @override
  String get addItemFlowCustomAddButton => 'Ajouter';

  @override
  String get itemActionSheetInfoLabel => 'Infos';

  @override
  String get itemActionSheetUseLabel => 'Utiliser';

  @override
  String get itemActionSheetEquipLabel => 'Équiper';

  @override
  String get itemActionSheetChangeSetLabel => 'Changer de set';

  @override
  String get itemActionSheetUnequipLabel => 'Déséquiper';

  @override
  String get itemActionSheetAttuneLabel => 'Harmoniser cet objet';

  @override
  String get itemActionSheetStopAttuneLabel => 'Ne plus harmoniser';

  @override
  String itemActionSheetAttunementCapReachedLabel(int cap) {
    return 'Limite ($cap) atteinte';
  }

  @override
  String get itemActionSheetRemoveLabel => 'Retirer';

  @override
  String itemActionSheetSubtitle(String category, int quantity) {
    return '$category · x$quantity';
  }

  @override
  String itemActionSheetRemoveConfirmationTitle(String itemName) {
    return 'Retirer $itemName ?';
  }

  @override
  String get itemActionSheetRemoveConfirmationBody =>
      'Cette action est définitive.';

  @override
  String get itemActionSheetRemoveConfirmationCancelButton => 'Annuler';

  @override
  String get itemActionSheetRemoveConfirmationConfirmButton => 'Retirer';

  @override
  String get itemInfoPanelWeightLabel => 'Poids unitaire';

  @override
  String itemInfoPanelWeightValue(String weight) {
    return '$weight kg';
  }

  @override
  String get itemInfoPanelCostLabel => 'Coût';

  @override
  String itemInfoPanelCostValue(String cost) {
    return '$cost po';
  }

  @override
  String get itemInfoPanelSetLabel => 'Set';

  @override
  String get itemInfoPanelAttackLabel => 'Attaque';

  @override
  String get itemInfoPanelDamageLabel => 'Dégâts';

  @override
  String get itemInfoPanelPropertiesLabel => 'Propriétés';

  @override
  String get itemInfoPanelRangeLabel => 'Portée';

  @override
  String itemInfoPanelRangeValue(String rangeNormal) {
    return '$rangeNormal m';
  }

  @override
  String itemInfoPanelRangeValueWithMax(String rangeNormal, String rangeMax) {
    return '$rangeNormal m (max $rangeMax m)';
  }

  @override
  String get itemInfoPanelArmorClassLabel => 'CA de base';

  @override
  String get itemInfoPanelDexBonusLabel => 'Bonus Dex';

  @override
  String get itemInfoPanelStrengthRequirementLabel => 'Force requise';

  @override
  String get itemInfoPanelStealthDisadvantageLabel => 'Désavantage discrétion';

  @override
  String get itemInfoPanelYesLabel => 'Oui';

  @override
  String get itemInfoPanelNoLabel => 'Non';

  @override
  String get itemInfoPanelRarityLabel => 'Rareté';

  @override
  String get itemInfoPanelDescriptionSectionLabel => 'DESCRIPTION';

  @override
  String get itemInfoPanelDescriptionUnavailable =>
      'Aucune description disponible.';

  @override
  String get itemInfoPanelUseButton => 'Utiliser';

  @override
  String get itemInfoPanelEquipButton => 'Équiper';

  @override
  String get itemInfoPanelUnequipButton => 'Déséquiper';

  @override
  String get itemInfoPanelAttuneLabel => 'Harmoniser cet objet';

  @override
  String get itemInfoPanelStopAttuneLabel => 'Ne plus harmoniser';

  @override
  String itemInfoPanelAttunementCapReachedCaption(int cap) {
    String _temp0 = intl.Intl.pluralLogic(
      cap,
      locale: localeName,
      other: 'Limite de $cap objets harmonisés atteinte.',
      one: 'Limite de 1 objet harmonisé atteinte.',
    );
    return '$_temp0';
  }

  @override
  String currencyAdjustmentSheetTitle(String currencyLabel) {
    return 'Ajuster les $currencyLabel';
  }

  @override
  String get currencyAdjustmentSheetAddOption => 'Ajouter';

  @override
  String get currencyAdjustmentSheetRemoveOption => 'Retirer';

  @override
  String get currencyAdjustmentSheetCancelButton => 'Annuler';

  @override
  String get currencyAdjustmentSheetApplyButton => 'Appliquer';

  @override
  String get currencyAdjustmentSheetConvertButton => 'Changer';

  @override
  String get numericAmountDecreaseLabel => 'Diminuer';

  @override
  String get numericAmountIncreaseLabel => 'Augmenter';

  @override
  String get hpAdjustmentSheetAmountFieldLabel => 'Montant de PV';

  @override
  String get currencyAdjustmentSheetAmountFieldLabel => 'Montant';

  @override
  String numericAmountMaxHint(int max) {
    return 'Max $max';
  }

  @override
  String currencyAdjustmentSheetBalanceHint(int balance) {
    return 'Solde : $balance';
  }

  @override
  String get currencyConversionSheetTitle => 'Changer des pièces';

  @override
  String get currencyConversionSheetFromLabel => 'PIÈCE À CHANGER';

  @override
  String get currencyConversionSheetToLabel => 'CONTRE';

  @override
  String get currencyConversionSheetAmountLabel => 'MONTANT À CHANGER';

  @override
  String currencyConversionSheetPreview(
    int spent,
    String fromUnit,
    int obtained,
    String toUnit,
  ) {
    return '$spent $fromUnit contre $obtained $toUnit';
  }

  @override
  String currencyConversionSheetRemainder(int unconverted, String fromUnit) {
    return '$unconverted $fromUnit non converties restent dans votre bourse.';
  }

  @override
  String get currencyConversionSheetTooSmall =>
      'Ce montant ne suffit pas pour obtenir une pièce entière.';

  @override
  String get currencyConversionSheetNothingToConvert =>
      'Aucune pièce à changer.';

  @override
  String get currencyConversionSheetCancelButton => 'Annuler';

  @override
  String get currencyConversionSheetApplyButton => 'Changer';

  @override
  String get inventoryCategoryFilterSheetTitle => 'FILTRER PAR CATÉGORIE';

  @override
  String get characterSpellsSectionTitle => 'SORTS';

  @override
  String characterSpellsSectionPactLabel(int level) {
    return 'Magie de pacte — Niveau $level';
  }

  @override
  String characterSpellsSectionPactSlotsSemanticLabel(
    int remaining,
    int total,
    int level,
  ) {
    return 'Emplacements de pacte : $remaining restants sur $total (niveau $level)';
  }

  @override
  String characterSpellsSectionSlotsSemanticLabel(int remaining, int total) {
    return 'Emplacements de sorts : $remaining restants sur $total';
  }

  @override
  String characterSpellsSectionSlotLevelSemanticLabel(
    int level,
    int remaining,
    int total,
  ) {
    return 'Niveau $level : $remaining sur $total emplacements disponibles';
  }

  @override
  String characterSpellsSectionGrantBadgeSemanticLabel(String sourceLabel) {
    return 'Toujours préparé, accordé par : $sourceLabel';
  }

  @override
  String get characterSpellsSectionInnateBadgeLabel => 'INNÉ';

  @override
  String get characterSpellsSectionInnateExhaustedLabel => 'Épuisé';

  @override
  String characterSpellsSectionInnateAvailableSemanticLabel(
    int remaining,
    int max,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: '$remaining utilisations restantes',
      one: '1 utilisation restante',
    );
    return 'Sort inné, sans emplacement, $_temp0 sur $max, repos long';
  }

  @override
  String get characterSpellsSectionInnateExhaustedSemanticLabel =>
      'Sort inné, épuisé, disponible après un repos long';

  @override
  String get characterSpellsTabBodyLimitedUseFeaturesCardTitle =>
      'INVOCATIONS & APTITUDES À USAGE LIMITÉ';

  @override
  String get characterSpellsTabBodySearchHint => 'Rechercher un sort';

  @override
  String get characterSpellsTabBodySearchClearTooltip => 'Effacer';

  @override
  String get characterSpellsTabBodyNoMatchAllLabel => 'Aucun sort';

  @override
  String get characterSpellsTabBodyNoMatchPreparedLabel => 'Aucun sort préparé';

  @override
  String get characterSpellsTabBodyNoMatchUnpreparedLabel =>
      'Aucun sort non préparé';

  @override
  String characterSpellsTabBodyNoMatchMessageEmpty(String kind) {
    return '$kind.';
  }

  @override
  String characterSpellsTabBodyNoMatchMessageQuery(String kind, String query) {
    return '$kind pour « $query ».';
  }

  @override
  String get characterSpellsTabBodyEmptyStateTitle => 'AUCUN SORT';

  @override
  String get characterSpellsTabBodyEmptyStateBody =>
      'Aucun sort sur cette fiche pour l\'instant. Pour les classes qui lancent des sorts, ils se choisissent depuis l\'assistant de création ou à la montée de niveau.';

  @override
  String get characterSpellsTabBodyNonCasterMessage =>
      'Ce personnage ne lance pas de sorts.';

  @override
  String get characterSpellsTabBodyResourcesTitle => 'RESSOURCES';

  @override
  String get characterSpellsTabBodySlotsCardTitle => 'EMPLACEMENTS DE SORTS';

  @override
  String characterSpellsTabBodySlotsLevelLabel(int level) {
    return 'Niveau $level';
  }

  @override
  String spellActionSheetTitle(String spellName) {
    return 'Lancer $spellName';
  }

  @override
  String get spellActionSheetSubtitle =>
      'Choisissez le niveau d\'emplacement à utiliser.';

  @override
  String get spellActionSheetCancelButton => 'Annuler';

  @override
  String get spellActionSheetCastButton => 'Lancer';

  @override
  String get spellActionSheetSlotExhaustedLabel => 'Épuisé';

  @override
  String spellActionSheetSlotRemainingLabel(int remaining, int total) {
    return '$remaining/$total restants';
  }

  @override
  String spellActionSheetPactSlotLevelLabel(int level) {
    return 'Niveau $level (pacte)';
  }

  @override
  String spellActionSheetSlotLevelLabel(int level) {
    return 'Niveau $level';
  }

  @override
  String get spellInfoPanelUsagesLabel => 'Utilisations';

  @override
  String get spellInfoPanelCastingTimeLabel => 'Temps d\'incantation';

  @override
  String get spellInfoPanelRangeLabel => 'Portée';

  @override
  String get spellInfoPanelDurationLabel => 'Durée';

  @override
  String get spellInfoPanelConcentrationLabel => 'Concentration';

  @override
  String get spellInfoPanelConcentrationYes => 'Oui';

  @override
  String get spellInfoPanelConcentrationNo => 'Non';

  @override
  String spellInfoPanelGrantSourceNote(String sourceLabel) {
    return 'Toujours préparé — sort de $sourceLabel (ne compte pas dans la limite de sorts préparés)';
  }

  @override
  String spellInfoPanelInnateNote(int usesPerLongRest) {
    return 'Sort inné — se lance sans emplacement, $usesPerLongRest fois par repos long';
  }

  @override
  String get spellInfoPanelDescriptionTitle => 'DESCRIPTION';

  @override
  String get spellInfoPanelCastButton => 'Lancer';

  @override
  String get spellInfoPanelCastInnateButton => 'Lancer (sort inné)';

  @override
  String get spellInfoPanelUnprepareLink => 'Ne plus préparer';

  @override
  String get spellInfoPanelPrepareLink => 'Préparer ce sort';

  @override
  String get spellInfoPanelComponentsLabel => 'Composantes';

  @override
  String get spellPreparationCardTitle => 'PRÉPARATION DES SORTS';

  @override
  String get spellPreparationCardInfoTooltip =>
      'Comment fonctionne la préparation des sorts ?';

  @override
  String spellPreparationCardClassLabel(String className) {
    return 'SORTS PRÉPARÉS — $className';
  }

  @override
  String get spellPreparationCardDefaultLabel => 'SORTS PRÉPARÉS';

  @override
  String spellPreparationCardOverLimitStatus(int overBy) {
    return 'Limite dépassée de $overBy';
  }

  @override
  String get spellPreparationCardLimitReachedStatus => 'Limite atteinte';

  @override
  String spellPreparationCardRemainingToPrepareStatus(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: 'Encore $remaining sorts à préparer',
      one: 'Encore 1 sort à préparer',
    );
    return '$_temp0';
  }

  @override
  String spellPreparationCardCounterSemanticLabel(
    String label,
    int count,
    int limit,
  ) {
    return '$label : $count sur $limit';
  }

  @override
  String get spellPreparationCardCounterOverLimitSuffix => ', limite dépassée';

  @override
  String get spellPreparationCardInfoEntryPrepareTitle =>
      'Préparer pour lancer';

  @override
  String get spellPreparationCardInfoEntryPrepareBody =>
      'Seuls les sorts préparés peuvent être lancés. Les sorts non préparés restent dans la liste, grisés, après les sorts préparés. Touchez un sort puis « Préparer ce sort » ou « Ne plus préparer ».';

  @override
  String get spellPreparationCardInfoEntryHowManyTitle => 'Combien de sorts ?';

  @override
  String spellPreparationCardInfoEntryHowManyBody(String limitsSentence) {
    return 'Clerc, Druide et Magicien : modificateur de caractéristique d\'incantation + niveau de classe. Paladin et Artificier (demi-lanceurs) : modificateur + moitié du niveau. Minimum 1. Multiclassé avec plusieurs classes qui préparent : chaque classe a sa propre limite, jamais un total commun.$limitsSentence Une fois la limite atteinte, impossible de préparer un nouveau sort de cette classe sans en dé-préparer un autre d\'abord.';
  }

  @override
  String spellPreparationCardSingleLimitSentence(int limit) {
    return ' Votre limite actuelle : $limit.';
  }

  @override
  String spellPreparationCardMultipleLimitsSentence(String limitsList) {
    return ' Vos limites actuelles : $limitsList.';
  }

  @override
  String get spellPreparationCardInfoEntryNoPreparationTitle =>
      'Sans préparation';

  @override
  String get spellPreparationCardInfoEntryNoPreparationBody =>
      'Les sorts mineurs, les sorts innés et les sorts de domaine ou de serment n\'ont jamais à être préparés et ne comptent pas dans la limite. Un sort inné de niveau 1 ou plus se lance sans emplacement, une fois par repos long.';

  @override
  String get spellPreparationCardInfoEntryCastDoesNotUnprepareTitle =>
      'Lancer ne dé-prépare pas';

  @override
  String get spellPreparationCardInfoEntryCastDoesNotUnprepareBody =>
      'Lancer un sort consomme un emplacement, mais le sort reste préparé : vous pouvez le relancer tant qu\'il vous reste des emplacements.';

  @override
  String get spellPreparationCardInfoEntryChangeListTitle => 'Changer sa liste';

  @override
  String get spellPreparationCardInfoEntryChangeListBody =>
      'La liste de sorts préparés se change après un repos long : le repos long vous propose de garder votre liste ou de la modifier.';

  @override
  String get prepareSpellsSheetTitle => 'PRÉPARER MES SORTS';

  @override
  String prepareSpellsSheetClassLabel(String className) {
    return 'SORTS PRÉPARÉS — $className';
  }

  @override
  String get prepareSpellsSheetSearchHint => 'Rechercher un sort';

  @override
  String get prepareSpellsSheetSearchClearTooltip => 'Effacer';

  @override
  String get prepareSpellsSheetNoMatchEmptyMessage => 'Aucun sort disponible.';

  @override
  String prepareSpellsSheetNoMatchQueryMessage(String query) {
    return 'Aucun sort pour « $query ».';
  }

  @override
  String prepareSpellsSheetInfoTooltip(String spellName) {
    return 'Description de $spellName';
  }

  @override
  String castInnateSpellConfirmationDialogTitle(String spellName) {
    return 'Lancer $spellName ?';
  }

  @override
  String get castInnateSpellConfirmationDialogMessage =>
      'Cette action consomme un usage de ce sort inné, récupéré seulement au prochain repos long.';

  @override
  String get castInnateSpellConfirmationDialogCancelButton => 'Annuler';

  @override
  String get castInnateSpellConfirmationDialogCastButton => 'Lancer';

  @override
  String characterDetailCastSpellSuccessMessage(String spellName) {
    return '$spellName lancé.';
  }

  @override
  String characterDetailCastSpellWithSlotSuccessMessage(
    String spellName,
    int slotLevel,
  ) {
    return '$spellName lancé (emplacement niveau $slotLevel).';
  }

  @override
  String get characterDetailCastSpellErrorMessage =>
      'Impossible de lancer ce sort. Réessayez.';

  @override
  String characterDetailCastPactSpellSuccessMessage(
    String spellName,
    int pactLevel,
  ) {
    return '$spellName lancé (emplacement de pacte niveau $pactLevel).';
  }

  @override
  String characterDetailCastInnateSpellSuccessMessage(String spellName) {
    return '$spellName lancé (sort inné).';
  }

  @override
  String get characterDetailInnateSpellSyncErrorMessage =>
      'Impossible de synchroniser les sorts innés. Réessayez.';

  @override
  String get characterStoryTabBodyEmptyStateTitle =>
      'AUCUNE HISTOIRE RENSEIGNÉE';

  @override
  String get characterStoryTabBodyEmptyStateSubtitle =>
      'Apparence, traits, idéaux... raconte l\'histoire de ton personnage quand tu veux.';

  @override
  String get characterStoryTabBodyEmptyStateButtonLabel =>
      'Renseigner mon histoire';

  @override
  String get characterStoryEditSheetTitle => 'MODIFIER L\'HISTOIRE';

  @override
  String get characterStoryEditSheetCancelButton => 'Annuler';

  @override
  String get characterStoryEditSheetSaveButton => 'Enregistrer';

  @override
  String get characterStoryEditSheetAppearanceLabel => 'APPARENCE PHYSIQUE';

  @override
  String get characterStoryEditSheetAppearanceHint =>
      'Décris l\'apparence physique de ton personnage…';

  @override
  String get characterStoryEditSheetTraitsLabel => 'TRAITS DE PERSONNALITÉ';

  @override
  String get characterStoryEditSheetTraitsHint =>
      'Décris les traits de personnalité de ton personnage…';

  @override
  String get characterStoryEditSheetIdealsLabel => 'IDÉAUX';

  @override
  String get characterStoryEditSheetIdealsHint =>
      'Quels idéaux guident ton personnage ?';

  @override
  String get characterStoryEditSheetBondsLabel => 'LIENS';

  @override
  String get characterStoryEditSheetBondsHint =>
      'Quels liens unissent ton personnage à d\'autres ?';

  @override
  String get characterStoryEditSheetFlawsLabel => 'DÉFAUTS';

  @override
  String get characterStoryEditSheetFlawsHint =>
      'Quels défauts ou faiblesses a ton personnage ?';

  @override
  String get characterStoryEditSheetBackstoryLabel => 'HISTOIRE PERSONNELLE';

  @override
  String get characterStoryEditSheetBackstoryHint =>
      'Raconte l\'histoire personnelle de ton personnage…';

  @override
  String get characterStoryEditSheetAlliesLabel => 'ALLIÉS';

  @override
  String get characterStoryEditSheetAlliesHint =>
      'Quels alliés ou organisations soutiennent ton personnage ?';

  @override
  String get characterStoryEditSheetFeaturesLabel => 'PARTICULARITÉS';

  @override
  String get characterStoryEditSheetFeaturesHint =>
      'Décris les particularités de ton personnage…';

  @override
  String get characterStoryEditSheetTreasureLabel => 'TRÉSOR';

  @override
  String get characterStoryEditSheetTreasureHint =>
      'Quels trésors ou objets précieux possède ton personnage ?';

  @override
  String get characterStoryEditSheetGenericErrorMessage =>
      'Impossible d\'enregistrer les modifications. Réessayez.';

  @override
  String get characterStoryEditSheetUpdatedMessage => 'Histoire mise à jour.';

  @override
  String get characterJournalCardTitle => 'JOURNAL DE CAMPAGNE';

  @override
  String get characterJournalCardAddButtonLabel => 'Ajouter une note';

  @override
  String get characterJournalCardEditAction => 'Modifier';

  @override
  String get characterJournalCardRemoveAction => 'Supprimer';

  @override
  String get characterJournalCardRemoveConfirmationTitle =>
      'Supprimer cette note ?';

  @override
  String get characterJournalCardRemoveConfirmationMessage =>
      'Cette action est définitive.';

  @override
  String get characterJournalCardRemoveConfirmationCancelButton => 'Annuler';

  @override
  String get characterJournalCardRemoveConfirmationConfirmButton => 'Supprimer';

  @override
  String get characterJournalCardRemovedMessage => 'Note supprimée.';

  @override
  String get characterJournalCardRemoveGenericErrorMessage =>
      'Impossible de supprimer cette note. Réessayez.';

  @override
  String get characterJournalEntryEditSheetAddTitle => 'AJOUTER UNE NOTE';

  @override
  String get characterJournalEntryEditSheetEditTitle => 'MODIFIER LA NOTE';

  @override
  String get characterJournalEntryEditSheetHint =>
      'Note de séance, événement marquant…';

  @override
  String get characterJournalEntryEditSheetCancelButton => 'Annuler';

  @override
  String get characterJournalEntryEditSheetSaveButton => 'Enregistrer';

  @override
  String get characterJournalEntryEditSheetGenericErrorMessage =>
      'Impossible d\'enregistrer cette note. Réessayez.';

  @override
  String get characterJournalEntryEditSheetAddedMessage => 'Note ajoutée.';

  @override
  String get characterJournalEntryEditSheetUpdatedMessage => 'Note modifiée.';

  @override
  String get characterGalleryCardTitle => 'GALERIE';

  @override
  String get galleryPhotoUploadSheetCameraAction => 'Prendre une photo';

  @override
  String get galleryPhotoUploadSheetGalleryAction => 'Choisir dans la galerie';

  @override
  String get galleryPhotoUploadSheetUrlAction => 'Utiliser une URL';

  @override
  String get galleryPhotoUploadSheetAddedMessage => 'Photo ajoutée.';

  @override
  String get galleryPhotoUploadSheetGenericErrorMessage =>
      'Impossible d\'ajouter cette photo. Réessayez.';

  @override
  String get galleryPhotoUploadSheetUrlDialogTitle => 'URL de la photo';

  @override
  String get galleryPhotoUploadSheetUrlDialogHint => 'https://...';

  @override
  String get galleryPhotoUploadSheetUrlDialogGenericError =>
      'Impossible de charger cette image.';

  @override
  String get galleryPhotoUploadSheetUrlDialogCancelButton => 'Annuler';

  @override
  String get galleryPhotoUploadSheetUrlDialogNextButton => 'Suivant';

  @override
  String get galleryPhotoViewerScreenRemoveButtonLabel => 'Retirer cette photo';

  @override
  String get galleryPhotoViewerScreenRemovedMessage => 'Photo retirée.';

  @override
  String get galleryPhotoViewerScreenRemoveGenericErrorMessage =>
      'Impossible de retirer cette photo. Réessayez.';

  @override
  String get galleryPhotoViewerScreenRemoveConfirmationTitle =>
      'Retirer cette photo ?';

  @override
  String get galleryPhotoViewerScreenRemoveConfirmationCancelButton =>
      'Annuler';

  @override
  String get galleryPhotoViewerScreenRemoveConfirmationConfirmButton =>
      'Retirer';

  @override
  String get portraitUploadSheetCameraAction => 'Prendre une photo';

  @override
  String get portraitUploadSheetGalleryAction => 'Choisir dans la galerie';

  @override
  String get portraitUploadSheetUrlAction => 'Utiliser une URL';

  @override
  String get portraitUploadSheetRemoveAction => 'Retirer le portrait';

  @override
  String get portraitUploadSheetRemovedMessage => 'Portrait retiré.';

  @override
  String get portraitUploadSheetRemoveGenericErrorMessage =>
      'Impossible de retirer le portrait. Réessayez.';

  @override
  String get portraitUploadSheetUrlDialogTitle => 'URL du portrait';

  @override
  String get portraitUploadSheetUrlDialogHint => 'https://...';

  @override
  String get portraitUploadSheetUrlDialogGenericError =>
      'Impossible de charger cette image.';

  @override
  String get portraitUploadSheetUrlDialogCancelButton => 'Annuler';

  @override
  String get portraitUploadSheetUrlDialogNextButton => 'Suivant';

  @override
  String get portraitUploadSheetRemoveConfirmationTitle =>
      'Retirer le portrait ?';

  @override
  String get portraitUploadSheetRemoveConfirmationCancelButton => 'Annuler';

  @override
  String get portraitUploadSheetRemoveConfirmationConfirmButton => 'Retirer';

  @override
  String get portraitCropScreenTitle => 'RECADRAGE';

  @override
  String get portraitCropScreenInstructions =>
      'Pincez pour zoomer, glissez pour cadrer.';

  @override
  String get portraitCropScreenCancelButton => 'Annuler';

  @override
  String get portraitCropScreenSaveButton => 'Valider';

  @override
  String get portraitCropScreenPrepareImageErrorMessage =>
      'Impossible de préparer l\'image. Réessayez.';

  @override
  String get portraitCropScreenGenericErrorMessage =>
      'Impossible d\'envoyer le portrait. Réessayez.';

  @override
  String get characterAdventuresCardTitle => 'AVENTURES';

  @override
  String characterAdventuresCardGmLabel(String gmName) {
    return 'MJ : $gmName';
  }

  @override
  String get characterAdventuresCardLeaveTooltip => 'Quitter l\'histoire';

  @override
  String characterAdventuresCardLeftMessage(String storyTitle) {
    return 'Tu as quitté $storyTitle.';
  }

  @override
  String get characterAdventuresCardLeaveGenericErrorMessage =>
      'Impossible de quitter cette histoire. Réessayez.';

  @override
  String characterAdventuresCardLeaveConfirmationTitle(String storyTitle) {
    return 'Quitter « $storyTitle » ?';
  }

  @override
  String get characterAdventuresCardLeaveConfirmationMessage =>
      'Ton personnage garde toutes ses données. Seul le lien avec cette histoire disparaît.';

  @override
  String get characterAdventuresCardLeaveConfirmationCancelButton => 'Annuler';

  @override
  String get characterAdventuresCardLeaveConfirmationConfirmButton => 'Quitter';
}
