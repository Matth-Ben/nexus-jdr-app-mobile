/// Message affiché après une écriture `CharacterRepository` qui retourne
/// `WriteOutcome.queued` (mode hors-ligne) alors que cette écriture précise
/// n'est **jamais** mise en file de synchro par
/// `PendingCharacterWriteQueue` — contrairement à `updateHp`/`addXp`/
/// `castSpell`/`setInnateSpellUsesSpent`/`useClassFeature`/`applyRest`
/// (voir `character_detail_screen.dart::_offlineQueuedMessage`), qui
/// promettent elles une synchronisation future réelle.
///
/// Concerne, à ce jour :
/// - `setDead`, `setArchived`, `deleteCharacter` — utilisées par les 3
///   appelants de cette constante (`character_detail_screen.dart`,
///   `character_list_screen.dart`, `character_card_action_sheet.dart`) ;
/// - côté `character_detail_screen.dart` uniquement, les écritures de
///   l'onglet "Inventaire"/"Histoire" encore hors périmètre de la file de
///   synchro (`useInventoryItem`/`setInventoryItemEquipped`/
///   `equipWeaponToSlot`/`setInventoryItemAttuned`/`removeInventoryItem`/
///   `adjustCurrency`/`addInventoryItem`/`addCustomInventoryItem`/
///   `addReward`/`updateStoryFields` — décision chef de projet du
///   09/10/2026, D11 du registre de dette technique : seuls le lancer de
///   sort, les aptitudes et le repos ont été étendus).
///
/// L'état optimiste local (quand il y en a un) est annulé dans ce cas
/// (revert) : laisser affichée une valeur modifiée serait trompeur puisque
/// rien ne sera jamais synchronisé pour ces écritures précises — voir
/// chaque appelant.
///
/// Extrait ici (dette technique D88, registre `docs/dette-technique.md`) :
/// ce texte encode un invariant comportemental du repository, pas un simple
/// libellé UI — avant cette extraction, il était dupliqué à l'identique,
/// `private`, dans les 3 fichiers listés ci-dessus, sans lien au
/// compilateur entre les copies.
const offlineNotPersistedMessage =
    "Hors ligne : cette action n'a pas pu être enregistrée. Réessayez une "
    'fois reconnecté.';
