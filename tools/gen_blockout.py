# -*- coding: utf-8 -*-
"""Genera world/blockout.tscn dalla pianta del GDD: muri grezzi da percorrere a piedi."""
import ast
import io
import os
import re as _re

from geometria import (K, SP, H, H_TETTO, PERIMETRO, MURI, H_ARCH, W_SILL, W_TOP, H_DOME_BASE, DOME_R, DOME_H,
                       blocchi_edificio, DISL_RAMPA, ante_porte, verifica_ante, verifica_trappole,
                       pezzi_anta, arredi, verifica_arredi,
                       ante_mobili, pezzi_anta_mobile,
                       scalati, verifica_aperture, verifica_copertura,
                       punti_luce, punti_interruttori, verifica_interruttori,
                       verifica_applique, verifica_passerella,
                       verifica_plafoniere,
                       luci_senza_comando, comandate_da, GIRATE_PLAFONIERA,
                       LUCI_ROSSE, PARTE_SPENTA, punti_applique,
                       H_APPLIQUE, NOME_LOCALE, LUCE_MONITOR, SEMPRE_ACCESE,
                       H_INTERRUTTORE, L_PLACCA, A_PLACCA, SP_PLACCA,
                       CASSA_MONITOR, VETRO_MONITOR, IMMAGINE_MONITOR,
                       SEDILE_MONITOR)

MURI, APERTURE, PAVIMENTI, SOFFITTI, SALA, (_CX, _CZ) = scalati()
_R = DOME_R

import math as _m

CX, CZ = 5.2 * K, 5.0 * K          # centro della cupola, per luci e istanza

blocchi = []   # (cx, cy, cz, sx, sy, sz, nome, rot_x)

def aggiungi(cx, cy, cz, sx, sy, sz, nome, rot_x=0.0, rot_z=0.0, rot_y=0.0):
    if sx > 0.01 and sy > 0.01 and sz > 0.01:
        blocchi.append((cx, cy, cz, sx, sy, sz, nome, rot_x, rot_z, rot_y))

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

def _base(rot_x, rot_z, cx, cy, cz, rot_y=0.0):
    """La matrice del blocco. Le tre rotazioni non si combinano mai: un blocco sale
    lungo Z (rot_x), oppure lungo X (rot_z), oppure gira in pianta (rot_y).

    I DODICI NUMERI SONO LE RIGHE della base, non le colonne: la colonna X - cioe'
    l'asse che il blocco segue - e' (riga0[0], riga1[0], riga2[0]). Scriverla per
    colonne monta tutto specchiato, ed e' gia' costato una giornata (D-081).
    """
    if abs(rot_y) > 1e-9:
        c, s_ = _m.cos(rot_y), _m.sin(rot_y)
        return ("Transform3D(%.4f, 0, %.4f, 0, 1, 0, %.4f, 0, %.4f, %.3f, %.3f, %.3f)"
                % (c, -s_, s_, c, cx, cy, cz))
    if abs(rot_z) > 1e-9:
        c, s_ = _m.cos(rot_z), _m.sin(rot_z)
        return ("Transform3D(%.4f, %.4f, 0, %.4f, %.4f, 0, 0, 0, 1, %.3f, %.3f, %.3f)"
                % (c, s_, -s_, c, cx, cy, cz))
    c, s_ = _m.cos(rot_x), _m.sin(rot_x)
    return ("Transform3D(1, 0, 0, 0, %.4f, %.4f, 0, %.4f, %.4f, %.3f, %.3f, %.3f)"
            % (c, s_, -s_, c, cx, cy, cz))


# Quali ante in gioco NON sono fatte di scatole ma di un modello, e con che
# ExtResource. Il battente del magazzino era otto scatole - nervature, griglia,
# portalucchetto - e i pezzi erano quelli giusti; solo che erano scatole, e da un
# metro si vedeva. Una porta di lamiera la fa la VERNICE, cioe' la texture.
ANTE_DAL_MODELLO = {"magazzino": "23_pmag"}


