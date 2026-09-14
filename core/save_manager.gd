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

## I file di una partita, dentro la sua cartella.
const PROFILE_FILE := "profile.tres"
const NIGHT_FILE := "night.tres"
const WORLD_FILE := "world.tres"

## LE PARTITE SONO CARTELLE (D-243). Prima c'era un profilo solo, sciolto in `SAVES_DIR`,
## e provare qualcosa da capo — la moka non ancora comprata — voleva dire toccare la
## partita vera di Federico, trentacinque notti e le lire. E le sonde ci giravano sopra:
## caricavano `main.tscn`, e con lui il suo salvataggio.
##
## `PARTITA_VERA` è quella che si gioca, e fuori dallo sviluppo è l'unica. `PARTITA_SONDE`
## è quella delle sonde, e si svuota a ogni avvio di una sonda: una prova che parte dal
## lavoro lasciato da quella di prima non misura niente. Le partite di prova si chiamano
## `prova-1`, `prova-2`… e le crea il pannello di F10.
const PARTITA_VERA := "partita"
const PARTITA_SONDE := "sonde"
const PREFISSO_PROVA := "prova"

## La cartella della partita in cui scrivono le chiamate senza percorso esplicito. La
## sceglie `Game` con `usa_partita()`; il banco passa percorsi suoi e non la guarda.
var cartella := SAVES_DIR.path_join(PARTITA_VERA)

## La frase gentile per l'umano quando un save è illeggibile: canale 2, EN, voce
## macchina, tono cozy. Vuota quando il load è normale (assente o valido).
const UNREADABLE_MESSAGE := "save file unreadable — starting a fresh logbook"

## Canale 2, EN; vuota se il load è normale. La riempie l'ultimo `load_*`.
var last_load_message := ""


## Salva il profilo del giocatore. Ritorna `true` se scritto, `false` su fallimento
## (che registra con `Log.warn`, canale 1 — non è un fatto per il giocatore).
func save_profile(profile: PlayerProfile, path := "") -> bool:
	return _save(profile, _file(path, PROFILE_FILE))


## Salva la notte conclusa. Stessa via di `save_profile`.
func save_run(run: NightRun, path := "") -> bool:
	return _save(run, _file(path, NIGHT_FILE))


## Salva com'è il mondo (D-243). Stessa via di `save_profile`.
func save_world(world: WorldState, path := "") -> bool:
	return _save(world, _file(path, WORLD_FILE))


## Carica il profilo. Assente → istanza nuova, silenzioso; illeggibile → istanza
## nuova + frase gentile + `Log.warn`; valido → `migrate()` SEMPRE, poi ritorno.
func load_profile(path := "") -> PlayerProfile:
	path = _file(path, PROFILE_FILE)
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
func load_run(path := "") -> NightRun:
	path = _file(path, NIGHT_FILE)
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


## Carica com'era il mondo. Stessa forma di `load_profile`: assente → mondo come lo
## dichiara la scena, in silenzio; illeggibile → lo stesso, col file messo da parte.
func load_world(path := "") -> WorldState:
	path = _file(path, WORLD_FILE)
	last_load_message = ""
	if not FileAccess.file_exists(path):
		return WorldState.new()
	if not _looks_like_tres(path):
		_quarantine("mondo", path)
		return WorldState.new()
	var res := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	var w := res as WorldState
	if w == null or w.version > WorldState.CURRENT_VERSION:
		_quarantine("mondo", path)
		return WorldState.new()
	w.migrate()                               # SEMPRE
	return w


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
	elif res is WorldState:
		(res as WorldState).version = WorldState.CURRENT_VERSION

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


# ---------------------------------------------------------------------------
# LE PARTITE (D-243)
# ---------------------------------------------------------------------------

## Da qui in poi le chiamate senza percorso esplicito leggono e scrivono in `nome`.
func usa_partita(nome: String) -> void:
	cartella = SAVES_DIR.path_join(nome)


func _file(path: String, file: String) -> String:
	return path if not path.is_empty() else cartella.path_join(file)


