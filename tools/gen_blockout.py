# -*- coding: utf-8 -*-
"""Genera world/blockout.tscn dalla pianta del GDD: muri grezzi da percorrere a piedi."""
import io

from geometria import (K, SP, H, H_TETTO, PERIMETRO, MURI, H_ARCH, W_SILL, W_TOP, H_DOME_BASE, DOME_R, DOME_H,
                       blocchi_edificio, DISL_RAMPA, ante_porte, verifica_ante, verifica_trappole,
                       pezzi_anta, arredi, verifica_arredi,
                       scalati, verifica_aperture, verifica_copertura,
                       punti_luce, punti_interruttori, verifica_interruttori,
                       luci_senza_comando, comandate_da, GIRATE_PLAFONIERA,
                       LUCI_ROSSE, PARTE_SPENTA, punti_applique,
                       H_APPLIQUE, NOME_LOCALE, LUCE_MONITOR,
                       H_INTERRUTTORE, L_PLACCA, A_PLACCA, SP_PLACCA)

MURI, APERTURE, PAVIMENTI, SOFFITTI, SALA, (_CX, _CZ) = scalati()
_R = DOME_R

import math as _m

CX, CZ = 5.2 * K, 5.0 * K          # centro della cupola, per luci e istanza

blocchi = []   # (cx, cy, cz, sx, sy, sz, nome, rot_x)

def aggiungi(cx, cy, cz, sx, sy, sz, nome, rot_x=0.0, rot_z=0.0):
    if sx > 0.01 and sy > 0.01 and sz > 0.01:
        blocchi.append((cx, cy, cz, sx, sy, sz, nome, rot_x, rot_z))

blocchi.extend(blocchi_edificio())
# Gli arredi entrano come SOLA COLLISIONE, come i muri: la forma la da' il modello
# controllo_pc.glb, che nasce dalle stesse impronte.
blocchi.extend(arredi())

# ---------------------------------------------------------------- esterno: prato, recinto, auto
# prato: continuo con il pavimento interno, cosi' uscendo non si cade
aggiungi(22.0 * K, -0.13, 22.0 * K, 96.0 * K, 0.20, 88.0 * K, "Prato")   # 3 cm sotto: niente z-fighting

# recinto del prato (h 1,4), con un varco per il cancello sul lato sud-est
REC_X0, REC_Z0, REC_X1, REC_Z1 = -10.0 * K, -8.0 * K, 54.0 * K, 52.0 * K
H_REC = 1.40
for (rx0, rz0, rx1, rz1, nm) in [
    (REC_X0, REC_Z0, REC_X1, REC_Z0, "RecN"),
    (REC_X0, REC_Z1, 40.0 * K, REC_Z1, "RecS"),      # varco del cancello da x=40 a x=54
    (REC_X0, REC_Z0, REC_X0, REC_Z1, "RecO"),
    (REC_X1, REC_Z0, REC_X1, REC_Z1, "RecE"),
]:
    if abs(rz1 - rz0) < 0.01:
        aggiungi((rx0 + rx1) / 2.0, H_REC / 2, rz0, abs(rx1 - rx0), H_REC, 0.15, nm)
    else:
        aggiungi(rx0, H_REC / 2, (rz0 + rz1) / 2.0, 0.15, H_REC, abs(rz1 - rz0), nm)

# l'auto: ~40 m dall'ingresso (21,7 / 19)
aggiungi(46.0 * K, 0.75, 50.0 * K, 4.20, 1.50, 1.80, "Auto")   # l'auto resta a misura vera

def _base(rot_x, rot_z, cx, cy, cz):
    """La matrice del blocco. Le due inclinazioni non si combinano mai: un blocco
    sale lungo Z (rot_x) oppure lungo X (rot_z)."""
    if abs(rot_z) > 1e-9:
        c, s_ = _m.cos(rot_z), _m.sin(rot_z)
        return ("Transform3D(%.4f, %.4f, 0, %.4f, %.4f, 0, 0, 0, 1, %.3f, %.3f, %.3f)"
                % (c, s_, -s_, c, cx, cy, cz))
    c, s_ = _m.cos(rot_x), _m.sin(rot_x)
    return ("Transform3D(1, 0, 0, 0, %.4f, %.4f, 0, %.4f, %.4f, %.3f, %.3f, %.3f)"
            % (c, s_, -s_, c, cx, cy, cz))


