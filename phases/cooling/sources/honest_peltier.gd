## La sorgente onesta della fase del raffreddamento: il Peltier fa quello che può.
##
## L'aggettivo nel nome dice se e come mente (NFR23). Questa non mente, e la fisica
## sta in tre righe: la cella scende di tanti gradi sotto l'ambiente e non di più;
## quello che le chiedi entro quel margine lo ottiene; quello che le chiedi oltre lo
## insegue senza arrivarci, e mentre lo insegue ondeggia.
##
## FUNZIONE PURA DI `input`, ed è un requisito e non uno stile: nessuno stato
## interno, `delta` mai usato. L'ondeggiare quando la cella satura è una funzione
## del TEMPO — `input.seconds_running`, non un numero casuale — proprio perché
## `sample(i, 0.016)` e `sample(i, 0.99)` devono dare lo stesso valore, ed è ciò che
## il banco verifica.
##
## PERCHÉ UN'ESPONENZIALE E NON UNA RAMPA. Una massa che si raffredda si avvicina
## alla propria temperatura di equilibrio di una frazione fissa per unità di tempo:
## veloce all'inizio, lenta alla fine. È anche il motivo per cui l'ultimo grado
## costa quanto i primi dieci, ed è la ragione per cui questa fase È un'attesa.
class_name HonestPeltier
extends CoolingTruthSource

## Quanto fa freddo in cupola, in gradi.
##
## STA QUI E NON IN `Tuning` perché è una proprietà della NOTTE e non del
## bilanciamento, e sta in un `.tres` perché il giorno in cui esisterà un meteo
## arriverà da lì con una riga sola. FINCHÉ È FISSO, IL SETPOINT MIGLIORE È SEMPRE
## LO STESSO e chi gioca molte notti lo impara: è lo stesso limite dichiarato dal
## fuoco, e ha la stessa cura — una temperatura che cambia con la notte.
@export var ambient: float = 6.0

## Di quanti gradi sotto l'ambiente arriva la cella a piena potenza.
##
## Trentotto è quello che dichiarava una SBIG a due stadi, e non è un numero
## rotondo per caso: è il confine fra ciò che si può chiedere e ciò che no, cioè
## l'intera decisione che questa fase chiede al giocatore.
@export var max_drop: float = 38.0

## In quanti secondi la differenza dalla temperatura di equilibrio si riduce a un
## terzo. Piccolo: la notte dura un'ora vera, e un raffreddamento realistico da
## quindici minuti sarebbe un quarto d'ora di niente. Il default è quello del `.tres`:
## un default diverso dal dato vero è una seconda risposta alla stessa domanda.
@export var time_constant: float = 6.0

## Di quanto ondeggia la temperatura quando la cella è satura, in gradi.
##
## UN GRADO E DUE, E LENTO. La prima stesura aveva mezzo grado ogni undici secondi
## e non si vedeva NIENTE: il sensore ha una costante di tempo di sei secondi e si
## comporta da filtro — un'oscillazione più rapida della propria inerzia la
## smorza a un quarto, e il referto diceva «cella al 100%» con la temperatura
## ferma e il punteggio pieno. Che è il contrario di quello che questa fase deve
## insegnare.
##
## E la forma giusta è anche più vera: una cella satura non oscilla per conto suo,
## SEGUE L'AMBIENTE. Il vento gira, la temperatura in cupola si muove di un grado
## nel giro di mezzo minuto, e senza margine di regolazione il sensore se la porta
## dietro tutta.
@export var wobble: float = 1.2

## Quanto vale un ondeggio completo, in secondi.
@export var wobble_period: float = 26.0


## Con la cella spenta, il sensore sta alla temperatura della cupola.
func ambient_temperature() -> float:
	return ambient


## La temperatura più bassa che la cella può tenere davvero.
func floor_temperature() -> float:
	return ambient - max_drop


## La temperatura verso cui il sensore sta andando, dato ciò che si è chiesto.
##
## È il cuore onesto della fase: se chiedi meno del possibile, ottieni quello che
## hai chiesto; se chiedi di più, ottieni il fondo — non quello che volevi.
func equilibrium(input: CoolingInput) -> float:
	var fondo := floor_temperature()
	if input.setpoint >= fondo:
		return input.setpoint
	# SATURA: si va al fondo, e lì si ondeggia. L'ondeggio è il sintomo che il
	# giocatore deve imparare a leggere, e non un effetto grafico: una temperatura
	# che balla è una serie di dark che non corrisponde più alle pose.
	var giro := TAU * input.seconds_running / maxf(wobble_period, 0.001)
	return fondo + wobble * sin(giro)


func sample(input: CoolingInput, _delta: float) -> float:
	var bersaglio := equilibrium(input)
	return (bersaglio - input.temperature) / maxf(time_constant, 0.001)


## Quanto sta lavorando la cella, da 0 a 1.
##
## PROPORZIONALE A QUANTO SI STA CHIEDENDO, non a quanto manca: una cella che ha
## raggiunto meno venti e li tiene sta lavorando quanto serve per tenerli, e quel
## lavoro dipende da quanto è distante l'ambiente — non dal fatto che sia arrivata.
## È la lettura che sul pannello di CCDOPS restava alta anche a temperatura ferma, e
## chi la guardava capiva se avrebbe retto la notte.
func duty(input: CoolingInput) -> float:
	var chiesto := ambient - maxf(input.setpoint, floor_temperature())
	return clampf(chiesto / maxf(max_drop, 0.001), 0.0, 1.0)

