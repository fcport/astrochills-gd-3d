## Ciò che è del GIOCATORE, e attraversa le notti. SOLO DATI, nessuna logica.
##
## È la sorella di `core/night_run.gd`, e la linea fra le due è l'intera ragione per
## cui questo file esiste. `NightRun` tiene ciò che appartiene a UNA notte — l'ora,
## i punteggi delle fasi, il bersaglio scelto, le foto scattate, la commessa — e muore
## con lei. Qui sta ciò che il giocatore si porta dietro: le lire guadagnate, quante
## notti ha lavorato, e domani ciò che ha comprato.
##
## PERCHÉ DUE TIPI E NON UNA FUNZIONE CHE COPIA. La storia 2.7 chiede che «portafoglio
## e flag di acquisto siano quelli di prima, e i punteggi delle fasi no: appartengono
## alla notte, non al giocatore». Quella distinzione esisteva nel pensiero e non nel
## codice: `Game.start_night()` faceva `NightRun.new()` e portava via tutto. Scriverla
## come un elenco di campi dentro una funzione di copia significa che ogni campo
## aggiunto da qui all'epica 3 va ricordato a mano, e dimenticarne uno non produce
## nessun errore — produce un portafoglio che si azzera ogni tanto, che è il guasto
## che si insegue per due giorni. Scritta come due tipi, la domanda «questo
## sopravvive?» se la pone chi aggiunge il campo, non chi legge sei mesi dopo.
##
## Chiude il rilievo C1 (2026-08-23), che bloccava la 2.7 e la 3.2.
##
## Salvato con ResourceSaver su user://saves/*.tres — leggibile e diffabile, come
## `NightRun`.
class_name PlayerProfile
extends Resource

## Incrementare a ogni cambio di formato, e gestirlo in `migrate()`.
const CURRENT_VERSION := 1

## IL DEFAULT E' 0, NON `CURRENT_VERSION`, e la differenza e' tutto il meccanismo.
## `ResourceSaver` omette ogni proprieta' uguale al proprio default: con il default a
## `CURRENT_VERSION` il campo non finiva MAI sul disco, perche' nel momento del
## salvataggio e' sempre uguale. Il save sembrava a posto, e il giorno in cui
## `CURRENT_VERSION` fosse passato a 2 un file v1 sarebbe stato letto come v2 — con
## `migrate()` che non ripara niente, in silenzio. Il ramo esisteva ed era inerte.
##
## Con 0 come default il numero vero viene sempre scritto — lo timbra `SaveManager`
## subito prima di salvare — e uno 0 letto significa «file cosi' vecchio da non avere
## la versione»: un caso che `migrate()` puo' vedere invece di scambiarlo per corrente.
## NON si timbra qui in un `_init()`: verrebbe applicato anche a un'istanza CARICATA da
## un file privo del campo, che e' esattamente il caso da riconoscere.
@export var version: int = 0

## Le lire che il giocatore ha davvero in tasca. Ci arrivano a fine notte dal
## `night_earnings` della `NightRun`, mai direttamente da una vendita: chi vende
## accredita sulla notte, e la notte versa al giocatore quando finisce.
@export var wallet_lire: int = 0

## Quante notti sono state portate a termine. È anche ciò da cui la notte successiva
## ricava il proprio `night_index`, e quindi la rotazione dei committenti.
@export var nights_completed: int = 0

## Ciò che il giocatore ha comprato al terminale, e che si porta dietro fra le
## notti. STA QUI PER LA STESSA RAGIONE DEL PORTAFOGLIO (C1): un acquisto è del
## GIOCATORE, non della notte — la moka comprata stanotte c'è ancora domani, mentre
## i punteggi delle fasi muoiono con la `NightRun`. Metterlo su `NightRun` lo
## azzererebbe a ogni `start_night()`, e la moka sparirebbe dalla cucina al risveglio.
##
## DEFAULT `[]`, E NESSUN BUMP DI `CURRENT_VERSION`: un save vecchio senza il campo
## è correttamente «niente posseduto». `ResourceSaver` omette una proprietà uguale al
## default, quindi un profilo con l'array vuoto non scrive il campo — e ricaricato
## torna vuoto, che è esattamente il significato giusto. Aggiungere un campo con
## default «assente = stato iniziale» non cambia il formato: non serve `migrate()`.
@export var owned_items: Array[StringName] = []

