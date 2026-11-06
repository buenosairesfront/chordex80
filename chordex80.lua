-- Chordex 80
-- sucesor de Chordex2 (que queda intacto): mismo instrumento de acordes
-- (una tecla = un acorde, suena la nota más grave), con motor de polisynth
-- ochentoso (D-50 / CS80 / OMNI) y pantalla outrun: atardecer + grilla.
--
-- La escena ES el sintetizador:
--   sol: tamaño = filtro (E1), halo = resonancia, franjas = distorsión,
--        temblor = wobble, fantasma a los lados = chorus (fatness),
--        brillo = la envolvente (attack/decay) respirando con lo que tocás
--   estrellas = shimmer, chispas = crackle (más de 2 teclas apretadas)
--   grilla: avanza con el tempo del arpegio; cada nota es una luz en la ruta
--
-- Controles (los mismos de Chordex2 + 3 nuevos):
--   E1: filtro            K3 + E1: modelo D-50 / CS80 / OMNI      (nuevo)
--   E2: elige parámetro   K3 + E2: resonancia
--   E3: ajusta parámetro  K3 + E3: tipo de acorde
--   K3 mantenido (sin girar): modo acorde on/off (off = una sola nota)
--   K2: tap = arpegiador on/off
--   K2 + E2: patrón (up, down, up-down, up x2, down x2, random, arpa)
--   K2 + E3: velocidad del arpegio                                 (nuevo)
--   K2 + E1: duración de cada nota del arpegio (gate), de cortita a
--            legato real al máximo (una voz que no se corta)      (nuevo)
--   K1 mantenido: retener on/off (el acorde sigue sonando al soltar) (nuevo)
--                 puntito a la izquierda de los faders: lleno = retenido
--   clock MIDI entrante: solo marca el tempo del arpegio, nunca dispara notas;
--   si el equipo repite la misma nota a tempo, no se vuelve a disparar el acorde
--   todo se guarda solo al salir y vuelve igual al cargar          (nuevo)

engine.name = 'Chordex80'

local musicutil = require 'musicutil'

local midi_in
local current_note = nil
local current_vel = 0.8
local last_note = nil
local held_stack = {}
-- teclas para el arpegio en modo simple (sin acorde): las apretadas, de
-- grave a aguda; al soltar todo quedan las últimas (para el retener)
local arp_keys = {}
local function update_arp_keys()
  if #held_stack == 0 then return end
  arp_keys = {}
  for i, n in ipairs(held_stack) do arp_keys[i] = n end
  table.sort(arp_keys)
end
-- modo simple: qué teclas están sonando, para no redisparar si no cambió nada
local voiced_sig = nil
local function keys_sig() return table.concat(arp_keys, ",") end
local last_midi_clock = nil
local CLOCK_TIMEOUT = 0.5     -- sin pulsos por medio segundo = vuelve al reloj interno
local tick_sec = nil          -- duración medida de un pulso MIDI (24 por negra)
local ext_ticks = 0           -- pulsos acumulados hacia el próximo paso del arpegio
local hold_on = false

local chord_types = {"maj", "min", "dim", "aug", "7", "maj7", "min7", "m7b5", "sus2", "sus4"}
local chord_suffix = {maj = "", min = "m", dim = "dim", aug = "+", ["7"] = "7",
  maj7 = "maj7", min7 = "m7", m7b5 = "m7b5", sus2 = "sus2", sus4 = "sus4"}
local chord_intervals = {
  maj = {0, 4, 7}, min = {0, 3, 7}, dim = {0, 3, 6}, aug = {0, 4, 8},
  ["7"] = {0, 4, 7, 10}, maj7 = {0, 4, 7, 11}, min7 = {0, 3, 7, 10},
  m7b5 = {0, 3, 6, 10}, sus2 = {0, 2, 7}, sus4 = {0, 5, 7},
}
local note_names = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
local model_names = {"D-50", "CS80", "OMNI"}
-- dibujos esquemáticos de los 3 modelos (reemplazan al nombre al cambiar
-- con K3 + E2): '#' = brillante, '+' = medio, '.' = tenue
local MODEL_ICON = {
  ["D-50"] = {
    "###############################",
    "#  #   #######  + + + + + + + #",
    "#  #   #.....#  . . . . . . . #",
    "# +++  #######  + + + + + + + #",
    "###############################",
    "#   ## ## # ## ## # ## ## #   #",
    "#   ## ## # ## ## # ## ## #   #",
    "#   ## ## # ## ## # ## ## #   #",
    "###############################",
  },
  CS80 = {
    "   #########################   ",
    "  #  + + + + + + + + + + +  #  ",
    " #   # # # # # # # # # # #   # ",
    "##  ## ## ## ## ## ## ## ##  ##",
    "##                           ##",
    "## ......................... ##",
    "##  #  #  ## #  #  #  ## #   ##",
    "##  ## ## ## ## ## ## ## ##  ##",
    "##  ## ## ## ## ## ## ## ##  ##",
    "###############################",
  },
  OMNI = {
    "   ######################      ",
    "  #                      #     ",
    " #  . . . . . . . .  ###  #    ",
    "#   + + + + + + + +  # #   #   ",
    "#   . . . . . . . .  ###  # #  ",
    "#   + + + + + + + +      # # # ",
    "#   . . . . . . . .     # # # #",
    " #                     # # # # ",
    "  #############################",
  },
}
local arp_pattern_names = {"up", "down", "up-down", "up x2", "down x2", "random", "arpa"}
-- velocidad del arpegio: multiplica el paso original de Chordex2 (x1 = igual)
local arp_rate_mult = {4, 2, 1, 0.5}
local arp_rate_names = {"x1/4", "x1/2", "x1", "x2"}

