## IL CIELO GIRA, IL TUBO LO INSEGUE, LA CUPOLA GLI VA DIETRO. Tutti e tre insieme.
##
## PERCHÉ SERVE UNA SONDA. Perché i tre pezzi si muovono di pochissimo — un sesto di
## grado al secondo — e un errore di segno, di fattore o di asse produce esattamente
## lo stesso spettacolo di quello giusto: qualcosa che gira piano. La differenza si
## vede dopo mezz'ora di gioco, cioè in un momento in cui nessuno sta più guardando,
## e si vede come «il soggetto è uscito dall'inquadratura» — un guasto che sembra un
## difetto di taratura.
##
## E I TRE PEZZI STANNO IN TRE FILE CHE NON SI CONOSCONO: il giro in
## `world/tempo_siderale.gd`, l'inseguimento in `world/telescope_mount.gd`, la
## calotta in `world/dome_azimuth.gd`. Che siano d'accordo non lo garantisce nessuno
## dei tre.
##
## LE DOMANDE:
##   0. DA CHE PARTE GIRA. A est le stelle salgono. È la sola domanda che non si
##      risponde confrontando il cielo col telescopio — due cose capovolte nello
##      stesso modo restano d'accordo — e si risponde guardando l'orizzonte.
##   1. QUINDICI GRADI L'ORA. Il giro cresce come il tempo, col fattore della Terra.
##   2. LO SHADER LO SA. Il numero non resta in memoria: finisce nel materiale del
##      cielo, che è l'unico posto in cui serve a qualcosa. Fra i due c'è una
##      `set_shader_parameter`, ed è esattamente il punto in cui un giro perfetto può
##      non arrivare da nessuna parte.
##   3. PARCHEGGIATA NON INSEGUE. A montatura appena accesa i motori sono fermi:
##      inseguire prima che qualcuno abbia puntato vorrebbe dire un tubo che si muove
##      da solo mentre il giocatore entra in cupola.
##   4a. ATTORNO A COSA GIRA IL TUBO. Si misura l'asse vero della montatura come
##      bisettrice fra due puntamenti opposti, e lo si confronta col polo celeste. È
##      la misura che spiega tutte le altre: girano attorno alla stessa retta o no.
##   4b. IL TUBO TIENE LA STELLA. È la domanda vera: si prende un punto del CIELO, si
##      lascia passare la notte, e si guarda se il telescopio ci sta ancora sopra.
##   5a. LA CUPOLA PARTE A STRAPPI. Non insegue di continuo: accumula quattro gradi di
##      errore e poi si muove (`DomeAzimuth.GIOCO`). Si conta quante volte parte in
##      quattro ore, e quanto errore arriva ad accumulare.
##   5b. E ALLO ZENIT NON CE LA FA. Non è una prova, è una misura: su un soggetto che
##      culmina a ottantanove gradi l'azimut d'uscita fa mezzo giro in pochi minuti,
##      e un motore da otto gradi al secondo non lo insegue. Si scrive quanto resta
##      indietro, perché è un fatto di questa cupola e non un guasto da correggere.
##   6. IL FINECORSA. Inseguendo, l'angolo orario cresce di quindici gradi l'ora: a un
##      certo punto la montatura si deve fermare invece di portare il tubo nel pilastro.
##
## I DIFETTI SI RIMETTONO, uno per interruttore, e ognuno spegne una risposta diversa:
##   NON_INSEGUE=1   i motori d'inseguimento spenti: è il gioco di ieri, e la stella
##                   si deve perdere di quindici gradi l'ora. Se la 4 non lo vedesse,
##                   non starebbe misurando l'inseguimento ma la propria aritmetica.
##   FERMO=1         il cielo fermo: la calotta non deve più partire (la 5 a zero).
##   SENZA_LIMITE=1  nessun finecorsa: si vede dove va a finire il tubo.
##
##     Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_rotazione.tscn
##     NON_INSEGUE=1 Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_rotazione.tscn
##     FERMO=1 Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_rotazione.tscn
##     SENZA_LIMITE=1 Godot_v4.7.2-stable_win64.exe --headless --path . tools/prova_rotazione.tscn
##
## IL TEMPO SCORRE, NON SI SCRIVE, ed è la seconda stesura di questa sonda: la prima
## metteva le ore a mano dentro `Game.run.elapsed_min`. Funzionava per il cielo — che
## è una funzione dell'ora e basta — e mentiva su tutto il resto, perché i motori
## della montatura e della calotta si muovono a gradi al SECONDO: spostando l'ora di
## un'ora in un fotogramma si misura la velocità del motore, non l'inseguimento. Qui
## si accelera il tempo con `Engine.time_scale` — lo stesso attrezzo di `F1`-`F4` —
## e i rapporti fra le tre velocità restano quelli veri.
##
## E TUTTO STA DENTRO UNA NOTTE SOLA. All'alba `Game.run` sparisce, e una sonda che
## la superasse si troverebbe senza orologio a metà misura. Nove ore sono il tetto:
## si punta a mezzanotte e si insegue fino alle sei, che è anche quello che farebbe
## un turnista.
extends Node

