// Engine_Chordex80.sc
// Chordex 80 — sucesor de Chordex2 (que queda intacto en code/Chordex2).
// Objetivo de sonido: polisynth analógico de los 80 (Juno-106 / Jupiter-8)
//   como en Kavinsky / FM-84 / Fren 79, más el costado "omnichord / HiChord"
//   para acordes suaves y el arpegio tipo arpa (strumplate).
//
// Voz (\cx_voice): un "DCO" por tono del acorde, como un Juno:
//   saw + pulse con PWM + sub cuadrada una octava abajo + un toque de ruido,
//   segundo saw desafinado (fatness) a lo Jupiter, deriva analógica lenta,
//   seno/triángulo para el modelo OMNI. Filtro 4 polos (MoogFF) POR VOZ con
//   envolvente propia y keytracking; cutoff y resonancia llegan por buses de
//   control, así E1 mueve en vivo hasta las notas del arpegio que ya sonaron.
// Modelos (command "model"): 0 D-50 (antes JUNO), 1 CS80, 2 OMNI — cambian la mezcla de
//   osciladores, cuánto abre la envolvente del filtro y el timbre del arpegio.
//   CS80 (antes JUPITER) tiene voz propia (\cx_cs80): metal a lo Vangelis /
//   Blade Runner, dos capas, filtro de 12 dB, vibrato con retardo bien notorio.
// FX (\cx_fx): crackle (sobrecarga con >2 teclas, igual que Chordex2) ->
//   chorus BBD estilo Juno (I / I+II según fatness) -> shimmer (reverb una
//   octava arriba) -> hall grande (JPverb) -> compresor de bus -> limiter.

