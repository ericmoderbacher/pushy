-- pushy
--
-- use an ableton push 1
-- on norns, i insist!
--
-- ericmoderbacher
-- 7/9/2020

MusicUtil = require "musicutil" --from https://monome.org/docs/norns/reference/params#example
math.randomseed(os.time()) --from https://monome.org/docs/norns/reference/params#example

local pushyLib = include("lib/pushyINC")

local pushy = {}
pushy.__index = pushy


function initParams() --from https://monome.org/docs/norns/reference/params#example
  params:add_separator("test script")
  params:add_group("example group",3)
  for i = 1,2 do
    params:add{
      type = "option",
      id = "example "..i,
      name = "parameter "..i,
      options = {"hi","hello","bye"},
      default = i
    }
  end
  params:add_number(
          "note_number", -- id
          "notes with wrap", -- name
          0, -- min
          127, -- max
          60, -- default
          function(param) return MusicUtil.note_num_to_name(param:get(), true) end, -- formatter
          true -- wrap
  )
  local groceries = {"green onions","shitake","brown rice","pop tarts","chicken thighs","apples"}
  params:add_option("grocery list","grocery list",groceries,1)
  params:add_control("frequency","frequency",controlspec.FREQ)
  params:add_file("clip sample", "clip sample")
  params:set_action("clip sample", function(file) load_sample(file) end)
  params:add_text("named thing", "my name is:", "")
  params:add_taper("taper_example", "taper", 0.5, 6.2, 3.3, 0, "%")
  params:add_separator()
  params:add_trigger("trig", "press K3 here")
  params:set_action("trig",function() print("boop!") end)
  params:add_binary("momentary", "press K3 here", "momentary")
  params:set_action("momentary",function(x) print(x) end)
  params:add_binary("toggle", "press K3 here", "toggle",1)
  params:set_action("toggle",function(x)
    if x == 0 then
      params:show("secrets")
    elseif x == 1 then
      params:hide("secrets")
    end
    _menu.rebuild_params()
  end)
  params:add_text("secrets","secret!!")
  params:hide("secrets")
  --params:print()
  random_grocery()
end

function init()
  initParams() --set up dummy params to display and edit with the push

  pushyLib.testReturn()
  pushyLib.init()
  print("test print pushy lib: ")
  --for i,v in ipairs(pushyLib) do print(i,v) end
  --pushyLib.printParams()

end


function load_sample(file)--from https://monome.org/docs/norns/reference/params#example
  print(file)
end

function random_grocery()--from https://monome.org/docs/norns/reference/params#example
  params:set("grocery list",math.random(params:get_range("grocery list")[1],params:get_range("grocery list")[2]))
end


return pushy