## Quanto si accelera il tempo. A sessanta, una notte di nove ore dura un quarto di
## minuto reale, e restano trentasei minuti di gioco per ogni secondo.
const SCALA := 20.0

## E IL PASSO DEI FOTOGRAMMI SI FISSA, che senza sarebbe la misura a ballare. In
## headless il gioco gira a migliaia di fotogrammi al secondo e ogni `delta` vale
## un pelo: i motori si muovono a passi minuscoli e la sonda misura un errore; su
## un'altra macchina i passi sono altri e l'errore e' un altro numero. Misurato:
## senza questa riga l'errore massimo della fessura ballava fra 8,8 e 13,1 gradi da
## un lancio all'altro, cioe' la soglia non voleva dire niente. Sessanta fotogrammi
## al secondo sono quelli a cui il gioco si gioca.
const FOTOGRAMMI := 60

## Le tappe della notte, in minuti dall'inizio (le 21:00).
const T_RITMO_DA := 20.0
const T_RITMO_A := 60.0
const T_FERMA := 120.0        ## fin qui la montatura non l'ha toccata nessuno
const T_PUNTA := 125.0        ## si punta, e si aspetta che il tubo ci arrivi
const T_STELLA := 130.0
const T_FINE := 370.0         ## quattro ore di inseguimento, dalle 23:10 alle 03:10
const T_ZENIT := 375.0        ## si cambia bersaglio: uno che passa quasi allo zenit
const T_ZENIT_FINE := 490.0   ## fin dopo il suo passaggio in meridiano
const T_LIMITE := 515.0

## Dove si manda il tubo. Declinazione VENTI, e la scelta è misurata: da questa
## latitudine un soggetto a venti gradi culmina a sessantasei, cioè comodamente
## sopra l'orizzonte della cupola (47,7) e comodamente lontano dallo zenit, dove
## l'azimut d'uscita impazzisce. Quattro ore attorno al meridiano, da -30 a +30 di
## angolo orario, e non scende mai sotto i cinquantacinque gradi.
const HA_PROVA := -30.0
const DEC_PROVA := 20.0

## E QUESTO INVECE PASSA QUASI ALLO ZENIT: a declinazione 45, da questa latitudine,
## il meridiano si attraversa a 88,9 gradi d'altezza. Serve alla domanda 5b, che non
## è una prova ma una misura: lì la fessura non ce la fa, e quanto non ce la faccia
## è un numero che vale la pena avere scritto.
const DEC_ZENIT := 45.0

## Da dove si parte per andare a sbattere nel finecorsa: quattro gradi sotto.
const HA_AL_LIMITE := 116.0

