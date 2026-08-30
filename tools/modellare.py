# -*- coding: utf-8 -*-
"""Le primitive comuni ai modellatori di arredo, e il banco per guardarli.

PERCHE' STA DA SOLO. La conversione fra gli assi di gioco e quelli di Blender
- (x, y, z) -> (x, -z, y) - e' il punto in cui questo progetto ha gia' sbagliato
piu' volte: un segno invertito manda una camera dentro un muro o una scala dalla
parte opposta. Averla scritta due volte, una per stanza, e' il modo sicuro di
farle divergere. Qui e' scritta UNA volta, e chi arreda una stanza non la vede.

Non ci sta niente che riguardi una stanza in particolare: chi lo usa dichiara i
suoi pezzi, chiama `finisci()` e ha gli oggetti pronti da esportare.
"""
import math
import os

import bmesh
import bpy
from mathutils import Matrix, Vector

# --- materiali ---------------------------------------------------------------
# Il beige e' una scelta di datazione, non di gusto: nel 1999 i calcolatori erano
# di quel colore, e un monitor bianco o nero sposta la stanza di dieci anni.
COLORI = {
    # IL LEGNO NON E' UNO. Tre ambienti, tre essenze: il truciolare nobilitato
    # dell'ufficio, il legno medio della cucina, il noce verniciato delle teche.
    # Con un materiale solo la consolle della sala di controllo era fatta della
    # stessa tavola della libreria, e non ha senso.
    "LegnoUfficio": (0.72, 0.60, 0.44),
    "LegnoCucina":  (0.52, 0.41, 0.29),
    "LegnoTeche":   (0.34, 0.26, 0.20),
    # i dorsi dei libri: cartonati e telati, non tavole
    "LibroRosso":   (0.42, 0.16, 0.14),
    "LibroBlu":     (0.16, 0.22, 0.36),
    "LibroVerde":   (0.18, 0.30, 0.22),
    "LibroCrema":   (0.78, 0.72, 0.58),
    "Metallo":  (0.36, 0.38, 0.41),
    "Plastica": (0.78, 0.74, 0.62),
    "Schermo":  (0.045, 0.055, 0.06),
    "Tessuto":  (0.20, 0.22, 0.27),
    "Carta":    (0.85, 0.83, 0.76),
    "Gomma":    (0.09, 0.09, 0.10),
    "Acceso":   (0.10, 0.16, 0.12),
    "Inox":     (0.60, 0.62, 0.64),
    "Bianco":   (0.86, 0.86, 0.83),
    "Formica":  (0.72, 0.70, 0.62),
    "Ceramica": (0.88, 0.87, 0.84),
    "Smalto":   (0.24, 0.35, 0.34),
    "Rame":     (0.55, 0.34, 0.20),
    "Vetrina":  (0.62, 0.72, 0.76),
    "Meteorite": (0.13, 0.115, 0.105),
    "Ferro":    (0.31, 0.29, 0.27),
    "Insegna":  (0.90, 0.62, 0.34),
    # I DIFFUSORI SONO SPENTI, E DEVONO ESSERLO. La faccia che si accende sta
    # nella scena di gioco, non nel modello: in Godot il materiale di un .glb e'
    # condiviso fra tutte le sue istanze, e spegnere il diffusore di una
    # plafoniera le spegnerebbe tutte e nove insieme.
    "Neon":     (0.80, 0.81, 0.78),
    "NeonRosso": (0.36, 0.05, 0.04),
    "Lamiera":  (0.78, 0.78, 0.76),
    # l'avorio degli interruttori: il bianco delle placche di oggi non c'era, e
    # quelle di allora sono ingiallite da vent'anni di dita
    "Avorio":   (0.86, 0.82, 0.70),
    # LA SPIA DI LOCALIZZAZIONE, quella arancione dentro il tasto. Non e' un
    # espediente di gioco: gli interruttori italiani di quegli anni ce l'avevano, e
    # ce l'avevano per questo - si accende quando la luce e' SPENTA, cosi' al buio
    # si trova l'interruttore. Il problema che risolve nel gioco e' lo stesso che
    # risolveva in casa.
    "Spia":     (0.95, 0.45, 0.10),
}
RUVIDEZZA = {"Metallo": 0.45, "Inox": 0.28, "Rame": 0.35, "Schermo": 0.12,
             "Acceso": 0.20, "Gomma": 0.75, "Ceramica": 0.25, "Smalto": 0.30}
METALLICI = ("Metallo", "Inox", "Rame", "Ferro")
# I materiali la cui texture va MOLTIPLICATA per il colore invece che sostituirlo.
# Di norma il colore e' solo un ripiego per quando la texture manca, e collegare la
# mappa al Base Color e' giusto. Non qui: il vetro rosso della cupola usa la stessa
# plastica opalina del diffusore bianco, e collegata cosi' com'e' lo faceva
# diventare bianco - la trama e' la stessa, il colore no.
# I dorsi stanno qui per la stessa ragione: una tela sola, otto colori. Senza,
# la libreria diventa una fila di volumi tutti dello stesso beige.
TINTI = ("NeonRosso", "LibroRosso", "LibroBlu", "LibroVerde", "LibroCrema",
         "Tessuto", "Carta")


