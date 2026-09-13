## Una pagina del quaderno delle procedure. SOLO DATI, nessuna logica.
##
## Sul modello di `data/forum/forum_message.gd`: una Resource di soli `@export`,
## salvata e diffabile come `.tres`. Il quaderno la LEGGE — l'impaginazione e l'a
## capo vivono su `QuadernoData`, dove il banco le può collaudare.
##
## È ITALIANO, ed è la regola della lingua (NFR10): il quaderno lo ha battuto a
## macchina una persona per chi viene dopo, non lo stampa un programma. I nomi dei
## programmi e le scritte che si leggono sul CRT restano come li scrive la macchina
## — MaxIm DL, COOLER, GOTO — perché è così che il giocatore li troverà a schermo.
class_name PaginaQuaderno
extends Resource

## Il titolo, in cima alla pagina. Corto: sta su una riga sola della colonna.
@export var titolo: String = ""

## Il corpo. Un a capo vero separa i paragrafi; dentro un paragrafo l'a capo lo
## decide `QuadernoData.a_capo()`, alla larghezza della colonna.
@export_multiline var testo: String = ""

## La `Phase.key()` della fase che questa pagina spiega, o vuota per le pagine
## generali. Serve al banco: ogni fase del piano della notte deve avere la sua
## pagina, o il quaderno smette di dire la verità il giorno che se ne aggiunge una.
@export var fase: StringName = &""