def tscn():
    righe = ['[gd_scene load_steps=%d format=3]' % (3 + len(set((b[3], b[4], b[5]) for b in blocchi)) * 2), '',
             '[ext_resource type="PackedScene" path="res://world/player/player.tscn" id="1_player"]',
             '[ext_resource type="PackedScene" path="res://assets/models/osservatorio.glb" id="2_modello"]',
             '[ext_resource type="Script" path="res://world/interactables/door.gd" id="3_door"]',
             '[ext_resource type="PackedScene" path="res://assets/models/controllo_pc.glb" id="4_arredi"]',
             '[ext_resource type="PackedScene" path="res://assets/models/cucina.glb" id="5_cucina"]',
             '[ext_resource type="PackedScene" path="res://assets/models/divulgazione.glb" id="6_divulg"]',
             # Le ante in gioco sono nodi Door generati qui, non pezzi del modello: le
             # loro texture vanno caricate nella scena, o restano l'unica cosa a colore
             # piatto rimasta a vista.
             '[ext_resource type="Texture2D" path="res://assets/textures/legno-porte/color.jpg" id="7_anta_c"]',
             '[ext_resource type="Texture2D" path="res://assets/textures/legno-porte/normal.jpg" id="8_anta_n"]',
             '[ext_resource type="Texture2D" path="res://assets/textures/legno-porte/roughness.jpg" id="9_anta_r"]',
             '[ext_resource type="PackedScene" path="res://assets/models/impianti.glb" id="10_impianti"]',
             '[ext_resource type="PackedScene" path="res://assets/models/plafoniera.glb" id="11_plafoniera"]',
             '[ext_resource type="Script" path="res://world/interactables/light_switch.gd" id="12_switch"]',
             '[ext_resource type="PackedScene" path="res://assets/models/applique_rossa.glb" id="13_applique"]',
             '[ext_resource type="Texture2D" path="res://assets/textures/diffusore/color.jpg" id="14_diff_c"]', '']
    dims = sorted(set((round(b[3], 3), round(b[4], 3), round(b[5], 3)) for b in blocchi)
                  | {(round(p[3], 3), round(p[4], 3), round(p[5], 3))
                     for a in ante_porte() for p in pezzi_anta(a)}
                  # il corpo delle placche: due misure sole, secondo come e' girato
                  # il muro, ma se non entrano qui il .tscn cita forme che non esistono
                  | {(round(L_PLACCA, 3), round(A_PLACCA, 3), 0.05),
                     (0.05, round(A_PLACCA, 3), round(L_PLACCA, 3))})
    idx = {}
    for n, dsz in enumerate(dims):
        idx[dsz] = n
        righe.append('[sub_resource type="BoxMesh" id="m_%d"]' % n)
        righe.append('size = Vector3(%.3f, %.3f, %.3f)' % dsz)
        righe.append('')
        righe.append('[sub_resource type="BoxShape3D" id="s_%d"]' % n)
        righe.append('size = Vector3(%.3f, %.3f, %.3f)' % dsz)
        righe.append('')
    for nome, col in [("mat_muro", "0.78, 0.76, 0.72"), ("mat_pav", "0.42, 0.40, 0.38"),
                      ("mat_soff", "0.60, 0.60, 0.62"), ("mat_pass", "0.55, 0.45, 0.32"), ("mat_prato", "0.20, 0.26, 0.17"),
                      ("mat_auto", "0.45, 0.13, 0.13"), ("mat_rec", "0.35, 0.33, 0.30"), ("mat_tetto", "0.24, 0.22, 0.21"), ("mat_anta", "0.38, 0.28, 0.19"), ("mat_dome", "0.86, 0.87, 0.88"), ("mat_tele", "0.30, 0.33, 0.38")]:
        righe += ['[sub_resource type="StandardMaterial3D" id="%s"]' % nome,
                  'albedo_color = Color(%s, 1)' % col]
        if nome == "mat_dome":
            righe.append('cull_mode = 2')   # visibile anche da dentro la cupola
        if nome == "mat_anta":
            # TRIPLANARE, non le UV della BoxMesh: quelle vanno da 0 a 1 su OGNI
            # faccia, quindi la venatura si stirerebbe per riempire l'anta invece di
            # avere una scala sua. Con il triplanare la venatura e' larga uguale
            # sull'anta e sul maniglione.
            righe += ['albedo_texture = ExtResource("7_anta_c")',
                      'normal_enabled = true',
                      'normal_texture = ExtResource("8_anta_n")',
                      'roughness_texture = ExtResource("9_anta_r")',
                      'uv1_triplanar = true',
                      'uv1_scale = Vector3(0.8, 0.8, 0.8)']
        righe.append('')
    # IL PANNELLO CHE SI ACCENDE, e sta qui in mezzo alle altre sub_resource
    # perche' in un .tscn TUTTE le sub_resource vanno prima del primo [node]:
    # scritte piu' sotto, fra i nodi, la scena non si apre nemmeno.
    # Sta nella scena e non nel .glb perche' in Godot il materiale di un modello
    # e' condiviso fra tutte le sue istanze, e spegnere il diffusore di una
    # plafoniera le spegnerebbe tutte e nove insieme.
    righe += ['[sub_resource type="StandardMaterial3D" id="mat_vetro_fin"]',
              'transparency = 1',
              'albedo_color = Color(0.78, 0.84, 0.88, 0.055)',
              'metallic_specular = 0.12', 'roughness = 0.22',
              'cull_mode = 2', '',
              '[sub_resource type="BoxMesh" id="mesh_diff"]',
              'size = Vector3(1.160, 0.006, 0.240)', '',
              # LA TRAMA SI VEDE ANCHE ACCESA, e serve: una superficie luminosa
              # uniforme legge come un rettangolo bianco disegnato sul soffitto,
              # una con dentro la grana della plastica legge come un vetro. La
              # stessa mappa fa da albedo e da emissiva.
              '[sub_resource type="StandardMaterial3D" id="mat_diff"]',
              'shading_mode = 0', 'albedo_color = Color(1, 0.93, 0.78, 1)',
              'albedo_texture = ExtResource("14_diff_c")',
              'uv1_scale = Vector3(3, 1, 1)',
              'emission_enabled = true', 'emission = Color(1, 0.86, 0.62, 1)',
              'emission_texture = ExtResource("14_diff_c")',
              'emission_energy_multiplier = 1.5', '',
              '[sub_resource type="BoxMesh" id="mesh_vetro"]',
              'size = Vector3(0.008, 0.210, 0.110)', '',
              '[sub_resource type="StandardMaterial3D" id="mat_vetro"]',
              # il vetro non deve andare in sovraesposizione: oltre l'unita' il
              # rosso satura e vira al rosa, che e' il contrario di quello che serve
              # il vetro BRILLA: e' il punto acceso in mezzo al buio, e con il
              # tonemapping puo' andare oltre l'unita' senza sbiancare
              'shading_mode = 0', 'albedo_color = Color(0.55, 0.02, 0.01, 1)',
              'emission_enabled = true', 'emission = Color(1, 0, 0, 1)',
              'emission_energy_multiplier = 3.6', '']

    # L'AMBIENTE E' LA NOTTE, e per tre giri non lo e' stato senza che me ne
    # accorgessi: le modifiche a questo blocco fallivano tutte in silenzio, perche'
    # cercavo un testo che finiva con `'']` mentre qui la riga prosegue con `'',`.
    # Il risultato e' che l'illuminazione ambientale e' rimasta a 0,45 - una stanza
    # spenta restava perfettamente leggibile - mentre io continuavo a riferire di
    # averla abbassata.
    #
    # 0,020: senza lampade accese si vedono le sagome e poco altro. Sotto,
    # provato, non si trovava nemmeno l'interruttore per accenderle - e un buio in
    # cui non si puo' fare la cosa che toglie il buio non e' atmosfera, e' un muro.
    #
    # TONEMAPPING ACES, e non e' un vezzo fotografico: con la curva lineare tutto
    # quello che supera l'unita' diventa bianco PIATTO. Sul terrazzo, che e'
    # chiaro, la zona sotto ogni plafoniera si accecava, e il rosso della cupola
    # virava al rosa nel punto piu' forte - tre canali saturi fanno bianco,
    # qualunque colore avesse la luce.
    righe += ['[sub_resource type="Environment" id="env"]',
              'background_mode = 1', 'background_color = Color(0.004, 0.005, 0.010, 1)',
              'ambient_light_source = 2', 'ambient_light_color = Color(0.26, 0.32, 0.48, 1)',
              'ambient_light_energy = 0.035',
              'tonemap_mode = 3', 'tonemap_exposure = 1.0', 'tonemap_white = 3.0', '',
              '[node name="Blockout" type="Node3D"]', '',
              '[node name="WorldEnvironment" type="WorldEnvironment" parent="."]',
              'environment = SubResource("env")', '']
    usati = {}
    for (cx, cy, cz, sx, sy, sz, nome, rot, rotz) in blocchi:
        usati[nome] = usati.get(nome, 0) + 1
        nn = "%s_%d" % (nome, usati[nome])
        n = idx[(round(sx, 3), round(sy, 3), round(sz, 3))]
        visibile = nome.startswith(("Prato", "Rec", "Auto"))
        righe += ['[node name="%s" type="StaticBody3D" parent="."]' % nn,
                  'transform = %s' % _base(rot, rotz, cx, cy, cz), '',
                  ] + ([] if not visibile else [
                  '[node name="Mesh" type="MeshInstance3D" parent="%s"]' % nn,
                  'mesh = SubResource("m_%d")' % n,
                  'material_override = SubResource("%s")' % (
                      "mat_pav" if nome.startswith("Pav") else
                      "mat_soff" if nome.startswith("Soff") else
                      "mat_pass" if nome.startswith(("Pass", "Scal")) else
                      "mat_prato" if nome.startswith("Prato") else
                      "mat_auto" if nome.startswith("Auto") else
                      "mat_tetto" if nome.startswith("Tetto") else
                      "mat_rec" if nome.startswith("Rec") else
                      "mat_tele" if nome.startswith(("Pilastro", "Tubo")) else
                      "mat_pass" if nome.startswith("Rampa") else "mat_muro"), '']) + [
                  '[node name="Col" type="CollisionShape3D" parent="%s"]' % nn,
                  'shape = SubResource("s_%d")' % n, '']
    # Il modello sostituisce le scatole a vista. Le scatole restano come COLLISIONE:
    # forme convesse semplici, che la fisica preferisce a una mesh con gli infissi.
    # IL VETRO LO RIFA' LA SCENA, e non e' un ripiego. Nel .glb il materiale e'
    # gia' giusto - alphaMode BLEND, sette centesimi di opacita' - ma con
    # `roughness` a 0,05 un vetro non metallico si comporta da SPECCHIO, e in una
    # stanza senza cielo ne' riflessi lo specchio riflette la luce ambientale:
    # una lastra grigia uniforme, identica da qualunque angolo la si guardi.
    # Attraverso non si vedeva niente. Quello che serve non e' meno opacita' -
    # quella era gia' a posto - ma meno RIFLESSO: `roughness` alta e
    # `metallic_specular` bassa. Sono due manopole che il glTF non porta, quindi
    # il materiale va scritto qui.
    righe += ['[node name="Osservatorio" parent="." instance=ExtResource("2_modello")]', '',
              '[node name="Vetri" parent="Osservatorio" index="%d"]' % 28,
              'material_override = SubResource("mat_vetro_fin")', '',
              '[node name="ControlloPC" parent="." instance=ExtResource("4_arredi")]', '',
              '[node name="Cucina" parent="." instance=ExtResource("5_cucina")]', '',
              '[node name="Divulgazione" parent="." instance=ExtResource("6_divulg")]', '',
              # LA LUNA, e con le ombre. Senza `shadow_enabled` una direzionale
              # attraversa i muri: illuminava il pavimento delle stanze interne
              # passando dal tetto, e si vedeva una luce che non veniva da nessuna
              # parte. Lo specular quasi a zero perche' faceva un riflesso bianco
              # sul terrazzo, una macchia che seguiva il giocatore.
              '[node name="Luna" type="DirectionalLight3D" parent="."]',
              'transform = Transform3D(0.86, -0.35, 0.37, 0, 0.73, 0.68, -0.51, -0.59, 0.63, 19, 12, 9)',
              # DALLA FINESTRA SI DEVE VEDERE FUORI. A 0,018 il prato era nero e i
              # vetri sembravano lastre opache: di notte si vede attraverso un vetro
              # solo se dall'altra parte c'e' qualcosa da vedere.
              'light_energy = 0.22', 'light_color = Color(0.60, 0.68, 0.96, 1)',
              'light_specular = 0.02', 'shadow_enabled = true',
              'directional_shadow_normal_bias = 0.2', '']
    # --- l'impianto luce: apparecchio, luce e comando ------------------------
    # OGNI LAMPADA E' DUE COSE: l'APPARECCHIO, che c'e' sempre, e quello che si
    # ACCENDE - la luce piu' il bagliore del diffusore. L'interruttore spegne solo
    # il secondo. La prima versione nascondeva il nodo intero, e spegnendo la luce
    # spariva anche la plafoniera dal soffitto.
    #
    # E lo stato iniziale sta sul nodo "Accesa", su una riga scritta SUBITO DOPO
    # la sua intestazione. In un .tscn le proprieta' appartengono all'ultimo
    # [node] dichiarato: scritte in fondo al gruppo finivano sull'OmniLight, e la
    # luce rossa della cupola nasceva spenta senza che l'interruttore potesse piu'
    # riaccenderla - accendeva un nodo padre che era gia' visibile.
    righe += ['[node name="Impianti" parent="." instance=ExtResource("10_impianti")]', '']
    nodo_luce = {}

    def gruppo_luce(nome, trasf, risorsa, spenta, luce, bagliore, pezzi):
        """Un apparecchio: modello sempre visibile, luce e bagliore commutabili.

        L'APPARECCHIO NON PROIETTA OMBRA. La sua lampada gli sta dentro, quindi si
        fa ombra da solo sul soffitto: una macchia scura a bordo netto sopra ogni
        plafoniera, che entrando e' la prima cosa che si nota. Fisicamente e'
        corretta - una plafoniera a plafone non si illumina il soffitto - ma una
        plafoniera vera non e' una lastra opaca illuminata da un punto, e quella
        macchia legge come un difetto. `shadow_blur` da solo non e' bastato.

        `pezzi` sono i nomi delle mesh dentro il .glb, che vanno scritti a mano
        perche' sovrascrivere una proprieta' dentro una scena istanziata vuole il
        percorso esatto del nodo.
        """
        acceso = "Luce_%s/Accesa" % nome
        fuori = ['[node name="Luce_%s" type="Node3D" parent="."]' % nome,
                 'transform = %s' % trasf, '',
                 '[node name="Apparecchio" parent="Luce_%s" instance=ExtResource("%s")]'
                 % (nome, risorsa), '']
        for pezzo in pezzi:
            fuori += ['[node name="%s" parent="Luce_%s/Apparecchio" index="%d"]'
                      % (pezzo, nome, pezzi.index(pezzo)),
                      'cast_shadow = 0', '']
        fuori += ['[node name="Accesa" type="Node3D" parent="Luce_%s"]' % nome]
        if spenta:
            fuori.append('visible = false')
        fuori += ['', '[node name="L" type="OmniLight3D" parent="%s"]' % acceso] + luce + [''] +                  ['[node name="Bagliore" type="MeshInstance3D" parent="%s"]' % acceso] + bagliore + ['']
        return fuori

    for lx, lz, ln in punti_luce():
        nodo_luce[ln] = "Luce_%s" % ln
        c, s_ = (0.0, 1.0) if ln in GIRATE_PLAFONIERA else (1.0, 0.0)
        righe += gruppo_luce(
            ln,
            'Transform3D(%.0f, 0, %.0f, 0, 1, 0, %.0f, 0, %.0f, %.2f, %.3f, %.2f)'
            % (c, -s_, s_, c, lx, H - 0.09, lz),
            "11_plafoniera", ln in PARTE_SPENTA,
            # LA LUCE STA TRENTA CENTIMETRI SOTTO IL DIFFUSORE, non due. A ridosso
            # dell'intradosso disegnava sul soffitto un disco bianco netto con
            # sotto l'ombra dura dell'apparecchio: una plafoniera che si illumina
            # il soffitto addosso e lascia al buio quello che dovrebbe illuminare.
            # Scesa, il disco si allarga e sfuma, e la luce va dove deve andare.
            ['transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -0.30, 0)',
             # GIALLE E PIU' BASSE. In Italia in quegli anni la luce era calda, e
             # una plafoniera bianco-neutro a 1,9 leggeva come un ufficio di oggi.
             'light_energy = 2.1', 'light_color = Color(1, 0.82, 0.56, 1)',
             # lo speculare basso: su un terrazzo lucido faceva sotto ogni
             # plafoniera una chiazza bianca che seguiva chi cammina
             'light_specular = 0.12',
             # attenuazione sotto l'unita': il decadimento e' piu' lento e la
             # stanza si illumina tutta invece che a chiazza sotto la lampada
             'omni_range = 11.0', 'omni_attenuation = 0.85',
             # l'ombra dell'apparecchio sul soffitto e' vera, ma a bordo netto
             # sembra un difetto: una plafoniera vera ha una sorgente larga un
             # metro, non un punto, e il suo bordo d'ombra e' morbido. Non piu' di
             # cosi': sfocare un'ombra la fa anche RIENTRARE, e su un muro di venti
             # centimetri la luce ricomincia a passare dall'altra parte.
             'shadow_blur = 1.2',
             # I BIAS PICCOLI, O LA LUCE ATTRAVERSA I MURI. Il default di
             # `shadow_normal_bias` e' 1.0: sposta il campione dell'ombra di un
             # METRO lungo la normale, e un muro spesso venti centimetri smette
             # semplicemente di fare ombra. Di notte la luce rossa della cupola
             # usciva sulla facciata come se il muro non ci fosse.
             # BIAS ALTI, e il caso lo giustifica: la lampada sta trenta
             # centimetri sotto il soffitto e lo illumina di STRISCIO. L'incidenza
             # rasente e' il caso peggiore per una mappa d'ombra - il passo dei
             # texel diventa enorme rispetto alla superficie, e quello che si vede
             # e' un tratteggio incrociato che non e' l'intonaco. Sul soffitto non
             # c'e' niente che debba fare ombra, quindi qui il bias non costa
             # nulla; sulle applique resta basso, perche' li' l'ombra e' il muro.
             'shadow_normal_bias = 0.45', 'shadow_bias = 0.09',
             # LE OMBRE SERVONO A CAPIRE CHI COMANDA COSA: senza, la luce della
             # cucina attraversa il muro e illumina il corridoio, e premendo un
             # interruttore cambia mezzo edificio.
             'shadow_enabled = true'],
            ['transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -0.002, 0)',
             'mesh = SubResource("mesh_diff")',
             'material_override = SubResource("mat_diff")'],
            ["Lamiera", "Neon"])

    for (ln, ax, az, anx, anz) in punti_applique():
        nodo_luce[ln] = "Luce_%s" % ln
        # il modello nasce addossato a x=0 e sporge verso +X: qui si gira in modo
        # che il suo +X locale coincida con la normale del muro
        ca, sa = anx, -anz
        righe += gruppo_luce(
            ln,
            'Transform3D(%.0f, 0, %.0f, 0, 1, 0, %.0f, 0, %.0f, %.2f, %.3f, %.2f)'
            % (ca, -sa, sa, ca, ax, H_APPLIQUE, az),
            "13_applique", ln in PARTE_SPENTA,
            # PIU' FORTE della plafoniera, non piu' debole: il rosso e' il solo
            # modo di vedere qualcosa in cupola, e non deve essere un lumino.
            ['transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.30, 0, 0)',
             # UN ROSSO CUPO, e il colore non bastava a ottenerlo. Quello che
             # slavava il rosso era il RIFLESSO SPECULARE: al centro dell'alone la
             # componente speculare porta tutti e tre i canali oltre l'unita', e
             # tre canali saturi fanno una macchia BIANCA in mezzo al rosso. Con
             # `light_specular` a zero resta solo il diffuso, che e' rosso e basta.
             # Piu' l'energia giu': sopra una certa intensita' anche il diffuso
             # satura, e satura verso il bianco.
             # LA LUCE ROSSA E' ANCHE PAURA, non solo mestiere. Quello che la
             # rende inquietante non e' quanta ne fai: e' una sorgente PICCOLA e
             # accesa in mezzo al nero, con la luce che cade in fretta. Con
             # l'attenuazione bassa la sala diventava uniformemente rosa e non
             # faceva ne' paura ne' luce.
             #
             # ROSSO PURO: zero verde E ZERO BLU. Il filo di blu che avevo messo
             # per avvicinarmi al rosso delle uscite di sicurezza faceva virare al
             # viola tutto quello che la luce colpiva di sfuggita - su una parete
             # chiara bastano cinque centesimi di blu.
             'light_energy = 4.6', 'light_color = Color(1, 0, 0, 1)',
             'light_specular = 0.0',
             'omni_range = 6.5', 'omni_attenuation = 2.2',
             'shadow_blur = 1.0', 'shadow_normal_bias = 0.14', 'shadow_bias = 0.045',
             'shadow_enabled = true'],
            ['transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.132, 0, 0)',
             'mesh = SubResource("mesh_vetro")',
             'material_override = SubResource("mat_vetro")'],
            ["Metallo", "NeonRosso"])

    # IL CRT E' UNA SORGENTE. Uno schermo acceso che non illumina niente e' un
    # adesivo: la sua luce cade sul piano della consolle e sulla faccia di chi ci
    # sta davanti, ed e' l'unica che resta se si spegne tutto il resto. Verde e
    # debole, con una portata corta - un monitor non illumina una stanza.
    righe += ['[node name="Luce_monitor" type="OmniLight3D" parent="."]',
              'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.2f, %.2f, %.2f)'
              % LUCE_MONITOR,
              'light_energy = 0.40', 'light_color = Color(0.55, 1, 0.68, 1)',
              'omni_range = 1.9', 'shadow_normal_bias = 0.14', 'shadow_bias = 0.045',
              'shadow_enabled = true', '']

    # le placche: la geometria sta nel modello, qui c'e' il corpo che il raggio
    # colpisce. Un pezzo di muro non serve a fermare nessuno, serve a essere visto.
    for (nome, x, z, nx, nz) in punti_interruttori():
        pulito = nome.replace(" -> ", "_a_").replace(" ", "_")
        sx, sz = (L_PLACCA, 0.05) if nz else (0.05, L_PLACCA)
        chiave = (round(sx, 3), round(A_PLACCA, 3), round(sz, 3))
        comandate = comandate_da(nome)
        righe += ['[node name="Interruttore_%s" type="StaticBody3D" parent="."]' % pulito,
                  'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.3f, %.3f, %.3f)'
                  % (x + nx * 0.02, H_INTERRUTTORE, z + nz * 0.02),
                  'script = ExtResource("12_switch")',
                  'locale = "%s"' % NOME_LOCALE.get(nome, ""),
                  # una placca che comanda solo lampade spente parte spenta: e' lo
                  # stesso stato, scritto una volta sola in geometria
                  'accesa = %s' % ("false" if all(n in PARTE_SPENTA for n in comandate)
                                   else "true"),
                  'luci = [%s]' % ", ".join('NodePath("../%s/Accesa")' % nodo_luce[n]
                                            for n in comandate), '',
                  '[node name="Col" type="CollisionShape3D" parent="Interruttore_%s"]' % pulito,
                  'shape = SubResource("s_%d")' % idx[chiave], '']

    # --- le porte: un nodo per anta, con l'origine SUL CARDINE ---------------
    for a in ante_porte():
        dx, _, dz = a["direzione"]
        nx, _, nz = a["normale"]
        px, _, pz = a["perno"]
        L, HA, T = a["larghezza"], a["altezza"], a["spessore"]
        # in Godot la basis X ruotata di theta attorno a Y vale (cos, 0, -sin):
        # orientare il nodo lungo la direzione dell'anta significa questo angolo
        rot = _m.atan2(-dz, dx)
        # e aprire verso la normale significa girare in questo verso
        verso = 1 if (dz * nx - dx * nz) > 0 else -1
        nome = "Porta_" + a["nome"].replace(" -> ", "_a_").replace(" ", "_")
        c, s_ = _m.cos(rot), _m.sin(rot)
        righe += ['[node name="%s" type="StaticBody3D" parent="."]' % nome,
                  'transform = Transform3D(%.4f, 0, %.4f, 0, 1, 0, %.4f, 0, %.4f, %.3f, 0.000, %.3f)'
                  % (c, -s_, s_, c, px, pz),
                  'script = ExtResource("3_door")',
                  'apertura_gradi = 80.0',
                  'verso = %d' % verso,
                  'prompt_text = "Apri"', '',
                  ]
        # il lato interno dell'anta sta lungo +Z locale quando verso vale +1
        for (lungo, alto, lato, sx, sy, sz, etichetta) in pezzi_anta(a):
            chiave = (round(sx, 3), round(sy, 3), round(sz, 3))
            suffisso = "Mesh" if etichetta == "Anta" else etichetta + str(round(lungo * 100))
            righe += ['[node name="%s" type="MeshInstance3D" parent="%s"]' % (suffisso, nome),
                      'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.3f, %.3f, %.3f)'
                      % (lungo, alto, -lato * verso),
                      'mesh = SubResource("m_%d")' % idx[chiave],
                      'material_override = SubResource("%s")'
                      % ("mat_anta" if etichetta == "Anta" else "mat_tele"), '']
        righe += ['[node name="Col" type="CollisionShape3D" parent="%s"]' % nome,
                  'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.3f, %.3f, 0)' % (L / 2, HA / 2),
                  'shape = SubResource("s_%d")' % idx[(round(L, 3), round(HA, 3), round(T, 3))], '']

    righe += ['[node name="Player" parent="." instance=ExtResource("1_player")]',
              'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.3f, 0.000, %.3f)' % (21.7 * K, 17.0 * K), '', '',
              '[node name="Camera" parent="Player" index="1"]',
              'fov = 55.0', '']
    return "\n".join(righe)