# Set di texture: nome del materiale -> (cartella in assets/textures, METRI PER
# RIPETIZIONE). Tutte da ambientCG, licenza CC0.
#
# LA SCALA STA QUI E FINISCE NELLE UV. La prima idea era tenere le UV in metri puri
# e scalare nel materiale con un nodo Mapping — piu' elegante, ma quella scala
# attraversa il glTF solo come KHR_texture_transform, che non tutti gli importatori
# rispettano. Siccome ogni mesh porta un materiale solo, la scala si puo' cuocere
# nelle UV senza perdere niente: cambiarla costa una rigenerazione, dieci secondi.
TEXTURE = {
    "LegnoUfficio": ("legno-ufficio", 1.10),
    "LegnoCucina":  ("legno-cucina", 0.80),
    "LegnoTeche":   ("legno-teche", 0.70),
    "Ante":         ("legno-porte", 1.00),
    "Telai":        ("legno-porte", 1.00),
    "Metallo":      ("metallo", 1.20),
    "Plastica":     ("plastica", 0.35),
    "Muri":         ("intonaco", 2.00),
    # il soffitto e' intonaco come i muri, ma la trama si ripete piu' larga: sopra la
    # testa la stessa scala dei muri si legge come un motivo, non come una superficie
    "Soffitto":     ("intonaco", 3.20),
    "Pavimento":    ("pavimento", 0.90),
    "Tetto":        ("tetto", 2.60),
    # MANDORLATA, e non la lamiera liscia della carpenteria. Un impalcato in
    # quota ha il rilievo antiscivolo, ed e' quel rilievo che dice all'occhio
    # "qui ci si cammina": con la lamiera liscia la passerella leggeva come un
    # disco di cartone. 0,55 per ripetizione: il passo delle mandorle vere.
    "Passerella":   ("mandorlata", 0.55),
    # gli impianti. Senza queste tre righe carcasse, diffusori e placche erano
    # colori piatti, e sul soffitto una plafoniera leggeva come un blocco appena
    # piu' chiaro dell'intonaco invece che come una lampada.
    "Lamiera":      ("lamiera", 0.60),
    "Neon":         ("diffusore", 0.32),
    "NeonRosso":    ("diffusore", 0.32),
    "Avorio":       ("placca", 0.22),
    # I DORSI. Sei centimetri per ripetizione, non uno: un dorso e' largo tre
    # centimetri, e con la scala di un mobile la trama della tela non ci starebbe
    # dentro nemmeno una volta - si vedrebbe una sfumatura, non un tessuto. A dodici
    # si intravedeva; a sei la tela si legge come tela su un dorso da un metro.
    "LibroRosso":   ("libri", 0.06),
    "LibroBlu":     ("libri", 0.06),
    "LibroVerde":   ("libri", 0.06),
    "LibroCrema":   ("libri", 0.06),
    "Tessuto":      ("libri", 0.30),
    "Carta":        ("carta", 0.22),
}
RADICE_TEX = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                          "assets", "textures")


def metri_ripetizione(nome):
    return TEXTURE[nome][1] if nome in TEXTURE else 1.0


def _immagine(cartella, nome_file):
    percorso = os.path.join(RADICE_TEX, cartella, nome_file)
    if not os.path.exists(percorso):
        return None
    chiave = "%s/%s" % (cartella, nome_file)
    if chiave in bpy.data.images:
        return bpy.data.images[chiave]
    img = bpy.data.images.load(percorso)
    img.name = chiave
    return img