def tscn():
    righe = ['[gd_scene load_steps=%d format=3]' % (3 + len(set((b[3], b[4], b[5]) for b in blocchi)) * 2), '',
             '[ext_resource type="PackedScene" path="res://world/player/player.tscn" id="1_player"]',
             '[ext_resource type="PackedScene" path="res://assets/models/osservatorio.glb" id="2_modello"]',
             '[ext_resource type="Script" path="res://world/interactables/door.gd" id="3_door"]',
             '[ext_resource type="PackedScene" path="res://assets/models/controllo_pc.glb" id="4_arredi"]',
             '[ext_resource type="PackedScene" path="res://assets/models/cucina.glb" id="5_cucina"]',
             '[ext_resource type="PackedScene" path="res://assets/models/divulgazione.glb" id="6_divulg"]',
             '[ext_resource type="PackedScene" path="res://assets/models/bagno.glb" id="19_bagno"]',
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
             '[ext_resource type="Texture2D" path="res://assets/textures/diffusore/color.jpg" id="14_diff_c"]',
             '[ext_resource type="PackedScene" path="res://assets/models/applique_bianca.glb" id="15_esterna"]',
             '[ext_resource type="Texture2D" path="res://assets/textures/metallo/color.jpg" id="16_met_c"]',
             '[ext_resource type="Texture2D" path="res://assets/textures/metallo/normal.jpg" id="17_met_n"]',
             '[ext_resource type="Texture2D" path="res://assets/textures/metallo/roughness.jpg" id="18_met_r"]',
             # IL BATTENTE DEL MAGAZZINO E' UN MODELLO, non delle scatole. Sta in un
             # .glb suo e non dentro quello dell'edificio perche' RUOTA: un pezzo che
             # gira ha bisogno di un nodo con l'origine sul cardine, e dentro
             # osservatorio.glb girerebbe l'edificio.
             '[ext_resource type="PackedScene" path="res://assets/models/porta_magazzino.glb" id="23_pmag"]',
             # LA POSTAZIONE AL MONITOR. Il tubo e' arredo e sta dentro
             # controllo_pc.glb; quello che sta qui e' cio' che l'arredo non puo'
             # essere: la collisione che il raggio dell'interazione cerca, il vetro
             # vivo su cui il gioco disegna, e il posto dove va la testa di chi si
             # siede. Il modello non sa niente di tutto questo, e non deve.
             '[ext_resource type="Script" path="res://world/desk_station.gd" id="24_postazione"]',
             '[ext_resource type="Script" path="res://world/interactables/crt_monitor.gd" id="25_crt"]',
             '[ext_resource type="PackedScene" path="res://crt/crt_screen.tscn" id="26_vetro"]',
             '']
    dims = sorted(set((round(b[3], 3), round(b[4], 3), round(b[5], 3)) for b in blocchi)
                  | {(round(p[3], 3), round(p[4], 3), round(p[5], 3))
                     for a in ante_porte() for p in pezzi_anta(a)}
                  # e quelle dei mobili: se non entrano qui il .tscn cita BoxMesh
                  # che non esistono, e Godot apre la scena senza le ante
                  | {(round(p[3], 3), round(p[4], 3), round(p[5], 3))
                     for a in ante_mobili() for p in pezzi_anta_mobile(a)}
                  | {(round(a["larghezza"], 3), round(a["altezza"], 3),
                      round(a["spessore"], 3)) for a in ante_mobili()}
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
                      ("mat_auto", "0.45, 0.13, 0.13"), ("mat_rec", "0.35, 0.33, 0.30"), ("mat_tetto", "0.24, 0.22, 0.21"), # L'ANTA E IL SUO TELAIO SONO LO STESSO LEGNO, e per sette porte non lo
                      # sembravano. Il telaio lo disegna Blender, l'anta nasce qui, e
                      # tutti e due usano la mappa `legno-porte`: solo che di la' il
                      # materiale NON e' fra i TINTI - la mappa parla da sola - e qui
                      # veniva moltiplicata per 0,38. Il risultato era un battente
                      # quasi nero incastrato in una mostra color miele, e si vedeva
                      # da qualunque punto del corridoio. Bianco pieno, come di la'.
                      ("mat_anta", "1, 1, 1"), ("mat_dome", "0.86, 0.87, 0.88"), ("mat_tele", "0.30, 0.33, 0.38"),
                      # la porta del magazzino: lamiera verniciata verde-grigio
                      # 0,73 QUI VUOL DIRE 0,50 LA'. La stessa lamiera e' tinta in
                      # due file - il telaio in Blender, l'anta qui - e la tinta
                      # dichiarata era la stessa: 0,50. Misurate, uscivano 100 e 52
                      # su 255. `albedo_color` di Godot e' in sRGB e viene convertita
                      # in lineare per illuminare, il Base Color di Blender e' gia'
                      # lineare: lo stesso numero vale 0,21 di qua e 0,50 di la',
                      # cioe' due volte e mezzo. 0,73 in sRGB e' 0,50 in lineare.
                      # I MOBILI DEL BAGNO. I loro colori sono gli stessi che il
                      # modellatore usa in Blender, CONVERTITI: `albedo_color` di
                      # Godot e' in sRGB, il Base Color di Blender e' lineare, e lo
                      # stesso numero scritto nei due posti da' due grigi diversi. E'
                      # la quarta volta che questo fattore 2,4 morde in questo
                      # progetto, e qui morderebbe peggio che altrove - un'anta e la
                      # cassa a cui e' attaccata devono essere lo STESSO legno.
                      ("mat_teche", "1, 1, 1"),
                      ("mat_armadietto", "0.808, 0.825, 0.803"),
                      ("mat_specchio", "0.862, 0.877, 0.892"),
                      ("mat_feritoia", "0.264, 0.284, 0.293"),
                      ("mat_metallo", "0.73, 0.75, 0.73")]:
        righe += ['[sub_resource type="StandardMaterial3D" id="%s"]' % nome,
                  'albedo_color = Color(%s, 1)' % col]
        if nome == "mat_dome":
            righe.append('cull_mode = 2')   # visibile anche da dentro la cupola
        if nome == "mat_metallo":
            # stesso triplanare dell'anta di legno e per la stessa ragione: le UV
            # di una BoxMesh vanno da 0 a 1 su OGNI faccia, quindi la grana della
            # lamiera si stirerebbe per riempire un'aletta di griglia larga due
            # centimetri e mezzo esattamente come riempie l'anta intera.
            righe += ['albedo_texture = ExtResource("16_met_c")',
                      'normal_enabled = true',
                      'normal_texture = ExtResource("17_met_n")',
                      'roughness_texture = ExtResource("18_met_r")',
                      # NIENTE METALLICO. E' la terza volta in questo progetto:
                      # una superficie metallica restituisce cio' che ha intorno, e
                      # in un corridoio a luce rossa non ha intorno niente. L'anta
                      # usciva quasi nera mentre il telaio - stesso colore, stessa
                      # mappa, ma senza metallico - era grigio-verde. La vernice a
                      # fuoco di una porta non e' uno specchio.
                      'metallic = 0.0', 'metallic_specular = 0.35', 'roughness = 0.55',
                      'uv1_triplanar = true',
                      'uv1_scale = Vector3(1.6, 1.6, 1.6)']
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
        if nome == "mat_teche":
            # LO STESSO LEGNO DELLA CASSA, E SENZA TINTA. Qui c'era il noce delle
            # teche moltiplicato per un colore scuro, e il risultato era un'anta piu'
            # scura del mobile a cui e' attaccata: in Blender quel materiale la tinta
            # NON la moltiplica - non sta fra i TINTI - e qui invece si'. Lo stesso
            # legno disegnato da due programmi con due formule diverse da' due legni.
            # Bianco pieno, la mappa parla da sola, come di la'.
            righe += ['albedo_texture = ExtResource("7_anta_c")',
                      'normal_enabled = true',
                      'normal_texture = ExtResource("8_anta_n")',
                      'roughness_texture = ExtResource("9_anta_r")',
                      'roughness = 0.45',
                      'uv1_triplanar = true',
                      # 1,82 = una ripetizione ogni 55 cm, che e' la scala con cui
                      # `modellare.TEXTURE` cuoce le UV della cassa in Blender
                      'uv1_scale = Vector3(1.82, 1.82, 1.82)']
        if nome == "mat_armadietto":
            righe += ['albedo_texture = ExtResource("16_met_c")',
                      'normal_enabled = true',
                      'normal_texture = ExtResource("17_met_n")',
                      'roughness_texture = ExtResource("18_met_r")',
                      'metallic = 0.0', 'metallic_specular = 0.30', 'roughness = 0.48',
                      'uv1_triplanar = true',
                      'uv1_scale = Vector3(2.0, 2.0, 2.0)']
        if nome == "mat_specchio":
            # LUCIDO MA NON METALLICO. La quinta volta: una superficie metallica in
            # una stanza chiusa restituisce il nero dell'ambiente, e uno specchio
            # nero non si legge come uno specchio, si legge come un buco. Lucido e
            # basta - riflette le luci e non pretende di riflettere la stanza.
            righe += ['metallic = 0.0', 'metallic_specular = 0.85', 'roughness = 0.06']
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
              'emission_energy_multiplier = 3.6', '',
              # il vetro delle due esterne: acceso appena, quanto basta a vedersi
              '[sub_resource type="StandardMaterial3D" id="mat_vetro_est"]',
              'shading_mode = 0', 'albedo_color = Color(0.86, 0.87, 0.84, 1)',
              'emission_enabled = true', 'emission = Color(1, 0.97, 0.90, 1)',
              'emission_energy_multiplier = 1.1', '']

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
              # La cassa del tubo come solido: e' cio' contro cui il raggio
              # dell'interazione sbatte, e senza non c'e' nessun prompt.
              '[sub_resource type="BoxShape3D" id="s_monitor"]',
              'size = Vector3(%.3f, %.3f, %.3f)' % CASSA_MONITOR[3:], '',
              # L'immagine: un quad 4:3 appoggiato un millimetro davanti al vetro.
              '[sub_resource type="QuadMesh" id="q_monitor"]',
              'size = Vector2(%.3f, %.3f)' % IMMAGINE_MONITOR, '',
              # IL COPIONE DELLA POSTAZIONE STA SULLA RADICE, ed e' l'unico script
              # di questa scena che non sia un interagibile: sedersi non e' una
              # proprieta' del monitor, e' una sequenza fra il monitor, il corpo del
              # giocatore e la sua testa. Vedi world/desk_station.gd.
              '[node name="Blockout" type="Node3D"]',
              'script = ExtResource("24_postazione")', '',
              '[node name="WorldEnvironment" type="WorldEnvironment" parent="."]',
              'environment = SubResource("env")', '']
    usati = {}
    # `*resto` e non tre nomi: non tutte le sorgenti di blocchi hanno le stesse
    # rotazioni - infissi e arredi ne dichiarano meno - e chiedere dieci valori a
    # una tupla da otto fa saltare tutto il generatore per un blocco che non gira.
    for (cx, cy, cz, sx, sy, sz, nome, rot, *resto) in blocchi:
        rotz = resto[0] if resto else 0.0
        roty = resto[1] if len(resto) > 1 else 0.0
        usati[nome] = usati.get(nome, 0) + 1
        nn = "%s_%d" % (nome, usati[nome])
        n = idx[(round(sx, 3), round(sy, 3), round(sz, 3))]
        visibile = nome.startswith(("Prato", "Rec", "Auto"))
        righe += ['[node name="%s" type="StaticBody3D" parent="."]' % nn,
                  'transform = %s' % _base(rot, rotz, cx, cy, cz, roty), '',
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
              '[node name="Bagno" parent="." instance=ExtResource("19_bagno")]', '',
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

    def gruppo_luce(nome, trasf, risorsa, spenta, luce, bagliore, pezzi,
                    tipo="OmniLight3D", rimbalzo=None):
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
        fuori += ['', '[node name="L" type="%s" parent="%s"]' % (tipo, acceso)] + luce + ['']
        if rimbalzo:
            fuori += ['[node name="Rimbalzo" type="OmniLight3D" parent="%s"]' % acceso] + rimbalzo + ['']
        fuori += ['[node name="Bagliore" type="MeshInstance3D" parent="%s"]' % acceso] + bagliore + ['']
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
             # ZERO: un intonaco non ha un riflesso speculare, e quel poco che
             # restava faceva sui muri puntini bianchi netti - piccoli, tondi, e
             # nel posto sbagliato per essere qualcosa.
             'light_specular = 0.0',
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
             'shadow_enabled = true',
             # E SONO OMBRE DI PENOMBRA, NON LAME. Una plafoniera e' un rettangolo
             # di plastica opalina largo mezzo metro, non un punto: le sue ombre
             # sfumano nel giro di qualche centimetro. Con una sorgente puntiforme
             # il bordo di un lavabo proiettava dentro il proprio catino una striscia
             # NERA a spigolo vivo, e da mezzo metro non si leggeva come un'ombra -
             # si leggeva come un pezzo mancante del modello. `light_size` da' alla
             # lampada la sua dimensione vera e l'ombra torna a essere un'ombra.
             # `shadow_blur` NON SI RIPETE QUI, e per un po' c'era. Piu' su, con
             # tre righe di motivo, sta gia' `shadow_blur = 1.2`, con scritto che
             # oltre quella soglia l'ombra RIENTRA e su un muro di venti
             # centimetri la luce ricomincia a passare dall'altra parte. Poi e'
             # stato aggiunto un secondo `shadow_blur = 1.6` in fondo alla stessa
             # lista, per ammorbidire l'ombra nel catino del lavabo - e in un
             # .tscn, fra due righe uguali dentro lo stesso nodo, VINCE L'ULTIMA.
             # Il valore in vigore era quello che il commento di sopra vieta, e il
             # commento restava li' a dire il contrario. Adesso lo dice anche
             # `verifica_doppioni()`.
             'light_size = 0.35'],
            ['transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -0.002, 0)',
             'mesh = SubResource("mesh_diff")',
             'material_override = SubResource("mat_diff")'],
            ["Lamiera", "Neon"],
            # LA LAMPADA DI RIMBALZO NON C'E' PIU', E NON SI PUO' RIMETTERE.
            # Era una seconda luce nello stesso punto, debole e SENZA OMBRE, per far
            # si' che quello che sta in ombra non fosse nero assoluto: la colonna
            # sotto il catino del lavabo passava da 63 a 92 su 255, e si vedeva.
            #
            # Accanto le stava scritto "portata corta, la caduta a 1,6 la fa morire
            # prima del muro". Misurata, non moriva affatto: spegnendo tutte le
            # lampade tranne quella del bagno, il magazzino di la' dal muro andava
            # da 0,06 a 24,15 di media. Una luce senza ombre attraversa venti
            # centimetri di muro come se non ci fossero, e la stanza accanto si
            # illuminava da sola.
            #
            # E NON E' UN NUMERO DA CORREGGERE, e' una cosa impossibile: la lampada
            # sta a 2,42 dal pavimento e a 1,40-1,65 dai muri della sua stanza. Una
            # portata che arrivi al pavimento arriva ai muri PRIMA. Non esiste il
            # valore giusto - esiste solo la scelta fra una stanza con le ombre nere
            # e un edificio con i muri trasparenti.
            #
            # Il rimedio vero e' la luce indiretta calcolata (VoxelGI), che e' una
            # decisione sull'atmosfera di tutto il gioco e non su una lampada.
            #
            # E L'AMBIENTE NON E' UN RIPIEGO: PROVATO E RIMESSO COM'ERA. Alzarlo da
            # 0,035 a 0,11 sembrava il rimedio a portata di mano, e i numeri dicono
            # che e' uno scambio alla pari nel verso sbagliato: la colonna del
            # lavabo sale di 3,5 livelli su 255, e la sala divulgazione al buio sale
            # esattamente di 3,5. La luce ambientale non distingue fra un'ombra
            # dentro una stanza illuminata e una stanza spenta - schiarisce tutte e
            # due allo stesso modo, e la seconda e' quella che deve restare nera.
            # Su una parete grande e piatta tre livelli di azzurro uniforme si
            # vedono benissimo: il nero diventa latte.
            # -- com'era, per memoria:
            # una seconda luce nello stesso punto, debole e
            # SENZA OMBRE. Non serve a illuminare di piu', serve a far si' che quello
            # che sta in ombra non sia NERO ASSOLUTO. In una stanza vera la luce
            # rimbalza sulle pareti e l'ombra sotto il bordo di un lavabo resta
            # grigio chiara; qui l'ambiente notturno vale 0,035 e ogni ombra diventa
            # un buco. Nel catino del lavabo si vedeva una striscia nera a spigolo
            # vivo che sembrava un pezzo di modello mancante - e non lo era:
            # illuminandola con una lampada in mano spariva.
            #
            # PORTATA CORTA, cinque metri contro undici. Senza ombre questa luce
            # attraversa i muri, e a undici metri avrebbe schiarito mezzo edificio;
            # a cinque, e a un sesto dell'energia, resta nella stanza.
            )

    for (ln, ax, az, anx, anz, aq) in punti_applique():
        nodo_luce[ln] = "Luce_%s" % ln
        # il modello nasce addossato a x=0 e sporge verso +X: qui si gira in modo
        # che il suo +X locale coincida con la normale del muro.
        #
        # IL SEGNO DI anz E' POSITIVO, e il meno che c'era prima ha causato tre
        # giri di diagnosi sbagliate. In un .tscn i dodici numeri di Transform3D
        # sono le RIGHE della base, non le colonne: la colonna X - cioe' l'asse
        # che il modello segue - viene fuori (ca, 0, sa), non (ca, 0, -ca).
        # Con il meno, ogni apparecchio su un muro orientato lungo Z guardava
        # dalla parte opposta alla sua normale: le due applique esterne finivano
        # DENTRO l'edificio (i due puntini bianchi in sala, e la loro luce che
        # non si capiva da dove venisse) e la rossa della cupola finiva FUORI,
        # sulla facciata nord - che e' il "passa attraverso il muro" che ho
        # inseguito con i bias per mezza giornata. Non passava: era gia' fuori.
        # Lo controlla verifica_orientamenti(), che rilegge il .tscn scritto.
        ca, sa = anx, anz
        fuori = ln in SEMPRE_ACCESE
        righe += gruppo_luce(
            ln,
            'Transform3D(%.0f, 0, %.0f, 0, 1, 0, %.0f, 0, %.0f, %.2f, %.3f, %.2f)'
            % (ca, -sa, sa, ca, ax, aq, az),
            "15_esterna" if fuori else "13_applique", ln in PARTE_SPENTA,
            # LE DUE DI FUORI SONO LEGGERISSIME. Un decimo della rossa e meno di un
            # decimo di una plafoniera: davanti alla porta di un osservatorio si
            # mette la luce che serve a non inciampare sui gradini, e nemmeno un
            # lumen di piu' - chi esce ha gli occhi fatti al buio, e rifarli costa
            # venti minuti. E' la stessa ragione del rosso in cupola.
            (# UN PROIETTORE, NON UNA LAMPADINA NUDA. Una omni davanti a una
             # facciata illumina anche all'indietro e di fianco, e di fianco ci
             # sono i vani: la sua luce entrava dalla porta e dalla finestra e
             # dentro erano due macchie bianche di cui non si vedeva la sorgente.
             # Spostarle sul pieno non basta - una sorgente puntiforme raggiunge
             # il vano lo stesso. Una vera plafoniera da esterno ha la calotta che
             # la scherma, e in Godot quella calotta si chiama SpotLight3D.
             #
             # La base: -Z locale e' dove il faro guarda, e qui deve guardare in
             # fuori e cinquanta gradi in giu' - il cono lava la facciata sotto la
             # lampada e i gradini, e non tocca ne' il muro dietro ne' i vani di
             # fianco. X locale del nodo padre e' gia' la normale del muro.
             ['transform = Transform3D(0, 0, 1, 0.766, 0.643, 0, -0.643, 0.766, 0, 0.22, -0.10, 0)',
              # 0,30: e' il valore che Federico aveva approvato. Prima non si
              # vedeva perche' era una omni sparsa su mezzo prato; concentrata in
              # un cono trenta centesimi bastano e avanzano.
              'light_energy = 0.30', 'light_color = Color(0.94, 0.96, 1, 1)',
              'spot_range = 6.0', 'spot_attenuation = 1.3',
              'spot_angle = 58.0', 'spot_angle_attenuation = 1.4',
              'light_specular = 0.05',
              # bias piccolo: la lampada sta a venti centimetri da un muro spesso
              # venti, e il default (1.0) sposterebbe il campione d'ombra oltre il
              # muro - cioe' dentro casa.
              'shadow_normal_bias = 0.02', 'shadow_bias = 0.01',
              'shadow_enabled = true'] if fuori else
             # CINQUANTA CENTIMETRI DAL MURO, NON TRENTA, e insieme meno energia.
              # Il nucleo bianco non veniva dalla potenza ma dalla DISTANZA:
              # l'irraggiamento va con l'inverso del quadrato, e a trenta
              # centimetri dall'intonaco il centro dell'alone riceveva
              # cinquanta volte quello che riceveva un metro piu' in la'. Tre
              # canali oltre l'unita' fanno bianco, ed era bianco. Allontanata e
              # smorzata il picco cala di quattro volte, il campo lontano di un
              # terzo: la stanza resta rossa, il centro smette di bruciare.
              ['transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.50, 0, 0)',
              # PIU' FORTE della plafoniera, non piu' debole: il rosso e' il solo
              # modo di vedere qualcosa in cupola, e non deve essere un lumino.
              #
              # UN ROSSO CUPO, e il colore non bastava a ottenerlo. Quello che
              # slavava il rosso era il RIFLESSO SPECULARE: al centro dell'alone
              # porta tutti e tre i canali oltre l'unita', e tre canali saturi
              # fanno una macchia BIANCA in mezzo al rosso.
              #
              # ROSSO PURO: zero verde E ZERO BLU. Cinque centesimi di blu, messi
              # per avvicinarsi al rosso delle uscite di sicurezza, facevano virare
              # al viola tutto quello che la luce toccava di sfuggita.
              # CINQUE CENTESIMI DI VERDE, e servono a togliere gli anelli.
              # Un rosso puro fa variare UN canale su tre: la sfumatura ha 256
              # gradini invece di 16 milioni, e su una parete larga ogni gradino
              # e' una fascia da mezzo metro - gli anelli concentrici attorno
              # alla lampada. Con un secondo canale che varia i gradini si
              # sfalsano e il dithering ha qualcosa su cui lavorare.
              # Verde e non blu: il blu vira al viola (era gia' successo), il
              # verde a questa dose sposta la tinta di un grado verso lo
              # scarlatto e non lo si vede.
              'light_energy = 2.0', 'light_color = Color(1, 0.05, 0, 1)',
              'light_specular = 0.0',
              # ESPONENTE PIU' BASSO = NUCLEO PIU' FREDDO, campo lontano piu'
              # vivo. Con 2,2 il centro dell'alone prendeva quattro volte e mezzo
              # quello che prendeva a un metro; con 1,5 ne prende meno di tre, e
              # la stanza si illumina piu' uniformemente invece di avere un punto
              # bianco e il resto scuro. L'energia scende di conseguenza.
              'omni_range = 6.5', 'omni_attenuation = 1.5',
              # SFOCATURA BASSA. Sfocare un'ombra la fa anche RIENTRARE: il bordo si
              # allarga di qualche texel in tutte le direzioni, e su un muro di
              # venti centimetri quei texel sono abbastanza per far ricomparire
              # la luce dall'altra parte. A 0,4 il bordo resta morbido e resta dentro.
              # GLI ANELLI CONCENTRICI SONO ACNE D'OMBRA, non banding: e' lo stesso
              # difetto del tratteggio incrociato sui soffitti, e ha la stessa causa.
              # La lampada sta a mezzo metro da una superficie che poi si allontana
              # per cinque, quindi la illumina DI STRISCIO: a incidenza rasente il
              # passo dei texel della mappa d'ombra diventa enorme, la superficie si
              # fa ombra da sola a scacchi, e su una calotta quegli scacchi sono
              # anelli concentrici. Il rimedio e' lo stesso che ha funzionato sulle
              # plafoniere - alzare il normal_bias - ma qui c'e' un tetto: sopra i
              # venti centimetri del muro la luce ricomincerebbe a passare fuori.
              # 0,12 sta comodamente sotto.
              'shadow_blur = 0.4', 'shadow_normal_bias = 0.12', 'shadow_bias = 0.04',
              'shadow_enabled = true']),
            ['transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.132, 0, 0)',
             'mesh = SubResource("mesh_vetro")',
             'material_override = SubResource("%s")'
             % ("mat_vetro_est" if fuori else "mat_vetro")],
            ["Metallo", "NeonRosso" if not fuori else "Neon"],
            tipo="SpotLight3D" if fuori else "OmniLight3D")

    # IL CRT ACCESO E' UNA SORGENTE. Il fosforo verde illumina il piano della
    # consolle e la faccia di chi ci sta davanti, ed e' l'unica luce propria della
    # sala di controllo quando tutto il resto e' spento. Sta fuori dai gruppi
    # commutabili perche' non risponde a nessun interruttore: risponde al
    # computer, che e' acceso.
    #
    # Le coordinate vengono da geometria.py, dove discendono da dove
    # arredi_blender.py posa il monitor - non sono misurate a occhio sulla scena.
    righe += ['[node name="LuceMonitor" type="OmniLight3D" parent="."]',
              'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.3f, %.3f, %.3f)'
              % (LUCE_MONITOR[0], LUCE_MONITOR[1], LUCE_MONITOR[2]),
              # IL COLORE NON E' PIU' IL FOSFORO, ED E' LA CONSEGUENZA DEL VETRO VERO.
              # Fino a ieri lo schermo era un adesivo emissivo verde saturo, e questa
              # luce ne era la copia: stesso colore, (0,24 0,72 0,36). Adesso sul vetro
              # c'e' il `SubViewport` del CRT, e quello che emette e' MISURABILE -
              # misurato da seduti, con la sonda: 156 178 166 su 255. Cioe' un
              # grigio-verde pallidissimo, non un fosforo.
              #
              # Con il verde saturo addosso, la cassa beige diventava verde fluo e la
              # MASCHERA NERA attorno all'immagine usciva a 48 111 49: una cornice verde
              # luminosa attorno allo schermo, che e' il difetto al posto del pezzo.
              #
              # Normalizzato sul canale piu' alto il colore misurato e' (0,88 1,00 0,93),
              # che e' - a due centesimi - il `tint` dichiarato in crt/shaders/crt.gdshader:
              # il vetro del tubo. I due numeri si sono incontrati da soli, ed e' il segno
              # che la luce adesso descrive la stessa cosa che si vede.
              #
              # 0,14 E NON 0,45, e il numero e' stato SCELTO MISURANDO, non a occhio -
              # a occhio una cassa beige illuminata e una bruciata sono tutte e due
              # "chiara". Tre passate della sonda, guardando la maschera nera (che deve
              # restare la cornice dell'immagine) e la cassa:
              #     energia   maschera        cassa
              #       0,00    38 31 16    189 144 68   (il fondo: solo la plafoniera)
              #       0,14    77 90 77    224 214 168
              #       0,26   103 123 112  236 233 201  (cassa bruciata, cornice sparita)
              # A 0,26 la maschera esce a 123 contro i 178 dello schermo: 1,4 a 1, e a
              # quel punto non e' piu' una cornice. A 0,14 il rapporto e' 2 a 1 e la
              # cornice si legge. Un colore quasi bianco ha luminanza 0,97 contro 0,59
              # del verde saturo: a parita' di energia illumina una volta e mezzo tanto,
              # ed e' per questo che il numero vecchio non poteva restare.
              #
              # QUANDO LE FASI AVRANNO UN CONTENUTO questo numero andra' rifatto, e va
              # detto adesso: un campo grigio pieno e del testo verde su nero non
              # emettono la stessa luce. Si rimisura con tools/prova_postazione.gd.
              'light_energy = 0.14', 'light_color = Color(0.876, 1.0, 0.931, 1)',
              'light_specular = 0.10',
              'omni_range = 2.4', 'omni_attenuation = 1.6',
              'shadow_normal_bias = 0.05', 'shadow_bias = 0.02',
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
                  'shape = SubResource("s_%d")' % idx[chiave], '',
                  # LA SPIA FA LUCE, POCHISSIMA. Finora era solo un materiale
                  # emissivo: si vedeva il puntino, ma non toccava niente attorno.
                  # Una spia al neon vera un alone ce l'ha, e in una stanza spenta
                  # sette aloni arancioni grandi un palmo sono l'unica cosa che
                  # dice dove sono le pareti. Non serve a illuminare - serve a dare
                  # una scala al buio.
                  #
                  # Cinque centimetri dal muro e non due: attaccata all'intonaco
                  # l'alone e' un mezzo disco tagliato, staccata e' una macchia
                  # tonda. L'ombra e' accesa perche' senza il mezzo metro di
                  # portata passerebbe dall'altra parte del muro, ed e' esattamente
                  # il difetto che abbiamo appena finito di togliere alle esterne.
                  '[node name="Spia" type="OmniLight3D" parent="Interruttore_%s"]' % pulito,
                  'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.3f, -0.030, %.3f)'
                  % (nx * 0.05, nz * 0.05),
                  # UN DECIMO DI QUELLO CHE AVEVO MESSO, E ANCORA MENO PORTATA.
                  # A 0,33 su 0,85 m la spia era una lampada da comodino: faceva
                  # un alone grande un metro sul muro e diventava la fonte di luce
                  # principale della stanza spenta. Non deve illuminare NIENTE -
                  # deve solo non essere un puntino piatto. 0,035 su 40 cm si legge
                  # come un velo attorno alla placca, e a due metri non c'e' piu'.
                  # PERCHE' ABBASSARLA NON BASTAVA MAI, ed e' un errore mio di
                  # aritmetica ripetuto tre volte. In Godot `omni_attenuation` NON
                  # e' uno smorzamento: e' l'ESPONENTE di distanza^(-attenuation).
                  # Ogni volta che l'alzavo per "spegnere" la spia la rendevo piu'
                  # forte, e in modo violento: a sette centimetri dal muro
                  # 0,07^(-3,5) vale undicimila, contro i duecento di un normale
                  # inverso del quadrato. Energia mille volte piu' bassa per
                  # undicimila di guadagno fa una lampada, ed e' quello che si
                  # vedeva.
                  # Con esponente 1 il guadagno a sette centimetri e' quattordici:
                  # 0,008 per quattordici fa un decimo di una parete illuminata
                  # normalmente, cioe' un velo.
                  'light_energy = 0.008', 'light_color = Color(1, 0.44, 0.12, 1)',
                  'light_specular = 0.0',
                  'omni_range = 0.35', 'omni_attenuation = 1.0',
                  # NIENTE OMBRA, e non e' una rinuncia: con venti centimetri di
                  # portata la spia non arriva nemmeno alla faccia opposta del muro
                  # (che ne e' spessa venti, e la lampada ne sta sette al di qua),
                  # quindi non c'e' niente da occludere. In piu' l'atlante delle
                  # ombre e' UNO E SI DIVIDE: otto spie con l'ombra accesa
                  # rimpicciolivano il riquadro di TUTTE le altre lampade, e la
                  # luce rossa della cupola ha ricominciato a uscire sulla facciata.
                  'shadow_enabled = false', '']

    # --- le porte: un nodo per anta, con l'origine SUL CARDINE ---------------
    for a in ante_porte():
        dx, _, dz = a["direzione"]
        nx, _, nz = a["normale"]
        px, _, pz = a["perno"]
        L, HA, T = a["larghezza"], a["altezza"], a["spessore"]
        # LO STESSO SEGNO SBAGLIATO DELLE APPLIQUE, e qui ne pagava una porta
        # sola: quella fra corridoio e divulgazione, l'unica su un muro che corre
        # lungo Z. Dichiarata con direzione (0,0,-1), nel .tscn il suo asse
        # veniva (0,0,+1) - l'anta partiva dal cardine giusto e si allungava
        # dalla parte opposta, cioe' dentro il muro. Sulle porte orizzontali dz
        # e' zero e il segno non si vedeva: la meta' che funziona nasconde la
        # meta' rotta, ed e' la terza volta in questo progetto.
        rot = _m.atan2(dz, dx)
        # IL VERSO NON VA INVERTITO, e averlo fatto ha aperto quattro porte dalla
        # parte sbagliata. Correggendo la base avevo invertito anche questo per
        # coerenza, ma la base cambiava SOLO per la porta su muro verticale: per
        # tutte le altre dz vale zero e la matrice era gia' quella giusta. Il
        # risultato e' stato ribaltare cucina, bagno, sala di controllo e ingresso
        # per sistemare l'unica che era rotta.
        #
        # Da dove viene il segno. Ruotando l'anta di +alfa attorno al suo Y, la
        # punta va da +X verso -Z locale; con la base corretta -Z vale
        # (dz, 0, -dx), quindi si apre verso la normale quando il prodotto scalare
        # di quella con la normale e' positivo - ed e' esattamente dz*nx - dx*nz.
        verso = 1 if (dz * nx - dx * nz) > 0 else -1
        nome = "Porta_" + a["nome"].replace(" -> ", "_a_").replace(" ", "_")
        c, s_ = _m.cos(rot), _m.sin(rot)
        righe += ['[node name="%s" type="StaticBody3D" parent="."]' % nome,
                  'transform = Transform3D(%.4f, 0, %.4f, 0, 1, 0, %.4f, 0, %.4f, %.3f, 0.000, %.3f)'
                  % (c, -s_, s_, c, px, pz),
                  'script = ExtResource("3_door")',
                  'apertura_gradi = 90.0',
                  'verso = %d' % verso,
                  'prompt_text = "Apri"', '',
                  ]
        # il lato interno dell'anta sta lungo +Z locale quando verso vale +1
        # IL NUMERO E' L'INDICE, non la distanza dal cardine. Con il nome ricavato
        # da `lungo` i dieci pezzi della griglia e delle nervature - tutti in
        # mezzeria - si chiamavano tutti "Lamiera37", e un .tscn con nodi omonimi
        # sotto lo stesso genitore non e' un file valido.
        materia = {"Anta": "mat_metallo" if a.get("metallo") else "mat_anta",
                   "Lamiera": "mat_metallo", "Maniglia": "mat_metallo",
                   "Maniglione": "mat_tele"}
        if a["nome"] in ANTE_DAL_MODELLO:
            # IL BATTENTE ARRIVA GIA' NEL SISTEMA DEL CARDINE: il suo modellatore lo
            # posa con l'origine sul perno, X verso il bordo libero, Y l'altezza -
            # cioe' la stessa convenzione di `pezzi_anta`. Quindi si istanzia senza
            # trasformazione, e il nodo Door non sa nemmeno che questa e' diversa
            # dalle altre.
            righe += ['[node name="Mesh" parent="%s" instance=ExtResource("%s")]'
                      % (nome, ANTE_DAL_MODELLO[a["nome"]]), '']
            righe += ['[node name="Col" type="CollisionShape3D" parent="%s"]' % nome,
                      'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.3f, %.3f, 0)' % (L / 2, HA / 2),
                      'shape = SubResource("s_%d")' % idx[(round(L, 3), round(HA, 3), round(T, 3))], '']
            continue
        for k, (lungo, alto, lato, sx, sy, sz, etichetta) in enumerate(pezzi_anta(a)):
            chiave = (round(sx, 3), round(sy, 3), round(sz, 3))
            suffisso = "Mesh" if etichetta == "Anta" else "%s%d" % (etichetta, k)
            righe += ['[node name="%s" type="MeshInstance3D" parent="%s"]' % (suffisso, nome),
                      'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.3f, %.3f, %.3f)'
                      % (lungo, alto, -lato * verso),
                      'mesh = SubResource("m_%d")' % idx[chiave],
                      'material_override = SubResource("%s")'
                      % materia.get(etichetta, "mat_tele"), '']
        righe += ['[node name="Col" type="CollisionShape3D" parent="%s"]' % nome,
                  'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.3f, %.3f, 0)' % (L / 2, HA / 2),
                  'shape = SubResource("s_%d")' % idx[(round(L, 3), round(HA, 3), round(T, 3))], '']

    # --- le ante dei mobili: stesso nodo `Door`, quota diversa ---------------
    #
    # NON UN SECONDO TIPO DI ANTA. Girano su un cardine, si aprono guardandole, non
    # passano dentro chi le apre: sono i bisogni di una porta, e `door.gd` li
    # risolve gia' tutti - compreso il pezzo difficile, scostare chi ha davanti un
    # po' per fotogramma invece di sparargli mezzo metro in uno. Un `CabinetDoor`
    # scritto a parte avrebbe rifatto quel pezzo peggio, e il banco delle porte non
    # lo avrebbe nemmeno visto.
    #
    # L'UNICA DIFFERENZA VERA E' LA QUOTA: un pensile appeso comincia a un metro e
    # quarantacinque, e quella entra nell'origine del nodo invece che nelle mesh -
    # cosi' le coordinate dei pezzi restano quelle dell'anta e non della stanza.
    materia_anta = {
        "specchio": {"Anta": "mat_teche", "Vetro": "mat_specchio",
                     "Maniglia": "mat_metallo"},
        "lamiera": {"Anta": "mat_armadietto", "Feritoia": "mat_feritoia",
                    "Maniglia": "mat_metallo"},
    }
    for a in ante_mobili():
        dx, _, dz = a["direzione"]
        nx, _, nz = a["normale"]
        px, py, pz = a["perno"]
        L, HA, T = a["larghezza"], a["altezza"], a["spessore"]
        rot = _m.atan2(dz, dx)
        verso = 1 if (dz * nx - dx * nz) > 0 else -1
        nome = "Anta_" + a["nome"].replace(" ", "_")
        c, s_ = _m.cos(rot), _m.sin(rot)
        righe += ['[node name="%s" type="StaticBody3D" parent="."]' % nome,
                  'transform = Transform3D(%.4f, 0, %.4f, 0, 1, 0, %.4f, 0, %.4f, %.3f, %.3f, %.3f)'
                  % (c, -s_, s_, c, px, py, pz),
                  'script = ExtResource("3_door")',
                  'apertura_gradi = %.1f' % a["apertura"],
                  'verso = %d' % verso,
                  # PIU' LENTA DI UNA PORTA, ed e' il gesto: una porta la si spinge e
                  # va, un'anta di mobile la si accompagna con la mano fino in fondo.
                  'durata = 0.40',
                  'prompt_text = "Apri"', '']
        quali = materia_anta[a["tipo"]]
        for k, (lungo, alto, lato, sx, sy, sz, etichetta) in enumerate(pezzi_anta_mobile(a)):
            chiave = (round(sx, 3), round(sy, 3), round(sz, 3))
            suffisso = "Mesh" if k == 0 else "%s%d" % (etichetta, k)
            righe += ['[node name="%s" type="MeshInstance3D" parent="%s"]' % (suffisso, nome),
                      'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.3f, %.3f, %.3f)'
                      % (lungo, alto, -lato * verso),
                      'mesh = SubResource("m_%d")' % idx[chiave],
                      'material_override = SubResource("%s")'
                      % quali.get(etichetta, "mat_metallo"), '']
        righe += ['[node name="Col" type="CollisionShape3D" parent="%s"]' % nome,
                  'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.3f, %.3f, 0)' % (L / 2, HA / 2),
                  'shape = SubResource("s_%d")' % idx[(round(L, 3), round(HA, 3), round(T, 3))], '']

    # --- il monitor: interagibile, con dentro il vetro vivo -------------------
    # Il nodo sta al CENTRO della cassa, cosi' la collisione non ha bisogno di uno
    # scostamento e chi legge la scena vede subito dov'e' il tubo.
    _cx, _cy, _cz = CASSA_MONITOR[:3]
    # IL VETRO GUARDA VERSO +X, cioe' verso chi siede: la rotazione di 90 gradi
    # attorno alla verticale porta il +Z del quad (la sua normale) su +X. La stessa
    # rotazione serve DUE volte, e per questo sta sul padre e non sul quad: gira
    # anche il `Seat`, che quindi si sposta AVANTI al vetro invece che di fianco, e
    # fa guardare a -X chi si siede.
    _vx = VETRO_MONITOR[0] + 0.001    # un millimetro, il gioco minimo contro lo z-fighting
    # Il beccheggio del sedile NON si dichiara: si calcola da quanto sta avanti e
    # quanto sta sopra. Un marcatore che punta altrove che al proprio vetro e' il
    # difetto che `crt/desk_camera.gd` racconta per esteso - modulo giusto, segno
    # sbagliato - e l'unico modo di non rifarlo e' non scrivere l'angolo a mano.
    _avanti, _sopra = SEDILE_MONITOR
    _t = -_m.atan2(_sopra, _avanti)
    _co, _si = _m.cos(_t), _m.sin(_t)
    righe += ['[node name="Monitor" type="StaticBody3D" parent="."]',
              'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.3f, %.3f, %.3f)'
              % (_cx, _cy, _cz),
              'script = ExtResource("25_crt")',
              'prompt_text = "Usa il monitor"', '',
              '[node name="Col" type="CollisionShape3D" parent="Monitor"]',
              'shape = SubResource("s_monitor")', '',
              '[node name="CrtScreen" parent="Monitor" instance=ExtResource("26_vetro")]',
              # `unique_name_in_owner` perche' `crt_monitor.gd` cerca `%CrtScreen`.
              # Qui il proprietario e' la radice del blockout e non una sotto-scena:
              # provato, il nome unico si risolve lo stesso da un figlio della radice.
              'unique_name_in_owner = true',
              'transform = Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, %.3f, %.3f, %.3f)'
              % (_vx - _cx, VETRO_MONITOR[1] - _cy, VETRO_MONITOR[2] - _cz), '',
              # L'immagine e' 4:3 e il vetro no: il quad della sotto-scena e' fatto
              # per un altro tubo, e qui va rimisurato sul nostro.
              '[node name="ScreenMesh" parent="Monitor/CrtScreen" index="1"]',
              'mesh = SubResource("q_monitor")', '',
              '[node name="Seat" parent="Monitor/CrtScreen" index="2"]',
              'transform = Transform3D(1, 0, 0, 0, %.5f, %.5f, 0, %.5f, %.5f, 0, %.3f, %.3f)'
              % (_co, -_si, _si, _co, _sopra, _avanti), '']

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
    for (cx, cy, cz, sx, sy, sz, nome, rot, rotz, *_r) in blocchi:
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