def verifica_raccordi(tolleranza=0.03):
    """Le superfici calpestabili che si toccano non devono lasciare scalini:
    un CharacterBody3D non fa step-up, e uno scalino di 9 cm blocca la salita."""
    problemi = []
    pas = [b for b in blocchi if b[6].startswith("Pass")]
    ram = [b for b in blocchi if b[6].startswith("Rampa")]
    if pas and ram:
        calpestio = max(b[1] + b[4] / 2 for b in pas)
        cima = DISL_RAMPA
        if abs(calpestio - cima) > tolleranza:
            problemi.append("  SCALINO           rampa a %.2f, passerella a %.2f: %.0f cm"
                            % (cima, calpestio, abs(calpestio - cima) * 100))
    return problemi


ESTERNI = ("Prato", "Rec", "Auto", "Tetto")   # gli unici blocchi ammessi fuori dai muri


def verifica_ingombri(margine=0.40):
    """Nessun blocco interno deve sporgere dall'impronta dell'edificio.
    E' la verifica che il pilastro-recinto da 30 metri non avrebbe superato."""
    problemi = []
    for (cx, cy, cz, sx, sy, sz, nome, rot, rotz) in blocchi:
        if nome.startswith(ESTERNI):
            continue
        # ogni angolo in pianta deve cadere dentro l'UNIONE dei pavimenti: un muro che
        # attraversa il confine fra due rettangoli adiacenti e' legittimo
        angoli = [(cx + a * sx / 2, cz + b * sz / 2) for a in (-1, 1) for b in (-1, 1)]
        dentro = all(any(x0 - margine <= x <= x1 + margine and z0 - margine <= z <= z1 + margine
                         for (x0, z0, x1, z1) in PAVIMENTI) for (x, z) in angoli)
        if not dentro:
            problemi.append("  FUORI SAGOMA      %-10s %.2f x %.2f x %.2f m in (%.2f, %.2f)"
                            % (nome, sx, sy, sz, cx, cz))
    return problemi


