-- mx.sample_bot v1.0.0
-- Create your own sample packs 
-- for mx.samples
-- 
-- Use enc2 & enc3 to
-- adjust settings
--
-- k2: Audition
-- k3: Record
-- k1+k2: Preview
-- k1+k3: Save

textentry = require('textentry')

function init()
  start_note = 60
  end_note = 72
  sample_every = 3
  sustain = 0.1
  release = 1.5
  vel_layers = 1
  min_vel = 120
  max_vel = 127
  variation = 1
  midi_devices = {}
  midi_device = 1
  midi_channel = 1
  selector = 2
  offset = 0
  isRecording = false
  isAuditioning = false
  isPreviewing = false
  velocity = {min_vel}
  counter = 1
  saved = "..."
  alt = false
  last_amp = 0
  calculateTime()
  sc_init() -- initialize softcut settings
  for i = 1,#midi.vports do -- query all ports
    table.insert(midi_devices,"port "..i..": "..util.trim_string_to_width(midi.vports[i].name,48)) -- register its name
  end
  out_midi = midi.connect(midi_device)
end

function sequence() -- play back the defined sequence of notes
  note_number = 0
  clock.sleep(0.05)
  while note <= end_note do
    while counter <= #velocity do
      note_number = note_number + 1
      redraw()
      out_midi:note_on(note, velocity[counter], midi_channel)
      clock.sleep(sustain)
      out_midi:note_off(note, velocity[counter], midi_channel)
      clock.sleep(release)
      counter = counter + 1
    end
    note = note + sample_every
    counter = 1
  end
  for i=1, 2 do -- stop recording
    softcut.rec(i,0)
  end
  isRecording = false
  redraw()
end

function key(n,z)
  if n==1 then -- k1 actions
    if z==1 then
      alt = true
    else 
      alt = false
      if isPreviewing then
          for i=1, 2 do
          softcut.play(i,0)
          end
        isPreviewing = false
      end
    end
  end
  
  if n==2 and z==1 then -- k2 actions
    if alt then
      if not isPreviewing then
        isPreviewing = true
        for i=1, 2 do -- playback the recording 
          softcut.loop_start(i,1)
          softcut.loop_end(i,rec_length+1.05)
          softcut.position(i,1)
          softcut.play(i,1)
        end
      end
    elseif save_error or save_success then
      save_error = false
      save_success = false
    else 
      if isRecording == false then
        if isAuditioning == true then -- if currently auditioning, stop and return to main screen
          clock.cancel(play)
          out_midi:note_off(note,min_vel, midi_channel)
          isAuditioning = false
        else -- otherwise, audition the sequence
          note = start_note
          play = clock.run(sequence)
          isAuditioning = true
        end
      end
    end
  end
  
  if n==3 and z==1 then -- k3 actions
    if alt then
      if isPreviewing then
          for i=1, 2 do
          softcut.play(i,0)
          end
        isPreviewing = false
      end
      alt = false
      textentry.enter(save_pack, "", "enter name of sample pack")
    elseif save_error or save_success then
      save_error = false
      save_success = false
    else
      if isAuditioning == false then
        if isRecording then
          clock.cancel(play)
          out_midi:note_off(note,min_vel, midi_channel)
          isRecording = false
        else
          note = start_note
          sc_begin_recording()
          play = clock.run(sequence)
          isRecording = true
        end
      end
    end
  end
  redraw()
end

