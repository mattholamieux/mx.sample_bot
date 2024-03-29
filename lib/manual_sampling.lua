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
musicUtil = require("musicutil")
-- print(musicutil.note_nums_to_names(60))

function init()
  note = 60
  note_name = musicUtil.note_nums_to_names({note}, true)[1]
  vel_layers = 1
  velocity_num = 1
  variation = 1
  selector = 2
  offset = 0
  rec_start = 0
  rec_length = 0
  isRecording = false
  isAuditioning = false
  isPreviewing = false
  isArmed = false
  counter = 1
  saved = "..."
  alt = false
  pack_name = ""
  sc_init() -- initialize softcut settings
  
  p = poll.set("amp_in_l")
  p.callback = function(val) 
    -- print("in > "..string.format("%.3f",val)) 
    if val > 0.001 and isArmed then
      rec_start = rec_length + 1
      print('begin recording')
      isArmed = false
      redraw()
      -- sc_begin_recording()
    end
  end
  p.time = 0.01
  p:start()
  clock.run(name_pack)
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
          print('play')
          softcut.loop_start(i,rec_start)
          softcut.loop_end(i,rec_length+rec_start)
          softcut.position(i,rec_start)
          softcut.play(i,1)
        end
      end
    elseif save_error or save_success then
      save_error = false
      save_success = false
    else 
      if isRecording == false then
        -- main k2 action
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
      save_pack()
    elseif save_error or save_success then
      save_error = false
      save_success = false
    elseif isAuditioning == false then
        if isRecording then
          sc_stop_recording()
        else
          sc_begin_recording()
          -- isArmed = true
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
        local val = 1
        val = util.clamp(val + d, 1, 2)
        sc_set_input(val)
      elseif selector == 3 then
        note = util.clamp(note + d, 0, 127)
        note_name = musicUtil.note_nums_to_names({note}, true)[1]
      elseif selector == 4 then
        velocity_num = util.clamp(velocity_num + d, 0, vel_layers)
      elseif selector == 5 then
        vel_layers = util.clamp(vel_layers + d, 1, 5)
      elseif selector == 6 then
        variation = util.clamp(variation + d, 1, 5)
      elseif selector == 7 then
        
      elseif selector == 8 then

      end
    end
    redraw()
end

function redraw()
  screen.clear()
  -- if pack_name ~= "" then
    if alt == true then
      screen.move(10,10)
      screen.text("k2 : preview | k3 : save")
        screen.move(10,20)
        screen.text('----------------------------')
    else
      if isRecording == true then
        screen.move(10,10)
        if isArmed then
          screen.text("armed")
        else
          screen.text("recording")
        end
        screen.move(10,20)
        screen.text('----------------------------')
        screen.move(85,60)
        screen.text("k3 to end recording")
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
        screen.text("input: "..input)
        screen.move(10,40 - offset)
        screen.text("note: "..note_name)
        screen.move(10,50 - offset)
        screen.text("velocity number: "..velocity_num)
        screen.move(10,60 - offset)
        screen.text("velocity layers: "..vel_layers)
        screen.move(10,70 - offset)
        screen.text("variation: "..variation)
        screen.move(10,80 - offset)
        screen.text("name pack "..pack_name)
        screen.move(0, ((selector*10)+10)-offset) -- draw arrow indicator
        screen.text(">")
      end
    end
  -- end
  screen.update()
end

function save_pack()
  print('beep')
  if pack_name ~= nil and pack_name ~= "" then
    if util.file_exists(_path.audio..'mx.samples') then
      local dir = _path.audio..'mx.samples/'..pack_name..'/'
      if not util.file_exists(dir) then
          util.make_dir(dir)
      end
      
      local file = note.."."..velocity_num.."."..vel_layers.."."..variation..".0.wav"
      print("saved "..file)
      softcut.buffer_write_stereo(dir..file,rec_start,(rec_length-rec_start))
      
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
    softcut.position(i, rec_start)
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

function count()
  while true do
    clock.sleep(0.01)
    rec_length = rec_length + 0.01
  end
end

function sc_arm_recording()
  isArmed = true
end


function sc_begin_recording()
  print('record')
  isArmed = true
  softcut.buffer_clear()
  rec_length = 0
  play = clock.run(count)
  for i=1, 2 do
    softcut.position(i, 1)
    softcut.rec(i,1)
  end
  isRecording = true
  redraw()
end

function sc_stop_recording()
  print('stop record')
  for i=1, 2 do -- stop recording
    softcut.rec(i,0)
  end
  isRecording = false
  clock.cancel(play)
  print(rec_length)
  redraw()
end

function name_pack()
  clock.sleep(0.1)
  textentry.enter(
    function(x) 
      if x ~= nil then 
        pack_name =x 
      end
    end, "", "enter name of sample pack")
end
