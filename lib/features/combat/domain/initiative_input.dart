/// Bornes serveur de l'initiative (`invalid_initiative` hors de cet intervalle).
const int kInitiativeMin = -20;
const int kInitiativeMax = 60;

/// Valeur proposée par « + » / « − » quand le champ est vide.
const int kInitiativeStart = 10;

/// Nombre maximal de monstres ajoutés en un appel (`npc_limit_per_call`).
const int kMonsterBatchMax = 20;

/// Longueur maximale d'un nom (`invalid_name` : 1..80).
const int kParticipantNameMax = 80;

enum InitiativeInputStatus { empty, valid, invalid }

/// Résultat de l'analyse d'une saisie d'initiative.
typedef InitiativeInput = ({InitiativeInputStatus status, int? value});

/// Analyse la saisie : vide, entier dans -20..60, ou invalide (texte, décimal,
/// hors bornes). Accepte le moins typographique (U+2212).
InitiativeInput parseInitiativeInput(String raw) {
  final text = raw.trim().replaceAll('−', '-');
  if (text.isEmpty) return (status: InitiativeInputStatus.empty, value: null);
  if (!RegExp(r'^[+-]?\d{1,3}$').hasMatch(text)) {
    return (status: InitiativeInputStatus.invalid, value: null);
  }
  final value = int.parse(text);
  if (value < kInitiativeMin || value > kInitiativeMax) {
    return (status: InitiativeInputStatus.invalid, value: null);
  }
  return (status: InitiativeInputStatus.valid, value: value);
}

/// Valeur après un tap sur « − » / « + » : champ vide ou invalide → départ à
/// [kInitiativeStart], sinon ±1 borné.
int stepInitiative(InitiativeInput current, int delta) {
  if (current.status != InitiativeInputStatus.valid) return kInitiativeStart;
  return (current.value! + delta).clamp(kInitiativeMin, kInitiativeMax);
}
