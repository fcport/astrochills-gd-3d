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
		_note_unreadable("profilo", path)
		return PlayerProfile.new()
	var res := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	var p := res as PlayerProfile
	if p == null:
		_note_unreadable("profilo", path)
		return PlayerProfile.new()
	p.migrate()                               # SEMPRE
	return p


## Carica l'ultima notte conclusa. Stessa forma di `load_profile`.
func load_run(path := NIGHT_PATH) -> NightRun:
	last_load_message = ""
	if not FileAccess.file_exists(path):
		return NightRun.new()                 # nessuna notte salvata: silenzioso
	if not _looks_like_tres(path):
		_note_unreadable("notte", path)
		return NightRun.new()
	var res := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	var r := res as NightRun
	if r == null:
		_note_unreadable("notte", path)
		return NightRun.new()
	r.migrate()                               # SEMPRE
	return r


func _save(res: Resource, path: String) -> bool:
	DirAccess.make_dir_recursive_absolute(SAVES_DIR)
	var err := ResourceSaver.save(res, path)
	if err != OK:
		Log.warn("save", "salvataggio fallito a %s — errore %d" % [path, err])
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


func _note_unreadable(what: String, path: String) -> void:
	last_load_message = UNREADABLE_MESSAGE
	Log.warn("save", "%s illeggibile a %s — %s nuovo" % [what, path, what])