def verifica_fessure(tolleranza=0.02, passo=0.5):
    """Fra la cima di un muro perimetrale e cio' che gli sta sopra non ci deve
    essere aria.

    IL DIFETTO CHE L'HA FATTO SCRIVERE. I muri finivano a H = 3,00 e il tetto
    comincia a 3,20: dove il solaio non arriva - la sala del telescopio, coperta
    dal tetto forato e dalla calotta - restava una feritoia di venti centimetri
    lungo tutto il perimetro. Da fuori ci si vedeva dentro, e di notte la luce
    rossa usciva a fascia sopra la facciata. Nessuno degli altri controlli la
    vedeva: guardano tutti la PIANTA, e questa e' una fessura in ALZATO.

    Si campiona la linea d'asse di ogni muro perimetrale e si cerca, sopra ogni
    campione, il pezzo di copertura piu' basso che lo copra.
    """
    coperture = [b for b in blocchi if b[6].startswith(("Tetto", "Soff", "Pav"))]
    problemi = []
    for i in range(len(PERIMETRO)):
        pezzi = [b for b in blocchi if b[6] == "M%d" % i]
        if not pezzi:
            continue
        cima = max(b[1] + b[4] / 2.0 for b in pezzi)
        x0, z0, x1, z1 = [v * K for v in PERIMETRO[i]]
        lungo = _m.hypot(x1 - x0, z1 - z0)
        n = max(2, int(lungo / passo))
        for k in range(n + 1):
            t = float(k) / n
            px, pz = x0 + (x1 - x0) * t, z0 + (z1 - z0) * t
            sopra = [c[1] - c[4] / 2.0 for c in coperture
                     if abs(px - c[0]) <= c[3] / 2.0 + 0.01
                     and abs(pz - c[2]) <= c[5] / 2.0 + 0.01
                     and c[1] - c[4] / 2.0 >= cima - 0.35]
            if not sopra:
                problemi.append("  MURO SCOPERTO     M%d in (%.2f, %.2f): sopra la cima"
                                " a %.2f non c'e' niente" % (i, px, pz, cima))
                break
            if min(sopra) > cima + tolleranza:
                problemi.append("  FESSURA IN ALTO   M%d in (%.2f, %.2f): il muro finisce a"
                                " %.2f, sopra si riparte da %.2f"
                                % (i, px, pz, cima, min(sopra)))
                break
    return problemi