def applica_texture(m, nome, tinta=None, set_texture=None, metallico=None):
    """Attacca le mappe al Principled, se il materiale ha un set dichiarato.

    Solo i cinque canali che il glTF sa portare: baseColor, roughness, metallic,
    normal. Qualunque cosa di piu' elaborata non attraversa l'export - e' la stessa
    trappola della trasmissione del vetro, che ha dovuto diventare alpha.

    La normale e' la NormalGL e non la NormalDX: con quella sbagliata l'illuminazione
    risulta scavata al contrario, e non si capisce guardando una texture ferma.
    """
    # `set_texture` e `tinta` servono a chi ha una tavolozza propria - il
    # telescopio ce l'ha, con i suoi Tubo/Montatura/Collari che qui non esistono.
    # Senza, quei materiali non avrebbero mai una mappa: aggiungerli a TEXTURE
    # significherebbe portare in questo file i nomi di un modello che non e' suo.
    if set_texture is None and nome not in TEXTURE:
        return False
    cartella = (set_texture or TEXTURE[nome])[0]
    # .get e non [nome]: questa funzione la chiama anche osservatorio_blender, che
    # ha una sua tavolozza e non passa da COLORI. Serve solo per i TINTI.
    c = tinta if tinta is not None else COLORI.get(nome, (1.0, 1.0, 1.0))
    moltiplica = tinta is not None or nome in TINTI
    # LA MAPPA METALLICA SI COLLEGA SOLO A CHI E' METALLO DAVVERO, e per un po'
    # non e' stato cosi'. Il set "metallo" e' Metal032, un metallo nudo: la sua
    # mappa metallica vale uno dappertutto. Collegata a una LAMIERA VERNICIATA -
    # la passerella, la ringhiera, la scala, il tubo del telescopio - li rende
    # specchi; e uno specchio in una stanza senza niente da riflettere e' NERO.
    # Sono i pezzi che si vedevano come sagome nere anche a luce rossa accesa.
    # La vernice e' un dielettrico: metallico zero, e la luce la prende tutta.
    if metallico is None:
        metallico = nome in METALLICI
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]

    def collega(nome_file, ingresso, spazio, y):
        img = _immagine(cartella, nome_file)
        if img is None:
            return
        img.colorspace_settings.name = spazio
        t = nt.nodes.new("ShaderNodeTexImage")
        t.image = img
        t.location = (-700, y)
        if ingresso == "Normal":
            nm = nt.nodes.new("ShaderNodeNormalMap")
            nm.location = (-350, y)
            nt.links.new(nm.inputs["Color"], t.outputs["Color"])
            nt.links.new(bsdf.inputs["Normal"], nm.outputs["Normal"])
        elif ingresso == "Base Color" and moltiplica:
            mix = nt.nodes.new("ShaderNodeMix")
            mix.data_type = "RGBA"
            mix.blend_type = "MULTIPLY"
            mix.location = (-350, y)
            mix.inputs["Factor"].default_value = 1.0
            mix.inputs[6].default_value = (c[0], c[1], c[2], 1.0)
            nt.links.new(mix.inputs[7], t.outputs["Color"])
            nt.links.new(bsdf.inputs[ingresso], mix.outputs[2])
        else:
            nt.links.new(bsdf.inputs[ingresso], t.outputs["Color"])

    collega("color.jpg", "Base Color", "sRGB", 400)
    collega("roughness.jpg", "Roughness", "Non-Color", 100)
    if metallico:
        collega("metallic.jpg", "Metallic", "Non-Color", -200)
    collega("normal.jpg", "Normal", "Non-Color", -500)
    return True


def materiale(nome):
    if nome in bpy.data.materials:
        return bpy.data.materials[nome]
    m = bpy.data.materials.new(nome)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    c = COLORI[nome]
    b.inputs["Base Color"].default_value = (c[0], c[1], c[2], 1.0)
    b.inputs["Roughness"].default_value = RUVIDEZZA.get(nome, 0.80)
    if nome in METALLICI:
        b.inputs["Metallic"].default_value = 0.85
    if nome == "Vetrina":
        # LA TRASMISSIONE DI BLENDER NON ATTRAVERSA IL glTF: Godot importerebbe una
        # lastra opaca, e una teca opaca e' una scatola. Quello che sopravvive
        # all'export e' l'ALPHA, quindi il vetro si fa con quello (D-044).
        # SEI CENTESIMI DI OPACITA', NON SEDICI. A 0,16 la lastra velava tutto
        # di lattiginoso e dentro una teca non si distingueva piu' niente: e'
        # tanto per un vetro sottile, e due lastre in fila (davanti e dietro) lo
        # raddoppiano. Il colore quasi neutro per la stessa ragione - un vetro da
        # vetrina non e' verde.
        b.inputs["Roughness"].default_value = 0.02
        b.inputs["IOR"].default_value = 1.45
        b.inputs["Alpha"].default_value = 0.06
        b.inputs["Base Color"].default_value = (0.80, 0.86, 0.88, 0.06)
        for attributo, valore in (("surface_render_method", "BLENDED"), ("blend_method", "BLEND")):
            if hasattr(m, attributo):
                setattr(m, attributo, valore)
        m.use_backface_culling = False
    if nome == "Spia":
        b.inputs["Emission Color"].default_value = (1.0, 0.42, 0.06, 1.0)
        # 1,0 e non 4,0: a quattro il puntino andava oltre il punto di bianco del
        # tonemapping e si vedeva ARANCIONE BRUCIATO, cioe' bianco. Deve dire dove
        # sta la placca, non fare luce - quella, pochissima, la fa la sua lampada.
        b.inputs["Emission Strength"].default_value = 1.0
        b.inputs["Roughness"].default_value = 0.25
    if nome == "Insegna":
        # il pannello luminoso di un distributore: acceso anche quando la sala e' spenta
        b.inputs["Emission Color"].default_value = (0.98, 0.70, 0.42, 1.0)
        b.inputs["Emission Strength"].default_value = 2.2
    if nome in ("Neon", "NeonRosso"):
        # NIENTE EMISSIONE QUI, e non e' una dimenticanza: vedi il commento sui
        # colori. La faccia accesa e' un pezzo della scena di gioco, che
        # l'interruttore accende e spegne insieme alla lampada. Nel modello resta
        # il diffusore da spento - opaco, un po' ingiallito.
        b.inputs["Roughness"].default_value = 0.55
    if nome == "Acceso":
        # Il fosforo verde di un monitor acceso e' l'unica luce propria della stanza.
        # L'emissione attraversa il glTF, la trasmissione no: qui serve la prima.
        b.inputs["Emission Color"].default_value = (0.24, 0.72, 0.36, 1.0)
        b.inputs["Emission Strength"].default_value = 1.6
    applica_texture(m, nome)
    return m


