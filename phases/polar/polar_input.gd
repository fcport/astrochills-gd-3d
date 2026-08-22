## Ciò che la fase polare passa alla propria sorgente di verità.
##
## È un RefCounted e non una Resource: non va salvato, non va condiviso, e vive
## quanto un fotogramma. La fase ne tiene una sola istanza e la riempie a ogni
## _process, invece di allocarne una nuova sessanta volte al secondo.
class_name PolarInput
extends RefCounted

## Errore residuo di azimuth, in arcominuti — cioè dove sta la vite adesso.
## Zero = allineato.
var azimuth: float = 0.0

## Errore residuo di altitudine, in arcominuti. Zero = allineato.
var altitude: float = 0.0

## Secondi da quando il giocatore ha toccato l'ultima volta una vite.
##
## Nessuna sorgente dell'MVP lo usa: la deriva onesta dipende solo dall'errore.
## Sta qui perché è nel contratto dichiarato dall'architettura, e perché una
## bugia futura del tipo «si comporta bene solo mentre la guardi» avrebbe bisogno
## esattamente di questo e di nient'altro.
var seconds_since_correction: float = 0.0