## Quanto si ammette che il tubo si allontani dalla stella, in gradi, in quattro ore.
##
## STRETTISSIMO, ED È UNA SCOPERTA DI QUESTA SONDA. Ci si aspettava un grado — il
## disallineamento polare che `telescope_mount.gd` dichiara da sempre — e invece
## viene zero: misurato qui (domanda 4a), l'ASSE della montatura sta esattamente sul
## polo celeste, 43,900 gradi contro 43,900. Quello che è storto è il TUBO, che a
## declinazione 90 guarda 0,95 gradi fuori dall'asse: è un errore di PUNTAMENTO — lo
## stesso che la fase di sincronizzazione esiste per azzerare — e non tocca
## l'inseguimento, perché una cosa che gira attorno all'asse giusto tiene la stella
## per sempre, anche se non è la stella che le avevano chiesto.
##
## Cinque centesimi di grado lasciano spazio al passo dei motori e non un millimetro
## a un errore di asse, che ne varrebbe uno e mezzo, o di segno, che ne varrebbe cento.
const PERDITA_MAX := 0.05

## Quanto errore d'azimut si ammette alla fessura, in gradi, sul bersaglio normale.
##
## SEI, CIOÈ IL GIOCO PIÙ DUE. Misurato: su un soggetto a declinazione venti la
## fessura non supera MAI il gioco — 4,0 gradi esatti, il motore riparte prima. I due
## gradi in più sono per il passo dei fotogrammi, non per il motore: al lancio
## successivo il picco cade dentro un fotogramma diverso. Una soglia larga qui non
## servirebbe a niente, perché il caso che la farebbe saltare non è «un po' peggio»,
## è lo zenit — e lì si va a 175, cioè quaranta volte tanto.
const ERRORE_CUPOLA_MAX := 6.0

var _guasti := 0
var _non_insegue := false
var _fermo := false
var _senza_limite := false

## Il conto della calotta, tenuto dal ciclo d'attesa: parte a ogni fotogramma, e
## nessun altro posto la guarda abbastanza spesso.
var _cupola: DomeAzimuth
var _partenze := 0
var _era_in_moto := false
var _errore_peggiore := 0.0
var _conta := false
var _conta_da := 0.0


func _ready() -> void:
	_non_insegue = OS.get_environment("NON_INSEGUE") == "1"
	_fermo = OS.get_environment("FERMO") == "1"
	_senza_limite = OS.get_environment("SENZA_LIMITE") == "1"
	_prova.call_deferred()


func _guasto(msg: String) -> void:
	_guasti += 1
	print("[rotazione] GUASTO: " + msg)


func _v(p: Vector3) -> String:
	return "%.3f, %.3f, %.3f" % [p.x, p.y, p.z]


