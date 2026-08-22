# Deferred work

Lavoro reale, rinviato con una ragione. Ogni voce dice da dove viene e cosa la sblocca.

## Deferred from: code review of 1-1-lallineamento-polare-e-la-prova-che-il-seam-regge (2026-08-22)

- **`phase_scores` con chiavi `StringName` non sopravvive a un round-trip JSON.** `Game.run.phase_scores[phase.key()]` usa `&"polar"`; in Godot 4 `dict[&"polar"]` e `dict["polar"]` sono due voci distinte. Una partita ricaricata da JSON avrebbe punteggi irraggiungibili tramite `phase.key()`, e un rigioco scriverebbe in silenzio una seconda voce parallela. *Rinviato: il sistema di save non esiste ancora — arriva con l'epica 2, ed è bloccato dalla decisione C1 (contenitore per lo stato che attraversa le notti).* [main.gd]

- **`_collect_materials` raccoglie solo `material_override`.** Salta i materiali per-superficie e `material_overlay`, e non deduplica: un `ShaderMaterial` condiviso fra N mesh viene scritto N volte e contato N volte, quindi il log `%d materiali` non permette di distinguere «non ho trovato niente» da «ho trovato la cosa sbagliata». *Rinviato: non c'è geometria 3D nel viewport finché la storia 1.2 non costruisce l'osservatorio — oggi il comando degrada in silenzio per progetto.* [debug/render_tuning.gd]

- **`_samples` salva il timestamp in float32 e lo confronta con un cutoff float64.** `Vector2` è `real_t` a 32 bit, `_elapsed` è un double GDScript: il timestamp memorizzato è una copia arrotondata del valore contro cui viene poi confrontato, quindi il confine di sfratto sbaglia fino a un ULP. `_elapsed` inoltre cresce senza limite e senza reset. *Rinviato: invisibile con la finestra di default da 8 s (±1 campione su ~480); degrada solo su sessioni molto lunghe.* [phases/polar/phase_polar.gd]

- **`set_anchors_preset(PRESET_FULL_RECT)` funziona per coincidenza.** Il default `keep_offsets = true` sposta solo le ancore e ricalcola gli offset per **preservare** il rect che il Control ha già: regge oggi soltanto perché `polar_screen._ready()` ha impostato `256×192` a (0,0), che combacia con il viewport. La chiamata che fa ciò che il commento intende è `set_anchors_and_offsets_preset`. *Rinviato: verificato funzionante oggi (256×192, offset zero); è fragilità latente che morde quando la 1.3 porta il Control sul CRT diegetico e le misure smettono di combaciare per caso.* [main.gd]

- **Dopo ENTER il ponte finisce nel vuoto.** `_advance()` svuota il viewport, libera la fase e si ferma: schermo nero, nessun riscontro che qualcosa si sia concluso, e il `reason` non lo legge nessuno. *Rinviato: limite dichiarato del ponte temporaneo, coperto dalla quarta clausola di AC6 — si chiude con la storia 1.3, quando il giocatore si siede al monitor. Registrato qui perché non venga scambiato per una regressione.* [main.gd]
