-- pushy
--
-- use an ableton push 1
-- on norns, i insist!
--
-- ericmoderbacher
-- 7/9/2020

local pushyLib = include("lib/pushyINC")

local pushy = {}
pushy.__index = pushy


function init()
  pushyLib.testReturn()
  pushyLib.init()
  print("test print pushy lib: ")
  --for i,v in ipairs(pushyLib) do print(i,v) end
  --pushyLib.printParams()

end

return pushy