func _prova() -> void:
	var scena: Node = load("res://main.tscn").instantiate()
	get_tree().root.add_child(scena)
	get_tree().current_scene = scena
	for _i in 30:
		await get_tree().process_frame

	var cielo := TempoSiderale.find_in(get_tree())
	var mount := TelescopeMount.find_in(get_tree())
	_cupola = DomeAzimuth.find_in(get_tree())
	if cielo == null or mount == null or _cupola == null:
		print("[rotazione] manca un pezzo (cielo %s, montatura %s, cupola %s): la prova non vale"
			% [cielo != null, mount != null, _cupola != null])
		get_tree().quit(1)
		return
	if Game.run == null:
		print("[rotazione] la notte non è cominciata: non c'è un tempo da girare")
		get_tree().quit(1)
		return

	if _fermo:
		cielo.fermo = true
		print("[rotazione] FERMO: il cielo non gira, la calotta non deve più partire")
	if _non_insegue:
		mount.insegue_il_cielo = false
		print("[rotazione] NON_INSEGUE: i motori sono spenti, la stella si deve perdere")
	if _senza_limite:
		mount.limite_ha_gradi = 0.0
		print("[rotazione] SENZA_LIMITE: nessun finecorsa, il tubo va dove vuole")

	Engine.max_fps = FOTOGRAMMI
	Engine.time_scale = SCALA
	print("[rotazione] polo celeste %s, alto %.1f gradi sull'orizzonte: è la latitudine"
		% [_v(cielo.polo()), rad_to_deg(asin(cielo.polo().y))])

	# --- 0. DA CHE PARTE GIRA: A EST SI SALE -------------------------------
	#
	# TRE RIGHE, E CHIUDONO L'UNICA DOMANDA CHE TUTTO IL RESTO DI QUESTA SONDA NON
	# PUÒ CHIUDERE. Le altre misure confrontano il cielo col telescopio, e due cose
	# capovolte nello stesso modo sono d'accordo: col verso al rovescio la stella
	# resterebbe nell'oculare tutta la notte e la domanda 4b direbbe ok. Nemmeno le
	# strisciate di `tools/scatta_cielo.gd` lo dicono — una traccia non ha una freccia.
	#
	# QUELLO CHE LO DICE È L'ORIZZONTE. Si prende il punto di cielo che sta a est,
	# all'orizzonte — azimut 90, altezza zero, cioè il versore (1, 0, 0) in questa
	# convenzione — e si guarda dove il cielo lo porta mezz'ora dopo. Se sale, le
	# stelle sorgono a est; se scende, questo osservatorio sta su un altro pianeta.
	var est := Vector3(1.0, 0.0, 0.0)
	var mezzora := Basis(cielo.polo(), deg_to_rad(7.5)) * est
	print("[rotazione] il punto di cielo all'orizzonte est, mezz'ora dopo, sta a %.2f "
		% rad_to_deg(asin(mezzora.y)) + "gradi d'altezza")
	if mezzora.y <= 0.0:
		_guasto("a est le stelle SCENDONO: il cielo gira dalla parte sbagliata")
	else:
		print("[rotazione] ok: a est si sorge, a ovest si tramonta")

	# --- 1. QUINDICI GRADI L'ORA ------------------------------------------
	if not await _fino_a(T_RITMO_DA):
		return
	var m0 := Game.run.elapsed_min
	var g0 := cielo.gradi()
	if not await _fino_a(T_RITMO_A):
		return
	var per_ora := (cielo.gradi() - g0) / ((Game.run.elapsed_min - m0) / 60.0)
	print("[rotazione] fra le %s e adesso il cielo ha girato di %.3f gradi l'ora"
		% [_ora(m0), per_ora])
	var atteso := 0.0 if _fermo else 15.0
	if absf(per_ora - atteso) > 0.05:
		_guasto("il cielo gira di %.3f gradi l'ora invece di %.0f" % [per_ora, atteso])
	elif _fermo:
		print("[rotazione] ok: FERMO, e infatti non gira — è il cielo di ieri")
	else:
		print("[rotazione] ok: quindici gradi l'ora, come la Terra")

	# --- 2. LO SHADER LO SA ------------------------------------------------
	_shader(cielo)

	# --- 3. PARCHEGGIATA NON INSEGUE ---------------------------------------
	var prima := mount.dove()
	if mount.insegue():
		_guasto("la montatura insegue senza che nessuno abbia puntato: il tubo si "
			+ "muoverebbe da solo mentre il giocatore entra in cupola")
	if not await _fino_a(T_FERMA):
		return
	if prima.distance_to(mount.dove()) > 0.01:
		_guasto("parcheggiata, la montatura si è mossa di %.3f gradi in un'ora"
			% prima.distance_to(mount.dove()))
	else:
		print("[rotazione] ok: parcheggiata sta ferma — i motori li accende il puntamento")

	# --- 4a. ATTORNO A COSA GIRA IL TUBO -----------------------------------
	#
	# LA BISETTRICE FRA DUE PUNTAMENTI OPPOSTI È L'ASSE. A declinazione 90 il tubo
	# dovrebbe stare SULL'asse: se non ci sta, ruotando l'ascensione di mezzo giro
	# descrive un cono, e l'asse del cono è la media delle due generatrici. È una
	# misura che non ha bisogno di sapere niente di come la montatura sia fatta dentro.
	mount.piazza(0.0, 90.0)
	await get_tree().process_frame
	var d1 := mount.direzione()
	mount.piazza(180.0, 90.0)
	await get_tree().process_frame
	var d2 := mount.direzione()
	var asse := (d1 + d2).normalized()
	var storto := rad_to_deg(d1.angle_to(asse))
	var fuori := rad_to_deg(asse.angle_to(cielo.polo()))
	print("[rotazione] asse della montatura: alto %.3f gradi, azimut %.3f - il polo "
		% [rad_to_deg(asin(asse.y)), rad_to_deg(atan2(asse.x, asse.z))]
		+ "celeste sta a %.3f gradi da lì" % fuori)
	print("[rotazione] e a declinazione 90 il tubo guarda %.3f gradi FUORI dal proprio "
		% storto + "asse: non è l'asse a essere storto, è il tubo")
	if fuori > 0.05:
		_guasto("la montatura gira attorno a un asse che sta %.3f gradi fuori dal polo: "
			% fuori + "inseguendo perderà la stella comunque la si punti")
	else:
		print("[rotazione] ok: gira attorno al polo celeste - l'inseguimento può essere esatto")
		print("[rotazione]     e quello che resta è errore di PUNTAMENTO, che è la cosa "
			+ "che la sincronizzazione esiste per azzerare")

	# --- si punta, e da qui in poi si guarda anche la calotta ---------------
	# La cupola non insegue niente finché è chiusa, e ha ragione: si apre.
	Events.dome_aperture_changed.emit(1.0)
	mount.punta(HA_PROVA, DEC_PROVA)
	if not await _fino_a(T_PUNTA):
		return
	if mount.insegue() == _non_insegue:
		_guasto("dopo il puntamento l'inseguimento è %s"
			% ["spento" if _non_insegue else "acceso"])
	if not await _fino_a(T_STELLA):
		return

	# --- 4. IL TUBO TIENE LA STELLA ----------------------------------------
	#
	# COME SI FISSA UNA STELLA SENZA UN CATALOGO. Si guarda dove punta il tubo
	# ADESSO e lo si riporta indietro nel sistema del cielo (`giro()` inversa):
	# quel versore è una stella, e non si muove più. Ore dopo, dove il cielo la
	# mostri lo dice la stessa rotazione in avanti. Se il tubo ci sta ancora
	# sopra, i due pezzi parlano la stessa lingua; se ci sta a novanta gradi,
	# uno dei due è fermo; se ci sta al doppio, uno dei due gira al contrario.
	var stella := cielo.giro().inverse() * mount.direzione()
	print("[rotazione] alle %s il tubo è su angolo orario %.1f, declinazione %.1f: "
		% [_ora(Game.run.elapsed_min), mount.dove().x, mount.dove().y]
		+ "la stella sta a %s nel cielo fermo" % _v(stella))
	var az0 := await _conta_da_adesso()

	var peggio := 0.0
	for tappa: float in [T_STELLA + 30.0, T_STELLA + 120.0, T_FINE]:
		if not await _fino_a(tappa):
			return
		var perso := rad_to_deg(mount.direzione().angle_to(cielo.giro() * stella))
		peggio = maxf(peggio, perso)
		print("[rotazione] alle %s (cielo girato di %.1f gradi): il tubo è a %.2f gradi "
			% [_ora(tappa), cielo.gradi(), perso] + "dalla stella")
	_conta = false

	if _non_insegue:
		if peggio < 10.0:
			_guasto("con i motori spenti il tubo ha perso solo %.2f gradi: questa sonda "
				% peggio + "non sta misurando l'inseguimento")
		else:
			print("[rotazione] ok: a motori spenti la stella si perde di %.1f gradi — "
				% peggio + "la sonda vede la differenza")
	elif peggio > PERDITA_MAX:
		_guasto("inseguendo, il tubo ha perso la stella di %.3f gradi (ammessi %.2f): "
			% [peggio, PERDITA_MAX] + "cielo e montatura non girano d'accordo")
	else:
		print("[rotazione] ok: in quattro ore il tubo perde la stella di %.3f gradi" % peggio)

	# --- 5. LA CUPOLA PARTE A STRAPPI --------------------------------------
	var girata := absf(_cupola.azimut() - az0)
	var ore := (Game.run.elapsed_min - _conta_da) / 60.0
	print("[rotazione] in %.1f ore la calotta è partita %d volte, ha girato di %.1f "
		% [ore, _partenze, girata] + "gradi, errore massimo %.1f (il gioco è %.1f)"
		% [_errore_peggiore, DomeAzimuth.GIOCO])
	# LA CALOTTA INSEGUE IL TUBO, NON IL CIELO: sta ferma se è fermo il cielo, e sta
	# ferma anche se è fermo il tubo. Sono due difetti diversi con la stessa faccia, e
	# tutti e due sono la risposta giusta a un interruttore.
	if _fermo or _non_insegue:
		var perche := "a cielo fermo" if _fermo else "a tubo fermo"
		if _partenze > 0:
			_guasto("%s la calotta è partita %d volte: si muove per qualcosa che non "
				% [perche, _partenze] + "è il telescopio")
		else:
			print("[rotazione] ok: %s la calotta non parte — è il gioco di ieri" % perche)
	elif _partenze == 0:
		_guasto("la calotta non è mai partita: la fessura non segue il tubo")
	elif _errore_peggiore > ERRORE_CUPOLA_MAX:
		_guasto("la fessura ha accumulato %.1f gradi d'errore: il motore non ce la fa"
			% _errore_peggiore)
	else:
		print("[rotazione] ok: parte ogni %.0f minuti di gioco, e fra una partenza e "
			% ((Game.run.elapsed_min - _conta_da) / float(_partenze))
			+ "l'altra la fessura resta dentro il gioco")

	# --- 5b. E ALLO ZENIT NON CE LA FA -------------------------------------
	#
	# NON C'È UN GIUDIZIO QUI, e non è una dimenticanza: che una cupola perda la
	# fessura su un soggetto che passa allo zenit non è un difetto del motore, è la
	# geometria di una sfera - vicino al polo di una sfera l'azimut non vuol più dire
	# niente, e per attraversare il meridiano la fessura deve fare mezzo giro. Le
	# cupole vere hanno lo stesso problema e lo chiamano zona cieca dello zenit. Si
	# misura per averlo scritto: il giorno che qualcuno decida di farci qualcosa -
	# rifiutare quei bersagli nel planetario, o un motore più svelto - parte da qui.
	if not await _fino_a(T_ZENIT):
		return
	mount.punta(-30.0, DEC_ZENIT)
	var _az1 := await _conta_da_adesso()
	if not await _fino_a(T_ZENIT_FINE):
		return
	_conta = false
	print("[rotazione] su un soggetto che culmina a 88,9 gradi: %d partenze, errore "
		% _partenze + "massimo %.0f gradi - la fessura resta indietro di mezzo giro"
		% _errore_peggiore)

	# --- 6. IL FINECORSA ---------------------------------------------------
	mount.punta(HA_AL_LIMITE, DEC_PROVA)
	if not await _fino_a(T_LIMITE):
		return
	var ha := mount.dove().x
	if _fermo:
		print("[rotazione] FERMO: l'angolo orario non cresce (è a %.1f), e senza cielo "
			% ha + "che gira non c'è finecorsa da toccare — la domanda 6 non vale")
		print("[rotazione] %d guasti" % _guasti)
		get_tree().quit(1 if _guasti > 0 else 0)
		return
	print("[rotazione] alle %s: angolo orario %.1f, inseguimento %s"
		% [_ora(T_LIMITE), ha, "acceso" if mount.insegue() else "fermo"])
	if _senza_limite:
		if mount.insegue():
			print("[rotazione] ok: senza limite non si ferma — il tubo è a %.0f gradi "
				% ha + "di angolo orario, cioè addosso al pilastro")
		else:
			_guasto("senza limite la montatura si è fermata lo stesso a %.1f gradi" % ha)
	elif mount.insegue():
		_guasto("l'angolo orario è a %.1f gradi e i motori vanno ancora: il tubo "
			% ha + "finisce dentro il pilastro")
	elif absf(ha) < mount.limite_ha_gradi - 5.0:
		_guasto("i motori si sono fermati a %.1f gradi, ben prima del limite di %.0f"
			% [ha, mount.limite_ha_gradi])
	else:
		print("[rotazione] ok: al finecorsa si ferma invece di continuare")

	print("[rotazione] %d guasti" % _guasti)
	get_tree().quit(1 if _guasti > 0 else 0)


