## Controllo del tempo — `F1`-`F4`. Esiste solo nelle build di sviluppo.
##
## È l'apparato sperimentale dell'MVP, non una comodità: la domanda a cui il
## gioco esiste per rispondere è quanto debba durare l'attesa, e rispondere
## rigiocando ogni volta la notte a velocità reale costerebbe quindici minuti per
## tentativo. FR35 gli riserva quattro tasti dal primo giorno, e le storie 1.1,
## 1.2 e 1.3 li hanno tenuti liberi apposta — `debug/render_tuning.gd` è finito
## sotto `Shift` per non toccarli.
##
## SCRIVE SU `Engine.time_scale`, e nessuna logica del gioco lo legge:
## `night/night_clock.gd` accumula `delta * game_min_per_sec`, e il motore ha già
## applicato la scala a quel `delta`. È ciò che l'architettura intende con «la
## notte ×10 senza toccare una riga di logica».
##
## COSA ACCELERA DAVVERO, e va saputo prima di fidarsi di una misura.
## `Engine.time_scale` è globale: a ×10 la transizione alla postazione dura 50 ms
## invece di mezzo secondo, e la finestra del punteggio polare —
## `polar_score_window_sec`, che è in secondi REALI — copre 0,8 secondi di gioco
## invece di 8. **Un punteggio misurato accelerato non è confrontabile con uno
## misurato a velocità reale.** Serve a vedere una notte intera in poco tempo,
## non a giudicare una fase.
##
## E LA FISICA NON SI ACCELERA DA SOLA: SI ALLUNGA IL PASSO (D-245). La scala moltiplica il
## passo di fisica invece di farne fare di più, e a ×10 ogni passo simula un sesto di
## secondo di gioco invece di un sessantesimo. Un corpo appoggiato su una cosa sottile non ci
## resta: misurato con `tools/prova_moka_fuochi.gd`, la moka messa sul fuoco a ×1 e ×2 ci
## resta su tutti e quattro i fuochi, a ×5 e ×10 rimbalza sulla griglia e finisce cinque o
## dieci centimetri più in là. Federico l'ha vista cadere giocando accelerato, dopo una riga
## che diceva «Metti la moka sul fuoco».
##
## QUINDI INSIEME ALLA SCALA SI ALZANO I PASSI (`accelera`): passi al secondo e tetto dei
## passi per frame crescono della stessa quantità, e ogni passo resta un sessantesimo di
## secondo di gioco — a ×10 sono seicento passi al secondo reale. Costa dieci volte la
## fisica, e su una macchina che non ce la fa il ×10 diventa più lento, non sbagliato. Lo si
## alza a runtime e solo qui: il file non esiste in release, e le impostazioni del progetto
## restano quelle di sempre.
##
## KEYCODE GREZZI, non azioni dell'`InputMap`, come gli altri tre strumenti — e
## qui c'è una ragione in più: `main.gd::_input()` ingoia le azioni durante la
## transizione alla postazione, quindi un controllo del tempo legato a un'azione
## smetterebbe di rispondere per mezzo secondo a ogni volta che ci si siede.
##
## `F1` torna sempre a velocità reale: qualunque cosa si stia guardando, c'è un
## tasto che rimette le cose com'erano.
extends Node

## I quattro passi. `F1` è il ritorno alla realtà; `F4` è il ×10 che
## l'architettura nomina per esteso.
const STEPS := {
	KEY_F1: 1.0,
	KEY_F2: 2.0,
	KEY_F3: 5.0,
	KEY_F4: 10.0,
}


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo or key.shift_pressed:
		return
	if not STEPS.has(key.keycode):
		return
	var scale: float = STEPS[key.keycode]
	accelera(scale)
	Log.info("debug", "time_scale %.1fx, fisica a %d passi al secondo" % [
		scale, Engine.physics_ticks_per_second])


## Porta il tempo a `scala` tenendo il passo di fisica a un sessantesimo di secondo di gioco.
## STATICA, perché le sonde che accelerano lo facciano allo stesso modo del gioco: una sonda
## che scrive solo `Engine.time_scale` misura la fisica rotta, non quella che si gioca.
static func accelera(scala: float) -> void:
	var passi: int = ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 60)
	var tetto: int = ProjectSettings.get_setting("physics/common/max_physics_steps_per_frame", 8)
	var n := maxi(1, roundi(scala))
	Engine.time_scale = scala
	Engine.physics_ticks_per_second = passi * n
	Engine.max_physics_steps_per_frame = tetto * n
