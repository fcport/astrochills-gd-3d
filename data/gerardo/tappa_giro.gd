## Una tappa del giro di Gerardo (D-287). SOLO DATI, nessuna logica.
##
## Sul modello di `data/quaderno/pagina_quaderno.gd`: una Resource di soli `@export`,
## salvata e diffabile come `.tres`. Chi la percorre è `world/gerardo/gerardo.gd`;
## chi controlla che le battute stiano sullo schermo è il banco, attraverso
## `GiroGerardo`.
##
## È ITALIANO, ed è la regola della lingua (NFR10): parla una persona, non una macchina.
class_name TappaGiro
extends Resource

## Come la si chiama nei log e al banco. Non si legge mai a schermo.
@export var nome: String = ""

## I punti da cui passa per arrivarci, in pianta (x, z del mondo), partendo da dove ha
## finito la tappa prima. L'ultimo è dove si ferma a parlare. La quota non c'è: la legge
## dal pavimento sotto i piedi, dentro come sul prato.
##
## LE PORTE NON SI SCRIVONO. Se un tratto passa per il vano di una porta chiusa, la apre
## lui da dove comincia il tratto: quindi il punto prima di una porta va messo FUORI dal
## giro dell'anta, a più di novanta centimetri dal cardine.
@export var percorso: PackedVector2Array = PackedVector2Array()

## Cosa dice, una battuta alla volta, con le domande e le risposte (`BattutaGiro`). Ogni
## testo deve stare in `GiroGerardo.RIGHE` righe di sottotitolo, e lo controlla il banco.
@export var battute: Array[BattutaGiro] = []

## Se a questa tappa aspetta il giocatore prima di parlare. Falso solo per l'ultima
## camminata, quella fino all'auto: lì ha già salutato, e non ti chiede di accompagnarlo.
@export var aspetta: bool = true