# --- primitive, in coordinate DI GIOCO --------------------------------------
GRUPPI = {}


def pulisci():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    GRUPPI.clear()


def bm_di(nome_mat):
    if nome_mat not in GRUPPI:
        GRUPPI[nome_mat] = bmesh.new()
    return GRUPPI[nome_mat]


def scatola(mat, x0, x1, y0, y1, z0, z1):
    """Un parallelepipedo dai suoi estremi di gioco: x e z in pianta, y in alto."""
    bmesh.ops.create_cube(bm_di(mat), size=1.0, matrix=(
        Matrix.Translation(Vector(((x0 + x1) / 2, -(z0 + z1) / 2, (y0 + y1) / 2)))
        @ Matrix.Diagonal(Vector((x1 - x0, z1 - z0, y1 - y0, 1.0)))))


def scatola_ruotata(mat, cx, cy, cz, sx, sy, sz, gradi):
    """Come `scatola`, ma girata di `gradi` attorno alla verticale, dal centro."""
    bmesh.ops.create_cube(bm_di(mat), size=1.0, matrix=(
        Matrix.Translation(Vector((cx, -cz, cy)))
        @ Matrix.Rotation(math.radians(-gradi), 4, "Z")
        @ Matrix.Diagonal(Vector((sx, sz, sy, 1.0)))))


def scatola_inclinata(mat, cx, cy, cz, sx, sy, sz, gradi, asse="z"):
    """Girata di `gradi` attorno a un asse ORIZZONTALE di gioco, dal proprio centro.

    L'ASSE VA DETTO, e la versione precedente non lo diceva: prometteva l'asse X e
    girava attorno a Z. Per una sedia rivolta lungo X la differenza non si vede -
    lo schienale si reclina lo stesso - ma per una rivolta lungo Z lo schienale si
    piega DI LATO invece che indietro, e la sedia sembra storta. Le sedie della sala
    proiezioni guardano a nord, ed erano tutte piegate a sinistra.

    `asse` e' l'asse di gioco attorno a cui si gira:
      "z"  la scatola si reclina nel piano X-Y  (per chi guarda lungo X)
      "x"  la scatola si reclina nel piano Z-Y  (per chi guarda lungo Z)
    """
    # gioco -> Blender: l'asse X resta X, l'asse Z di gioco diventa -Y di Blender
    girata = (Matrix.Rotation(math.radians(gradi), 4, "Y") if asse == "z"
              else Matrix.Rotation(math.radians(gradi), 4, "X"))
    bmesh.ops.create_cube(bm_di(mat), size=1.0, matrix=(
        Matrix.Translation(Vector((cx, -cz, cy)))
        @ girata
        @ Matrix.Diagonal(Vector((sx, sz, sy, 1.0)))))


def cilindro(mat, x, z, y0, y1, r, seg=16, r2=None):
    """Verticale. Con `r2` diverso da `r` diventa un tronco di cono."""
    bmesh.ops.create_cone(bm_di(mat), cap_ends=True, cap_tris=False, segments=seg,
                          radius1=r, radius2=r if r2 is None else r2, depth=y1 - y0,
                          matrix=Matrix.Translation(Vector((x, -z, (y0 + y1) / 2))))


def cilindro_orizz(mat, x, y, z, asse, lunghezza, r, seg=12):
    """Un tubo lungo l'asse indicato ('x' o 'z'), per manici, rubinetti e cavi."""
    d = Vector((1, 0, 0)) if asse == "x" else Vector((0, -1, 0))
    bmesh.ops.create_cone(bm_di(mat), cap_ends=True, cap_tris=False, segments=seg,
                          radius1=r, radius2=r, depth=lunghezza,
                          matrix=Matrix.Translation(Vector((x, -z, y)))
                          @ d.to_track_quat("Z", "Y").to_matrix().to_4x4())


def barra(mat, p0, p1, r, seg=6):
    """Un cilindro fra due punti QUALSIASI, in coordinate di gioco.

    `cilindro` e `cilindro_orizz` coprono solo gli assi; questa serve a tutto quello
    che sta di sbieco - le spirali di un distributore, un tirante, un corrimano - e
    stava per essere riscritta a mano per la terza volta.
    """
    a = Vector((p0[0], -p0[2], p0[1]))
    b_ = Vector((p1[0], -p1[2], p1[1]))
    d = b_ - a
    if d.length < 1e-6:
        return
    bmesh.ops.create_cone(bm_di(mat), cap_ends=True, cap_tris=False, segments=seg,
                          radius1=r, radius2=r, depth=d.length,
                          matrix=Matrix.Translation((a + b_) / 2)
                          @ d.to_track_quat("Z", "Y").to_matrix().to_4x4())


