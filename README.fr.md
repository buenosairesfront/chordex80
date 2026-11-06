[English](README.md) · [Español](README.es.md) · **Français** · [Deutsch](README.de.md) · [日本語](README.ja.md) · [中文](README.zh.md) · [हिन्दी](README.hi.md)

# Chordex 80

Un instrument d'accords au polysynthé des années 80 pour
[monome norns](https://monome.org/docs/norns/). Une touche joue un accord (la
touche la plus grave enfoncée donne la fondamentale) à travers un moteur
polyphonique à trois modèles inspirés de machines classiques de la décennie,
pendant que l'écran dessine un coucher de soleil outrun.

![Chordex 80](docs/sheet.png)

**La scène est le synthétiseur :**

- **le soleil :** sa taille est le filtre (E1), le halo la résonance, les
  bandes la distorsion, le tremblement le wobble, les fantômes sur les côtés
  le chorus (fatness), et son éclat l'enveloppe qui respire avec votre jeu
- **les étoiles** sont le shimmer, **les étincelles** le craquement (plus de
  deux touches enfoncées)
- **la grille** avance au tempo de l'arpège ; chaque note est une lumière sur
  la route

## Fonctions

- **3 modèles** : D-50, CS80 et OMNI (inspirés des Roland D-50, Yamaha CS-80
  et ARP Omni), avec un choix d'attaque pour le D-50 (souffle, pluck, aucune)
- **10 accords** : maj, min, dim, aug, 7, maj7, min7, m7b5, sus2, sus4
- **arpégiateur** : up, down, up-down, up x2, down x2, random et *arpa*
  (harpe) ; le gate va de très court au vrai legato (une voix qui ne coupe
  jamais)
- **mode accord** on/off (off = notes seules) et **maintien**
- l'horloge MIDI entrante ne règle que le tempo de l'arpège, elle ne
  déclenche jamais de notes ; une même note répétée en rythme ne redéclenche
  pas l'accord
- tout est sauvegardé en quittant et revient à l'identique au chargement

<!-- u-ma:family -->
## La famille Chordex

Mêmes contrôles, moteurs différents. Essayez les autres :

| | |
|---|---|
| <a href="https://github.com/buenosairesfront/chordexfm/blob/main/README.fr.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexfm/main/docs/3_metal.png" width="200" alt="Chordex FM"></a> | **[Chordex FM](https://github.com/buenosairesfront/chordexfm/blob/main/README.fr.md)**<br>FM à 4 opérateurs, dessinée comme une fleur<br>`;install https://github.com/buenosairesfront/chordexfm` |
| <a href="https://github.com/buenosairesfront/chordexstg/blob/main/README.fr.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexstg/main/docs/2_tutti.png" width="200" alt="ChordexSTG"></a> | **[ChordexSTG](https://github.com/buenosairesfront/chordexstg/blob/main/README.fr.md)**<br>cordes d'orchestre avec le vrai mouvement d'une corde frottée<br>`;install https://github.com/buenosairesfront/chordexstg` |
| <a href="https://github.com/buenosairesfront/chordexwt/blob/main/README.fr.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexwt/main/docs/2_vocal.png" width="200" alt="Chordex WT"></a> | **[Chordex WT](https://github.com/buenosairesfront/chordexwt/blob/main/README.fr.md)**<br>wavetable : 8 banques de 8 ondes, dessinée comme une table en 3D<br>`;install https://github.com/buenosairesfront/chordexwt` |
| <a href="https://github.com/buenosairesfront/chordexchip/blob/main/README.fr.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexchip/main/docs/1_nes.png" width="200" alt="Chordex CHIP"></a> | **[Chordex CHIP](https://github.com/buenosairesfront/chordexchip/blob/main/README.fr.md)**<br>chiptune : 8 puces de console × 8 presets, dessiné comme un tracker<br>`;install https://github.com/buenosairesfront/chordexchip` |

**Plus de U-MA :** tous les instruments et outils au même endroit → [vitrine U-MA](https://github.com/buenosairesfront/U-ma/blob/main/README.fr.md)
<!-- /u-ma:family -->

## Prérequis

- norns (shield, standard ou fates)
- un clavier ou contrôleur MIDI

## Installation

Depuis maiden :

```
;install https://github.com/buenosairesfront/chordex80
```

Ensuite **redémarrez norns** (SYSTEM > RESTART) pour compiler le nouveau
moteur `Chordex80`, puis chargez **chordex80** depuis SELECT.

## Contrôles

| contrôle | action |
|---|---|
| E1 | filtre |
| E2 | choisir un paramètre |
| E3 | régler le paramètre |
| K3 + E1 | modèle : D-50 / CS80 / OMNI |
| K3 + E2 | résonance |
| K3 + E3 | type d'accord |
| K3 maintenu (sans tourner) | mode accord on/off |
| K2 (appui bref) | arpégiateur on/off |
| K2 + E1 | gate de l'arpège (max = legato) |
| K2 + E2 | motif de l'arpège |
| K2 + E3 | vitesse de l'arpège |
| K1 maintenu | maintien on/off (point plein à gauche des faders = maintenu) |

**Faders :** attaque, decay, distorsion, shimmer, wobble, fatness.

**Menu PARAMETERS :** canal MIDI (0 = tous, par défaut), diviseur d'horloge
MIDI, attaque du D-50, hall, volume, et tout ce qui précède.

## Galerie

| | |
|---|---|
| ![D-50](docs/1_d50.png) D-50 · Cmaj7 | ![CS80](docs/2_cs80.png) CS80 · Am, filtre ouvert |
| ![OMNI](docs/3_omni.png) OMNI · Dsus2, filtre fermé | ![arpège](docs/4_arp.png) arpège · Em7 |

## Crédits

Créé par [Buenos Aires Front](https://github.com/buenosairesfront) / U-MA.
Les noms des modèles renvoient aux instruments qui les ont inspirés ; ce
projet n'est pas affilié à Roland, Yamaha ou ARP. Licence MIT.