def verifica_angoli():
    """Dove due muri finiscono nello stesso punto, l'angolo dev'essere pieno.

    IL DIFETTO CHE L'HA FATTO SCRIVERE. Un muro va da asse ad asse e ha spessore SP
    centrato sull'asse: nell'angolo fra due muri che finiscono entrambi li', il
    quadrato di SP/2 per SP/2 dalla parte esterna non lo copre nessuno dei due.
    Restava un intaglio di dieci centimetri alto quanto il muro, in otto angoli su
    ventiquattro incroci - tre dentro e cinque sulla facciata.

    Nessuno degli altri controlli lo vedeva, e non e' un caso: `verifica_fessure`
    cerca l'aria fra il muro e cio' che gli sta SOPRA, `verifica_raccordi` gli
    scalini fra pavimenti, `verifica_ingombri` cio' che sborda. Questo e' un pezzo
    di spigolo che manca, e da dentro non si legge come un buco - ci si vede
    attraverso solo di sguincio - ma come uno scalino nell'angolo. Che e'
    esattamente come mi e' stato descritto: "molti muri non fanno un angolo a 90
    ma quasi un gradino".

    Si guardano i quattro quadranti attorno a ogni incrocio, e si segnala quello
    vuoto che ha pieni tutti e due i vicini: quello e' un angolo, non una fine.
    """
    pieni = [(b[0] - b[3] / 2.0, b[2] - b[5] / 2.0, b[0] + b[3] / 2.0, b[2] + b[5] / 2.0)
             for b in blocchi if b[6].startswith("M") and not b[6].startswith("Mont")]

    def coperto(px, pz):
        return any(x0 - 0.001 <= px <= x1 + 0.001 and z0 - 0.001 <= pz <= z1 + 0.001
                   for (x0, z0, x1, z1) in pieni)

    incroci = {}
    for (x0, z0, x1, z1) in MURI:
        for capo in ((round(x0, 3), round(z0, 3)), (round(x1, 3), round(z1, 3))):
            incroci[capo] = incroci.get(capo, 0) + 1
    problemi = []
    for (px, pz), quanti in sorted(incroci.items()):
        if quanti < 2:
            continue
        for sx in (-1, 1):
            for sz in (-1, 1):
                cx, cz = px + sx * SP / 4, pz + sz * SP / 4
                if coperto(cx, cz):
                    continue
                if coperto(px - sx * SP / 4, cz) and coperto(cx, pz - sz * SP / 4):
                    problemi.append("  ANGOLO INTAGLIATO in (%.2f, %.2f): manca il quadrante"
                                    " %s%s, e l'angolo legge come uno scalino"
                                    % (px, pz, "+x" if sx > 0 else "-x",
                                       "+z" if sz > 0 else "-z"))
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
def verifica_orientamenti(testo):
    """Ogni nodo guarda dove ha dichiarato di guardare.

    Il controllo che mancava, e che sarebbe costato mezza giornata di meno. In un
    .tscn i dodici numeri di Transform3D sono le RIGHE della base: la colonna X -
    l'asse che il modello segue - e' (r0[0], r1[0], r2[0]), non la prima terna.
    Averlo letto per colonne ha montato le applique al contrario, e il difetto non
    si vedeva come "montata al contrario" ma come luce che attraversa i muri: si
    inseguono i bias delle ombre per ore mentre la lampada e' semplicemente
    dall'altra parte.
    """
    problemi = []
    atteso = {"Luce_%s" % a[0]: (a[3], a[4]) for a in punti_applique()}
    for a in ante_porte():
        nome = "Porta_" + a["nome"].replace(" -> ", "_a_").replace(" ", "_")
        atteso[nome] = (a["direzione"][0], a["direzione"][2])
    for nome, (ax, az) in atteso.items():
        motivo = (r'\[node name="' + _re.escape(nome) + r'" type="[^"]+" parent="\."\]'
                  + r'\s+transform = Transform3D\(([^)]*)\)')
        m = _re.search(motivo, testo)
        if m is None:
            problemi.append("  NODO SENZA MATRICE       %s" % nome)
            continue
        v = [float(x) for x in m.group(1).split(",")]
        gx, gz = v[0], v[6]          # colonna X: riga0[0] e riga2[0]
        if abs(gx - ax) > 0.01 or abs(gz - az) > 0.01:
            problemi.append("  MONTATO AL CONTRARIO     %s guarda (%.0f, %.0f), "
                            "dichiarato (%.0f, %.0f)" % (nome, gx, gz, ax, az))
    # E LE PORTE DEVONO APRIRSI DOVE E' SCRITTO. Il controllo sopra guarda come
    # sono orientate, non da che parte sbattono: sono due sbagli diversi, e il
    # secondo l'ho fatto subito dopo aver corretto il primo. Qui si simula
    # l'apertura vera - si gira la punta dell'anta di apertura_gradi * verso
    # attorno all'asse Y del nodo - e si controlla che finisca dalla parte della
    # normale dichiarata. E' l'unico modo di accorgersene senza aprire il gioco.
    for a in ante_porte():
        nome = "Porta_" + a["nome"].replace(" -> ", "_a_").replace(" ", "_")
        fine = chr(10) + chr(10)          # il blocco del nodo finisce a riga vuota
        m = _re.search(r'\[node name="' + _re.escape(nome) + r'"[^\]]*\](.*?)' + fine,
                       testo, _re.S)
        if m is None:
            continue
        blocco = m.group(1)
        verso = float(_re.search(r'verso = (-?\d+)', blocco).group(1))
        gradi = float(_re.search(r'apertura_gradi = ([\d.]+)', blocco).group(1))
        v = [float(x) for x in _re.search(r'Transform3D\(([^)]*)\)', blocco).group(1).split(",")]
        asse_x, asse_z = (v[0], v[6]), (v[2], v[8])       # colonne X e Z della base
        alfa = _m.radians(gradi * verso)
        # ruotando di +alfa attorno a Y la punta va da +X verso -Z locale
        px = _m.cos(alfa) * asse_x[0] - _m.sin(alfa) * asse_z[0]
        pz = _m.cos(alfa) * asse_x[1] - _m.sin(alfa) * asse_z[1]
        nx, _, nz = a["normale"]
        if px * nx + pz * nz <= 0.0:
            problemi.append("  APRE DALLA PARTE SBAGLIATA  %s: aprendo la punta va "
                            "(%+.2f, %+.2f), la normale e' (%+.0f, %+.0f)"
                            % (nome, px, pz, nx, nz))
    return problemi