## Azzera i conti della calotta e comincia a guardarla, ma solo DOPO che ha finito
## di sistemarsi. Torna l'azimut da cui si comincia.
##
## PERCHÉ SI ASPETTA. Un GOTO manda il tubo dall'altra parte del cielo, e la fessura
## lo segue con un mezzo giro che dura secondi: è una partenza vera, ma è la partenza
## del PUNTAMENTO. Contarla insieme alle altre vorrebbe dire misurare l'inseguimento
## e trovarci dentro un errore di novanta gradi che non c'entra niente — è successo,
## alla prima stesura di questa sonda, e sembrava un motore che non ce la fa.
func _conta_da_adesso() -> float:
	for _i in 4000:
		if not _cupola.in_moto():
			break
		await get_tree().process_frame
	_partenze = 0
	_errore_peggiore = 0.0
	_era_in_moto = _cupola.in_moto()
	_conta_da = Game.run.elapsed_min
	_conta = true
	return _cupola.azimut()


## L'ora di gioco che corrisponde a `minuti` dall'inizio della notte.
func _ora(minuti: float) -> String:
	return "%02d:%02d" % [int(NightClock.NIGHT_START_HOUR + minuti / 60.0) % 24,
		int(minuti) % 60]


## Lascia scorrere la notte fino a `minuti`. Torna `false` se l'alba se l'è portata
## via, e in quel caso la prova è finita: senza `Game.run` non c'è più un orologio.
##
## E QUI DENTRO SI GUARDA LA CALOTTA, perché è l'unico posto che passa da ogni
## fotogramma. Contare le partenze del motore a intervalli vorrebbe dire perderne
## metà: parte, fa il suo quarto di giro e si ferma, e fra due letture lontane
## sembra non essersi mai mossa.
func _fino_a(minuti: float) -> bool:
	while true:
		if Game.run == null:
			print("[rotazione] l'alba è arrivata prima delle %s: la prova finisce qui"
				% _ora(minuti))
			get_tree().quit(1)
			return false
		if _conta:
			if _cupola.in_moto() and not _era_in_moto:
				_partenze += 1
			_era_in_moto = _cupola.in_moto()
			_errore_peggiore = maxf(_errore_peggiore, _cupola.errore())
		if Game.run.elapsed_min >= minuti:
			return true
		await get_tree().process_frame
	return true


