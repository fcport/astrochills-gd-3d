## I NUMERI DEL PANORAMA, scritti da `tools/prendi_panorama.py`: le quote vere attorno
## all'osservatorio, dove stanno gli alberi e dove le luci dei paesi.
##
## È UNA RISORSA E NON UN FILE DA LEGGERE A MANO perché così la esporta Godot come
## tutto il resto, e perché i nomi dei campi li controlla il parser invece di un
## dizionario. Nessun campo si scrive a mano: si rifà lanciando lo script.
class_name PanoramaDati
extends Resource

## Il punto del gioco (x, z) che corrisponde all'osservatorio vero.
@export var ancora := Vector2.ZERO
## La quota vera dell'osservatorio sul mare, in metri: è lo zero del gioco.
@export var quota_zero := 0.0

## LA GRIGLIA VICINA, quadrata e centrata sull'ancora: `vicino_lato` vertici per lato,
## a `vicino_passo` metri, da −`vicino_mezzo` a +`vicino_mezzo`. Le quote sono riga per
## riga lungo z (da sud a nord) e dentro la riga lungo x (da ovest a est), in metri sopra
## lo zero, con la curvatura della Terra già tolta.
@export var vicino_mezzo := 800.0
@export var vicino_passo := 5.0
@export var vicino_lato := 0
@export var vicino_quote := PackedFloat32Array()

## GLI ANELLI LONTANI: `lontano_raggi` dall'ancora, `lontano_settori` settori per anello
## a partire da nord in senso orario (verso est). Quote anello per anello.
@export var lontano_raggi := PackedFloat32Array()
@export var lontano_settori := 0
@export var lontano_quote := PackedFloat32Array()

## Il colore medio della mappa vicina: la trama del terreno si schiarisce e si scurisce di
## quanto un campo se ne scosta.
@export var colore_vicino_medio := Color(0.2, 0.2, 0.2)
## Quanti metri copre, attorno all'ancora, la mappa del colore lontano; fuori si usa il
## colore medio.
@export var colore_lontano_mezzo := 30000.0
@export var colore_lontano_medio := Color(0.1, 0.1, 0.1)

## GLI ALBERI: x, scala e z (la quota la dà il terreno), e una variante a caso da 0 a 255.
@export var alberi := PackedVector3Array()
@export var alberi_varianti := PackedByteArray()

## LE LUCI DEI PAESI che dall'osservatorio si vedono: posizione e potenza relativa.
@export var luci := PackedVector3Array()
@export var luci_potenza := PackedFloat32Array()

## LA QUOTA DEL TERRENO VERO in un punto (x, z), COME LA DISEGNA LA GRIGLIA: fra un vertice
## e l'altro due triangoli piani, con la diagonale da (i, j) a (i+1, j+1) come la mesh di
## `Panorama`. Non la bicubica: chi deve combaciare con la griglia - il bordo del prato -
## deve leggere la stessa superficie che si vede, o fra le due resta una fessura.
func quota_griglia(p: Vector2) -> float:
	var n := vicino_lato
	var locale := (p - ancora + Vector2.ONE * vicino_mezzo) / vicino_passo
	var i := clampi(int(floor(locale.x)), 0, n - 2)
	var j := clampi(int(floor(locale.y)), 0, n - 2)
	var u := clampf(locale.x - i, 0.0, 1.0)
	var v := clampf(locale.y - j, 0.0, 1.0)
	var h00 := vicino_quote[j * n + i]
	var h10 := vicino_quote[j * n + i + 1]
	var h01 := vicino_quote[(j + 1) * n + i]
	var h11 := vicino_quote[(j + 1) * n + i + 1]
	if u >= v:
		return h00 + u * (h10 - h00) + v * (h11 - h10)
	return h00 + v * (h01 - h00) + u * (h11 - h01)