Engine_Chordex80 : CroneEngine {

  var voiceBus, cutBus, resBus;
  var fxSynth;
  var noteGroup, releasingGroup, padSynth, legatoSynth, plucks;

  var atk = 0.01, rel = 0.9;
  var wobble = 0.25, drive = 0.2;
  var shimmer = 0.0, fatness = 0.5, d50atk = 0;
  var model = 0;

  // pesos por modelo:
  // [saw, pulse, sub, sine, detune, fenv, brass, wDet, wSync, chorus, spread, hpf, bajo, nivel, v1, cs, hall]
  // v1 = 1: la voz y el chorus se calculan exactamente como en la primera versión
  var models;

  alloc {
    plucks = List.new;
    models = [
      // D-50 (en el lugar del JUNO): voz \cx_d50 (cs = 2). Las columnas de
      //       oscilador quedan como las del JUNO: solo las usa el arpegio.
      //       Chorus ensemble, voces abiertas y sala grande.
      [0.50, 0.65, 0.28, 0.00, 0.0, 0.9, 0.0, 0.0, 0.0, 0.8, 0.7, 140, 0.11, 0.8, 0, 2, 1.6],
      // CS80: voz \cx_cs80 (las columnas de oscilador solo valen para el
      //       arpegio); ensemble casi siempre puesto, voces abiertas y
      //       sala más grande, como en los discos de Vangelis
      [0.70, 0.30, 0.00, 0.20, 0.0040, 1.2, 0.0, 0, 0, 0.75, 0.7, 90, 0.20, 1.0, 0, 1, 1.9],
      // OMNI: seno/triángulo de órgano suave, arpegio campana
      [0.10, 0.18, 0.00, 0.80, 0.0012, 0.4, 0.0, 0, 0, 0, 0, 60, 0.35, 1.0, 1, 0, 1.0]
    ];

    voiceBus = Bus.audio(context.server, 2);
    cutBus = Bus.control(context.server, 1);
    resBus = Bus.control(context.server, 1);
    cutBus.set(2400);
    resBus.set(1.0);

    // --- tono de acorde (gate) ---
    SynthDef(\cx_voice, {
      arg out = 0, freq = 440, gate = 1, vel = 0.8,
          atk = 0.01, rel = 0.9, amp = 0.2, pan = 0,
          wobble = 0.25, drive = 0.2, fat = 0.5,
          wSaw = 0.55, wPulse = 0.5, wSub = 0.32, wSine = 0, det = 0.0025,
          fenvAmt = 0.9, brass = 0, wDet = 0, wSync = 0, hpf = 60, v1 = 0,
          cutBus = 0, resBus = 0;
      var env, fenv, f, drift, vib, pwm, osc, cut, res, sig, dg, d2, dd, r1, r2, w2;

      env = EnvGen.kr(Env.adsr(atk, 0.6, 0.8, rel, curve: -3), gate, doneAction: 2);
      // envolvente de filtro: un poco más rápida que la de amplitud;
      // con brass (JUPITER) el ataque es lento -> "bwaaah" de metal
      fenv = EnvGen.kr(Env.adsr(atk * 0.6 + 0.002 + (brass * 0.09), 0.25 + (rel * 0.25), 0.35, rel), gate);

      drift = LFNoise2.kr(0.25).range(-0.0025, 0.0025);
      // vibrato del LFO tipo Juno con delay: entra de a poco al mantener
      vib = SinOsc.kr(5.3) * wobble * 0.0045 * EnvGen.kr(Env([0, 0, 1], [0.35, 0.9]));
      f = freq * (1 + drift + vib);
      pwm = LFTri.kr(0.6 + (wobble * 2.4), Rand(0, 4)) * (0.08 + (wobble * 0.32));

      dd = det * (0.6 + (fat * 0.8));
      r1 = 1 - (dd * 0.5 * (1 - v1));
      r2 = 1 + (dd * (1 - v1)) + ((det + (fat * det * 1.5)) * v1);
      w2 = (wDet * (1 - v1)) + ((0.35 + (fat * 0.5)) * v1);
      osc = (Saw.ar(f * r1) * wSaw)
        + (Saw.ar(f * r2) * wSaw * w2)
        + (SyncSaw.ar(f * (1 + (dd * 0.3)), f * (1.4 + (fenv * 2.2) + (wobble * LFTri.kr(0.3) * 0.5))) * wSync * (0.5 + (vel * 0.5)))
        + (Pulse.ar(f, (0.5 + pwm).clip(0.06, 0.94)) * wPulse)
        + (Pulse.ar(f * 0.5, 0.5) * wSub)
        + ((SinOsc.ar(f) + (LFTri.ar(f * 2) * 0.25)) * wSine)
        + (PinkNoise.ar(0.012));

      cut = In.kr(cutBus, 1);
      res = In.kr(resBus, 1);
      cut = cut * (freq / 261.6).pow(0.35)
        * (1 + (fenv * fenvAmt * (0.5 + (vel * 0.7))));
      sig = MoogFF.ar(osc, cut.clip(40, 16000), res) * (1 + (res * 0.35));
      sig = HPF.ar(sig, hpf);

      // saturación tipo cinta/consola: tibia abajo, mugrosa (Nightcall) arriba
      dg = 1 + (drive.pow(1.4) * 10);
      d2 = (sig * dg).tanh;
      sig = (sig * (1 - drive.min(1))) + (d2 * drive.min(1) / (1 + (drive * 0.9)));

      sig = sig * env * amp * (0.45 + (vel * 0.55));
      Out.ar(out, Pan2.ar(sig, pan));
    }).add;

    // --- CS-80: dos capas por tecla como el Yamaha (I: dos sierras abiertas,
    //     II: pulso con PWM lento + seno), filtros de 12 dB (LPF resonante +
    //     HPF) con envolvente lenta de metal, y la modulación que lo hace
    //     Vangelis: vibrato con retardo que crece como el aftertouch, profundo
    //     y un poco irregular (mano), el mismo LFO "abriendo" el filtro y un
    //     leve barrido de afinación desde abajo al atacar (cinta/ribbon).
    //     wobble = profundidad de toda esa modulación (0 ya se oye, 1 marea).
    SynthDef(\cx_cs80, {
      arg out = 0, freq = 440, gate = 1, vel = 0.8,
          atk = 0.01, rel = 0.9, amp = 0.2, pan = 0,
          wobble = 0.25, drive = 0.2, fat = 0.5,
          cutBus = 0, resBus = 0;
      var env, fenv, vdel, lfo, depth, f, hand, swoop, sp, l1, l2,
          cut, res, rq, s1, s2, sig, dg, d2;

      env = EnvGen.kr(Env.adsr(atk + 0.035, 1.0, 0.85, rel * 1.4 + 0.1, curve: -2), gate, doneAction: 2);
      // filtro: arranca cerrado, abre en ~0.2 s ("bwaaah") y se asienta
      fenv = EnvGen.kr(Env.adsr(0.16 + (atk * 0.7), 0.8 + (rel * 0.4), 0.4, rel * 1.3, curve: -2), gate);

      // vibrato con retardo: nada al principio, entra en ~1 s
      vdel = EnvGen.kr(Env([0, 0, 1], [0.22, 1.0], [0, 2]));
      lfo = SinOsc.kr(5.4 + LFNoise1.kr(0.5).range(-0.35, 0.35), Rand(0, 6.28));
      wobble = Lag.kr(wobble, 0.1);
      depth = (0.007 + (wobble * 0.016)) * vdel;            // ~12 a ~40 cents
      hand = LFNoise2.kr(0.4) * 0.0022;
      swoop = EnvGen.kr(Env([-0.018, 0], [0.2], [4]));        // sube ~30 cents
      f = freq * (1 + (lfo * depth) + hand + swoop);

      sp = 0.0022 + (fat * 0.003);
      l1 = (Saw.ar(f * (1 - sp)) + Saw.ar(f * (1 + sp))) * 0.5;
      l2 = (Pulse.ar(f * 1.0015, (0.5 + (LFTri.kr(0.35 + (wobble * 0.5), Rand(0, 4)) * 0.32)).clip(0.08, 0.92)) * 0.55)
        + (SinOsc.ar(f * 0.5) * 0.35) + (PinkNoise.ar(0.01));

      cut = In.kr(cutBus, 1);
      res = In.kr(resBus, 1);
      cut = cut * (freq / 261.6).pow(0.4)
        * (0.45 + (fenv * 1.5 * (0.5 + (vel * 0.7))))
        * (1 + (lfo * vdel * (0.06 + (wobble * 0.22))));     // el LFO también "habla" en el filtro
      rq = (1 - (res / 3.6 * 0.82)).clip(0.16, 1);
      s1 = RLPF.ar(l1, cut.clip(60, 13000), rq);
      s2 = RLPF.ar(l2, (cut * 0.75).clip(60, 11000), (rq * 1.4).min(1));
      sig = (s1 * 0.6) + (s2 * 0.5);
      sig = RHPF.ar(sig, 110, 0.8);
      sig = sig * (1 - (res * 0.08));

      dg = 1 + (drive.pow(1.4) * 8);
      d2 = (sig * dg).tanh;
      sig = (sig * (1 - drive.min(1))) + (d2 * drive.min(1) / (1 + (drive * 0.9)));

      // un poco de trémolo con el mismo LFO
      sig = sig * (1 + (lfo * vdel * (0.05 + (wobble * 0.1))));
      sig = sig * env * amp * (0.45 + (vel * 0.55));
      Out.ar(out, Pan2.ar(sig, pan));
    }).add;

    // --- D-50 (síntesis LA de Roland): cada tecla = un ataque "digital"
    //     cortito (chiff de aire + capa de ataque, como los PCM de
    //     ataque del D-50) encima de un colchón de dos sierras abiertas +
    //     pulso, con filtro de 12 dB que se abre lento y respira.
    //     fatness = cuánto se abren las sierras; wobble = respiración del
    //     filtro + un vibrato leve con retardo.
    SynthDef(\cx_d50, {
      arg out = 0, freq = 440, gate = 1, vel = 0.8,
          atk = 0.01, rel = 0.9, amp = 0.2, pan = 0,
          wobble = 0.25, drive = 0.2, fat = 0.5,
          cutBus = 0, resBus = 0, atkmode = 0;
      var env, swell, breath, vib, f, sp, pad, cut, res, rq,
          chiff, aenv, aire, penv, pluck, capa, sig, dg, d2;

      // el colchón entra un poco por debajo del ataque y suelta largo
      env = EnvGen.kr(Env.adsr(atk + 0.16, 1.4, 0.88, rel * 1.6 + 0.25, curve: -2), gate, doneAction: 2);
      swell = EnvGen.kr(Env([0.3, 1, 0.75], [0.7 + atk, 1.8], [2, -2]));

      wobble = Lag.kr(wobble, 0.1);
      breath = SinOsc.kr(0.17 + Rand(-0.03, 0.03), Rand(0, 6.28));
      vib = SinOsc.kr(4.8, Rand(0, 6.28)) * (0.0006 + (wobble * 0.0028))
        * EnvGen.kr(Env([0, 0, 1], [0.5, 1.5]));
      f = freq * (1 + vib + (LFNoise2.kr(0.2) * 0.0007));

      sp = 0.003 + (fat * 0.005);                  // ±5 a ±14 cents
      pad = ((Saw.ar(f * (1 - sp)) + Saw.ar(f * (1 + sp))) * 0.4)
        + (Pulse.ar(f * 1.0007, (0.5 + (LFTri.kr(0.23, Rand(0, 4)) * 0.25))) * 0.3)
        + (SinOsc.ar(f * 2) * 0.1);

      cut = In.kr(cutBus, 1);
      res = In.kr(resBus, 1);
      cut = cut * (freq / 261.6).pow(0.35) * swell
        * (1 + (breath * (0.06 + (wobble * 0.3))));
      rq = (1 - (res / 3.6 * 0.75)).clip(0.2, 1);
      pad = RLPF.ar(pad, cut.clip(80, 12000), rq) * (1 - (res * 0.06));
      pad = pad * (1 + (breath * (0.02 + (wobble * 0.05))));

      // ataque: soplido de ruido + campana FM (relación 3.5 = vidrio)
      chiff = BPF.ar(WhiteNoise.ar, (freq * 4).clip(900, 9000), 0.35)
        * EnvGen.kr(Env.perc(0.001, 0.09, curve: -4)) * (0.5 + (vel * 0.6));
      // capa de ataque (atkmode): 0 aire = soplido afinado que queda
      // respirando bajito; 1 pluck = cuerda digital pulsada; 2 = solo colchón
      aenv = EnvGen.kr(Env([0, 1, 0.3], [0.05, 0.6], [2, -3]));
      aire = ((BPF.ar(WhiteNoise.ar, f * 2, 0.012) * 7) + (BPF.ar(WhiteNoise.ar, f * 3, 0.018) * 4))
        * aenv * 1.5 * (0.5 + (vel * 0.6));
      penv = EnvGen.kr(Env.perc(0.001, 0.9 + (vel * 0.5), curve: -4));
      pluck = LPF.ar(Pluck.ar(WhiteNoise.ar(0.6), Impulse.ar(0), 0.05, 1 / (f * 2), 1.2, 0.45), 5000)
        * penv * 1.6 * (0.4 + (vel * 0.8));
      capa = Select.ar(atkmode.clip(0, 2), [aire, pluck, DC.ar(0)]);

      sig = (pad * env) + ((chiff + capa) * EnvGen.kr(Env.asr(0, 1, 0.15), gate));
      sig = HPF.ar(sig, 90);

      dg = 1 + (drive.pow(1.4) * 8);
      d2 = (sig * dg).tanh;
      sig = (sig * (1 - drive.min(1))) + (d2 * drive.min(1) / (1 + (drive * 0.9)));

      sig = sig * amp * (0.45 + (vel * 0.55));
      Out.ar(out, Pan2.ar(sig, pan));
    }).add;

    // --- arpegio: pluck Juno (filtro que cierra rápido) mezclado con
    //     campana de omnichord (seno + armónico que decae más rápido) ---
    SynthDef(\cx_pluck, {
      arg out = 0, freq = 440, dur = 0.2, vel = 0.8, amp = 0.3, pan = 0,
          wobble = 0.25, drive = 0.2, fat = 0.5,
          wSaw = 0.55, wPulse = 0.5, wSine = 0, det = 0.0025, chime = 0.3,
          cutBus = 0, resBus = 0, gate = 1;
      var env, fenv, cenv, pwm, osc, cut, res, syn, bell, sig, tail, dg;

      tail = dur * (1 + (chime * 3));
      // gate=0 = robo de voz: fade de 60 ms y se libera
      env = EnvGen.kr(Env.perc(0.003, tail, curve: -4), doneAction: 2)
        * EnvGen.kr(Env.asr(0, 1, 0.06), gate, doneAction: 2);
      fenv = EnvGen.kr(Env.perc(0.001, dur * 0.7, curve: -6));
      cenv = EnvGen.kr(Env.perc(0.001, tail * 0.35, curve: -5));

      pwm = LFTri.kr(0.6 + (wobble * 2.4), Rand(0, 4)) * (0.1 + (wobble * 0.3));
      osc = (Saw.ar(freq) * wSaw)
        + (Saw.ar(freq * (1 + det + (fat * det))) * wSaw * 0.5)
        + (Pulse.ar(freq, (0.5 + pwm).clip(0.06, 0.94)) * wPulse);

      cut = In.kr(cutBus, 1);
      res = In.kr(resBus, 1);
      cut = cut * 0.6 * (freq / 261.6).pow(0.4) * (1 + (fenv * 4 * (0.4 + vel)));
      syn = MoogFF.ar(osc, cut.clip(60, 15000), res) * (1 + (res * 0.35));

      bell = (SinOsc.ar(freq) * 0.7)
        + (SinOsc.ar(freq * 2.0) * 0.35 * cenv)
        + (SinOsc.ar(freq * 3.01) * 0.12 * cenv)
        + (LFTri.ar(freq) * 0.25 * wSine);

      sig = (syn * (1 - chime)) + (bell * chime * 0.8);
      dg = 1 + (drive.pow(1.4) * 6);
      sig = (sig * (1 - drive)) + ((sig * dg).tanh * drive / (1 + drive));
      sig = HPF.ar(sig, 80) * env * amp * (0.45 + (vel * 0.55));
      Out.ar(out, Pan2.ar(sig, pan));
    }).add;

    // --- arpegio legato (gate al máximo): la misma mezcla que el pluck pero
    //     sostenida; una sola voz que no se redispara, cada paso solo cambia
    //     la altura (con un deslizamiento cortito) -> legato real
    SynthDef(\cx_legato, {
      arg out = 0, freq = 440, gate = 1, vel = 0.8, amp = 0.3, pan = 0,
          wobble = 0.25, drive = 0.2, fat = 0.5,
          wSaw = 0.55, wPulse = 0.5, wSine = 0, det = 0.0025, chime = 0.3,
          cutBus = 0, resBus = 0;
      var env, f, pwm, osc, cut, res, syn, bell, sig, dg;

      env = EnvGen.kr(Env.asr(0.01, 1, 0.35, curve: -3), gate, doneAction: 2);
      f = Lag.kr(freq, 0.035);
      pwm = LFTri.kr(0.6 + (wobble * 2.4), Rand(0, 4)) * (0.1 + (wobble * 0.3));
      osc = (Saw.ar(f) * wSaw)
        + (Saw.ar(f * (1 + det + (fat * det))) * wSaw * 0.5)
        + (Pulse.ar(f, (0.5 + pwm).clip(0.06, 0.94)) * wPulse);

      cut = In.kr(cutBus, 1);
      res = In.kr(resBus, 1);
      cut = cut * 0.6 * (f / 261.6).pow(0.4) * 1.8;
      syn = MoogFF.ar(osc, cut.clip(60, 15000), res) * (1 + (res * 0.35));

      bell = (SinOsc.ar(f) * 0.7) + (SinOsc.ar(f * 2.0) * 0.12) + (LFTri.ar(f) * 0.25 * wSine);

      sig = (syn * (1 - chime)) + (bell * chime * 0.8);
      dg = 1 + (drive.pow(1.4) * 6);
      sig = (sig * (1 - drive)) + ((sig * dg).tanh * drive / (1 + drive));
      sig = HPF.ar(sig, 80) * env * amp * 0.7 * (0.45 + (Lag.kr(vel, 0.03) * 0.55));
      Out.ar(out, Pan2.ar(sig, Lag.kr(pan, 0.05)));
    }).add;

    // --- bajo: seno + cuadrada filtrada, dos octavas abajo ---
    SynthDef(\cx_bass, {
      arg out = 0, freq = 55, gate = 1, atk = 0.01, rel = 0.6,
          drive = 0.2, amp = 0.35, cutBus = 0;
      var env, sig, cut;
      env = EnvGen.kr(Env.asr(atk, 1, rel), gate, doneAction: 2);
      cut = (In.kr(cutBus, 1) * 0.25).clip(120, 900);
      sig = (SinOsc.ar(freq) * 0.75) + (LPF.ar(Pulse.ar(freq, 0.5), cut) * 0.35);
      sig = (sig * (1 + (drive * 3))).tanh / (1 + (drive * 0.6));
      sig = sig * env * amp;
      Out.ar(out, Pan2.ar(sig, 0));
    }).add;

    SynthDef(\cx_fx, {
      arg in, out, fat = 0.5, shimmer = 0, crackle = 0, space = 0.22, gain = 1.0, cmode = 1, v1 = 0, hall = 1;
      var dry, sig, lfo1, lfo2, cdL, cdR, cmix, wet1, wet2, sh, verb, cn, cg, comp;

      dry = In.ar(in, 2);
      sig = dry;

      // crackle: igual que en Chordex2 (solo suena si hay señal)
      cn = HPF.ar(Crackle.ar(1.85, mul: [1, 1]), 1600);
      cg = Amplitude.kr(Mix(dry), 0.01, 0.08) > 0.02;
      sig = sig + (cn * crackle * 0.3 * cg);

      // chorus BBD tipo Juno: modo I (0.51 Hz) y II (0.86 Hz), triangulares,
      // en contrafase L/R. fatness 0 -> seco, 0.5 -> I, 1 -> I+II
      lfo1 = LFTri.kr(0.513);
      lfo2 = LFTri.kr(0.863);
      cmix = Mix(sig) * 0.5;
      cmix = LPF.ar(cmix, 9000);
      wet1 = [DelayC.ar(cmix, 0.02, 0.0035 + (lfo1 * 0.0017)), DelayC.ar(cmix, 0.02, 0.0035 - (lfo1 * 0.0017))];
      wet2 = [DelayC.ar(cmix, 0.02, 0.0035 + (lfo2 * 0.0019)), DelayC.ar(cmix, 0.02, 0.0035 - (lfo2 * 0.0019))];
      // cmode: JUNO 1 (chorus siempre, fat solo elige I / I+II),
      //        CS80 0.75 (ensemble), OMNI v1
      cmode = Lag.kr(cmode, 0.2);
      cdL = (wet1 * ((fat * 2).clip(0, 1) * (1 - cmode) + cmode))
        + (wet2 * ((fat - 0.5) * 2).clip(0, 1));
      v1 = Lag.kr(v1, 0.2);
      sig = ((sig * (1 - (cmode * 0.3) - (fat * 0.2))) + (LPF.ar(cdL, 7000) * ((cmode * 0.6) + (fat * 0.35)) * (0.4 + cmode))) * (1 - v1)
        + (((sig * (1 - (fat * 0.35))) + (LPF.ar((wet1 * (fat * 2).clip(0, 1)) + (wet2 * ((fat - 0.5) * 2).clip(0, 1)), 7000) * (0.25 + (fat * 0.55)))) * v1);

      // shimmer: reverb de la señal una octava arriba (como Chordex2)
      sh = PitchShift.ar(sig, 0.15, 2.0, 0.008, 0.01);
      sh = FreeVerb2.ar(sh[0], sh[1], 1, 0.9, 0.3);
      sig = sig + (sh * shimmer * 0.8);

      // hall grande ochentoso: siempre un poco, más con shimmer
      // (JPverb sonaba lindo pero gastaba ~30% de CPU solo)
      verb = HPF.ar(sig, 220) * (space + (shimmer * 0.35)) * Lag.kr(hall, 0.3);
      verb = DelayN.ar(verb, 0.05, 0.03);
      verb = FreeVerb2.ar(verb[0], verb[1], 1, 0.93 + (shimmer * 0.05), 0.45);
      sig = sig + (verb * 0.9);

      // compresor de bus: el "pegamento" de las producciones synthwave
      comp = Compander.ar(sig, Mix(sig) * 0.5, 0.25, 1, 0.45, 0.008, 0.18);
      sig = comp * 2.0 * gain;
      sig = Limiter.ar(LeakDC.ar(sig), 0.92, 0.01);
      Out.ar(out, sig);
    }).add;

    context.server.sync;

    fxSynth = Synth.tail(context.xg, \cx_fx, [
      \in, voiceBus, \out, context.out_b, \fat, fatness, \shimmer, shimmer
    ]);

    this.addCommand("noteOn", "ffffff", { |msg|
      var freqs = [msg[1], msg[2], msg[3], msg[4]];
      var subf = msg[5], vel = msg[6];
      var m = models[model];
      // freq 0 = voz apagada (modo acorde off: una sola nota, centrada y
      // compensada para que suene igual de fuerte que el acorde)
      var nv = freqs.count({ |f| f > 0 }).max(1);
      var va = 0.2 * m[13] * ((4 / nv) ** 0.5);

      if (releasingGroup.notNil) { releasingGroup.free };
      if (noteGroup.notNil) {
        noteGroup.set(\gate, 0);
        releasingGroup = noteGroup;
      };
      noteGroup = Group.head(context.xg);

      freqs.do({ |f, i|
        if (f > 0) {
        if (m[15] == 2) {
          Synth.new(\cx_d50, [
            \out, voiceBus, \freq, f, \vel, vel, \atk, atk, \rel, rel,
            \wobble, wobble, \drive, drive, \fat, fatness, \amp, va,
            \cutBus, cutBus.index, \resBus, resBus.index, \atkmode, d50atk,
            \pan, if (nv == 1) { 0 } { ((i - 1.5) * 0.4 * (0.6 + (fatness * 0.6))).clip(-0.9, 0.9) }
          ], noteGroup);
        } {
        if (m[15] > 0) {
          Synth.new(\cx_cs80, [
            \out, voiceBus, \freq, f, \vel, vel, \atk, atk, \rel, rel,
            \wobble, wobble, \drive, drive, \fat, fatness, \amp, va,
            \cutBus, cutBus.index, \resBus, resBus.index,
            \pan, if (nv == 1) { 0 } { ((i - 1.5) * 0.4 * (0.6 + (fatness * 0.6))).clip(-0.9, 0.9) }
          ], noteGroup);
        } {
        Synth.new(\cx_voice, [
          \out, voiceBus, \freq, f, \vel, vel, \atk, atk, \rel, rel,
          \wobble, wobble, \drive, drive, \fat, fatness, \amp, va,
          \wSaw, m[0], \wPulse, m[1], \wSub, m[2], \wSine, m[3],
          \det, m[4], \fenvAmt, m[5], \brass, m[6],
          \wDet, m[7], \wSync, m[8], \hpf, m[11], \v1, m[14],
          \cutBus, cutBus.index, \resBus, resBus.index,
          \pan, if (nv == 1) { 0 } { if (m[14] > 0) { (i - 1.5) * 0.3 * (0.4 + fatness) } {
            ((i - 1.5) * (0.1 + (m[10] * 0.4)) * (0.6 + (fatness * 0.6))).clip(-0.9, 0.9) } }
        ], noteGroup);
        };
        };
        };
      });
      Synth.new(\cx_bass, [
        \out, voiceBus, \freq, if (m[14] > 0) { subf } { this.bassFreq(subf) }, \atk, atk, \rel, rel,
        \drive, drive, \cutBus, cutBus.index, \amp, m[12]
      ], noteGroup);
    });

    // al soltar: el grupo queda como "releasing" y se borra solo cuando
    // termina la cola (en Chordex2 quedaban grupos vacíos acumulándose)
    this.addCommand("noteOff", "", { |msg|
      var g;
      if (releasingGroup.notNil) { releasingGroup.free; releasingGroup = nil };
      if (noteGroup.notNil) {
        g = noteGroup;
        g.set(\gate, 0);
        releasingGroup = g;
        noteGroup = nil;
        SystemClock.sched(rel + 0.5, {
          if (releasingGroup === g) { g.free; releasingGroup = nil };
          nil
        });
      };
    });

    this.addCommand("padOn", "f", { |msg|
      if (padSynth.notNil) {
        padSynth.set(\freq, if (models[model][14] > 0) { msg[1] } { this.bassFreq(msg[1]) });
      } {
        padSynth = Synth.new(\cx_bass, [
          \out, voiceBus, \freq, if (models[model][14] > 0) { msg[1] } { this.bassFreq(msg[1]) }, \atk, atk, \rel, rel,
          \drive, drive, \cutBus, cutBus.index,
          \amp, if (models[model][14] > 0) { 0.35 } { models[model][12] * 1.6 }
        ], context.xg);
      };
    });

    this.addCommand("padOff", "", { |msg|
      if (padSynth.notNil) { padSynth.set(\gate, 0); padSynth = nil };
    });

    // freq, dur, vel, pan
    this.addCommand("arpStep", "ffff", { |msg|
      var m = models[model];
      var chime = [0.3, 0.12, 0.85][model];
      var p;
      // máximo 8 notas de arpegio sonando: con gate alto las colas se apilaban
      // (24+ voces) y el CPU se saturaba -> audio roto. Se apaga la más vieja.
      while { plucks.size >= 8 } { plucks.removeAt(0).set(\gate, 0) };
      p = Synth.new(\cx_pluck, [
        \out, voiceBus, \freq, msg[1], \dur, msg[2], \vel, msg[3], \pan, msg[4],
        \wobble, wobble, \drive, drive, \fat, fatness,
        \wSaw, m[0], \wPulse, m[1], \wSine, m[3], \det, m[4], \chime, chime,
        \cutBus, cutBus.index, \resBus, resBus.index
      ], context.xg);
      plucks.add(p);
      p.onFree { plucks.remove(p) };
    });

    // freq, vel, pan: primera vez crea la voz, después solo la mueve
    this.addCommand("arpLegato", "fff", { |msg|
      var m = models[model];
      // una sola voz contra varias notas pulsadas superpuestas: compensación
      // por modelo para que suene igual de fuerte que el gate 0.9 (medido)
      var lg = 0.3 * [2.06, 1.79, 2.26][model];
      if (legatoSynth.notNil) {
        legatoSynth.set(\freq, msg[1], \vel, msg[2], \pan, msg[3], \amp, lg);
      } {
        legatoSynth = Synth.new(\cx_legato, [
          \out, voiceBus, \freq, msg[1], \vel, msg[2], \pan, msg[3], \amp, lg,
          \wobble, wobble, \drive, drive, \fat, fatness,
          \wSaw, m[0], \wPulse, m[1], \wSine, m[3], \det, m[4],
          \chime, [0.3, 0.12, 0.85][model],
          \cutBus, cutBus.index, \resBus, resBus.index
        ], context.xg);
      };
    });
    this.addCommand("arpLegatoOff", "", { |msg|
      if (legatoSynth.notNil) { legatoSynth.set(\gate, 0); legatoSynth = nil };
    });

    this.addCommand("atk", "f", { |msg| atk = msg[1] });
    this.addCommand("rel", "f", { |msg|
      rel = msg[1];
      if (noteGroup.notNil) { noteGroup.set(\rel, rel) };
    });
    this.addCommand("drive", "f", { |msg|
      drive = msg[1];
      if (noteGroup.notNil) { noteGroup.set(\drive, drive) };
    });
    // ataque del D-50: 0 aire, 1 pluck, 2 sin capa (vale desde la próxima nota)
    this.addCommand("d50atk", "i", { |msg| d50atk = msg[1].clip(0, 2) });
    this.addCommand("wobble", "f", { |msg|
      wobble = msg[1];
      if (noteGroup.notNil) { noteGroup.set(\wobble, wobble) };
    });
    this.addCommand("fatness", "f", { |msg|
      fatness = msg[1];
      fxSynth.set(\fat, fatness);
      if (noteGroup.notNil) { noteGroup.set(\fat, fatness) };
    });
    this.addCommand("shimmer", "f", { |msg|
      shimmer = msg[1];
      fxSynth.set(\shimmer, shimmer);
    });
    this.addCommand("space", "f", { |msg| fxSynth.set(\space, msg[1]) });
    this.addCommand("gain", "f", { |msg| fxSynth.set(\gain, msg[1]) });
    this.addCommand("cutoff", "f", { |msg| cutBus.set(msg[1]) });
    this.addCommand("res", "f", { |msg| resBus.set(msg[1]) });
    this.addCommand("crackle", "f", { |msg| fxSynth.set(\crackle, msg[1]) });
    this.addCommand("model", "i", { |msg|
      model = msg[1].clip(0, 2);
      fxSynth.set(\cmode, models[model][9], \v1, models[model][14], \hall, models[model][16]);
    });
  }

  // el bajo nunca por debajo de ~40 Hz: en notas graves sube una octava
  bassFreq { |f| ^if (f < 40) { f * 2 } { f } }

  free {
    if (noteGroup.notNil) { noteGroup.free };
    if (releasingGroup.notNil) { releasingGroup.free };
    if (padSynth.notNil) { padSynth.free };
    if (legatoSynth.notNil) { legatoSynth.free };
    fxSynth.free;
    voiceBus.free;
    cutBus.free;
    resBus.free;
  }
}
