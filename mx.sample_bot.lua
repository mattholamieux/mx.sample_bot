-- mx.sample_bot v1.1.0
-- Create your own sample packs 
-- for mx.samples
-- 
-- Choose auto sampling for
-- midi devices
--
-- manual sampling for
-- other things

function key(n,z)
  if z==1 then
    if n == 2 then
      norns.script.clear()
      norns.script.load('code/sample_bot_playground/lib/manual_sampling.lua')
    elseif n == 3 then
      norns.script.clear()
      norns.script.load('code/sample_bot_playground/lib/auto_sampling.lua')
    end
  end
end

function redraw()
  screen.clear()
  screen.level(15)
  screen.move(20,10)
  screen.text("Select Sampling Mode")
  screen.move(5, 40)
  screen.text('k2: manual')
  screen.move(90, 40)
  screen.text('k3: auto')
  screen.update()
end