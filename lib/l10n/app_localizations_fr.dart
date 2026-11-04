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
      'Sur aidedd.org, ouvre la fiche de ton personnage puis utilise son export XML (bouton d\'export du site). Dans Nexus JDR, va dans Personnages > « + » > Importer un fichier XML, puis sélectionne ce fichier. L\'app pré-remplit automatiquement la fiche (caractéristiques, classe, race, sorts, inventaire...) et te montre un écran de vérification avant de l\'enregistrer, avec les champs qu\'elle n\'a pas reconnus signalés d\'une pastille pour que tu les complètes toi-même.';

  @override
  String get profileFaqQuestion2 => 'Comment rejoindre l\'histoire de mon MJ ?';

  @override
  String get profileFaqAnswer2 =>
      'Ton MJ te partage un code d\'invitation ou un lien depuis l\'app « Histoires ». Dans Nexus JDR, ouvre ce lien ou saisis le code dans l\'écran « Rejoindre une histoire », puis choisis le personnage à rattacher (un existant ou un nouveau). Le personnage reste ensuite synchronisé avec cette histoire tant que le MJ ne retire pas l\'accès.';

  @override
  String get profileFaqQuestion3 =>
      'Mes personnages sont-ils sauvegardés hors ligne ?';

  @override
  String get profileFaqAnswer3 =>
      'Oui. Tous tes personnages restent consultables et modifiables sans connexion : les changements (points de vie, XP, inventaire...) sont mis en file d\'attente sur ton appareil puis synchronisés automatiquement avec le serveur dès que la connexion revient. Aucune donnée n\'est perdue en cas de coupure réseau.';

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
}
