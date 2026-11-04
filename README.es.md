[English](README.md) · **Español** · [Français](README.fr.md) · [Deutsch](README.de.md) · [日本語](README.ja.md) · [中文](README.zh.md) · [हिन्दी](README.hi.md)

# Chordex 80

Instrumento de acordes con polisintetizador ochentoso para
[monome norns](https://monome.org/docs/norns/). Una tecla toca un acorde (la
tecla más grave apretada marca la raíz) a través de un motor polifónico con
tres modelos inspirados en máquinas clásicas de la década, mientras la
pantalla dibuja un atardecer outrun.

![Chordex 80](docs/sheet.png)

**La escena es el sintetizador:**

- **el sol:** su tamaño es el filtro (E1), el halo es la resonancia, las
  franjas son la distorsión, el temblor es el wobble, los fantasmas a los
  lados son el chorus (fatness) y su brillo es la envolvente, que respira con
  lo que tocás
- **estrellas** = shimmer, **chispas** = crackle (más de dos teclas apretadas)
- **la grilla** avanza con el tempo del arpegio; cada nota es una luz en la
  ruta

## Características

- **3 modelos**: D-50, CS80 y OMNI (inspirados en Roland D-50, Yamaha CS-80 y
  ARP Omni), con ataque a elección para el D-50 (aire, pluck, ninguno)
- **10 acordes**: maj, min, dim, aug, 7, maj7, min7, m7b5, sus2, sus4
- **arpegiador**: up, down, up-down, up x2, down x2, random y *arpa*; el gate
  va de cortito a legato real (una voz que no se corta)
- **modo acorde** on/off (off = una sola nota) y **retener**
- crackle de disco viejo con más de dos teclas apretadas
- el clock MIDI entrante solo marca el tempo del arpegio, nunca dispara notas;
  si el equipo repite la misma nota a tempo, no se vuelve a disparar el acorde
- todo se guarda al salir y vuelve igual al cargar

<!-- u-ma:family -->
## La familia Chordex

Mismos controles, motores distintos. Probá los otros:

| | |
|---|---|
| <a href="https://github.com/buenosairesfront/chordexfm/blob/main/README.es.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexfm/main/docs/3_metal.png" width="200" alt="Chordex FM"></a> | **[Chordex FM](https://github.com/buenosairesfront/chordexfm/blob/main/README.es.md)**<br>FM de 4 operadores, dibujado como una flor<br>`;install https://github.com/buenosairesfront/chordexfm` |
| <a href="https://github.com/buenosairesfront/chordexstg/blob/main/README.es.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexstg/main/docs/2_tutti.png" width="200" alt="ChordexSTG"></a> | **[ChordexSTG](https://github.com/buenosairesfront/chordexstg/blob/main/README.es.md)**<br>cuerdas de orquesta con el movimiento real de una cuerda frotada<br>`;install https://github.com/buenosairesfront/chordexstg` |
| <a href="https://github.com/buenosairesfront/chordexwt/blob/main/README.es.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexwt/main/docs/2_vocal.png" width="200" alt="Chordex WT"></a> | **[Chordex WT](https://github.com/buenosairesfront/chordexwt/blob/main/README.es.md)**<br>wavetable: 8 bancos de 8 ondas, dibujado como una tabla en 3D<br>`;install https://github.com/buenosairesfront/chordexwt` |
| <a href="https://github.com/buenosairesfront/chordexchip/blob/main/README.es.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexchip/main/docs/1_nes.png" width="200" alt="Chordex CHIP"></a> | **[Chordex CHIP](https://github.com/buenosairesfront/chordexchip/blob/main/README.es.md)**<br>chiptune: 8 chips de consola × 8 presets, dibujado como un tracker<br>`;install https://github.com/buenosairesfront/chordexchip` |

**Más de U-MA:** todos los instrumentos y herramientas en un solo lugar → [muestrario U-MA](https://github.com/buenosairesfront/U-ma/blob/main/README.es.md)
<!-- /u-ma:family -->

## Requisitos

- norns (shield, estándar o fates)
- un teclado o controlador MIDI

## Instalación

Desde maiden:

```
;install https://github.com/buenosairesfront/chordex80
```

Después **reiniciá la norns** (SYSTEM > RESTART) para que compile el engine
nuevo `Chordex80`, y cargá **chordex80** desde SELECT.

## Controles

| control | acción |
|---|---|
| E1 | filtro |
| E2 | elegir parámetro |
| E3 | ajustar parámetro |
| K3 + E1 | modelo: D-50 / CS80 / OMNI |
| K3 + E2 | resonancia |
| K3 + E3 | tipo de acorde |
| K3 mantenido (sin girar) | modo acorde on/off |
| K2 (toque) | arpegiador on/off |
| K2 + E1 | gate del arpegio (al máximo, legato) |
| K2 + E2 | patrón del arpegio |
| K2 + E3 | velocidad del arpegio |
| K1 mantenido | retener on/off (puntito a la izquierda de los faders: lleno = retenido) |

**Faders:** attack, decay, distorsión, shimmer, wobble, fatness.

**Menú PARAMETERS:** canal MIDI (0 = todos, por defecto), divisor del reloj
MIDI, ataque del D-50, hall, volumen y todo lo anterior.

## Galería

| | |
|---|---|
| ![D-50](docs/1_d50.png) D-50 · Cmaj7 | ![CS80](docs/2_cs80.png) CS80 · Am, filtro abierto |
| ![OMNI](docs/3_omni.png) OMNI · Dsus2, filtro cerrado | ![arpegio](docs/4_arp.png) arpegio · Em7 |

## Créditos

Hecho por [Buenos Aires Front](https://github.com/buenosairesfront) / U-MA.
Los nombres de los modelos hacen referencia a los instrumentos que los
inspiraron; este proyecto no está afiliado a Roland, Yamaha ni ARP.
Licencia MIT.