function enc(n,d)
    if n==2 then -- e2 actions (moving the selector)
        selector = util.clamp(selector +d, 2, 13)
        if selector > 4 then
          offset = (selector - 5) * 10
        end
    end
    if n==3 then -- e3 actions 
      if selector == 2 then
          midi_device = util.clamp(midi_device + d, 1, #midi_devices)
          out_midi = midi.connect(midi_device)
      elseif selector == 3 then
        midi_channel = util.clamp(midi_channel + d, 1, 16)
      elseif selector == 4 then
        local val = 1
        val = util.clamp(val + d, 1, 2)
        sc_set_input(val)
      elseif selector == 5 then
        start_note = util.clamp(start_note + d, 0, end_note)
      elseif selector == 6 then
        end_note = util.clamp(end_note + d, start_note, 127)
      elseif selector == 7 then
        sample_every = util.clamp(sample_every + d, 1, (end_note-start_note))
      elseif selector == 8 then
        local decimal = d/100
        sustain = util.clamp(sustain + decimal, 0, 10)
      elseif selector == 9 then
        local decimal = d/100
        release = util.clamp(release + decimal, 0, 100)
      elseif selector == 10 then
        variation = util.clamp(variation + d, 1, 5)
      elseif selector == 11 then
        vel_layers = util.clamp(vel_layers + d, 1, 5)
        calculateVelocity(vel_layers)
      elseif selector == 12 then
        min_vel = util.clamp(min_vel + d, 0, max_vel)
        calculateVelocity(vel_layers)
      elseif selector == 13 then
        max_vel = util.clamp(max_vel + d, min_vel, 127)
        calculateVelocity(vel_layers)
      end
      calculateTime()
    end
    redraw()
end

function redraw()
  screen.clear()
  if alt == true then
    screen.move(10,10)
    screen.text("k2 : preview | k3 : save")
      screen.move(10,20)
      screen.text('----------------------------')
  else
    if isRecording == true then
      screen.move(10,10)
      screen.text("recording")
      screen.move(10,20)
      screen.text('----------------------------')
      screen.move(10,30)
      screen.text(note_number.." / "..(num_notes*vel_layers))
      screen.move(10,40)
      screen.text("note: "..note)
      screen.move(10,50)
      screen.text("velocity: "..velocity[counter])
      screen.move(85,60)
      screen.text("k3 to exit")
    elseif isAuditioning == true then
      screen.move(10,10)
      screen.text("auditioning")
      screen.move(10,20)
      screen.text('----------------------------')
      screen.move(10,30)
      screen.text(note_number.." / "..(num_notes*vel_layers))
      screen.move(10,40)
      screen.text("note: "..note)
      screen.move(10,50)
      screen.text("velocity: "..velocity[counter])
      screen.move(85,60)
      screen.text("k2 to exit")
    elseif save_error then
      screen.move(10,20)
      screen.text("could not find")
      screen.move(10,30)
      screen.text("dust/audio/mx.samples")
    elseif save_success then
      screen.move(10,20)
      screen.text("sample pack saved at")
      screen.move(10,30)
      screen.text("dust/audio/mx.samples")
    else
      screen.move(10,10 - offset)
      screen.text("k2 : audition | k3 : record")
      screen.move(10,20 - offset)
      screen.text('----------------------------')
      screen.move(10,30 - offset)
      screen.text("midi device: "..midi_devices[midi_device])
      screen.move(10,40 - offset)
      screen.text("midi channel: "..midi_channel)
      screen.move(10,50 - offset)
      screen.text("input: "..input)
      screen.move(10,60 - offset)
      screen.text("start note: "..start_note)
      screen.move(10,70 - offset)
      screen.text("end note: "..end_note)
      screen.move(10,80 - offset)
      screen.text("sample every: "..sample_every)
      screen.move(10,90 - offset)
      screen.text("note sustain: "..sustain)
      screen.move(10,100 - offset)
      screen.text("note release: "..release)
      screen.move(10,110 - offset)
      screen.text("variation: "..variation)
      screen.move(10,120 - offset)
      screen.text("velocity layers: "..vel_layers)
      screen.move(10,130 - offset)
      if (vel_layers < 2) then
        screen.text("velocity: "..min_vel)
      else 
        screen.text("min velocity: "..min_vel)
        screen.move(10,140 - offset)
        screen.text("max velocity: "..max_vel)
      end
      screen.move(0, ((selector*10)+10)-offset) -- draw arrow indicator
      screen.text(">")
    end
  end
  screen.update()
end

function calculateVelocity(layers)
 if layers == 1 then
   velocity = {min_vel}
 elseif layers == 2 then
    velocity = {min_vel, max_vel}
 else
   local dist = max_vel - min_vel
   local step = math.floor(dist/(layers-1))
   velocity = {}
   for i=1, layers-1 do
    velocity[i] = min_vel + (step* (i-1))
    table.insert(velocity, max_vel)
    tab.print(velocity)
  end
 end
end

function calculateTime()
  num_notes = math.floor((end_note - start_note) / sample_every) + 1
  rec_length = (num_notes * vel_layers) * (sustain + release)
  print(rec_length)
end

function save_pack(txt)
  if txt ~= nil and txt ~= "" then
    if util.file_exists(_path.audio..'mx.samples') then
      local dir = _path.audio..'mx.samples/'..txt..'/'
      if not util.file_exists(dir) then
          util.make_dir(dir)
      end
      local note = start_note
      local file_length = sustain + release
      local file_start = 1.05
      while note <= end_note do -- notes while loop
        while counter <= #velocity do -- velocity layer while loop
          print(note.."."..counter.."."..vel_layers..".1.0.wav")
          local file = note.."."..counter.."."..vel_layers.."."..variation..".0.wav"
          softcut.buffer_write_stereo(dir..file,file_start,file_length)
          counter = counter + 1
          file_start = file_start + file_length
        end
      note = note + sample_every
      counter = 1
      end
      save_success = true
    else
      save_error = true
    end
  redraw()
  end
end

function sc_init()
  audio.level_adc_cut(1)
  sc_stereo()
  softcut.buffer_clear()
  for i = 1, 2 do
    softcut.enable(i, 1)
    softcut.level(i, 1)
    softcut.buffer(i, i)
    softcut.rate(i,1)
    softcut.loop_start(i,1)
    softcut.loop_end(i,300)
    softcut.loop(i, 0)
    softcut.position(i, 1)
    softcut.rec_level(i,1)
    softcut.pre_level(i,0)
    softcut.rec(i,0)
  end
  softcut.pan(1, -1)
  softcut.pan(2, 1)
end

function sc_stereo()
  softcut.level_input_cut(1, 1, 1)
  softcut.level_input_cut(2, 1, 0)
  softcut.level_input_cut(1, 2, 0)
  softcut.level_input_cut(2, 2, 1)
  input = "stereo"
end

function sc_mono()
  softcut.level_input_cut(1, 1, 1)
  softcut.level_input_cut(2, 1, 0)
  softcut.level_input_cut(1, 2, 1)
  softcut.level_input_cut(2, 2, 0)
  input = "mono"
end

function sc_set_input(n)
  if n == 1 then
    sc_stereo()
  else
    sc_mono()
  end
end

function sc_begin_recording()
  softcut.buffer_clear()
  for i=1, 2 do
    softcut.position(i, 1)
    softcut.rec(i,1)
  end
end