# Quale script scrive quale modello. Serve solo a `verifica_freschezza`, e sta qui
# perche' e' l'unico posto che deve saperlo: chi aggiunge una stanza aggiunge una riga.
SCRIVONO = {
    "osservatorio_blender.py": "osservatorio.glb",
    "telescopio_blender.py": "telescopio.glb",
    "cupola_blender.py": "cupola.glb",
    "arredi_blender.py": "controllo_pc.glb",
    "cucina_blender.py": "cucina.glb",
    "bagno_blender.py": "bagno.glb",
    "divulgazione_blender.py": "divulgazione.glb",
    "impianti_blender.py": "impianti.glb",
    "porta_magazzino_blender.py": "porta_magazzino.glb",
}


# I materiali la cui ripetizione NON deve valere la misura del quadro, col motivo.
# Una deroga senza motivo e' una svista che si e' fatta regola.
RIGHELLO_A_PARTE = {
    "LibroRosso": "un dorso di libro e' largo cinque centimetri: alla misura vera "
                  "della tela non ci starebbe dentro un filo di trama",
    "LibroBlu": "come LibroRosso", "LibroVerde": "come LibroRosso",
    "LibroCrema": "come LibroRosso",
}


def verifica_luci_cieche(testo, portata_max=0.60, energia_max=0.05):
    """Ogni lampada dentro l'edificio proietta ombra. Senza, attraversa i muri.

    NON E' UNA REGOLA DI GUSTO, E' GEOMETRIA. Una luce che non proietta ombra
    illumina tutto quello che sta nel suo raggio, muri compresi: se il raggio arriva
    al pavimento della sua stanza - e deve, altrimenti non serve a niente - arriva
    anche di la' dal muro, perche' il muro e' PIU' VICINO del pavimento. Una
    plafoniera sta a 2,42 dal pavimento e a 1,40 dal muro piu' vicino.

    Il caso che l'ha fatta scrivere: le plafoniere avevano una seconda luce senza
    ombre, per schiarire le ombre nere. Accanto le stava scritto che la sua caduta
    "la fa morire prima del muro". Misurato spegnendo tutte le lampade tranne quella
    del bagno, il magazzino di la' dal muro passava da 0,06 a 24,15 di media - cioe'
    si illuminava da solo, ed e' esattamente quello che si vedeva giocando.

    ATTENZIONE AL DEFAULT: in Godot `shadow_enabled` vale FALSO se non e' scritto.
    Una luce senza quella riga e' una luce cieca, e non lo dice nessuno.

    NON SI PASSA PER NOME. Le spie arancioni dentro gli interruttori sono cieche e
    vanno bene cosi': 0,008 di energia su 35 cm di portata. Attraversano il muro
    anche loro, e non arriva niente dall'altra parte. Quello che le assolve e' il
    prodotto dei loro numeri, non il loro nome - e cosi' la prossima luce cieca
    verra' giudicata per quello che fa, non per come si chiama.
    """
    FUORI = ("esterno_porta", "esterno_sud")   # illuminano il piazzale: nessun muro
    problemi = []
    blocco = tipo = ""
    ombra, portata, energia = False, 0.0, 0.0

    def valore(riga):
        try:
            return float(riga.split(" = ")[1])
        except (IndexError, ValueError):
            return 0.0

    def chiudi():
        if not tipo.endswith("Light3D") or ombra:
            return
        if any(f in blocco for f in FUORI):
            return
        if portata <= portata_max or energia <= energia_max:
            return
        problemi.append("  LUCE CIECA               %s non proietta ombra e arriva a "
                        "%.1f m con %.2f di energia: attraversa i muri"
                        % (blocco, portata, energia))
    for riga in testo.split(chr(10)):
        if riga.startswith("["):
            chiudi()
            blocco, ombra, portata, energia = riga.strip(), False, 0.0, 0.0
            tipo = riga.split('type="')[1].split('"')[0] if 'type="' in riga else ""
            continue
        if riga.strip() == "shadow_enabled = true":
            ombra = True
        elif riga.startswith("omni_range = ") or riga.startswith("spot_range = "):
            portata = valore(riga)
        elif riga.startswith("light_energy = "):
            energia = valore(riga)
    chiudi()
    return problemi