out = r"E:\GIT\astrochills-gd-3d\world\blockout.tscn"
io.open(out, "w", encoding="utf-8").write(tscn())
_pr = verifica_aperture()
if _pr:
    print("ATTENZIONE, aperture da sistemare:")
    for _p in _pr:
        print(_p)
else:
    print("aperture: tutte collocate, nessun montante sotto i 30 cm")
_tetti = [(b[0]-b[3]/2, b[2]-b[5]/2, b[0]+b[3]/2, b[2]+b[5]/2)
          for b in blocchi if b[6].startswith('TettoCup')]
_ing = (verifica_ingombri() + verifica_raccordi() + verifica_ante()
        + verifica_trappole() + verifica_arredi() + verifica_interruttori()
        + verifica_fessure())
if _ing:
    print("ATTENZIONE:")
    for _p in _ing:
        print(_p)
else:
    print("ingombri, raccordi, trappole e arredi: niente fuori sagoma, nessuno scalino,"
          " nessun buco senza uscita, niente che tappi un vetro o isoli un angolo")
_sc = verifica_copertura(_tetti)
_senza = luci_senza_comando()
print("impianto: %d plafoniere, %d placche%s"
      % (len(punti_luce()), len(punti_interruttori()),
         ("; senza interruttore: " + ", ".join(_senza)) if _senza else ""))
