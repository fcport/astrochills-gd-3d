## LA LUCE DEL CIELO CHE ENTRA DALLA FENDITURA, e solo da lì.
##
## COSA FA, IN UNA RIGA: ascolta `Events.dome_aperture_changed` e accende sé stessa
## in proporzione a quanto la cupola è aperta.
##
## PERCHÉ NON BASTAVA ALZARE L'AMBIENTE. La richiesta era: «se sono dentro è tutto
## super buio, ma quando apro la cupola un po' di luce da lì riesce a penetrare». La
## luce ambientale non sa fare questo, ed è già stato misurato in questo progetto:
## portandola da 0,035 a 0,11, la colonna in ombra sotto il lavabo del bagno saliva
## di 3,5 livelli su 255 — e la sala divulgazione **spenta** saliva esattamente di
## 3,5. L'ambiente non distingue una stanza aperta da una chiusa: schiarisce tutto
## allo stesso modo, e il nero diventa latte. Serve una lampada vera, che i muri
## possano fermare.
##
## QUINDI È UN PROIETTORE SOPRA LA CALOTTA, non una sorgente dentro la sala. Sta a
## nove metri, guarda in giù, e proietta ombra: a cupola chiusa il guscio se la
## mangia tutta, a cupola aperta scende dalla fenditura. È la stessa cosa che fa il
## cielo vero, fatta con l'unico attrezzo che un rasterizzatore ha per farla.
##
## E L'ENERGIA SEGUE L'APERTURA lo stesso, pur essendoci l'ombra a fare il lavoro.
## Non è una cintura con le bretelle: a spiraglio appena aperto la mappa d'ombra ha
## pochi texel su cui decidere, e quello che passerebbe sarebbe un tremolio invece
## di una lama. Moltiplicare per l'apertura fa nascere la luce **da zero** insieme
## alla fessura, che è anche il modo in cui la si vede arrivare.
##
## NON TOGLIE L'ADATTAMENTO AL BUIO, ed è un vincolo dichiarato, non un caso: è la
## stessa ragione per cui in cupola la luce è rossa e per cui le due lampade esterne
## valgono un decimo di una plafoniera (D-011 e il commento delle applique). Chi
## lavora di notte ci mette venti minuti a farsi l'occhio e un lampo glieli azzera.
## `ENERGIA_PIENA` è tarata per far **comparire le sagome**, non per illuminare: a
## cupola spalancata il pavimento della cupola sta ancora sotto quello che una
## plafoniera accesa dà a una stanza vuota.
class_name SkyLight
extends SpotLight3D

## Quanta energia a cupola tutta aperta. Il resto è proporzione diretta.
##
## IL NUMERO È GRANDE E NON VUOL DIRE «FORTE»: un'energia si legge solo insieme alla
## portata e all'attenuazione, e questo proiettore sta a NOVE METRI con la portata
## dichiarata a ventisei — cioè lontanissimo dal suo limite, apposta, perché un cielo
## non ha una distanza. Con la portata a dieci, il pavimento della cupola riceveva un
## terzo di quello che riceveva la calotta tre metri più su, e si vedeva: la luce
## moriva a mezz'aria. Con ventisei la differenza scende sotto il dieci per cento e la
## sala si illumina tutta uguale, che è quello che fa il cielo.
##
## MISURATO con `tools/prova_trafila.gd`, lampade tutte spente, in livelli su 255
## dalla passerella verso il pavimento della cupola:
##
##     energia   cupola chiusa   cupola aperta
##       0,42        niente          0,38     invisibile: non è poca luce, è zero
##       1,20        niente          6,27     il telescopio si staglia, il parapetto
##                                            si legge, il resto resta silhouette
##
## E LA PROVA CHE CONTA È L'ALTRA: a cupola spalancata, dalla sala divulgazione
## questa luce misura **meno di 0,05**, cioè non esce dalla cupola. Era il difetto di
## D-181 — una luce senza ombra sta in tutte le stanze insieme — e qui non c'è.
const ENERGIA_PIENA := 1.2

## Sotto questa apertura non si accende affatto. Uno spiraglio di due centimetri non
## fa entrare niente di misurabile, e accendere comunque vorrebbe dire un velo che
## compare mentre la fessura non si vede ancora — cioè una luce senza causa
## visibile, che è il difetto di D-181 rifatto apposta.
##
## E NON È LA SOGLIA CHE COMANDA DAVVERO: è il guscio. Misurato, ad apertura 0,5 la
## luce del cielo sul pavimento vale ancora meno di 0,05, perché i due portelli a
## metà corsa stanno proprio SOPRA, attorno allo zenit, dove sta il proiettore.
## Comincia a passare qualcosa solo quando si scostano davvero. Non è un difetto da
## correggere — è quello che fa una cupola vera, e vuol dire che aprire a metà non
## serve a vedere: serve solo a puntare.
const SOGLIA := 0.04

var _apertura := 0.0


func _ready() -> void:
	light_energy = 0.0
	Events.dome_aperture_changed.connect(_su_apertura)


func _su_apertura(fraction: float) -> void:
	_apertura = clampf(fraction, 0.0, 1.0)
	if _apertura < SOGLIA:
		light_energy = 0.0
		return
	# Da SOGLIA a 1 si rimappa su 0..1: così la luce parte davvero da zero nel punto
	# in cui si accende, invece di scattare a un gradino.
	var q := (_apertura - SOGLIA) / (1.0 - SOGLIA)
	light_energy = ENERGIA_PIENA * q


## Quanto la cupola è aperta, secondo quello che questa luce ha sentito. Serve alle
## sonde: un controllo che legge il segnale invece dello stato non prova niente sul
## fatto che il nodo lo abbia ricevuto.
func aperture() -> float:
	return _apertura
