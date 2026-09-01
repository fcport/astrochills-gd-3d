## Accesso ai valori di bilanciamento.
##
## REGOLA: si legge SEMPRE da qui — `Tuning.night_length_min`. Mai
## `load("res://data/tuning.tres")`, che scavalcherebbe l'override esterno in
## silenzio.
##
## L'override esiste perché l'MVP serve a stabilire quanto deve durare l'attesa:
## senza, ogni valore da provare richiede l'editor.
extends Node

const PROFILE_PATH := "res://data/tuning.tres"
const OVERRIDE_PATH := "user://tuning_override.cfg"

## Valori che devono restare strettamente positivi.
##
## L'override esterno esiste perché una build già esportata si possa tarare sul
## posto — cioè lo usa proprio chi NON ha l'editor per accorgersi di un numero
## sbagliato. Un `polar_score_window_sec = 0` battuto per errore non produce un
## errore: produce una finestra che si svuota a ogni frame e un punteggio
## inchiodato a 0 per tutta la partita, in silenzio.
const POSITIVE_KEYS := [
	"night_length_min", "game_min_per_sec", "pose_time_scale",
	"polar_score_window_sec", "polar_max_drift_rate",
	"focus_best_hfd", "focus_max_hfd",
	"cooling_full_drop", "cooling_zero_drop",
]

var profile: TuningProfile

## Identifica con quali numeri è stata giocata una notte. Senza questo, i dati
## di telemetria di notti diverse non sono confrontabili e l'esperimento non
## conclude niente.
var profile_hash: String = ""

# Superficie documentata: Tuning.<nome>, non Tuning.profile.<nome>.
var night_length_min: float:
	get: return profile.night_length_min
var game_min_per_sec: float:
	get: return profile.game_min_per_sec
var pose_time_scale: float:
	get: return profile.pose_time_scale
var polar_score_window_sec: float:
	get: return profile.polar_score_window_sec
var polar_max_drift_rate: float:
	get: return profile.polar_max_drift_rate
var cooling_full_drop: float:
	get: return profile.cooling_full_drop

var cooling_zero_drop: float:
	get: return profile.cooling_zero_drop

var focus_best_hfd: float:
	get: return profile.focus_best_hfd
var focus_max_hfd: float:
	get: return profile.focus_max_hfd
## La curva del payout, letta SEMPRE da qui — mai `load()` diretto sul `.tres` — così
## un override esterno futuro passerebbe da questa superficie come gli altri numeri.
var payout_tiers: Array[Dictionary]:
	get: return profile.payout_tiers


func _ready() -> void:
	if ResourceLoader.exists(PROFILE_PATH):
		profile = load(PROFILE_PATH) as TuningProfile
	if profile == null:
		Log.warn("tuning", "%s assente: uso i valori di default" % PROFILE_PATH)
		profile = TuningProfile.new()
	else:
		profile = profile.duplicate(true)  # mai mutare la risorsa condivisa
	_apply_override()
	profile_hash = _hash()
	Log.info("tuning", "profilo %s — notte %.0f min, %.2f min/s" % [
		profile_hash, profile.night_length_min, profile.game_min_per_sec])


func _apply_override() -> void:
	if not FileAccess.file_exists(OVERRIDE_PATH):
		return
	var cfg := ConfigFile.new()
	if cfg.load(OVERRIDE_PATH) != OK:
		Log.warn("tuning", "override illeggibile, ignorato")
		return
	for section in cfg.get_sections():
		for key in cfg.get_section_keys(section):
			if not (key in profile):
				Log.warn("tuning", "override: chiave sconosciuta '%s'" % key)
				continue
			var value: Variant = cfg.get_value(section, key)
			if key in POSITIVE_KEYS and not _is_positive_number(value):
				Log.warn("tuning", "override: '%s' = %s ignorato, deve essere un numero > 0" % [
					key, value])
				continue
			profile.set(key, value)
			Log.info("tuning", "override: %s = %s" % [key, value])


func _is_positive_number(value: Variant) -> bool:
	var t := typeof(value)
	if t != TYPE_FLOAT and t != TYPE_INT:
		return false
	return float(value) > 0.0


func _hash() -> String:
	var parts := PackedStringArray()
	for p in profile.get_property_list():
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			parts.append("%s=%s" % [p.name, profile.get(p.name)])
	return "\n".join(parts).md5_text().substr(0, 8)