## Se la lampada della cucina è stata cambiata (3.4). È una modifica PERMANENTE del
## giocatore al suo mondo — come `owned_items` — quindi vive qui e non sulla `NightRun`:
## una lampada sistemata resta sistemata dopo il sonno e dopo il riavvio. Possedere la
## `lampadina` ≠ averla installata: si può comprare e non montare, o uscire a metà cambio;
## serve perciò un bit DISTINTO dal possesso. Lo scrive `Game.mark_lamp_fixed()`.
##
## DEFAULT `false`, E NESSUN BUMP DI `CURRENT_VERSION`: stessa contabilità di
## `owned_items`. `ResourceSaver` omette una proprietà uguale al default, quindi un save
## vecchio senza il campo non lo scrive — e ricaricato torna `false`, cioè «non riparata»,
## che è esattamente lo stato iniziale giusto. Aggiungere un campo con default «assente =
## stato iniziale» non cambia il formato: non serve `migrate()`.
@export var lamp_fixed: bool = false

## I messaggi del forum della BBS che il giocatore ha gia' letto (3.7). Un letto una
## notte resta letto la notte dopo: la distinzione e' del GIOCATORE — come `owned_items`
## e `lamp_fixed` — quindi vive qui e non sulla `NightRun`, che muore col sonno. Lo
## scrive `Game.mark_forum_read()`; lo legge la BBS per disegnare in `DIM` cio' che e'
## gia' stato aperto.
##
## DEFAULT `[]`, E NESSUN BUMP DI `CURRENT_VERSION`: stessa contabilita' di `owned_items`.
## `ResourceSaver` omette una proprieta' uguale al default, quindi un save vecchio senza
## il campo non lo scrive — e ricaricato torna vuoto, cioe' «niente letto», che e'
## esattamente lo stato iniziale giusto. Aggiungere un campo con default «assente =
## stato iniziale» non cambia il formato: non serve `migrate()`.
@export var forum_read: Array[StringName] = []

## Se il giocatore possiede l'articolo `id`. Lo legge il terminale (per mostrare
## `OWNED`) e lo leggeranno 3.3/3.4 (per far comparire la moka/la lampadina).
func owns(id: StringName) -> bool:
	return owned_items.has(id)

## Marca l'articolo `id` come posseduto. Idempotente: comprare due volte non lo
## duplica nell'array. La spesa la fa il chiamante (`Game.spend_lire`), il salvataggio
## anche — qui si segna soltanto il possesso.
func mark_owned(id: StringName) -> void:
	if not owned_items.has(id):
		owned_items.append(id)

## Se il giocatore ha gia' letto il messaggio `id` del forum. Lo legge la BBS per
## disegnare in `DIM` cio' che e' letto e in `FG` cio' che non lo e'.
func has_read(id: StringName) -> bool:
	return forum_read.has(id)

## Marca il messaggio `id` come letto. Idempotente: leggerlo due volte non lo duplica
## nell'array. Il salvataggio lo fa il chiamante (`Game.mark_forum_read`), come per
## `mark_owned`: qui si segna soltanto il letto.
func mark_read(id: StringName) -> void:
	if not forum_read.has(id):
		forum_read.append(id)


func migrate() -> void:
	if version == CURRENT_VERSION:
		return
	# Nessuna migrazione ancora: il ramo esiste dal primo giorno perché aggiungerlo
	# dopo significa avere già partite da riparare.
	Log.warn("save", "PlayerProfile v%d → v%d, nessuna migrazione definita" % [version, CURRENT_VERSION])
	version = CURRENT_VERSION
