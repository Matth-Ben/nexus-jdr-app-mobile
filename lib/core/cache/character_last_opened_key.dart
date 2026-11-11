/// Clé SharedPreferences des horodatages locaux « dernière ouverture » des
/// fiches (tri de la liste, P18), scopée par compte. Partagée entre le
/// provider qui les écrit (`CharacterLastOpened`) et la purge à la
/// déconnexion / suppression de compte (`SupabaseAuthRepository`, D31).
String characterLastOpenedKey(String ownerId) =>
    'character_last_opened:$ownerId';