## Un nome di partita è una cartella, e può arrivare da una variabile d'ambiente: solo
## minuscole, cifre, trattini. Un `../` qui vorrebbe dire scrivere il profilo dove capita.
##
## E NON COMINCIA CON `_`: sotto `SAVES_DIR` il banco si tiene le sue cartelle —
## `_bench`, `_bench_items` — e senza questa regola comparirebbero fra le partite di F10.
static func nome_valido(nome: String) -> bool:
	if nome.is_empty() or nome.length() > 40 or nome.begins_with("_") or nome.begins_with("-"):
		return false
	for c in nome:
		var ok := (c >= "a" and c <= "z") or (c >= "0" and c <= "9") or c == "-" or c == "_"
		if not ok:
			return false
	return true


## Le partite che esistono: le cartelle sotto `SAVES_DIR` con un nome valido, la vera per
## prima e le altre in ordine.
static func elenco_partite() -> PackedStringArray:
	var out := PackedStringArray()
	if not DirAccess.dir_exists_absolute(SAVES_DIR):
		return out
	for d in DirAccess.get_directories_at(SAVES_DIR):
		if nome_valido(d):
			out.append(d)
	out.sort()
	var i := out.find(PARTITA_VERA)
	if i > 0:
		out.remove_at(i)
		out.insert(0, PARTITA_VERA)
	return out


## Il primo nome di prova libero: `prova-1`, poi `prova-2`. PURA, per il banco.
static func nome_libero(esistenti: PackedStringArray) -> String:
	var n := 1
	while esistenti.has("%s-%d" % [PREFISSO_PROVA, n]):
		n += 1
	return "%s-%d" % [PREFISSO_PROVA, n]


## Crea la cartella di una partita. Vuota vuol dire «da zero»: un profilo assente è un
## avvio nuovo, silenzioso, e non serve scrivere niente.
static func crea_partita(nome: String) -> bool:
	if not nome_valido(nome):
		return false
	var dir := SAVES_DIR.path_join(nome)
	return DirAccess.make_dir_recursive_absolute(dir) == OK or DirAccess.dir_exists_absolute(dir)


## Copia i file di una partita in un'altra — per provare una cosa sulla partita vera senza
## rischiare la partita vera. Si copiano solo i tre file: una quarantena resta dov'è.
static func copia_partita(da: String, a: String) -> bool:
	if not (nome_valido(da) and nome_valido(a)) or not crea_partita(a):
		return false
	for f in [PROFILE_FILE, NIGHT_FILE, WORLD_FILE]:
		var src := SAVES_DIR.path_join(da).path_join(f)
		if not FileAccess.file_exists(src):
			continue
		var err := DirAccess.copy_absolute(src, SAVES_DIR.path_join(a).path_join(f))
		if err != OK:
			Log.warn("save", "copia di %s fallita — errore %d" % [src, err])
			return false
	return true


## Toglie i tre file di una partita. La usano le sonde, per partire ogni volta da zero.
static func svuota_partita(nome: String) -> void:
	if not nome_valido(nome):
		return
	for f in [PROFILE_FILE, NIGHT_FILE, WORLD_FILE]:
		var p := SAVES_DIR.path_join(nome).path_join(f)
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


## IL TRASLOCO DEI SALVATAGGI DI PRIMA. Fino al D-243 profilo e notte stavano sciolti in
## `SAVES_DIR`, ed erano la partita vera. Si spostano nella sua cartella UNA VOLTA: se
## là c'è già un profilo non si tocca niente, perché sovrascriverlo vorrebbe dire perdere
## il più nuovo dei due.
static func trasloca_vecchi() -> void:
	var vera := SAVES_DIR.path_join(PARTITA_VERA)
	if FileAccess.file_exists(vera.path_join(PROFILE_FILE)):
		return
	if not FileAccess.file_exists(SAVES_DIR.path_join(PROFILE_FILE)):
		return
	DirAccess.make_dir_recursive_absolute(vera)
	for f in [PROFILE_FILE, NIGHT_FILE]:
		var da := SAVES_DIR.path_join(f)
		if not FileAccess.file_exists(da):
			continue
		var err := DirAccess.rename_absolute(ProjectSettings.globalize_path(da),
			ProjectSettings.globalize_path(vera.path_join(f)))
		if err != OK:
			Log.warn("save", "trasloco di %s fallito — errore %d" % [da, err])
			return
	Log.info("save", "i salvataggi di prima sono ora la partita «%s»" % PARTITA_VERA)