def sasso(mat, cx, cy, cz, raggio, seme, schiacciamento=0.75, ruvidezza=0.35):
    """Un ciottolo irregolare: una sfera geodetica con i vertici spostati a caso.

    Serve ai meteoriti, e la casualita' e' SEMINATA: due esecuzioni dello stesso
    script devono dare lo stesso file, o ogni rigenerazione sporca il modello senza
    che sia cambiato niente.
    """
    import random
    rnd = random.Random(seme)
    bm = bm_di(mat)
    prima = len(bm.verts)
    centro = Vector((cx, -cz, cy))
    try:
        bmesh.ops.create_icosphere(bm, subdivisions=2, radius=raggio,
                                   matrix=Matrix.Translation(centro))
    except TypeError:      # il nome del parametro e' cambiato fra le versioni
        bmesh.ops.create_icosphere(bm, subdivisions=2, diameter=raggio,
                                   matrix=Matrix.Translation(centro))
    bm.verts.ensure_lookup_table()
    for v in bm.verts[prima:]:
        d = v.co - centro
        d *= 1.0 + rnd.uniform(-ruvidezza, ruvidezza)
        d.z *= schiacciamento
        v.co = centro + d


def prisma(mat, davanti, dietro):
    """Un tronco di piramide da due quadrilateri: e' quello che rende un CRT un CRT.

    `davanti` e `dietro` sono quattro punti di gioco ciascuno, nello stesso ordine.
    Una scatola dritta darebbe un monitor a scatola, che e' esattamente il difetto
    per cui una stanza sembra fatta di cubi.
    """
    bm = bm_di(mat)
    va = [bm.verts.new((p[0], -p[2], p[1])) for p in davanti]
    vb = [bm.verts.new((p[0], -p[2], p[1])) for p in dietro]
    bm.faces.new(va)
    bm.faces.new(list(reversed(vb)))
    for k in range(4):
        k2 = (k + 1) % 4
        bm.faces.new((va[k], va[k2], vb[k2], vb[k]))


def uv_a_scatola(bm, scala=1.0):
    """UV per proiezione a scatola, in METRI: una unita' UV = un metro.

    PERCHE' NON `smart_project`. Questa geometria e' fatta di scatole e cilindri
    generati, di cui conosco le misure esatte: proiettare ogni faccia sul piano
    perpendicolare alla sua normale dominante da' una densita' di texel COSTANTE e
    deterministica, mentre lo smart project impacchetta a caso e cambia a ogni
    rigenerazione — cioe' a ogni volta che tocco la pianta.

    Tenere le UV in metri significa che la scala della texture NON sta qui: sta nel
    materiale, dove ognuno la vuole diversa (l'intonaco ripete ogni 2 m, il laminato
    ogni 0,5). Una scala cablata nelle UV andrebbe rigenerata per cambiarla.

    Il prezzo e' una cucitura sugli spigoli e un po' di stiramento sulle superfici
    oblique: per texture ripetitive e senza disegno non si vede.
    """
    uv = bm.loops.layers.uv.verify()
    for f in bm.faces:
        n = f.normal
        asse = max(range(3), key=lambda i: abs(n[i]))
        for l in f.loops:
            co = l.vert.co
            if asse == 0:
                u, v = co.y, co.z
                if n.x < 0.0:
                    u = -u
            elif asse == 1:
                u, v = co.x, co.z
                if n.y > 0.0:
                    u = -u
            else:
                u, v = co.x, co.y
                if n.z < 0.0:
                    u = -u
            l[uv].uv = (u / scala, v / scala)


def finisci(morbidi=()):
    """Una mesh per materiale, saldata e con le normali a posto.

    `morbidi` elenca i materiali da sfumare: l'angolo tiene gli spigoli veri, cosi'
    un cilindro diventa tondo senza che una scatola diventi molle.
    """
    oggetti = []
    for nome in sorted(GRUPPI):
        bm = GRUPPI[nome]
        bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=1e-5)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
        uv_a_scatola(bm, metri_ripetizione(nome))
        malla = bpy.data.meshes.new(nome)
        bm.to_mesh(malla)
        bm.free()
        malla.materials.append(materiale(nome))
        o = bpy.data.objects.new(nome, malla)
        bpy.context.collection.objects.link(o)
        oggetti.append(o)
    if morbidi:
        bpy.ops.object.select_all(action="DESELECT")
        for o in oggetti:
            if o.name in morbidi:
                o.select_set(True)
                bpy.context.view_layer.objects.active = o
        if bpy.context.view_layer.objects.active is not None:
            bpy.ops.object.shade_smooth_by_angle(angle=math.radians(35.0))
    return oggetti