-- parámetros de la tabla de 6 (E2 elige, E3 ajusta)
local P = {
  {id = "atk",     name = "attack",     min = 0.001, max = 2,  step = 0.01, def = 0.01},
  {id = "rel",     name = "decay",      min = 0.02,  max = 4,  step = 0.03, def = 0.9},
  {id = "drive",   name = "distorsion", min = 0,     max = 1,  step = 0.02, def = 0.2},
  {id = "shimmer", name = "shimmer",    min = 0,     max = 1,  step = 0.02, def = 0},
  {id = "wobble",  name = "wobble",     min = 0,     max = 1,  step = 0.02, def = 0.25},
  {id = "fatness", name = "fatness",    min = 0,     max = 1,  step = 0.02, def = 0.5},
}
local focus_index = 1

local arp_on = false
local arp_clock_id = nil
local arp_step_lit = 0
local k2_held, k2_turned, k3_held = false, false, false
local k3_turned = false
local k3_press = nil
local K3_LONG = 0.5   -- segundos manteniendo K3 para alternar el modo acorde

-- animación
local PULSE = 24
local param_pulse = {0, 0, 0, 0, 0, 0}
local filter_pulse = 0
local model_flash = 0
local env = 0              -- envolvente simulada (brillo del sol)
local flash = 0            -- golpe de luz en la grilla al tocar
local grid_ph = 0
local streaks = {}
local last_t = nil
local frame = 0

-- ============================================================
-- ayudas
-- ============================================================

local function pv(id) return params:get(id) end

local function note_to_hz(n) return musicutil.note_num_to_freq(n) end

local function four_tone_intervals(name)
  local iv = chord_intervals[name]
  if #iv >= 4 then return iv end
  return {iv[1], iv[2], iv[3], iv[1] + 12}
end

local function chord_name() return chord_types[pv("chord")] end

-- intervalos que suenan: el acorde, o solo la nota con el modo acorde apagado
local function chord_ivs()
  if pv("chord_on") == 1 then return {0} end
  return four_tone_intervals(chord_name())
end

