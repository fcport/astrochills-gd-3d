## Sotto-contratto tipizzato della fase del raffreddamento (ADR-001, Pattern 1).
##
## `PhaseTruthSource` è un marker senza metodi, apposta: ogni fase dichiara qui la
## firma che le serve, e un nome sbagliato non compila invece di fallire in
## silenzio a runtime.
##
## DUE METODI E NON UNO, ed è una scelta che va difesa. Questa fase ha DUE cose
## osservabili — la temperatura del sensore e quanto sta lavorando il
## refrigeratore — e sono due letture distinte sullo stesso apparecchio, esattamente
## come sul pannello di CCDOPS. Farne un `Vector2` le avrebbe messe in una scatola
## dove `x` e `y` non vogliono dire niente; farne un oggetto sarebbe stato un
## oggetto nuovo per due numeri. Sono due funzioni pure dello stesso ingresso, e il
## banco le collauda separatamente.
##
## Chi eredita: `HonestPeltier` (MVP, dice la verità). La bugia che il GDD promette
## per questa fase è di questa firma: una temperatura che scende sotto il possibile,
## e dei dark che a quella temperatura contengono qualcosa.
class_name CoolingTruthSource
extends PhaseTruthSource


## Da che temperatura si parte: quella della cupola, perché la cella è spenta.
##
## VIENE DALLA SORGENTE E NON DALLA FASE, e non è pedanteria: è un'OSSERVAZIONE —
## il termometro della camera al momento in cui la accendi — ed è la prima cosa che
## una sorgente bugiarda vorrà falsificare. La fase, che da questo numero calcola
## tutto il proprio punteggio, non deve poterlo scegliere.
func ambient_temperature() -> float:
	push_error("[cooling] sorgente astratta: usa una sottoclasse")
	return 0.0


## Di quanto cambia la temperatura del sensore, in GRADI AL SECONDO. Negativa
## raffredda.
##
## UNA VELOCITÀ E NON UNA TEMPERATURA, come la deriva polare e come il battente
## della cupola, e per la stessa ragione: la fase la integra, e il giocatore vede
## il numero muoversi mentre guarda. Con una temperatura la sorgente diventerebbe
## padrona anche del tempo, e una bugia sul tempo non si distingue da uno scatto.
func sample(_input: CoolingInput, _delta: float) -> float:
	push_error("[cooling] sorgente astratta: usa una sottoclasse")
	return 0.0


## Quanto sta lavorando il refrigeratore, da 0 a 1.
##
## È LA SOLA COSA CHE INSEGNA QUESTA FASE. La temperatura dice dove sei; questa
## dice se ci puoi restare. Un Peltier al cento per cento non è un Peltier che va
## forte: è un Peltier che ha finito i margini, e alla prima folata la temperatura
## se ne va — con i dark che non corrispondono più.
func duty(_input: CoolingInput) -> float:
	push_error("[cooling] sorgente astratta: usa una sottoclasse")
	return 0.0
