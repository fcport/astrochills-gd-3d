## Ciò che la fase di imaging passa alla propria sorgente di verità.
##
## È un RefCounted e non una Resource: non va salvato, non va condiviso, e vive
## quanto un fotogramma. La fase ne tiene una sola istanza e la riempie a ogni
## _process, sul modello dell'input della fase di targeting.
class_name ImagingInput
extends RefCounted

## Minuti di gioco trascorsi dall'avvio della sequenza: `run.elapsed_min` meno
## l'istante di partenza. È l'orologio della notte, non un accumulatore duplicato,
## così pausa e `Engine.time_scale` valgono gratis.
var elapsed_since_start_min: float = 0.0

## Quanti frame la sequenza deve acquisire in totale, scelti dal giocatore in
## configurazione.
var frames_total: int = 0

## Minuti di gioco consumati da un singolo frame di posa. È `Tuning.min_per_frame`,
## passato qui perché la sorgente resti una funzione pura del proprio input e non
## legga l'autoload da sola.
var min_per_frame: float = 0.0
