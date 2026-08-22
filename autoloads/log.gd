## Logging tecnico. CANALE 1: solo per lo sviluppatore.
##
## Un fallimento diegetico non passa mai da qui — quello è un PhaseResult che il
## giocatore legge sul CRT. Vedi game-architecture.md § Cross-cutting Concerns.
extends Node

enum Level { ERROR, WARN, INFO, DEBUG }

## In release il livello scende a INFO: DEBUG non deve costare nulla.
var min_level: Level = Level.DEBUG

var _log_path := ""


func _ready() -> void:
	min_level = Level.DEBUG if OS.is_debug_build() else Level.INFO
	var date := Time.get_date_string_from_system()
	_log_path = "user://logs/%s.log" % date
	DirAccess.make_dir_recursive_absolute("user://logs")


func error(system: String, msg: String) -> void:
	_write(Level.ERROR, system, msg)


func warn(system: String, msg: String) -> void:
	_write(Level.WARN, system, msg)


func info(system: String, msg: String) -> void:
	_write(Level.INFO, system, msg)


func debug(system: String, msg: String) -> void:
	_write(Level.DEBUG, system, msg)


func _write(level: Level, system: String, msg: String) -> void:
	if level > min_level:
		return
	var line := "%s [%s] %s" % [Level.keys()[level], system, msg]
	print(line)
	if _log_path.is_empty():
		return
	var f := FileAccess.open(_log_path, FileAccess.READ_WRITE)
	if f == null:
		f = FileAccess.open(_log_path, FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line("%s %s" % [Time.get_time_string_from_system(), line])
	f.close()
