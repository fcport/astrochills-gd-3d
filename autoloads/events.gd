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