def _collega_texture_vicine(percorso, oggetti):
    """Attacca ai materiali le mappe che stanno nella stessa cartella del modello.

    UN .fbx NON PORTA LE TEXTURE. Un glTF le ha dentro o le referenzia; un FBX
    scaricato da un archivio arriva con i PNG accanto e nessun collegamento, e
    importato cosi' da' un oggetto grigio senza che niente segnali un errore. Si
    riconoscono dal nome, che negli archivi PBR e' sempre lo stesso.
    """
    cartella = os.path.dirname(percorso)
    trovate = {}
    for f in sorted(os.listdir(cartella)):
        b_ = f.lower()
        if not b_.endswith((".png", ".jpg", ".jpeg")):
            continue
        if "base_color" in b_ or "basecolor" in b_ or "_diff" in b_ or "albedo" in b_:
            trovate.setdefault("Base Color", f)
        elif "normal" in b_ and "_dx" not in b_ and "normaldx" not in b_:
            trovate.setdefault("Normal", f)
        elif "rough" in b_:
            trovate.setdefault("Roughness", f)
        elif "metal" in b_:
            trovate.setdefault("Metallic", f)
    # Se nessun nome e' riconoscibile ma nella cartella c'e' UNA sola immagine, e'
    # quella: molti modelli di archivio hanno una texture sola con un nome qualsiasi
    # ("computer_texture.png"), e scartarla per questo lascia il modello grigio.
    if "Base Color" not in trovate:
        immagini = [f for f in sorted(os.listdir(cartella))
                    if f.lower().endswith((".png", ".jpg", ".jpeg"))]
        if len(immagini) == 1:
            trovate["Base Color"] = immagini[0]
    if not trovate:
        return
    materiali = set()
    for o in oggetti:
        for slot in getattr(o, "material_slots", []):
            if slot.material is not None:
                materiali.add(slot.material)
    accanto = {f.lower(): f for f in os.listdir(cartella)}
    for m in materiali:
        m.use_nodes = True
        nt = m.node_tree
        # UN NODO IMMAGINE CON L'IMMAGINE ROTTA E' PEGGIO DI NESSUN NODO: Blender lo
        # rende MAGENTA, e il primo tentativo si limitava a vedere che i nodi c'erano
        # e a non toccare niente - la sedia arrivava fucsia. Un FBX porta i percorsi
        # della macchina di chi l'ha esportato, che qui non esistono: si riaggancia
        # per nome di file, e quello che resta senza immagine si butta.
        for n in list(nt.nodes):
            if n.type != "TEX_IMAGE":
                continue
            if n.image is not None:
                base = os.path.basename(n.image.filepath).lower()
                if base in accanto:
                    n.image.filepath = os.path.join(cartella, accanto[base])
                    n.image.reload()
            if n.image is None or not n.image.has_data:
                nt.nodes.remove(n)
        if any(x.type == "TEX_IMAGE" for x in nt.nodes):
            continue          # il modello le porta gia', e ora funzionano
        bsdf = next((n for n in nt.nodes if n.type == "BSDF_PRINCIPLED"), None)
        if bsdf is None:
            continue
        for i, (ingresso, nome_file) in enumerate(sorted(trovate.items())):
            img = bpy.data.images.load(os.path.join(cartella, nome_file), check_existing=True)
            img.colorspace_settings.name = "sRGB" if ingresso == "Base Color" else "Non-Color"
            t = nt.nodes.new("ShaderNodeTexImage")
            t.image = img
            t.location = (-700, 300 - i * 280)
            if ingresso == "Normal":
                nm = nt.nodes.new("ShaderNodeNormalMap")
                nm.location = (-350, 300 - i * 280)
                nt.links.new(nm.inputs["Color"], t.outputs["Color"])
                nt.links.new(bsdf.inputs["Normal"], nm.outputs["Normal"])
            else:
                nt.links.new(bsdf.inputs[ingresso], t.outputs["Color"])


