[English](README.md) · [Español](README.es.md) · [Français](README.fr.md) · **Deutsch** · [日本語](README.ja.md) · [中文](README.zh.md) · [हिन्दी](README.hi.md)

# Chordex 80

Ein Akkordinstrument mit 80er-Polysynth für
[monome norns](https://monome.org/docs/norns/). Eine Taste spielt einen Akkord
(die tiefste gehaltene Taste bestimmt den Grundton) über eine polyphone Engine
mit drei Modellen, inspiriert von klassischen Geräten des Jahrzehnts, während
das Display einen Outrun-Sonnenuntergang zeichnet.

![Chordex 80](docs/sheet.png)

**Die Szene ist der Synthesizer:**

- **die Sonne:** Ihre Größe ist der Filter (E1), der Halo die Resonanz, die
  Streifen die Verzerrung, das Zittern der Wobble, die Geister an den Seiten
  der Chorus (Fatness), und ihr Leuchten ist die Hüllkurve, die mit deinem
  Spiel atmet
- **Sterne** sind Shimmer, **Funken** sind Knistern (mehr als zwei Tasten
  gehalten)
- **das Gitter** bewegt sich im Arpeggio-Tempo; jeder Ton ist ein Licht auf
  der Straße

## Funktionen

- **3 Modelle**: D-50, CS80 und OMNI (inspiriert von Roland D-50, Yamaha CS-80
  und ARP Omni), mit wählbarem Attack für den D-50 (Luft, Pluck, keiner)
- **10 Akkorde**: maj, min, dim, aug, 7, maj7, min7, m7b5, sus2, sus4
- **Arpeggiator**: up, down, up-down, up x2, down x2, random und *arpa*
  (Harfe); das Gate reicht von ganz kurz bis echtem Legato (eine Stimme, die
  nie abreißt)
- **Akkordmodus** an/aus (aus = Einzeltöne) und **Halten**
- Knistern einer alten Schallplatte, wenn mehr als zwei Tasten gehalten werden
- eingehende MIDI-Clock bestimmt nur das Arpeggio-Tempo und löst nie Töne aus;
  im Takt wiederholte Töne lösen den Akkord nicht erneut aus
- alles wird beim Beenden gespeichert und beim Laden identisch wiederhergestellt

Teil der Chordex-Familie, zusammen mit
[Chordex FM](https://github.com/buenosairesfront/chordexfm).

## Voraussetzungen

- norns (shield, Standard oder fates)
- ein MIDI-Keyboard oder -Controller

## Installation

In maiden:

```
;install https://github.com/buenosairesfront/chordex80
```

Danach **norns neu starten** (SYSTEM > RESTART), damit die neue Engine
`Chordex80` kompiliert wird, und **chordex80** über SELECT laden.

## Bedienung

| Bedienelement | Funktion |
|---|---|
| E1 | Filter |
| E2 | Parameter wählen |
| E3 | Parameter einstellen |
| K3 + E1 | Modell: D-50 / CS80 / OMNI |
| K3 + E2 | Resonanz |
| K3 + E3 | Akkordtyp |
| K3 halten (ohne zu drehen) | Akkordmodus an/aus |
| K2 (antippen) | Arpeggiator an/aus |
| K2 + E1 | Arpeggio-Gate (Maximum = Legato) |
| K2 + E2 | Arpeggio-Muster |
| K2 + E3 | Arpeggio-Geschwindigkeit |
| K1 halten | Halten an/aus (gefüllter Punkt links der Fader = gehalten) |

**Fader:** Attack, Decay, Verzerrung, Shimmer, Wobble, Fatness.

**Menü PARAMETERS:** MIDI-Kanal (0 = alle, Standard), MIDI-Clock-Teiler,
D-50-Attack, Hall, Lautstärke und alles oben Genannte.

## Galerie

| | |
|---|---|
| ![D-50](docs/1_d50.png) D-50 · Cmaj7 | ![CS80](docs/2_cs80.png) CS80 · Am, offener Filter |
| ![OMNI](docs/3_omni.png) OMNI · Dsus2, geschlossener Filter | ![Arpeggio](docs/4_arp.png) Arpeggio · Em7 |

## Credits

Erstellt von [Buenos Aires Front](https://github.com/buenosairesfront) / U-MA.
Die Modellnamen verweisen auf die Instrumente, die sie inspiriert haben; dieses
Projekt steht in keiner Verbindung zu Roland, Yamaha oder ARP. MIT-Lizenz.
