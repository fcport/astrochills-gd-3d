## Una battuta di Gerardo (D-287, D-289), e quello che le si risponde. SOLO DATI.
##
## Di solito Gerardo dice `testo` e va avanti. Due eccezioni, una alla volta:
##   * `chiede_nome`: dopo il testo aspetta che il giocatore scriva il suo nome;
##   * `rami` non vuoto: dopo il testo il giocatore sceglie una delle risposte, e Gerardo
##     dice le battute di quel ramo.
## Una risposta sola è una domanda del giocatore («Quale luce rossa?»): si sceglie per
## dirla, e non per decidere.
class_name BattutaGiro
extends Resource

@export_multiline var testo: String = ""
@export var chiede_nome: bool = false
@export var rami: Array[RamoGiro] = []

## Se mentre la dice INDICA qualcosa (D-292): si gira verso `dove`, un punto in pianta, e
## parla guardandolo. Il proiettore, la vetrata, la cupola.
@export var indica: bool = false
@export var dove: Vector2 = Vector2.ZERO

## Se dopo averla detta ASPETTA CHE TU FACCIA QUALCOSA (D-293): «dai, prova subito» e la
## cupola si apre, «accendila un po'» e la luce rossa si accende. Non va avanti finché non
## l'hai fatto; la cupola, se ci metti troppo, te la ricorda.
enum Aspetta { NIENTE, CUPOLA_APERTA, LUCE_ROSSA }
@export var aspetta: Aspetta = Aspetta.NIENTE