def verifica_doppioni(testo):
    """Nessun nodo scrive due volte la stessa proprieta'.

    IN UN .tscn, FRA DUE RIGHE UGUALI DENTRO LO STESSO NODO, VINCE L'ULTIMA - in
    silenzio. E' un modo di sbagliare tipico di un file GENERATO: le proprieta' di
    una lampada qui vengono da una lista costruita a pezzi, e aggiungere una riga in
    fondo non somiglia affatto a cancellarne una in mezzo, anche se e' quello che fa.

    Il caso che l'ha fatta scrivere: `shadow_blur` compariva due volte su tutte e
    nove le plafoniere. In cima alla lista c'era 1,2 con tre righe di motivo -
    "oltre questa soglia l'ombra rientra e su un muro di venti centimetri la luce
    ricomincia a passare dall'altra parte" - e in fondo un 1,6 aggiunto dopo per
    ammorbidire l'ombra nel catino del lavabo. In vigore c'era 1,6, cioe' proprio
    il valore che il commento di sopra vieta, e il commento restava li' a dire il
    contrario a chiunque lo leggesse.

    Si controlla il testo GENERATO e non il generatore: le due righe possono nascere
    a cinquanta righe di distanza, da due rami diversi, e comunque finire nello
    stesso nodo. Quello che conta e' cosa arriva a Godot.
    """
    problemi, blocco, visti = [], "", set()
    for riga in testo.split(chr(10)):
        if riga.startswith("["):
            blocco, visti = riga.strip(), set()
            continue
        if " = " not in riga or riga.startswith(" ") or riga.startswith(";"):
            continue
        p = riga.split(" = ")[0]
        if not p.replace("_", "").replace("/", "").isalnum():
            continue
        if p in visti:
            problemi.append("  PROPRIETA' DOPPIA        %s scritta due volte in %s: "
                            "vale l'ultima" % (p, blocco))
        visti.add(p)
    return problemi


