## Controllo del tempo — `F1`-`F4`. Esiste solo nelle build di sviluppo.
##
## È l'apparato sperimentale dell'MVP, non una comodità: la domanda a cui il
## gioco esiste per rispondere è quanto debba durare l'attesa, e rispondere
## rigiocando ogni volta la notte a velocità reale costerebbe quindici minuti per
## tentativo. FR35 gli riserva quattro tasti dal primo giorno, e le storie 1.1,
## 1.2 e 1.3 li hanno tenuti liberi apposta — `debug/render_tuning.gd` è finito
## sotto `Shift` per non toccarli.
##
## SCRIVE SU `Engine.time_scale` E BASTA. Nessuna logica del gioco lo legge:
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
## E LA FISICA SATURA A ×8, che è la parte che sorprende. `project.godot` non ha
## una sezione `[physics]`, quindi `max_physics_steps_per_frame` vale 8: a 60 fps
## servirebbero dieci passi di fisica per frame e il motore ne fa otto, buttando
## il resto. A `F4` l'orologio e il `_process` delle fasi corrono a ×10 pieni,
## mentre camminata, raycast di interazione e depenetrazione del corpo corrono a
## ×8. Guardato in code review il 2026-08-23 e lasciato così di proposito: alzare
## quell'impostazione la paga ogni frame di stutter anche in release, dove questo
## file non esiste. Chi tara deve saperlo — `F3` (×5) sta sotto la soglia e non
## ha il problema.
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
	Engine.time_scale = scale
	Log.info("debug", "time_scale %.1fx" % scale)

