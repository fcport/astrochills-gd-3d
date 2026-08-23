## Un committente che compra le foto. SOLO DATI, nessuna logica.
##
## È la casa tipizzata di un cliente, sul modello di `data/targets/target_data.gd`:
## una Resource di soli `@export`, salvata e diffabile come `.tres`. La logica della
## commessa (chi viene scelto, e come) vive in `photo/commission.gd` — questo file
## non la conosce.
class_name ClientData
extends Resource

## Sigla stabile, minuscola: l'id del committente (es. "coelum").
@export var id: StringName = &""

## Nome mostrato a schermo, nell'interfaccia di vendita (es. "Coelum").
@export var name: String = ""

## Moltiplicatore applicato al payout base quando la commessa è accettata.
## SEGNAPOSTO (FR22): non tarare. È una decisione d'economia, non una verità
## matematica — vive nel dato, mai come `const` nel codice.
@export var multiplier: float = 1.0

## L'id del soggetto richiesto: uno dei sei target reali (m42/m13/m45/m31/m57/m8).
## La commessa è applicabile solo se la foto ha esattamente questo target.
@export var wanted_target: StringName = &""

## Se il committente entra nella selezione della notte. `privato_g` nasce
## `false`: esiste come file ma la scelta lo esclude sempre.
@export var enabled: bool = true