def posa_modello(percorso, impronta, gradi=0.0, riempi=1.0, appoggio=0.0,
                 appeso=False, tieni=None):
    """Importa un modello esterno e lo POSA DENTRO la sua impronta.

    Un modello preso da fuori non conosce ne' la scala ne' l'orientamento di
    questo progetto: arriva con la sua altezza, il suo nord e la sua origine. Qui
    lo si scala sull'ALTEZZA dichiarata dall'impronta - che e' la misura che conta
    per una sedia - e se cosi' l'ingombro in pianta non ci sta, si scala ancora
    finche' ci sta. Poi si centra in pianta e si appoggia a terra.

    Cosi' un modello di fuori rispetta lo stesso patto dei pezzi fatti in casa:
    quello che si vede e quello contro cui si sbatte sono la stessa cosa.

    `impronta` e' (x0, z0, x1, z1, altezza), `gradi` la rotazione attorno alla
    verticale di gioco (0 = come e' nato), `appoggio` la quota su cui posarlo - zero
    per terra, il piano di un tavolo per quello che ci sta sopra.

    `tieni` e' un pezzo di nome: tutto quello che non lo contiene viene buttato
    PRIMA di scalare. Serve piu' spesso di quanto sembri - un file di fuori non
    contiene sempre un oggetto solo. Quello delle plafoniere ne porta sette,
    sette varianti dello stesso apparecchio impilate nella stessa posizione, e
    importandolo intero si ottiene un pettine di sette lampade sovrapposte che
    scalato sull'ingombro complessivo diventa una fila di striscioline.

    Con `appeso` la quota e' quella del punto piu' ALTO invece che del piu' basso:
    una plafoniera non si appoggia al soffitto, ci si attacca sotto, e il suo
    ingombro verticale non lo si conosce prima di averla scalata.
    """
    x0, z0, x1, z1, alt = impronta
    prima = set(bpy.data.objects)
    basso = percorso.lower()
    if basso.endswith(".fbx"):
        bpy.ops.import_scene.fbx(filepath=percorso)
    elif basso.endswith(".blend"):
        # da una libreria .blend si prendono le MESH e basta: dentro ci sono anche le
        # luci e le camere di chi l'ha fatta, e importarle spegnerebbe il banco di posa
        with bpy.data.libraries.load(percorso) as (da, a_):
            a_.objects = list(da.objects)
        for o in a_.objects:
            if o is not None and o.type == "MESH":
                bpy.context.collection.objects.link(o)
    else:
        bpy.ops.import_scene.gltf(filepath=percorso)
    nuovi = [o for o in bpy.data.objects if o not in prima]
    if tieni is not None:
        for o in list(nuovi):
            if o.type == "MESH" and tieni not in o.name:
                bpy.data.objects.remove(o, do_unlink=True)
                nuovi.remove(o)
    _collega_texture_vicine(percorso, nuovi)
    radici = [o for o in nuovi if o.parent is None]
    perno = bpy.data.objects.new(os.path.basename(os.path.dirname(percorso)), None)
    bpy.context.collection.objects.link(perno)
    for o in radici:
        o.parent = perno
    perno.rotation_euler = (0.0, 0.0, math.radians(-gradi))
    bpy.context.view_layer.update()

    def ingombro():
        punti = [o.matrix_world @ Vector(c) for o in nuovi if o.type == "MESH"
                 for c in o.bound_box]
        if not punti:
            return None
        return ([min(q[i] for q in punti) for i in range(3)],
                [max(q[i] for q in punti) for i in range(3)])

    mm = ingombro()
    if mm is None:
        return [perno] + nuovi
    minimi, massimi = mm
    lati = [massimi[i] - minimi[i] for i in range(3)]
    scala = (alt * riempi) / max(1e-6, lati[2])
    # se scalando sull'altezza l'ingombro in pianta esce, comanda la pianta
    scala = min(scala, (x1 - x0) / max(1e-6, lati[0]), (z1 - z0) / max(1e-6, lati[1]))
    perno.scale = (scala, scala, scala)
    bpy.context.view_layer.update()
    minimi, massimi = ingombro()
    perno.location = (
        perno.location.x + (x0 + x1) / 2 - (minimi[0] + massimi[0]) / 2,
        perno.location.y - (z0 + z1) / 2 - (minimi[1] + massimi[1]) / 2,
        perno.location.z - (massimi[2] if appeso else minimi[2]) + appoggio)
    bpy.context.view_layer.update()
    return [perno] + nuovi


def verifica_impronte(oggetti, impronte, tolleranza=0.06):
    """Nessun vertice fuori dai rettangoli dichiarati in geometria.

    E' il controllo che tiene insieme mesh e collisione: senza, il modello cresce
    oltre le scatole e si passa attraverso quello che si vede, o ci si ferma
    contro l'aria. `impronte` e' un elenco di (x0, z0, x1, z1).
    """
    fuori = []
    for o in oggetti:
        if o.type != "MESH" or o.data is None:
            continue
        for v in o.data.vertices:
            p = o.matrix_world @ v.co
            gx, gz = p.x, -p.y
            dentro = False
            for (x0, z0, x1, z1) in impronte:
                if (x0 - tolleranza <= gx <= x1 + tolleranza
                        and z0 - tolleranza <= gz <= z1 + tolleranza):
                    dentro = True
                    break
            if not dentro:
                fuori.append((o.name, gx, gz))
    if not fuori:
        return []
    return ["%d vertici fuori dalle impronte, il primo in %s a (%.2f, %.2f)"
            % (len(fuori), fuori[0][0], fuori[0][1], fuori[0][2])]


