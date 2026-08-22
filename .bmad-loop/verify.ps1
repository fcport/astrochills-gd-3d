# Cancello di verifica per bmad-loop: eseguito dopo la review e PRIMA del commit.
# Se esce non-zero, la storia non viene committata e la run si ferma.
#
# PERCHE' STA FUORI DAL BANCO. `tests/test_bench.gd` dichiara nella propria
# intestazione di essere un banco che STAMPA, non che asserisce (NFR19), e chiude
# con `get_tree().quit()` senza argomento: esce 0 anche quando stampa una riga di
# allarme. Finche' un umano legge l'output, va bene cosi' — e' una scelta, non una
# svista. Dentro un loop non sorvegliato quel silenzio diventa il guasto, perche'
# nessuno legge piu' niente. Questo script e' il lettore automatico, e sta fuori
# apposta: il banco resta un banco, e nessuna riga di produzione cambia per
# compiacere un orchestratore.
#
# COSA NON COPRE, dichiarato invece che sottinteso: il giro del gioco si ferma a
# 600 fotogrammi, quindi vede l'avvio e i primi secondi, non l'alba — che coi
# valori del profilo arriva dopo 900 secondi reali. L'aritmetica della notte la
# copre il banco, sui numeri veri del `.tres`. Una regressione che si manifesta
# solo a meta' notte passa di qui indisturbata.

$ErrorActionPreference = 'Continue'

$root = Split-Path -Parent $PSScriptRoot
$failures = @()

# L'eseguibile sta sciolto nella radice del progetto (rilievo aperto della 1.1).
# $env:GODOT lo scavalca, per il giorno in cui la toolchain avra' una casa.
$godot = $env:GODOT
if (-not $godot) {
    $found = Get-ChildItem -Path $root -Filter 'Godot_v4.7*.exe' -File -ErrorAction SilentlyContinue |
             Select-Object -First 1
    if ($found) { $godot = $found.FullName }
}
if (-not $godot -or -not (Test-Path $godot)) {
    Write-Host "VERIFY: nessun eseguibile Godot 4.7 trovato in $root (ne' `$env:GODOT)"
    exit 2
}

function Invoke-Godot {
    param([string]$Label, [string[]]$GodotArgs)

    Write-Host "--- $Label"
    $out = & $godot @GodotArgs 2>&1 | ForEach-Object { "$_" }
    $code = $LASTEXITCODE
    $text = $out -join "`n"

    if ($code -ne 0) { $script:failures += "$Label -> uscita $code" }

    # I due canali del progetto: `push_error("[system] ...")` diventa un ERROR di
    # Godot, e un warning dell'analizzatore non deve mai arrivare a un commit.
    $noisy = $out | Where-Object { $_ -match 'ERROR|SCRIPT ERROR|WARNING|USER ERROR' }
    if ($noisy) {
        $script:failures += "$Label -> $($noisy.Count) righe di errore/warning"
        $noisy | Select-Object -First 10 | ForEach-Object { Write-Host "    $_" }
    }

    return $text
}

# 1. Il banco. Il suo verdetto e' nel testo, non nel codice d'uscita.
$bench = Invoke-Godot -Label 'banco di collaudo' -GodotArgs @(
    '--headless', '--path', $root, 'res://tests/test_bench.tscn')

# Arrivare in fondo e' parte del collaudo: un banco che muore a meta' stampa
# tutto verde fino al punto in cui e' morto.
if ($bench -notmatch '=== fine ===') {
    $failures += "banco di collaudo -> non e' arrivato a '=== fine ==='"
}

# `<-- ATTESO` marca una divergenza dal comportamento atteso; `NON CARICABILE`, una
# risorsa che il gioco userebbe e che non si apre. `<-- nota:` NON e' un guasto:
# segnala una taratura diversa dal commento, che e' spesso deliberata.
foreach ($marker in @('<-- ATTESO', 'NON CARICABILE')) {
    $hits = ($bench -split "`n") | Where-Object { $_ -like "*$marker*" }
    if ($hits) {
        $failures += "banco di collaudo -> $($hits.Count) riga/e con '$marker'"
        $hits | ForEach-Object { Write-Host "    $_" }
    }
}

# 2. Il gioco vero, avviato dal suo punto d'ingresso.
Invoke-Godot -Label 'avvio del gioco' -GodotArgs @(
    '--headless', '--path', $root, '--quit-after', '600') | Out-Null

Write-Host ""
if ($failures.Count -gt 0) {
    Write-Host "VERIFY: FALLITO"
    $failures | ForEach-Object { Write-Host "  - $_" }
    exit 1
}
Write-Host "VERIFY: pulito — banco fino in fondo, gioco senza errori ne' warning"
exit 0