def verifica_ripetizioni(tolleranza=0.12):
    """Ogni texture si ripete alla misura che la sua fonte DICHIARA.

    IL RIGHELLO DELLA STANZA. E' il difetto che in questo progetto e' gia' costato
    due giri: le piastrelle del bagno si ripetevano ogni 75 cm su una mappa da dieci
    piastrelle - sette centimetri e mezzo l'una - e sanitari misurati al centimetro
    leggevano come giocattoli. Non si giudica a occhio quanto e' grande un water: si
    contano le piastrelle che gli stanno dietro, e se il righello e' sbagliato tutto
    quello che ci si misura sopra e' sbagliato con lui.

    ambientCG la misura la PUBBLICA - Wood048 copre 80x80 cm, Wood066 quaranta - e
    `prendi_texture.py` la scrive nel FONTE.txt accanto alla cartella. Finche'
    nessuno la leggeva, il rovere della consolle si ripeteva ogni 1,10 (un terzo
    troppo grande) e quello della cucina ogni 0,80, cioe' il DOPPIO del vero.

    Chi vuole discostarsene lo puo' fare, ma lo scrive in `RIGHELLO_A_PARTE` con il
    motivo: i dorsi dei libri usano una tela da 40 cm a 6, perche' un dorso e' largo
    cinque centimetri e alla misura vera non ci starebbe dentro un filo di trama.

    Dove la fonte la misura non la dichiara - l'intonaco, il terrazzo, la lamiera -
    non c'e' niente da controllare: quella la sceglie l'occhio, e il perche' sta
    scritto accanto al numero.
    """
    qui = os.path.dirname(os.path.abspath(__file__))
    fonte = os.path.join(os.path.dirname(qui), "assets", "textures")
    sorgente = io.open(os.path.join(qui, "modellare.py"), encoding="utf-8").read()
    blocco = sorgente[sorgente.index("TEXTURE = {"):]
    blocco = blocco[:blocco.index(chr(10) + "}") + 2]
    dichiarate = ast.literal_eval(blocco[blocco.index("{"):])
    problemi = []
    for nome, (cartella, metri) in sorted(dichiarate.items()):
        via_ = os.path.join(fonte, cartella, "FONTE.txt")
        if not os.path.exists(via_):
            continue
        m = _re.search(r"Il quadro copre (\d+) x (\d+) cm",
                      io.open(via_, encoding="utf-8").read())
        if m is None:
            continue
        vero = int(m.group(1)) / 100.0
        if nome in RIGHELLO_A_PARTE:
            continue
        if abs(metri / vero - 1.0) > tolleranza:
            problemi.append(
                "  RIGHELLO SBAGLIATO      %s si ripete ogni %.2f m ma %s copre "
                "%.2f m (x%.2f)" % (nome, metri, cartella, vero, metri / vero))
    return problemi


