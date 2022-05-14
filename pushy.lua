-- pushy
--
-- use an ableton push 1
-- on norns, i insist!
--
-- ericmoderbacher
-- 7/9/2020


local setupParams = include("setupDemoParams")
local pushyLib = include("lib/pushyINC")


function init()

  --set up dummy params to display and edit with the push
  initParams() --in setupDemoParams.lua
  
  --sets up the pushy library
  --you must have all params added before calling this init() (for now)
  pushyLib.init()
  
  --rest of init would go here, but this is a very simple example so nothing is here yet.

end