## EventBus — SOLO per i fatti di notte che interessano a più di due ascoltatori.
##
## LA REGOLA: se sai chi ascolta ed è uno solo → signal diretto sull'emettitore.
## Se non lo sai, o sono più di due → qui.
##
## Senza questa regola il bus diventa una discarica in tre mesi e nessuno sa più
## chi ascolta cosa. Tutti i signal sono dichiarati e tipizzati: un nome
## sbagliato non deve fallire in silenzio.
extends Node

## Un CrtScreen si annuncia entrando in scena. È così che `night/` raggiunge il
## monitor senza conoscere `world/`, dove il monitor fisicamente vive.
signal screen_registered(screen: Node)

signal phase_started(key: StringName)
signal phase_finished(key: StringName, score: int)

signal hour_passed(hour: int)
signal dawn_reached()

signal photo_sold(photo_id: StringName, lire: int)

## Attività durante la posa: è ciò con cui si misura l'ipotesi dell'MVP.
##
## Due signal e non uno con un argomento «inizio/fine», per tre ragioni:
## la regola di naming vuole il passato e questi sono due fatti distinti; non
## servono stringhe magiche da sbagliare; e un rituale abbandonato si riconosce
## da solo — è uno `started` senza il suo `ended`, che è precisamente il dato
## che serve, non un buco.
##
## Chi ascolta ricava la durata di ogni attività dalla coppia, e i tratti `idle`
## per differenza sulla finestra della posa. Senza la coppia, `idle` non è
## calcolabile e l'esperimento perde il suo dato più importante.
signal wait_activity_started(what: StringName)
signal wait_activity_ended(what: StringName)

## LA SEQUENZA STA GIRANDO — e non «lo schermo della sequenza esiste».
##
## PERCHÉ NON BASTAVA `phase_started(&"imaging")`. Quello lo emette l'orchestratore
## quando MONTA la fase, cioè quando compare il pannello di configurazione: da lì al
## momento in cui il giocatore preme START passa tutto il tempo che gli serve per
## scegliere frame ed esposizione. Il telescopio inseguiva e la montatura ronzava per
## tutto quel tempo, e la cupola contava «sto a guardare la posa» quando nessuna posa
## esisteva. Sono due fatti distinti e servono due segnali distinti.
##
## SENZA CHIAVE, di proposito: chi ascolta non deve più filtrare su `&"imaging"`, e
## la stringa sparisce da `world/`. Se un giorno una seconda fase avrà una sequenza,
## emetterà lo stesso fatto e il mondo risponderà senza sapere chi è stato.
##
## `sequence_ended` arriva SEMPRE, e arriva una volta sola: a sequenza conclusa, e
## anche quando la fase viene smontata a sequenza in corso — l'alba durante una posa,
## o *rifai setup*. Senza quel secondo caso il telescopio resterebbe a ronzare per il
## resto della partita. NON è il segnale del suono di fine sequenza: quello resta
## `phase_finished`, perché una posa interrotta non ha finito niente e non deve suonare.
signal sequence_started()
signal sequence_ended()

## Un articolo è stato comprato al terminale. È il SEAM verso 3.3/3.4: il terminale
## scala il portafoglio, marca il possesso e salva, poi ANNUNCIA qui — senza sapere
## chi ascolta. La moka in cucina (3.3) e la lampadina (3.4) nasceranno ascoltando
## questo segnale e leggendo `Game.profile.owns(id)`. 3.2 consegna il contratto, non
## il suo consumatore: nessuna moka finta, nessun effetto simulato.
##
## Sul bus e non diretto perché gli ascoltatori saranno più di uno (moka, lampadina,
## e domani la telemetria degli acquisti) e non si conoscono fra loro. `id` tipizzato
## e al passato, come ogni altro segnale qui.
signal item_purchased(id: StringName)

## Il menu post-foto è stato PRESENTATO. È il condotto di `menu_reopened` della
## telemetria (3.6): il menu `extends Control`, non `Phase`, quindi non emette
## `phase_started` e nessun altro segnale annunciava che era comparso.
##
## Sul bus e non diretto per la stessa ragione di `wait_activity_*`: chi è misurato
## (`night/`, che monta il menu) non deve conoscere chi misura (`Telemetry`), e
## togliendo l'autoload il segnale resta a cadere nel vuoto senza rompere niente.
## Ogni PRESENTAZIONE è un fatto — inclusa la riapertura di *chiudi ed esplora* — non
## ogni menu distinto: chi conta somma le presentazioni.
signal photo_menu_opened()