def verifica_freschezza():
    """I .glb devono essere piu' nuovi di chi li scrive, e in gioco piu' nuovi di loro.

    TRE MODI DI GIOCARE CON UN MODELLO CHE NON ESISTE PIU', e li ho fatti tutti e tre.

    1. UN MODELLO CHE NE IMPORTA UN ALTRO va ricostruito DOPO di quello.
       osservatorio.glb incorpora cupola.glb e telescopio.glb al momento della
       costruzione: rifare la cupola e non rifare l'osservatorio lascia in gioco la
       vecchia. E' successo con lo shading liscio della calotta - ricostruita,
       reimportata, e in gioco restava sfaccettata mentre davo la colpa alle ombre.

    2. UNO SCRIPT MODIFICATO E NON RILANCIATO. Il mouse della sala di controllo e'
       stato spostato di fianco alla tastiera in arredi_blender.py, e per due
       sessioni e' rimasto dov'era: il .glb era di due ore prima della modifica.
       Ci siamo detti due volte la stessa cosa - "il mouse sta a sinistra" - e
       tutte e due le volte l'ho spostato in un file che nessuno rileggeva.

    3. UN .glb NON REIMPORTATO. Avviare il gioco non reimporta niente: usa quello
       che sta in .godot/imported, che resta quello di prima (vedi assets/LEGGIMI.txt).
       Questo e' l'unico dei tre che non si vede nemmeno guardando le date dei
       modelli, perche' i modelli sono giusti - e' la scena a leggere altro.

    Sono tre difetti identici da fuori: si guarda il gioco e si vede roba vecchia.
    Nessuno dei tre da' errore, e tutti e tre fanno perdere un pomeriggio a cercare
    la causa nel posto sbagliato.
    """
    import glob
    import hashlib
    import os
    qui = os.path.dirname(os.path.abspath(__file__))
    modelli = os.path.join(qui, "..", "assets", "models")
    importati = os.path.join(qui, "..", ".godot", "imported")
    problemi = []

    def data(*pezzi):
        via = os.path.join(*pezzi)
        return os.path.getmtime(via) if os.path.exists(via) else None

    # 1. chi incorpora chi
    for contenitore, pezzi in (("osservatorio.glb", ("cupola.glb", "telescopio.glb")),):
        fuori = data(modelli, contenitore)
        if fuori is None:
            continue
        for pezzo in pezzi:
            dentro = data(modelli, pezzo)
            if dentro is not None and dentro > fuori:
                problemi.append("  MODELLO VECCHIO          %s e' piu' nuovo di %s: "
                                "rifai %s" % (pezzo, contenitore, contenitore))

    # 2. lo script e il modello che produce - E ANCHE CIO' CHE LO SCRIPT LEGGE
    #
    # QUESTO CONTROLLO HA TACIUTO QUANDO SERVIVA, ed e' il modo peggiore in cui un
    # controllo puo' sbagliare: quello silenzioso. Le porte interne sono state
    # ristrette cambiando `geometria.py` - non i modellatori - e questo confronto
    # guardava solo la data del MODELLATORE. Osservatorio.glb e' rimasto quello di
    # sei ore prima: i vani nei muri larghi 1,30, le ante generate dalla scena
    # larghe 0,90. In gioco si vedeva una porta stretta in un buco largo, con la
    # luce che passava di fianco, e il controllo diceva che era tutto a posto.
    #
    # OGNI modellatore legge `geometria.py` e `modellare.py`: sono sorgenti dei loro
    # modelli quanto lo script stesso, e vanno guardate come tale.
    COMUNI = ("geometria.py", "modellare.py")
    for script, prodotto in SCRIVONO.items():
        fuori = data(modelli, prodotto)
        if fuori is None:
            continue
        for sorgente_nome in (script,) + COMUNI:
            sorgente = data(qui, sorgente_nome)
            if sorgente is not None and sorgente > fuori:
                problemi.append("  MODELLO VECCHIO          %s e' cambiato dopo %s: "
                                "rilancia %s" % (sorgente_nome, prodotto, script))
                break

    # 3. il modello e cio' che la scena legge davvero
    #
    # SI CONFRONTA L'MD5, NON LA DATA, perche' e' l'MD5 che guarda Godot. Ricostruire
    # un modello senza cambiare niente riscrive il file con lo stesso contenuto: la
    # data avanza, l'md5 no, e Godot giustamente non reimporta. Con il confronto sulle
    # date questo controllo gridava "da reimportare" su due modelli che erano gia'
    # esattamente quelli in gioco - e un controllo che grida quando va tutto bene si
    # impara a ignorare, che e' il modo migliore di non accorgersi di quando ha ragione.
    for prodotto in sorted(set(SCRIVONO.values())):
        via = os.path.join(modelli, prodotto)
        if not os.path.exists(via):
            continue
        firme = glob.glob(os.path.join(importati, prodotto + "-*.md5"))
        if not firme:
            problemi.append("  DA REIMPORTARE           %s non e' mai stato importato: "
                            "vedi assets/LEGGIMI.txt" % prodotto)
            continue
        with io.open(via, "rb") as f:
            adesso = hashlib.md5(f.read()).hexdigest()
        registrati = []
        for firma in firme:
            for riga in io.open(firma, encoding="utf-8"):
                if riga.startswith("source_md5="):
                    registrati.append(riga.split('"')[1])
        if adesso not in registrati:
            problemi.append("  DA REIMPORTARE           %s e' cambiato dopo l'ultimo "
                            "import: vedi assets/LEGGIMI.txt" % prodotto)
    return problemi