def verifica_luce(oggetti, finestre, soglia=0.30, cieco=0.40, bin_=0.05):
    """Quanto una finestra e' tappata DALLE MESH, non dalle impronte.

    IL CONTROLLO SULLE IMPRONTE NON BASTA, e va detto perche' sembra che basti:
    l'impronta di un mobile dichiara la sua altezza di collisione, ma la mesh puo'
    salire quanto vuole sopra di essa. Un pensile disegnato sopra un bancone alto
    0,90 e' invisibile a quel controllo e copre la finestra per intero.

    SI GUARDANO LE FACCE, NON I VERTICI, e la differenza non e' accademica: la prima
    versione contava i vertici caduti nel vano, e un pensile che attraversa tutta la
    finestra non ne ha nemmeno uno li' dentro — i suoi vertici stanno ai due lati.
    Messo apposta sopra il lavello, quel pensile passava il controllo con il 4 per
    cento. Ogni faccia proietta invece il suo ingombro sulla larghezza del vano, e
    una tavola che lo scavalca lo copre tutto.

    SI MISURA DUE VOLTE, e la seconda e' quella che boccia. Sopra il davanzale
    finiscono anche il rubinetto e lo scolapiatti, che davanti a un lavello ci
    stanno di mestiere e non tolgono la vista: contandoli, la cucina arrivava al
    29 per cento contro una soglia del 30, cioe' un controllo che sarebbe passato
    per un centimetro e sarebbe cambiato al primo piatto spostato. La soglia si
    applica alla quota `cieco` sopra il davanzale, dove un pensile c'e' e un
    rubinetto no.

    `finestre`: (nome, x0, z0, x1, z1, davanzale, asse) con `asse` in ("x", "z"),
    la direzione lungo cui la finestra e' larga.
    """
    problemi = []
    for (nome, x0, z0, x1, z1, davanzale, asse) in finestre:
        a0, a1 = (x0, x1) if asse == "x" else (z0, z1)
        bassi, alti = set(), set()
        for o in oggetti:
            malla = o.data
            for faccia in malla.polygons:
                punti = [o.matrix_world @ malla.vertices[k].co for k in faccia.vertices]
                gx = [q.x for q in punti]
                gy = [q.z for q in punti]
                gz = [-q.y for q in punti]
                if max(gy) <= davanzale + 0.05:
                    continue
                if max(gx) < x0 or min(gx) > x1 or max(gz) < z0 or min(gz) > z1:
                    continue
                lungo = gx if asse == "x" else gz
                b0 = int((max(a0, min(lungo)) - a0) / bin_)
                b1 = int((min(a1, max(lungo)) - a0) / bin_)
                for b in range(b0, b1 + 1):
                    bassi.add(b)
                    if max(gy) > davanzale + cieco:
                        alti.add(b)
        totale = max(1, int(round((a1 - a0) / bin_)))
        q_basso = min(1.0, len(bassi) / float(totale))
        q_alto = min(1.0, len(alti) / float(totale))
        print("  %-20s ingombra il %2.0f%% della larghezza, di cui il %2.0f%% sopra i %.0f cm"
              % (nome, q_basso * 100, q_alto * 100, (davanzale + cieco) * 100))
        if q_alto > soglia:
            problemi.append("la finestra %s e' tappata per il %.0f%% della larghezza"
                            % (nome, q_alto * 100))
    return problemi


def esporta(percorso, escludi=()):
    os.makedirs(os.path.dirname(percorso), exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    for o in escludi:
        o.select_set(False)
    scelti = [o.name for o in bpy.context.selected_objects if o.type == "MESH"]
    bpy.ops.export_scene.gltf(filepath=percorso, export_format="GLB",
                              use_selection=True, export_apply=True)
    # SI STAMPA COSA ESCE, e non e' rumore: un .glb non si apre a occhio, e quello
    # che ci finisce dentro per sbaglio ha quasi sempre un nome che si riconosce
    # al volo - "Cube" e' il cubo di default di Blender, e ci e' finito davvero,
    # diventando dieci lastroni da due metri sospesi sopra le stanze.
    print("\nscritto %s\n  contiene: %s" % (percorso, ", ".join(sorted(scelti))))


# --- banco di posa -----------------------------------------------------------
def prepara_render(larghezza=1100, altezza=700, cielo=(0.30, 0.31, 0.34)):
    """Motore, mondo e camera puntata da un vincolo.

    IL MOTORE SI LEGGE, NON SI INDOVINA: il nome cambia fra le versioni di Blender
    (EEVEE_NEXT in 4.x, EEVEE in 5.x) e sbagliandolo si finisce in Workbench, che
    IGNORA i materiali e rende tutto grigio uniforme - facendo sembrare privo di
    dettagli un modello che ce li ha.
    """
    scena = bpy.context.scene
    scena.render.resolution_x, scena.render.resolution_y = larghezza, altezza
    motori = [e.identifier for e in
              bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
    scena.render.engine = next((m for m in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE", "CYCLES")
                                if m in motori), motori[0])
    print("motore di render: %s" % scena.render.engine)

    mondo = bpy.data.worlds.new("Ambiente")
    mondo.use_nodes = True
    mondo.node_tree.nodes["Background"].inputs[0].default_value = (cielo[0], cielo[1], cielo[2], 1)
    scena.world = mondo

    dati = bpy.data.cameras.new("Camera")
    camera = bpy.data.objects.new("Camera", dati)
    bpy.context.collection.objects.link(camera)
    scena.camera = camera
    bersaglio = bpy.data.objects.new("Bersaglio", None)
    bpy.context.collection.objects.link(bersaglio)
    v = camera.constraints.new("TRACK_TO")
    v.target = bersaglio
    v.track_axis = "TRACK_NEGATIVE_Z"
    v.up_axis = "UP_Y"

    def scatta(percorso, posizione, mira, lente=28.0):
        """Posizione e mira in coordinate DI GIOCO, come tutto il resto."""
        camera.location = (posizione[0], -posizione[2], posizione[1])
        dati.lens = lente
        bersaglio.location = (mira[0], -mira[2], mira[1])
        bpy.context.view_layer.update()
        scena.render.filepath = percorso
        bpy.ops.render.render(write_still=True)
        print("scritto %s" % percorso)

    return scatta


def lampada(nome, posizione, energia, tipo="POINT", dimensione=1.2):
    """Una luce, in coordinate di gioco."""
    dati = bpy.data.lights.new(nome, type=tipo)
    dati.energy = energia
    if tipo == "AREA":
        dati.size = dimensione
    o = bpy.data.objects.new(nome, dati)
    o.location = (posizione[0], -posizione[2], posizione[1])
    bpy.context.collection.objects.link(o)
    return o