## Il giro finisce nel materiale del cielo, che è l'unico posto in cui serve.
func _shader(cielo: TempoSiderale) -> void:
	var we := cielo.get_node_or_null(cielo.ambiente) as WorldEnvironment
	var mat: ShaderMaterial = null
	if we != null and we.environment != null and we.environment.sky != null:
		mat = we.environment.sky.sky_material as ShaderMaterial
	if mat == null:
		_guasto("il materiale del cielo non si trova: il giro non arriva a nessuno")
		return
	var scritto: float = mat.get_shader_parameter("giro")
	var polo: Vector3 = mat.get_shader_parameter("polo_celeste")
	print("[rotazione] nel materiale: giro %.4f rad (%.2f gradi), polo %s"
		% [scritto, rad_to_deg(scritto), _v(polo)])
	if absf(rad_to_deg(scritto) - cielo.gradi()) > 0.5:
		_guasto("lo shader crede che il cielo abbia girato di %.2f gradi, il mondo dice %.2f"
			% [rad_to_deg(scritto), cielo.gradi()])
	elif polo.distance_to(cielo.polo()) > 0.001:
		_guasto("lo shader gira attorno a %s, il mondo attorno a %s"
			% [_v(polo), _v(cielo.polo())])
	else:
		print("[rotazione] ok: il cielo disegnato e il cielo calcolato sono lo stesso cielo")