_pr = verifica_aperture()
if _pr:
    print("ATTENZIONE, aperture da sistemare:")
    for _p in _pr:
        print(_p)
else:
    print("aperture: tutte collocate, nessun montante sotto i 30 cm")
_tetti = [(b[0]-b[3]/2, b[2]-b[5]/2, b[0]+b[3]/2, b[2]+b[5]/2)
          for b in blocchi if b[6].startswith('TettoCup')]
_testo_scena = io.open(out, encoding="utf-8").read()
_ing = (verifica_ingombri() + verifica_raccordi() + verifica_ante()
        + verifica_trappole() + verifica_arredi() + verifica_interruttori()
        + verifica_applique() + verifica_passerella() + verifica_plafoniere()
        + verifica_ripetizioni()
        + verifica_fessure() + verifica_angoli()
        + verifica_freschezza()
        + verifica_orientamenti(_testo_scena)
        + verifica_doppioni(_testo_scena)
        + verifica_luci_cieche(_testo_scena))
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
           ('locale = "la cucina"', "il nome del locale nel prompt"),
           # C'ERA GIA' SUCCESSO: l'import di LUCE_MONITOR e' rimasto in cima al
           # file mentre il nodo che lo usava spariva in una sostituzione, e la
           # sala di controllo e' rimasta senza la sua unica luce propria senza che
           # niente si lamentasse. Un valore che conta si controlla NEL FILE.
           ('[node name="LuceMonitor" type="OmniLight3D"', "la luce del monitor"),
           ('[node name="Luce_esterno_porta"', "le applique esterne"),
           # LA POSTAZIONE, per la stessa ragione della luce qui sopra e con lo
           # stesso precedente: sono tre nodi che si tengono per mano, e due di
           # loro sono silenziosi se il terzo sparisce. Senza il copione sulla
           # radice il monitor ha il prompt e non fa niente; senza il vetro il
           # monitor si monta e mostra una scatola nera; senza il monitor nessuno
           # dei due esiste, e l'unico sintomo e' una consolle muta.
           ('script = ExtResource("24_postazione")', "il copione della postazione"),
           ('[node name="Monitor" type="StaticBody3D"', "il monitor interagibile"),
           ('instance=ExtResource("26_vetro")', "il vetro vivo del CRT")]
_mancanti = ["  MANCA NEL .tscn   %s (%s)" % (t, perche)
             for (t, perche) in _attesi if t not in _scritto]
if _mancanti:
    print("ATTENZIONE:")
    for _p in _mancanti:
        print(_p)
else:
    print("scena: ambiente notturno, tonemapping e ombre verificati NEL FILE")