print("copertura: tutto coperto" if _sc < 0.05 else "ATTENZIONE, %.1f m2 di pavimento senza tetto" % _sc)
print("scritto %s  -  %d blocchi, %d dimensioni distinte" % (out, len(blocchi), len(set((b[3], b[4], b[5]) for b in blocchi))))


# --- controllo sul FILE, non sul sorgente ------------------------------------
# LE MODIFICHE A QUESTO GENERATORE POSSONO FALLIRE IN SILENZIO. E' successo per tre
# giri di fila con il blocco dell'Environment: riferivo di aver abbassato la luce
# ambientale mentre nel .tscn restava a 0,45. Qui si rilegge il file scritto e si
# controlla che i valori che contano ci siano davvero.
_scritto = io.open(out, encoding="utf-8").read()
_attesi = [("ambient_light_energy = 0.035", "la luce ambientale della notte"),
           ("tonemap_mode = 3", "il tonemapping ACES"),
           ("shadow_normal_bias = 0.45", "i bias delle ombre delle plafoniere"),
           ('locale = "la cucina"', "il nome del locale nel prompt")]
_mancanti = ["  MANCA NEL .tscn   %s (%s)" % (t, perche)
             for (t, perche) in _attesi if t not in _scritto]
if _mancanti:
    print("ATTENZIONE:")
    for _p in _mancanti:
        print(_p)
else:
    print("scena: ambiente notturno, tonemapping e ombre verificati NEL FILE")
