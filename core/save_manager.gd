## Persistenza del save. Puro: nessuno `SceneTree`, istanziabile sul banco (NFR19).
##
## È ciò che fa arrivare il lavoro di una notte alla successiva: `Game` ne tiene
## un'istanza (`_saves`), carica il profilo all'avvio e versa+salva a fine notte.
## Non è un autoload perché non ha stato di sessione da esporre: è una funzione con
## dei percorsi. Dipende solo da `core/` e da `Log` (autoload di logging, ammesso).
##
## SI SALVA SOLO `.tres` DI TESTO con `ResourceSaver`, sotto `user://saves/`: niente
## JSON, niente `FileAccess` per serializzare dati di gioco. Il file resta leggibile e
## diffabile, apribile in un editor durante la validazione dell'MVP.
##
## I DUE CANALI. Un save assente è un avvio nuovo, silenzioso — non un errore. Un save
## presente ma illeggibile è un FATTO recuperabile: canale 1 lo registra con `Log.warn`
## (mai `push_error`), e la frase per l'umano è dato di canale 2, in inglese (voce
## macchina del 1999), tono cozy, su `last_load_message`. Mai uno stack trace, mai un
## modale.
##
## PERCHÉ LO SNIFF DELL'HEADER PRIMA DI `ResourceLoader`. `ResourceLoader.load` su un
## `.tres` corrotto fa stampare a Godot un `ERROR` di caricamento, che il cancello
## `.bmad-loop/verify.ps1` tratta come guasto. Leggere la prima riga con `FileAccess` e
## verificare che cominci con `[gd_resource` intercetta il caso illeggibile SENZA
## invocare il loader — così il banco può dimostrare il ramo gentile restando verde. La
## corruzione profonda che superasse lo sniff ricade comunque sul controllo `null` dopo
## `load` (ramo raro, non pilotato dal banco).
class_name SaveManager
extends RefCounted

const SAVES_DIR := "user://saves"
const PROFILE_PATH := "user://saves/profile.tres"
const NIGHT_PATH := "user://saves/night.tres"

## La frase gentile per l'umano quando un save è illeggibile: canale 2, EN, voce
## macchina, tono cozy. Vuota quando il load è normale (assente o valido).
const UNREADABLE_MESSAGE := "save file unreadable — starting a fresh logbook"

## Canale 2, EN; vuota se il load è normale. La riempie l'ultimo `load_*`.
var last_load_message := ""


## Salva il profilo del giocatore. Ritorna `true` se scritto, `false` su fallimento
## (che registra con `Log.warn`, canale 1 — non è un fatto per il giocatore).
func save_profile(profile: PlayerProfile, path := PROFILE_PATH) -> bool:
	return _save(profile, path)


## Salva la notte conclusa. Stessa via di `save_profile`.
func save_run(run: NightRun, path := NIGHT_PATH) -> bool:
	return _save(run, path)


## Carica il profilo. Assente → istanza nuova, silenzioso; illeggibile → istanza
## nuova + frase gentile + `Log.warn`; valido → `migrate()` SEMPRE, poi ritorno.
func load_profile(path := PROFILE_PATH) -> PlayerProfile:
	last_load_message = ""
	if not FileAccess.file_exists(path):
		return PlayerProfile.new()            # primo avvio: silenzioso
	if not _looks_like_tres(path):            # sniff header, no ResourceLoader
		_quarantine("profilo", path)
		return PlayerProfile.new()
	var res := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	var p := res as PlayerProfile
	if p == null:
		_quarantine("profilo", path)
		return PlayerProfile.new()
	# UN SAVE PIU' NUOVO DEL GIOCO non è migrabile: `migrate()` sa scendere dal
	# passato, non dal futuro. Degradarlo in silenzio significa riscriverlo alla fine
	# della notte successiva nel formato vecchio, perdendo per sempre i campi che la
	# versione nuova aveva aggiunto. Meglio trattarlo come illeggibile e metterlo da
	# parte intatto: succede a chi prova una build nuova e poi torna indietro.
	if p.version > PlayerProfile.CURRENT_VERSION:
		_quarantine("profilo", path)
		return PlayerProfile.new()
	p.migrate()                               # SEMPRE
	return p


## Carica l'ultima notte conclusa. Stessa forma di `load_profile`.
func load_run(path := NIGHT_PATH) -> NightRun:
	last_load_message = ""
	if not FileAccess.file_exists(path):
		return NightRun.new()                 # nessuna notte salvata: silenzioso
	if not _looks_like_tres(path):
		_quarantine("notte", path)
		return NightRun.new()
	var res := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	var r := res as NightRun
	if r == null:
		_quarantine("notte", path)
		return NightRun.new()
	if r.version > NightRun.CURRENT_VERSION:
		_quarantine("notte", path)
		return NightRun.new()
	r.migrate()                               # SEMPRE
	return r


