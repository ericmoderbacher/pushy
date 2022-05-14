--
-- Created by IntelliJ IDEA.
-- User: eric moderbacher
-- Date: 7/15/2020
-- Time: 12:23 PM
-- To change this template use File | Settings | File Templates.
--

local midi_out = midi.connect(1)
local midi_in = midi.connect(2)

local sliderChars = {empty=6,left=3,right=4,center=124}

local lcdLines = {{dirty=true, elementsMoved = false, message={}},{dirty=true, elementsMoved = false, message={}},{dirty=true, elementsMoved = false, message={}},{dirty=true, elementsMoved = false, message={}} }
local sliders = {}
local texts = {}
local lineToBeRefreshed = 1 -- the screen cant be updated all at once so instead of adding logic to wait before sending the next line we will just do it like this
local numberOfCharsPerLine = 68

local numberOfParams = nil
local currentParamID = 1

local PUSH_SCREEN_FRAMERATE = 40

-- Chain a new action onto a paramset (even if one isn't already set)
-- written by awwaiid and really helps keep this project clean
params.append_action = function(self, index, new_action)
  local current_action = self:lookup_param(index).action or function() end
  self:set_action(index, function()
    current_action()
    new_action()
  end)
end
params.prepend_action = function(self, index, new_action)
  local current_action = self:lookup_param(index).action or function() end
  self:set_action(index, function()
    new_action()
    current_action()
  end)
end

local pushyLib = {}
--pushyLib.__index = pushyLib

--used to send the midi sysex message to the push
--used in this patch to set led colors and control the screen
local function send_sysex(m, d)
  --given to me by zebra on lines
  m:send{0xf0}
  for i,v in ipairs(d) do
      m:send{d[i]}
  end
  m:send{0xf7}
end


local ParamSetTYPES = {
[0] = "tSEPARATOR",
"tNUMBER",
"tOPTION",
"tCONTROL",
"tFILE",
"tTAPER",
"tTRIGGER",
"tGROUP",
"tTEXT",
"tBINARY",
"sets"
 }

local function setupEmptyLine(lineNumber)
  header = {71, 127, 21, (23 + lineNumber), 0, 69, 0}
  for i=1,7,1 do
    lcdLines[lineNumber].message[i]=header[i]
  end  
  for i=8,75,1 do 
    lcdLines[lineNumber].message[i]=32
  end
end

local function setEmptyScreen()
  print("trying to set screen empty")
  for i=1,4,1 do
      setupEmptyLine(i)
      lcdLines[i].dirty = true
  end
  pushScreenDirty = true
end

function pushyLib.countParams()
  count = 0
  for i, v in ipairs(params.params) do
    count = count + 1
  end
  numberOfParams = count
end


--eventually just debugging code for understanding how to use the params lib
function pushyLib.printParams()
  print("These are the current params: ")
    for i, v in ipairs(params.params) do
    id = params:get_id(i)
    if id == nil then id = 'nil' end --because you cant use concatination operator on nil
     
    value = params:get(i)
    if value == nil then value = 'nil' end --because you cant use concatination operator on nil
    print(i)
    print(i .. ' ' .. id .. ' type number '.. params:t(i) .. 'type string ' .. ParamSetTYPES[params:t(i)] .. ' ' .. params:string(i) .. ' ' .. value .. ' ' )
        
        
    if params:get_id(i) ~= nil then
      print('what?')
      --params:get_raw(i):print() 
      end
    end
end

local function lcdRedraw(line)
  if lcdLines[line].elementsMoved then
    setupEmptyLine(line)
    for i,v in ipairs(sliders) do
      if (sliders[i].line == line) then sliders[i].dirty = true end
    end
    lcdLines[line].elementsMoved = false
  end  
  for i,v in ipairs(sliders) do
    if (sliders[i].line == line and sliders[i].dirty)  then
      sliders[i]:redraw()
      sliders[i].dirty = false
    end
  end
    for i,v in ipairs(texts) do
    if (texts[i].line == line and texts[i].dirty)  then
      texts[i]:redraw()
      texts[i].dirty = false
    end
  end

  send_sysex(midi_out, lcdLines[line].message)
end

--this breaks out 
local function enc(n, delta)
  print("encoder number:" .. n .. " Delta:" .. delta)
  
  --the encoders at the top are cc numbers 71-79 numbered from left to right (79 is the extra one)
  --the two smaller encoders are numbers 14 and 15 also left to right
  if n == 71 then
    sliders[1]:set_value_delta(delta)
    lcdLines[sliders[1].line].dirty = true
  end
  -- removing this because i dont want the sliders to overlap
  -- esm todo add a max width for the sliders so that overlap isnt a thing
  -- if n == 72 then
  --   sliders[1]:changeWidth(delta)
  --   lcdLines[sliders[1].line].dirty = true
  -- end
  if n == 14 then
    nextID = currentParamID + delta
    if nextID >= numberOfParams then nextID = numberOfParams end
    if nextID <= 1 then nextID = 1 end
    currentParamID = nextID
    texts[2].entry = params:get_id(currentParamID)
    texts[2].dirty = true
    lcdLines[texts[2].line].dirty = true
    pushScreenDirty = true
  end
end

local function key(n, val)
  if (n == 2 and val == 1) then setEmptyScreen() end
  if (n == 3 and val == 1) then writeAllChars() end
end

-------- Slider --------
--this section pertains to drawing a slider on the push screen

--attempting to be as close to UI.Slider as possible
--changing the value of a slider wont update the message for the dirty line untill the the lcddraw event.
pushyLib.Slider = {}
pushyLib.Slider.__index = pushyLib.Slider

function pushyLib.Slider.new(x, line, width, height, value, min_value, max_value, markers)
  local slider = {
    x = x or 0,
    line = line or 0,
    width = width or 3,
    height = height or 1,
    value = value or 0,
    min_value = min_value or 0,
    max_value = max_value or 1,
    markers = markers or {},
    active = true,
    dirty = true 
  }
  setmetatable(pushyLib.Slider, {__index = UI})
  setmetatable(slider, pushyLib.Slider)
  return slider
end

--- Set value.
-- @tparam number number Value number.
function pushyLib.Slider:set_value(number)
  self.value = util.clamp(number, self.min_value, self.max_value)
  self.dirty = true
end

--- Set value using delta.
-- @tparam number delta Number.
function pushyLib.Slider:set_value_delta(delta)
  self:set_value(self.value + delta)
end

function pushyLib.Slider:changeWidth(delta)
    local previousWidth = self.width
    self.width = util.clamp(self.width + delta, 1, (numberOfCharsPerLine - self.x + 1))
    --remove the chars that we dont need.
    lcdLines[self.line].elementsMoved = true

    self.dirty = true
end

--- Set marker position.
-- @tparam number id Marker number.
-- @tparam number position Marker position number.
function pushyLib.Slider:set_marker_position(id, position)
  self.markers[id] = util.clamp(position, self.min_value, self.max_value)
end

--- Redraw Slider. --Call when changed.
function pushyLib.Slider:redraw()
  local inCharicterlengths = (self.value/self.max_value)*(self.width)
  local onChar = math.ceil(inCharicterlengths) --the number of chars that will be lit up
  local partials = math.ceil((inCharicterlengths + 1 - onChar)*3)-- the portion of the last char that will be on
  --print("partial: " .. partials)
  --print("on char: " .. onChar)
  --print("incharlen: " .. inCharicterlengths)
  --print("value: " .. self.value)
  
  local pos = 1
  
  for i=(7 + self.x),(6 + self.x + self.width),1 do
    if pos == onChar then
      if partials == 1 then
        lcdLines[self.line].message[i]=sliderChars.left
      elseif partials ==  2 then
        lcdLines[self.line].message[i]=sliderChars.center
      else
        lcdLines[self.line].message[i]=sliderChars.right
      end
    else lcdLines[self.line].message[i]=sliderChars.empty
    end

    pos = pos + 1
  end
  self.dirty = false
end

-------- Slider END -------

-------- Text Block --------
--this section pertains to writing text to the push screen
pushyLib.text = {}
pushyLib.text.__index = pushyLib.text

function pushyLib.text.new(x, entry, line, width, height)
  local text = {
    x = x or 0,
    entry = entry or "String entry",
    line = line or 0,
    width = width or 17,
    height = height or 1,
    active = true,
    dirty = true 
  }
  lcdLines[line].dirty = true
  setmetatable(pushyLib.text, {__index = UI})
  setmetatable(text, pushyLib.text)
  return text
end

--- Redraw text block. --Call when changed.
function pushyLib.text:redraw()
  
  local pos = 1
  local charVal
  for i=(7 + self.x),(6 + self.x + self.width),1 do
    if self.entry == nil then charVal = 32
    elseif pos <= string.len(self.entry) then
      charVal = string.byte(self.entry, pos)
    else
    charVal = 32
    end
    
    if charVal > 127 then charval = 1 end
    
    lcdLines[self.line].message[i]= charVal
    pos = pos + 1
  end
  self.dirty = false
end

-------- Text Block END --------

local function writeAllChars()
  lcdLines[1].message = {71, 127, 21, 24, 0, 69, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67}
  lcdLines[2].message = {71, 127, 21, 25, 0, 69, 0, 124, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 0, 0, 0, 0, 0, 0, 0, 0, 0}
  lcdLines[3].message = {71, 127, 21, 26, 0, 69, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67}
  lcdLines[4].message = {71, 127, 21, 27, 0, 69, 0, 124, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 0, 0, 0, 0, 0, 0, 0, 0, 0}
  lcdLines[1].dirty = true
  lcdLines[2].dirty = true
  lcdLines[3].dirty = true
  lcdLines[4].dirty = true
end

--this is the starting point for the flow of midi data coming from the push
--we want to split the input up by input type (encoder turns, encoder touch, buttons, pads, slider)

local function pushMidiCallBackHandler(data)
    message = midi.to_msg(data)
    print(message.val)
    if message.type == "cc" then
      if ((message.cc >= 71 and message.cc <= 79) or (message.cc == 14 or message.cc == 15)) then
        delta = -1 * (math.floor((message.val - 64)/math.abs(message.val - 64))* (64 - math.abs(message.val - 64))) --yeah i know
        enc(message.cc, delta)
      end
    end
end

function testNumberParamAction(paramid)
  
    --this function is called when a parameter value is changed (doesnt mater from where)
    print(paramid)
    
end

function pushyLib.init()
  
  midi_in.event = pushMidiCallBackHandler
  pushyLib.countParams()
  print("there are " .. numberOfParams .. " params.")
  --pushyLib.printParams() --early tests in working with params TODO remove when finished

  sliders[1] = pushyLib.Slider.new(1, 1, 68, 1, 1, 1, 204, nil)
  texts[1] = pushyLib.text.new(1,params:get("frequency"), 3, 17, 1)
  --texts[1].entry = "a test so long that it carelessly leaves the screen!!!!!!!!"
  texts[2] = pushyLib.text.new(18,params:get_id(currentParamID), 3, 17, 1)
  
  
  params:set_action("note_number", function(x) testNumberParamAction("note_number") end)
  params:set_action("grocery list", function(x) testNumberParamAction("grocery list") end)
  
  params:append_action("frequency", function() 
    print(params:get("frequency") )
    texts[1].entry = params:get("frequency") 
        texts[1].dirty = true
    lcdLines[texts[1].line].dirty = true
    pushScreenDirty = true
    end);

  -- Metro to call redraw()
  screen_refresh_metro = metro.init()
  screen_refresh_metro.event = function()
    if lcdLines[lineToBeRefreshed].dirty then
      lcdLines[lineToBeRefreshed].dirty = false
      lcdRedraw(lineToBeRefreshed)
    end
  lineToBeRefreshed = lineToBeRefreshed + 1
  if lineToBeRefreshed > 4 then lineToBeRefreshed = 1 end
  end
  screen_refresh_metro:start(1 / PUSH_SCREEN_FRAMERATE)
  setEmptyScreen()
end


return pushyLib
