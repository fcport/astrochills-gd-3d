## Contratto comune di una fase.
##
## Una fase è una scena autonoma (ADR-002): l'orchestratore la istanzia, si
## collega a `finished`, e non sa cosa faccia dentro. Una fase non conosce mai
## un'altra fase.
class_name Phase
extends Node

signal finished(result: PhaseResult)


## Identità stabile della fase.
##
## NON usare mai `name`: Godot rinomina in @PhasePolar@2 quando due nodi omonimi
## finiscono sotto lo stesso padre — e con «rifai setup» succede davvero, e
## finisce nel save.
func key() -> StringName:
	push_error("[phase] key() non implementata da %s" % get_script().resource_path)
	return &""


## LA COMMESSA DI STANOTTE, GIÀ IN FORMA LEGGIBILE, dentro il `ctx`.
##
## PERCHÉ UNA STRINGA E NON IL DIZIONARIO. La commessa vive su `NightRun`, che le
## fasi ricevono — ma le sue CHIAVI sono costanti di `photo/commission.gd`, e la
## tabella dei confini vieta a `phases/` di conoscere `photo/`. Ricopiare qui i
## nomi delle chiavi sarebbe una duplicazione che diverge in silenzio il giorno in
## cui una cambia. L'orchestratore, che è l'unico a vedere entrambe le sponde,
## compone la riga e la passa: la fase la mostra e basta.
##
## Vuota quando non c'è commessa. `ctx` è il solo canale previsto verso le fasi.
const CTX_COMMISSION_LINE := &"commission_line"

## La SIGLA del soggetto richiesto, maiuscola, o "" se non c'è commessa. Separata
## dalla riga leggibile perché serve a un confronto, non a una lettura: cercare la
## sigla dentro la frase funzionerebbe finché a qualcuno non venisse in mente un
## catalogo con "M4" e "M42".
const CTX_COMMISSION_TARGET := &"commission_target"


## Chiamato dall'orchestratore prima di aggiungere il nodo all'albero.
func setup(_run: NightRun, _ctx: Dictionary) -> void:
	pass


## Il Control che questa fase mostra sullo schermo CRT.
func screen() -> Control:
	return null


## Punteggio corrente, 0-100.
func score() -> int:
	return 100


## Se questa fase sta LAVORANDO adesso, e non solo esistendo.
##
## SONO DUE FATTI DIVERSI, e confonderli è costato tre difetti nell'epica 3. Una
## fase montata mostra il proprio schermo — il giocatore la sta configurando — ma
## non sta ancora facendo niente; il telescopio che inseguiva e la cupola che
## contava l'attesa partivano dal montaggio, cioè da un momento in cui non c'è
## nessuna posa. E `night/` apriva i programmi del PC solo a fase ASSENTE, che è
## l'unico stato in cui la posa di sicuro non gira: la BBS della 3.7 — «leggere
## mentre la posa gira» — non era apribile durante la posa.
##
## DEFAULT `false`, e la ragione è che così NESSUNA fase esistente deve cambiare
## per rispondere: chi non distingue i due stati non sta mai «lavorando» in questo
## senso. `phases/polar/phase_polar.gd` in particolare non cambia di una riga — è
## la prova dell'AC2 della storia 1.1, rieseguibile con `git diff`.
func is_working() -> bool:
	return false


## true se la fase continua a girare quando il giocatore si allontana.
##
## Una fase in background non assume MAI di essere visibile: niente
## get_viewport().size, niente accesso alla camera. E i suoni del luogo stanno
## sul luogo, non sulla fase.
func runs_in_background() -> bool:
	return false


## Il Control mostrato sul CRT resta di proprietà della fase anche dopo il
## reparent nel SubViewport. Senza questo, liberare la fase lo lascerebbe orfano
## a schermo. Il contrappeso sta nell'orchestratore, che chiama
## `crt.show_control(null)` PRIMA di liberare.
##
## PREDELETE e non `_exit_tree()`, e la differenza non è di stile: `_exit_tree()`
## scatta anche su un'uscita TEMPORANEA — un remove_child() per parcheggiare la
## fase, uno spostamento fra host, la distruzione del viewport che la ospita — e
## libererebbe l'interfaccia di una fase ancora viva, che il frame dopo la
## userebbe. Qui si libera solo quando la fase sta davvero morendo.
func _notification(what: int) -> void:
	if what != NOTIFICATION_PREDELETE:
		return
	var s := screen()
	if s != null and is_instance_valid(s) and not is_ancestor_of(s):
		s.queue_free()