local function chord_tone_hz(note)
  local f = {}
  for _, iv in ipairs(chord_ivs()) do
    f[#f + 1] = note_to_hz(note + iv)
  end
  return f
end

-- una luz que viaja por la ruta (lane -1.5..1.5)
local function spawn(lane, lv)
  if #streaks > 24 then table.remove(streaks, 1) end
  streaks[#streaks + 1] = {lane = lane, z = 0, lv = lv}
end

-- ============================================================
-- sonido
-- ============================================================

local function voice_chord(note)
  local f = chord_tone_hz(note)
  -- modo simple con varias teclas: suenan todas juntas (hasta 4, las más agudas)
  if pv("chord_on") == 1 and #arp_keys > 1 then
    f = {}
    for i = math.max(1, #arp_keys - 3), #arp_keys do f[#f + 1] = note_to_hz(arp_keys[i]) end
  end
  voiced_sig = keys_sig()
  for i = #f + 1, 4 do f[i] = 0 end   -- 0 = esa voz no suena
  engine.noteOn(f[1], f[2], f[3], f[4], note_to_hz(note - 24), current_vel)
end

local function sound_chord(note)
  voice_chord(note)
  flash = 1
  for i = 1, 4 do spawn(i - 2.5, 9 + current_vel * 6) end
end

local function step_order(pat, n)
  local t = {}
  if pat == 1 or pat == 7 then for i = 1, n do t[#t + 1] = i end
  elseif pat == 2 then for i = n, 1, -1 do t[#t + 1] = i end
  elseif pat == 3 then
    for i = 1, n do t[#t + 1] = i end
    for i = n - 1, 2, -1 do t[#t + 1] = i end
  elseif pat == 4 then for i = 1, n do t[#t + 1] = i; t[#t + 1] = i end
  elseif pat == 5 then for i = n, 1, -1 do t[#t + 1] = i; t[#t + 1] = i end
  end
  return t
end

-- tonos del arpegio: "arpa" (7) recorre el acorde en dos octavas, como
-- pasar el dedo por la strumplate de un omnichord
local function arp_tones()
  local f = chord_tone_hz(current_note)
  if pv("chord_on") == 1 and #arp_keys > 0 then
    f = {}
    for i, n in ipairs(arp_keys) do f[i] = note_to_hz(n) end
  end
  if pv("arp_pattern") == 7 then
    local n = #f
    for i = 1, n do f[#f + 1] = f[i] * 2 end
  end
  return f
end

local function ext_clock_on()
  return last_midi_clock ~= nil and (util.time() - last_midi_clock) < CLOCK_TIMEOUT
end

-- pulsos MIDI por paso: el mismo cálculo de Chordex2 (1/16 de pulso de norns
-- por el divisor), contado directo sobre los pulsos que llegan
local function ticks_per_step()
  local div = ({1, 2, 4, 8})[params:get("midi_clock_div")]
  return math.max(1, 24 * (1 / 16) * div * arp_rate_mult[pv("arp_rate")])
end

local function step_seconds()
  if ext_clock_on() and tick_sec then return tick_sec * ticks_per_step() end
  return clock.get_beat_sec() * (1 / 16) * arp_rate_mult[pv("arp_rate")]
end

local function beat_seconds()
  if ext_clock_on() and tick_sec then return tick_sec * 24 end
  return clock.get_beat_sec()
end

-- gate del arpegio (0..1): cuánto dura cada nota respecto del paso.
-- 0 = muy cortita (1/4 de paso), 0.75 = como sonaba antes (3.4 pasos),
-- 1 = legato real: una voz sostenida que pasa de nota en nota sin cortar
local function arp_note_dur(step_sec)
  local g = params:get("arp_gate")
  return util.clamp(step_sec * 0.25 * (32 ^ g), 0.03, 4)
end

local step_i = 1
local function arp_step()
  if current_note == nil then return end
  do
    local freqs = arp_tones()
    local pat = pv("arp_pattern")
    local idx, pos
    if pat == 6 then
      idx = math.random(1, #freqs); pos = 1
    else
      local order = step_order(pat, #freqs)
      pos = ((step_i - 1) % #order) + 1
      idx = order[pos]
    end
    step_i = step_i + 1
    local step_sec = step_seconds()

    local vel = (pos == 1 and 1 or 0.72) * (0.55 + current_vel * 0.45)
    local pan = ((idx - 1) % 4 - 1.5) * 0.22
    if params:get("arp_gate") >= 0.995 then
      engine.arpLegato(freqs[idx], vel, pan)
    else
      engine.arpLegatoOff()
      engine.arpStep(freqs[idx], arp_note_dur(step_sec), vel, pan)
    end
    arp_step_lit = idx
    spawn(((idx - 1) % 4) - 1.5, 6 + vel * 9)
    flash = math.max(flash, 0.35 * vel)
  end
end

-- con clock MIDI los pasos los da midi_event (pulso a pulso); este loop solo
-- marca el paso con el reloj interno cuando no llega clock
local function arp_loop()
  while arp_on and current_note do
    if ext_clock_on() then
      clock.sleep(0.05)
    else
      local quantum = (1 / 16) * arp_rate_mult[pv("arp_rate")]
      if params:get("clock_source") == 1 then clock.sync(quantum)
      else clock.sleep(clock.get_beat_sec() * quantum) end
      if arp_on and current_note and not ext_clock_on() then arp_step() end
    end
  end
  arp_step_lit = 0
  engine.arpLegatoOff()
end

local function start_arp_if_needed()
  if arp_clock_id == nil and current_note then
    engine.padOn(note_to_hz(current_note - 24))
    step_i = 1
    ext_ticks = 0
    arp_step()
    arp_clock_id = clock.run(arp_loop)
  end
end

local hold_flash = 0

local function stop_arp()
  if arp_clock_id ~= nil then
    clock.cancel(arp_clock_id)
    arp_clock_id = nil
  end
  arp_step_lit = 0
  engine.padOff()
  engine.arpLegatoOff()
end

local function lowest_held()
  local m = nil
  for _, n in ipairs(held_stack) do
    if m == nil or n < m then m = n end
  end
  return m
end

local crackle_amt = 0
local function update_crackle()
  crackle_amt = util.clamp((#held_stack - 2) * 0.35, 0, 1)
  engine.crackle(0)   -- el ruido ya no crece con cada tecla (armaba un siseo fuerte)
end

-- con clock MIDI, algunos equipos repiten la nota apretada a tempo (note-off
-- y note-on enseguida): el soltar espera un poco y si vuelve la misma nota
-- el acorde sigue sonando sin redisparar
local release_id = nil

local function cancel_release()
  if release_id then clock.cancel(release_id); release_id = nil end
end

local function release_now()
  release_id = nil
  if #held_stack == 0 and not hold_on and current_note ~= nil then
    if arp_on then stop_arp() else engine.noteOff() end
    current_note = nil
  end
end

local function release_grace()
  return util.clamp((tick_sec or 0.02) * 13, 0.05, 0.8)
end

local function on_note_on(note, vel)
  cancel_release()
  local prev = current_note
  -- con HOLD, la primera tecla después de soltar todo reemplaza al acorde retenido
  local fresh = hold_on and #held_stack == 0 and prev ~= nil
  local added = hold_on and #held_stack > 0
  table.insert(held_stack, note)
  if added then
    -- con HOLD, una tecla más mientras hay otras apretadas se suma a lo
    -- retenido (aunque alguna ya se haya soltado)
    local dup = false
    for _, n in ipairs(arp_keys) do if n == note then dup = true end end
    if not dup then table.insert(arp_keys, note); table.sort(arp_keys) end
  else
    update_arp_keys()
  end
  -- modo acorde: manda la última tecla apretada (también si es más aguda);
  -- modo simple: suenan todas las apretadas y la más grave da el bajo
  local simple = pv("chord_on") == 1
  local low = simple and arp_keys[1] or note
  if low ~= prev or fresh or (simple and not arp_on and keys_sig() ~= voiced_sig) then
    current_note = low
    last_note = low
    current_vel = vel / 127
    if arp_on then
      if arp_clock_id == nil then start_arp_if_needed()
      else engine.padOn(note_to_hz(current_note - 24)) end
    else
      sound_chord(current_note)
    end
  end
  update_crackle()
end

local function on_note_off(note)
  for i = #held_stack, 1, -1 do
    if held_stack[i] == note then table.remove(held_stack, i); break end
  end
  -- con HOLD, soltar teclas no cambia nada: queda el acorde / las notas
  -- del arpegio tal como se apretaron
  if hold_on then update_crackle(); return end
  update_arp_keys()
  -- modo acorde: al soltar la que suena vuelve la última que sigue apretada;
  -- modo simple: soltar una de varias no redispara (cambia con la próxima tecla)
  local low = held_stack[#held_stack]
  if pv("chord_on") == 1 then low = (low ~= nil) and current_note or nil end
  if low == nil then
    if not hold_on and current_note ~= nil then
      if ext_clock_on() then
        cancel_release()
        local wait = release_grace()
        release_id = clock.run(function() clock.sleep(wait); release_now() end)
      else
        release_now()
      end
    end
  elseif low ~= current_note then
    current_note = low
    last_note = low
    if arp_on then engine.padOn(note_to_hz(current_note - 24))
    else sound_chord(current_note) end
  end
  update_crackle()
end

local function set_hold(on)
  hold_on = on
  hold_flash = PULSE
  if not on then cancel_release(); release_now() end
end

-- el clock MIDI solo empuja el arpegio: nunca dispara ni repite el acorde
local function midi_event(data)
  local msg = midi.to_msg(data)
  if msg.type == "clock" then
    local now = util.time()
    if last_midi_clock then
      local d = now - last_midi_clock
      if d > 0.002 and d < 0.25 then
        tick_sec = tick_sec and (tick_sec * 0.9 + d * 0.1) or d
      end
    end
    last_midi_clock = now
    if arp_on and arp_clock_id and current_note then
      local tps = ticks_per_step()
      ext_ticks = ext_ticks + 1
      if ext_ticks >= tps then
        ext_ticks = math.min(ext_ticks - tps, tps - 1)
        arp_step()
      end
    end
    return
  elseif msg.type == "start" then
    ext_ticks = 0
    step_i = 1
    return
  elseif msg.type == "stop" or msg.type == "continue" then
    return
  end
  local ch = params:get("midi_channel")
  if ch ~= 0 and msg.ch ~= ch then return end
  if msg.type == "note_on" and msg.vel > 0 then
    on_note_on(msg.note, msg.vel)
  elseif msg.type == "note_off" or (msg.type == "note_on" and msg.vel == 0) then
    on_note_off(msg.note)
  end
end

-- ============================================================
-- parámetros (se guardan solos en data/chordex80/estado.pset)
-- ============================================================

local STATE_FILE

local function add_params()
  params:add_separator("chordex_80", "CHORDEX 80")
  params:add_number("midi_channel", "canal MIDI (0=todos)", 0, 16, 0)
  params:add_option("midi_clock_div", "divisor reloj MIDI", {"1x", "2x", "4x", "8x"}, 3)
  params:add_option("model", "modelo", model_names, 1)
  params:add_option("d50_atk", "ataque D-50", {"aire", "pluck", "ninguno"}, 1)
  params:set_action("d50_atk", function(v) engine.d50atk(v - 1) end)
  -- al cambiar de modelo, lo que está sonando (también retenido o en
  -- arpegio) pasa al sinte nuevo
  params:set_action("model", function(v)
    engine.model(v - 1)
    if current_note then
      if arp_on then
        if arp_clock_id then
          engine.arpLegatoOff()
          engine.padOff()
          engine.padOn(note_to_hz(current_note - 24))
        end
      else
        voice_chord(current_note)
      end
    end
  end)
  params:add_option("chord", "acorde", chord_types, 1)
  params:set_action("chord", function()
    if current_note and not arp_on then sound_chord(current_note) end
  end)
  params:add_option("chord_on", "modo acorde", {"no", "sí"}, 2)
  params:set_action("chord_on", function()
    if current_note and not arp_on then sound_chord(current_note) end
  end)
  params:add_option("arp_pattern", "patrón arp", arp_pattern_names, 1)
  params:add_option("arp_rate", "velocidad arp", arp_rate_names, 3)
  params:add_control("arp_gate", "gate arp (1=legato)", controlspec.new(0, 1, "lin", 0, 0.75, ""))

  params:add_control("cutoff", "filtro", controlspec.new(150, 9000, "exp", 0, 2400, "Hz"))
  params:set_action("cutoff", function(v) engine.cutoff(v) end)
  params:add_control("res", "resonancia", controlspec.new(0, 3.6, "lin", 0, 1.0, ""))
  params:set_action("res", function(v) engine.res(v) end)

  for _, p in ipairs(P) do
    params:add_control(p.id, p.name, controlspec.new(p.min, p.max, "lin", 0, p.def, ""))
  end
  params:set_action("atk", function(v) engine.atk(v) end)
  params:set_action("rel", function(v) engine.rel(v) end)
  params:set_action("drive", function(v) engine.drive(v) end)
  params:set_action("shimmer", function(v) engine.shimmer(v ^ 3) end)  -- curva "embrague"
  params:set_action("wobble", function(v) engine.wobble(v) end)
  params:set_action("fatness", function(v) engine.fatness(v) end)

  params:add_control("space", "hall", controlspec.new(0, 0.6, "lin", 0, 0.22, ""))
  params:set_action("space", function(v) engine.space(v) end)
  params:add_control("gain", "volumen", controlspec.new(0, 1.5, "lin", 0, 1.0, ""))
  params:set_action("gain", function(v) engine.gain(v) end)
end

-- ============================================================
-- init / controles
-- ============================================================

local screen_metro
local splash_start = nil
-- primero la intro U-MA de particulas (la de uma_splash/splash), despues CHORDEX
local SPLASH_IN, SPLASH_HOLD, SPLASH_FADE = 0.5, 1.6, 0.7
local uma_intro = include("lib/uma_splash_particles")
local uma_sound = include("lib/uma_splash") -- base de la intro, maneja el sonido

local function skip_splash()
  if splash_start and util.time() - splash_start < uma_intro.DUR then uma_sound.sound_off() end
  splash_start = nil
end

function init()
  midi_in = {}
  for i = 1, #midi.vports do
    midi_in[i] = midi.connect(i)
    midi_in[i].event = midi_event
  end

  add_params()
  STATE_FILE = norns.state.data .. "estado.pset"
  if util.file_exists(STATE_FILE) then params:read(STATE_FILE) end
  params:bang()

  uma_sound.sound_on(norns.state.path .. "lib/uma_particles.wav")
  splash_start = util.time()
  screen_metro = metro.init(function() redraw() end, 1 / 24, -1)
  screen_metro:start()
end

function cleanup()
  if STATE_FILE then params:write(STATE_FILE, "chordex80") end
end

function enc(n, d)
  if splash_start then return end
  if n == 1 then
    if k2_held then
      params:set("arp_gate", util.clamp(params:get("arp_gate") + d * 0.02, 0, 1))
      k2_turned = true
    elseif k3_held then
      k3_turned = true
      params:set("model", util.clamp(pv("model") + (d > 0 and 1 or -1), 1, 3))
      model_flash = PULSE * 2
    else
      params:set("cutoff", util.clamp(pv("cutoff") * (1.05 ^ d), 150, 9000))
      filter_pulse = PULSE
    end
  elseif n == 2 then
    local dir = d > 0 and 1 or -1
    if k2_held then
      params:set("arp_pattern", ((pv("arp_pattern") - 1 + dir) % #arp_pattern_names) + 1)
      k2_turned = true
    elseif k3_held then
      k3_turned = true
      params:set("res", util.clamp(pv("res") + d * 0.05, 0, 3.6))
      filter_pulse = PULSE
    else
      focus_index = ((focus_index - 1 + dir) % 6) + 1
      param_pulse[focus_index] = PULSE
    end
  elseif n == 3 then
    if k2_held then
      params:set("arp_rate", util.clamp(pv("arp_rate") + (d > 0 and 1 or -1), 1, #arp_rate_names))
      k2_turned = true
    elseif k3_held then
      k3_turned = true
      params:set("chord", util.clamp(pv("chord") + (d > 0 and 1 or -1), 1, #chord_types))
    else
      local p = P[focus_index]
      params:set(p.id, util.clamp(pv(p.id) + d * p.step, p.min, p.max))
      param_pulse[focus_index] = PULSE
    end
  end
end

function key(n, z)
  -- K1 llega acá solo si se mantiene (el toque corto abre el menú de norns)
  if n == 1 then
    if z == 1 then
      if splash_start then skip_splash() end
      set_hold(not hold_on)
    end
  elseif n == 2 then
    if z == 1 then
      k2_held = true; k2_turned = false
    else
      if splash_start then skip_splash()
      elseif k2_held and not k2_turned then
        arp_on = not arp_on
        if arp_on then
          engine.noteOff()
          if current_note then start_arp_if_needed() end
        else
          stop_arp()
          if current_note then sound_chord(current_note) end
        end
      end
      k2_held = false
    end
  elseif n == 3 then
    k3_held = (z == 1)
    if z == 1 and splash_start then skip_splash() end
    if z == 1 then
      -- mantener K3 sin girar ningún encoder entra / sale del modo acorde
      k3_turned = false
      local press = util.time()
      k3_press = press
      clock.run(function()
        clock.sleep(K3_LONG)
        if k3_held and not k3_turned and k3_press == press then
          params:set("chord_on", 3 - params:get("chord_on"))
        end
      end)
    end
  end
end

-- ============================================================
-- GRÁFICOS — acumulador por nivel (mismo esquema que Glitch / sun_down)
-- ============================================================

local G = {}
do
local bt, b1, b2, b3, b4, bn = {}, {}, {}, {}, {}, {}
for lv = 1, 15 do bt[lv] = {}; b1[lv] = {}; b2[lv] = {}; b3[lv] = {}; b4[lv] = {}; bn[lv] = 0 end

local function add(lv, ty, a, b, c, d)
  lv = math.floor(lv + 0.5)
  if lv < 1 then return end
  if lv > 15 then lv = 15 end
  local n = bn[lv] + 1
  bn[lv] = n
  bt[lv][n] = ty; b1[lv][n] = a; b2[lv][n] = b; b3[lv][n] = c; b4[lv][n] = d
end

function G.px(lv, x, y) add(lv, 0, x, y) end
function G.line(lv, x1, y1, x2, y2) add(lv, 3, x1, y1, x2, y2) end
function G.rect(lv, x, y, w, h) add(lv, 4, x, y, w, h) end

function G.flush()
  local floor = math.floor
  for lv = 1, 15 do
    local n = bn[lv]
    if n > 0 then
      local T, A, B, C, D = bt[lv], b1[lv], b2[lv], b3[lv], b4[lv]
      screen.level(lv)
      local fills, strokes = false, false
      for k = 1, n do
        local ty = T[k]
        if ty == 0 then
          screen.pixel(floor(A[k]), floor(B[k])); fills = true
        elseif ty == 4 then
          screen.rect(floor(A[k]), floor(B[k]), C[k], D[k]); fills = true
        else
          strokes = true
        end
      end
      if fills then screen.fill() end
      if strokes then
        for k = 1, n do
          if T[k] == 3 then
            screen.move(floor(A[k]) + 0.5, floor(B[k]) + 0.5)
            screen.line(floor(C[k]) + 0.5, floor(D[k]) + 0.5)
          end
        end
        screen.stroke()
      end
      bn[lv] = 0
    end
  end
end
end

local BAYER = {{0, 8, 2, 10}, {12, 4, 14, 6}, {3, 11, 1, 9}, {15, 7, 13, 5}}
local function dith(d, x, y)
  return d > (BAYER[math.floor(x) % 4 + 1][math.floor(y) % 4 + 1] + 0.5) / 16
end

local HOR = 37          -- horizonte
local SX = 64           -- centro del sol

local stars = {}
for i = 1, 24 do
  stars[i] = {x = math.random(2, 126), y = math.random(1, HOR - 4), ph = math.random() * 6.28}
end

-- radio del sol según el filtro (escala exponencial, igual que E1)
local function sun_R()
  return 8 + 13 * math.log(pv("cutoff") / 150) / math.log(9000 / 150)
end

-- montañas a los costados del horizonte (alturas fijas)
local MTN = {}
do
  local h = {0, 2, 4, 3, 5, 3, 1, 2, 1, 0}
  for i = 1, #h do MTN[i] = h[i] end
end

-- iconos 3x3 de los 6 parámetros (columna de sliders estilo Juno)
local ICON = {
  {{0, 2}, {1, 1}, {2, 0}},                                   -- attack  /
  {{0, 0}, {1, 1}, {2, 2}},                                   -- decay   \
  {{0, 0}, {1, 0}, {2, 0}, {0, 1}, {2, 1}, {0, 2}, {2, 2}},   -- distorsión: onda cuadrada
  {{0, 0}, {2, 0}, {1, 1}, {0, 2}, {2, 2}},                   -- shimmer x
  {{0, 1}, {1, 0}, {2, 1}},                                   -- wobble  ^
  {{0, 0}, {1, 0}, {2, 0}, {0, 2}, {1, 2}, {2, 2}},           -- fatness =
}

local function norm(id)
  for _, p in ipairs(P) do
    if p.id == id then return (pv(id) - p.min) / (p.max - p.min) end
  end
  return 0
end

local function draw_sky(t)
  local sh = pv("shimmer")
  local nvis = 5 + math.floor(sh * 19)
  for i = 1, nvis do
    local s = stars[i]
    local tw = (math.sin(t * (1.2 + sh * 3) + s.ph) + 1) * 0.5
    G.px(1 + tw * (2 + sh * 9), s.x, s.y)
  end
  -- chispas de crackle alrededor del sol
  if crackle_amt > 0 then
    local R = sun_R()
    for i = 1, math.floor(crackle_amt * 7) do
      local a = math.random() * math.pi
      local r = R + 1 + math.random() * 5
      G.px(15, SX + math.cos(a) * r, HOR - math.sin(a) * r)
    end
  end
end

local function draw_sun(t)
  local R = sun_R()
  local lum = 0.4 + 0.6 * env
  local drv = pv("drive")
  local wob = pv("wobble")
  local fat = pv("fatness")
  local res = pv("res") / 3.6
  local stripe_top = 0.35 + 0.45 * drv                   -- desde dónde hay franjas
  local ph = grid_ph * 4

  -- halo (resonancia): anillo tramado alrededor del sol
  local hw_ = 1 + res * 5 + (k3_held and 1 or 0)
  local hl = (k3_held and 9 or 4) * (0.5 + 0.5 * lum)
  for y = math.floor(HOR - R - hw_), HOR - 1 do
    local dy = HOR - y
    for x = math.floor(SX - R - hw_), math.ceil(SX + R + hw_) do
      local dx = x - SX
      local dd = math.sqrt(dx * dx + dy * dy) - R
      if dd > 0.5 and dd < hw_ then
        if dith((1 - dd / hw_) * (0.25 + res * 0.6), x, y) then G.px(hl, x, y) end
      end
    end
  end

  for y = math.floor(HOR - R), HOR - 1 do
    local dy = HOR - y
    local hw = math.sqrt(math.max(0, R * R - dy * dy))
    local fr = dy / R
    local gap = false
    if fr < stripe_top then
      local depth = (stripe_top - fr) / stripe_top           -- 0 arriba .. 1 horizonte
      local period = 5 - math.floor(depth * 2)
      gap = ((dy + math.floor(ph)) % period) < (1 + depth * 1.6)
    end
    if not gap and hw >= 0.5 then
      local ox = math.floor(math.sin(y * 0.7 + t * 5) * wob * 2.2 + 0.5)
      G.line((5 + 10 * fr) * lum, SX - hw + ox, y, SX + hw + ox, y)
    end
    -- chorus: dos "fantasmas" del borde que se separan y vuelven
    if fat > 0.02 and y % 2 == 0 then
      local sep = 1 + fat * 3 * (0.6 + 0.4 * math.sin(t * 3.2))
      G.px(2 + fat * 2, SX - hw - sep, y)
      G.px(2 + fat * 2, SX + hw + sep, y)
    end
  end
end

local function draw_ground(t)
  -- montañas
  for side = 0, 1 do
    for i = 1, #MTN - 1 do
      local x1 = side == 0 and 50 - (i - 1) * 1.6 or 127 - (i - 1) * 4
      local x2 = side == 0 and 50 - i * 1.6 or 127 - i * 4
      G.line(3, x1, HOR - 1 - MTN[i], x2, HOR - 1 - MTN[i + 1])
    end
  end
  -- horizonte
  G.line(5 + 10 * filter_pulse / PULSE, 0, HOR, 127, HOR)

  local glum = 0.55 + 0.8 * flash + 0.3 * env
  -- líneas de fuga
  for k = -7, 7 do
    local lv = (k == 0) and 0 or (2 + glum * 1.5)
    G.line(lv, SX + k * 3, HOR + 1, SX + k * 24, 63)
  end
  -- líneas horizontales que avanzan
  local N = 7
  for i = 0, N - 1 do
    local tt = ((i + grid_ph) % N) / N
    local y = HOR + 1 + (63 - HOR - 1) * tt * tt
    G.line((1 + tt * 6) * glum, 0, y, 127, y)
  end
  -- luces en la ruta (cada nota que suena)
  for _, s in ipairs(streaks) do
    local z1, z0 = s.z, math.max(0, s.z - 0.16)
    local p1, p0 = z1 * z1, z0 * z0
    local x1 = SX + s.lane * (2 + 22 * p1)
    local x0 = SX + s.lane * (2 + 22 * p0)
    local y1 = HOR + 1 + 26 * p1
    local y0 = HOR + 1 + 26 * p0
    G.line(s.lv * (1 - z1 * 0.35), x0, y0, x1, y1)
  end
end

-- acorde: tónica grande + sufijo, teclado de una octava, glifo del arpegio
local function draw_chord_text(t)
  local root = current_note or last_note
  local cname = chord_name()
  local lit = (current_note ~= nil)
  local blink = (math.floor(t * 6) % 2 == 0)
  if root then
    local lv = lit and 15 or 4
    screen.font_face(1)
    screen.font_size(24)
    screen.level(lv)
    local rn = note_names[(root % 12) + 1]
    screen.move(2, 16)
    screen.text(rn)
    local w = screen.text_extents(rn)
    screen.font_size(8)
    screen.level(k3_held and (blink and 15 or 8) or (lit and 11 or 3))
    screen.move(3 + w, 16)
    if pv("chord_on") == 2 or k3_held then
      screen.text(chord_suffix[cname] ~= "" and chord_suffix[cname] or (k3_held and "maj" or ""))
    end
  elseif k3_held then
    screen.font_face(1)
    screen.font_size(8)
    screen.level(blink and 15 or 8)
    screen.move(2, 16)
    screen.text(cname)
  end
end

local function draw_chord(t)
  local root = current_note or last_note
  local cname = chord_name()
  local lit = (current_note ~= nil)
  local blink = (math.floor(t * 6) % 2 == 0)

  -- teclado escalonado: negras arriba, blancas abajo
  local pcs = {}
  local base = root or 0
  if root or k3_held then
    for i, iv in ipairs(k3_held and four_tone_intervals(cname) or chord_ivs()) do
      pcs[(base + iv) % 12] = (i == 1) and 15 or 10
    end
  end
  local black = {[1] = true, [3] = true, [6] = true, [8] = true, [10] = true}
  for pc = 0, 11 do
    local x = 2 + pc * 3
    local on = pcs[pc]
    local lv = on and (lit and on or on * 0.45) or (black[pc] and 1 or 2)
    if black[pc] then G.rect(lv, x, 20, 2, 4) else G.rect(lv, x, 24, 2, 5) end
  end

  -- glifo del arpegio: los pasos del patrón como escalera de puntos
  local pat = pv("arp_pattern")
  local order
  if pat == 6 then
    order = {}
    for i = 1, 6 do order[i] = (math.floor(t * 4) * 7 + i * 5) % 4 + 1 end
  else
    order = step_order(pat, pat == 7 and 8 or 4)
  end
  local top = (pat == 7) and 8 or 4
  local base_lv = k2_held and (blink and 15 or 8) or (arp_on and 6 or 3)
  for i, idx in ipairs(order) do
    local x = 2 + (i - 1) * 3
    local y = 35 - (idx - 1) * (3 / (top - 1))
    local cur = arp_on and arp_step_lit > 0 and idx == arp_step_lit
    G.rect(cur and 15 or base_lv, x, math.floor(y), 2, 1)
  end
  -- velocidad: 1..4 pixeles a la derecha del glifo
  local rx = 2 + #order * 3 + 1
  for i = 1, pv("arp_rate") do
    G.px(k2_held and 12 or (arp_on and 5 or 2), rx + (i - 1) * 2, 35)
  end
end

-- columna de 6 sliders tipo panel Juno
local function draw_sliders(t)
  for i, p in ipairs(P) do
    local x = 100 + (i - 1) * 5
    local focused = (focus_index == i)
    local pl = param_pulse[i]
    local lv = focused and 15 or (pl > 0 and util.linlin(0, PULSE, 3, 12, pl) or 3)
    for y = 5, 23, 2 do G.px(focused and 4 or 1, x + 1, y) end
    local v = norm(p.id)
    local cy = math.floor(22 - v * 17 + 0.5)
    G.rect(lv, x, cy, 3, 2)
    for _, q in ipairs(ICON[i]) do G.px(focused and 12 or 3, x + q[1], 26 + q[2]) end
  end
  -- retener (K1 mantenido): puntito a la izquierda de los faders,
  -- vacío y tenue = libre, lleno y encendido = el acorde queda sonando
  local lk = hold_on and (current_note and 13 or 8) or 3
  lk = math.min(15, lk + hold_flash * 0.25)
  G.px(lk, 95, 2) G.px(lk, 94, 3) G.px(lk, 96, 3) G.px(lk, 95, 4)
  if hold_on then G.px(lk, 95, 3) end
  -- modelo: 3 puntos arriba de los sliders
  for m = 1, 3 do
    G.rect(pv("model") == m and 12 or 2, 108 + (m - 1) * 5, 1, 2, 1)
  end
end

-- al cambiar de modelo aparece su dibujo arriba al centro y se desvanece
local ICON_LV = {["#"] = 15, ["+"] = 9, ["."] = 4}
local function draw_model_name()
  if model_flash <= 0 then return end
  local a = math.min(1, model_flash / PULSE)
  local rows = MODEL_ICON[model_names[pv("model")]]
  local w, h = #rows[1], #rows
  local x0, y0 = math.floor(SX - w / 2), 1
  screen.level(0)
  screen.rect(x0 - 2, y0 - 1, w + 4, h + 2)
  screen.fill()
  for ch, l in pairs(ICON_LV) do
    local lv = math.floor(l * a + 0.5)
    if lv > 0 then
      screen.level(lv)
      for y = 1, h do
        local r = rows[y]
        for x = 1, w do
          if r:sub(x, x) == ch then screen.rect(x0 + x - 1, y0 + y - 1, 1, 1) end
        end
      end
      screen.fill()
    end
  end
end

-- ---- splash (idéntico a Chordex2) ----
local function draw_splash(alpha)
  screen.clear()
  screen.level(math.max(0, math.min(15, math.floor(15 * alpha))))
  screen.font_face(1)
  screen.font_size(16)
  local txt = "C H O R D E X"
  local w = screen.text_extents(txt)
  screen.move(64 - w / 2, 34)
  screen.text(txt)
  screen.move(64 - 20, 42)
  screen.line(64 + 20, 42)
  screen.stroke()
  screen.update()
end

local function tick(dt)
  frame = frame + 1
  for i = 1, 6 do param_pulse[i] = math.max(0, param_pulse[i] - 1) end
  filter_pulse = math.max(0, filter_pulse - 1)
  model_flash = math.max(0, model_flash - 1)
  hold_flash = math.max(0, hold_flash - 1)

  local sounding = current_note ~= nil
  if sounding then
    env = math.min(1, env + dt / math.max(0.02, pv("atk")))
  else
    env = math.max(0, env - dt / math.max(0.05, pv("rel")))
  end
  flash = math.max(0, flash - dt * 3)

  -- grilla: con arpegio va a una línea por negra; si no, deriva lenta
  local speed
  if arp_on and sounding then
    speed = 1 / beat_seconds()
  else
    speed = 0.25 + env * 0.5
  end
  grid_ph = (grid_ph + dt * speed) % 7

  for i = #streaks, 1, -1 do
    local s = streaks[i]
    s.z = s.z + dt * (0.9 + (sounding and 0.3 or 0))
    if s.z > 1.1 then table.remove(streaks, i) end
  end
end

function redraw()
  local now = util.time()
  if splash_start then
    local e = now - splash_start
    if e < uma_intro.DUR then
      uma_intro.render(e)
      screen.update()
      return
    end
    e = e - uma_intro.DUR
    local t1 = SPLASH_IN
    local t2 = t1 + SPLASH_HOLD
    local t3 = t2 + SPLASH_FADE
    if e < t1 then draw_splash(e / SPLASH_IN) return
    elseif e < t2 then draw_splash(1) return
    elseif e < t3 then draw_splash(1 - (e - t2) / SPLASH_FADE) return
    else splash_start = nil end
  end

  local dt = last_t and math.min(0.2, now - last_t) or 1 / 24
  last_t = now
  tick(dt)

  screen.clear()
  draw_sky(now)
  draw_sun(now)
  draw_ground(now)
  draw_sliders(now)
  draw_chord(now)
  G.flush()
  draw_chord_text(now)
  draw_model_name()
  screen.update()
end