## DOVE STA IL BATTENTE DELLA CUPOLA, 0 chiusa, 1 tutta aperta.
##
## È UN FATTO E NON UN COMANDO, e la distinzione è tutta la ragione per cui il
## segnale sta qui. La fase 1 vive in `phases/`, la cupola in `world/`, e le due
## cartelle non si nominano a vicenda: la fase dice ad alta voce dov'è arrivata la
## corsa, e chi in giro per il mondo ha un battente lo mette lì. Il giorno in cui
## la cupola la aprirà un interruttore in loco, o un temporizzatore, o un upgrade,
## quel qualcosa dirà lo stesso fatto e il mondo risponderà senza sapere chi è
## stato — è la stessa proprietà per cui `sequence_started` non porta più la chiave
## della fase.
##
## PORTA LA POSIZIONE E NON «APERTA/CHIUSA»: il battente si vede muovere, e un
## booleano lo farebbe scattare. Chi ascolta insegue il valore.
signal dome_aperture_changed(fraction: float)


## Qualcuno tiene premuto un pulsante del quadro della cupola: +1 apre, -1 chiude,
## 0 ha lasciato.
##
## VA NEL VERSO OPPOSTO A `dome_aperture_changed`, ed e' l'unica coppia di segnali
## del bus che fa il giro completo: il mondo dice che cosa sta premendo una mano,
## la notte risponde dove sta il battente. Sono due FATTI, nessuno dei due e' un
## comando dato a qualcuno in particolare — e infatti il quadro non sa che esista
## una fase, e la fase non sa che esista un quadro.
##
## SOLO QUANDO CAMBIA: un pulsante tenuto premuto sei secondi non deve riempire il
## bus di trecentosessanta copie dello stesso numero.
signal dome_button_changed(direction: int)


## DOVE STA PUNTANDO IL TUBO, in angolo orario e declinazione (gradi).
##
## È UN FATTO E NON UN COMANDO, esattamente come `dome_aperture_changed`, e per la
## stessa ragione: le fasi del puntamento vivono in `phases/`, la montatura in
## `world/`, e le due cartelle non si nominano a vicenda. Il software dice ad alta
## voce dove ha mandato il tubo; chi in giro per il mondo ha un telescopio lo porta
## lì. La cupola non ascolta questo segnale — insegue il tubo VERO, misurandogli
## l'apertura, perché su una equatoriale tedesca l'azimut della fessura non è
## quello del telescopio (vedi `world/dome_azimuth.gd`).
##
## PORTA LA POSIZIONE FISICA, non quella che il software CREDE. È la distinzione
## su cui gira tutta la fase 5: finché la montatura non è sincronizzata le due
## cose differiscono di qualche grado, e chi muove il tubo deve ricevere la prima.
## La seconda non esce mai da `phases/`, che è dove sta il software.
signal telescope_aim_changed(ha_gradi: float, dec_gradi: float)


## LA MONTATURA SI STA MUOVENDO, o si è appena fermata.
##
## SERVE PERCHÉ IL FERRO È LENTO E IL SOFTWARE NO. Chi comanda un puntamento sa
## subito dove ha mandato il tubo, ma il tubo ci mette una decina di secondi ad
## arrivarci: senza questo fatto lo schermo direbbe di essere sul bersaglio mentre
## il telescopio è ancora a mezza strada, e la fase accetterebbe un SYNC su una
## stella che nessuno ha ancora inquadrato.
##
## SOLO QUANDO CAMBIA, come `dome_button_changed`: un tubo fermo per dieci minuti
## non deve dirlo trentaseimila volte.
signal telescope_slewing_changed(moving: bool)


## C'È CORRENTE, o non c'è più.
##
## Lo dice il quadro in facciata quando qualcuno preme il fungo rosso. Le luci le
## stacca il quadro stesso, che le ha in elenco; questo segnale è per tutto il
## RESTO di quello che il GDD affida al contatore — «PC, monitor, montatura» — che
## oggi non lo ascolta ancora. Sta sul bus e non è un signal diretto proprio per
## questo: gli ascoltatori saranno più di uno e non si conoscono fra loro.
signal mains_changed(on: bool)
