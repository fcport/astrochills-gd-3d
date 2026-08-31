## L'interruttore dei toni sintetizzati in codice.
##
## COSA SONO. Il ronzio della lampada, il cigolio della cupola, la montatura del
## telescopio, il borbottio della moka: onde quadre generate a mano in GDScript,
## nate come segnaposto — nessun asset d'arte, coerenti con il resto del progetto,
## che aspetta un pack. Ognuna era ragionevole scritta da sola.
##
## PERCHÉ SONO SPENTE. Tutte insieme, in loop, per un'ora di notte, non fanno un
## ambiente: fanno un'onda quadra continua sotto ogni cosa. È un giudizio
## d'operatore — «il suono è un incubo», 31 agosto 2026 — e vale più di quattro
## commenti che spiegano perché ogni singolo tono aveva senso. Una notte muta è
## meglio di una notte che ronza.
##
## LE SPENTE SONO SOLO QUELLE CONTINUE. I suoni brevi restano: il beep del
## terminale, quello della BBS, la portante del modem, il campanello di fine
## sequenza. Durano un istante, dicono che qualcosa è successo, e nessuno li tiene
## in testa. Il problema non era il timbro, era la durata.
##
## COME SI RIACCENDONO: `CONTINUI = true`, e basta questa riga. Il giorno in cui
## arriveranno i campioni veri, ogni nodo ha già il proprio posto dove metterli —
## `_install_*_sound()` — e questo file sparisce con un `git rm`.
class_name ToniSegnaposto

## I toni continui suonano o no.
const CONTINUI := false


## Se un tono continuo può partire: deve essere acceso E ci deve essere
## un'uscita audio vera.
##
## LA SECONDA METÀ È SEPARATA DALLA PRIMA, e non per eleganza: in headless — il
## cancello, il banco, l'import — il driver è `Dummy`, e un suono avviato che
## l'engine spegne a forza lascia il proprio playback come istanza persa, cioè un
## WARNING che fa fallire il cancello di verifica. Era una guardia già presente,
## ricopiata in quattro file; adesso sta in uno.
static func continui() -> bool:
	return CONTINUI and DisplayServer.get_name() != "headless"


## Se un suono BREVE può partire. Non passa dall'interruttore: i beep restano.
static func brevi() -> bool:
	return DisplayServer.get_name() != "headless"