## SI SCRIVE DI FIANCO, POI SI SOSTITUISCE. `ResourceSaver.save` sul file definitivo
## lo tronca dal primo byte: se il processo muore a metà scrittura — un alt-F4 su un
## freeze, la batteria, un crash del driver — al riavvio il save esiste, è mozzo, e le
## lire di tutte le notti precedenti non ci sono più. E quei secondi di I/O sono i più
## prevedibili della partita, perché cadono sempre alla chiusura della notte.
##
## Con il temporaneo, un'interruzione lascia intatto il save di ieri: si perde la notte
## appena finita, non la carriera.
func _save(res: Resource, path: String) -> bool:
	# La directory del path che si sta per scrivere, non una costante: le due funzioni
	# pubbliche accettano un percorso qualsiasi, e il banco ne usa uno suo.
	var dir := path.get_base_dir()
	var derr := DirAccess.make_dir_recursive_absolute(dir)
	if derr != OK and not DirAccess.dir_exists_absolute(dir):
		Log.warn("save", "cartella dei salvataggi non creabile: %s — errore %d" % [dir, derr])
		return false

	# `.tmp.tres` e NON `.tres.tmp`: `ResourceSaver` sceglie il formato dall'estensione,
	# e con un suffisso che non conosce rifiuta di scrivere. (Verificato rompendolo: la
	# prima versione di questa funzione usava `.tres.tmp` e non salvava piu' niente.)
	# SI TIMBRA LA VERSIONE PRIMA DI SCRIVERE. Il campo ha default 0 apposta, cosi'
	# `ResourceSaver` — che omette ogni proprieta' uguale al default — lo scrive davvero.
	# Senza, il numero non finiva sul file e ogni save si sarebbe letto come «versione
	# corrente» per sempre: il ramo di migrazione esisteva ed era inerte.
	if res is PlayerProfile:
		(res as PlayerProfile).version = PlayerProfile.CURRENT_VERSION
	elif res is NightRun:
		(res as NightRun).version = NightRun.CURRENT_VERSION

	var tmp := path.get_basename() + ".tmp.tres"
	var err := ResourceSaver.save(res, tmp)
	if err != OK:
		Log.warn("save", "salvataggio fallito a %s — errore %d" % [tmp, err])
		return false

	# `rename_absolute` sovrascrive: il vecchio file sparisce solo adesso, quando il
	# nuovo è già completo sul disco.
	var rerr := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(path))
	if rerr != OK:
		Log.warn("save", "sostituzione fallita %s -> %s — errore %d" % [tmp, path, rerr])
		return false
	return true


## Vero se la prima riga del file comincia con `[gd_resource`: è l'intestazione di un
## `.tres` di testo. Non apre `ResourceLoader`, così un file spazzatura non fa emettere
## a Godot un errore di caricamento (che il cancello leggerebbe come guasto).
func _looks_like_tres(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var header := f.get_line()
	f.close()
	return header.begins_with("[gd_resource")


## Il file illeggibile si SPOSTA, non si lascia dov'è.
##
## Prima restava al suo posto, e la prima notte conclusa ci scriveva sopra il profilo
## azzerato: la finestra per recuperarlo a mano — che è l'intera ragione per cui si
## salva in testo leggibile — durava una notte, e nessuno avvisava il giocatore che si
## stava consumando. Rinominato, resta lì finché qualcuno decide di guardarlo.
func _quarantine(what: String, path: String) -> void:
	last_load_message = UNREADABLE_MESSAGE
	# Col timestamp, perche' una seconda corruzione non deve cancellare la prima: e' il
	# file che si spera di riaprire a mano, e sovrascriverlo vanifica la quarantena.
	var kept := "%s.corrupt-%d" % [path, int(Time.get_unix_time_from_system())]
	var abs_from := ProjectSettings.globalize_path(path)
	var abs_to := ProjectSettings.globalize_path(kept)
	if DirAccess.rename_absolute(abs_from, abs_to) == OK:
		Log.warn("save", "%s illeggibile a %s — messo da parte in %s, %s nuovo" % [
			what, path, kept, what])
	else:
		Log.warn("save", "%s illeggibile a %s — %s nuovo (non spostabile)" % [what, path, what])
