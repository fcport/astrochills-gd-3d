## LA GEOMETRIA DEL CIELO SOPRA QUESTO OSSERVATORIO. Solo funzioni statiche.
##
## PERCHÉ ESISTE UN FILE SOLO PER TRE FORMULE. Servono a due fasi diverse — il
## planetario deve sapere quanto è alto un soggetto, il GOTO deve sapere dove
## mandarci il tubo — e sono lo stesso fatto. Scritte due volte, il giorno in cui
## una cambia il planetario offrirebbe un oggetto che il GOTO non riesce a
## raggiungere, e nessuno dei due file sarebbe sbagliato da solo.
##
## `phases/` non può conoscere `world/` né `night/`: qui dentro non c'è niente che
## li nomini, solo trigonometria e due costanti dichiarate.
class_name SkyGeometry


## La latitudine di Montegrimano (PU). Sta anche in `tools/geometria.py`, che è la
## sorgente per il modello 3D; il banco verifica che le due non divergano.
const LATITUDINE := 43.9


## SOTTO QUESTA ALTEZZA QUESTA CUPOLA NON VEDE FUORI, in gradi.
##
## NON È UNA REGOLA DI GIOCO, È UNA MISURA. Il raggio del telescopio esce
## dall'apertura a un metro e ottanta da terra, mentre il foro del tetto sta a
## tre e venti: puntando basso il raggio esce dalla fenditura, scende, e trova la
## falda. Nessun azimut della cupola può aiutare — è l'orizzonte dell'EDIFICIO.
## Misurato da `tools/prova_orizzonte.gd`, che spara il raggio vero contro la
## geometria vera: 43,1 gradi nel punto migliore, 47,7 nel peggiore.
##
## SI PRENDE IL PEGGIORE, perché il migliore vale solo in una direzione: offrire
## un soggetto che si raggiunge a est e non a ovest sarebbe peggio che non
## offrirlo. E il numero È ALTO — così alto che due dei sei soggetti non si
## vedono mai da qui. La cura non è ritoccare questa riga: è alzare lo strumento
## dentro la cupola, e quanto costerebbe è misurato (`ALZA=` nella stessa sonda).
const ORIZZONTE_CUPOLA := 47.7


## L'altezza sull'orizzonte di un punto del cielo, in gradi. Trigonometria
## sferica classica, la stessa con cui si è tarato `AR_ZERO` della montatura.
static func altezza(ha_gradi: float, dec_gradi: float) -> float:
	var h := deg_to_rad(ha_gradi)
	var d := deg_to_rad(dec_gradi)
	var l := deg_to_rad(LATITUDINE)
	return rad_to_deg(asin(sin(d) * sin(l) + cos(d) * cos(l) * cos(h)))


## L'altezza massima che un soggetto raggiunge in tutta la notte: quella del
## passaggio in meridiano. Serve a dire se è raggiungibile MAI, che è una
## domanda diversa da «è raggiungibile adesso».
static func altezza_massima(dec_gradi: float) -> float:
	return altezza(0.0, dec_gradi)


## Il telescopio riesce a guardarlo da dentro questa cupola.
static func raggiungibile(ha_gradi: float, dec_gradi: float) -> bool:
	return altezza(ha_gradi, dec_gradi) >= ORIZZONTE_CUPOLA
