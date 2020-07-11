-- pushy
--
-- use an ableton push 1
-- on norns, i insist!
--
-- ericmoderbacher
-- 7/9/2020

local midi_out = midi.connect(1)
local midi_in = midi.connect(2)
local pushScreenDirty = false
local emptyChar = 6
local leftChar = 4
local rightChar = 3
local centerChar = 124
local lcdLines = {{dirty=true},{dirty=true},{dirty=true},{dirty=true} }
local sliderValue = 0
PUSH_SCREEN_FRAMERATE = 30


function send_sysex(m, d)
  --given to me by zebra on lines
   m:send{0xf0}
  for i,v in ipairs(d) do
      m:send{d[i]}
  end
  m:send{0xf7}
end
function setupEmptyScreen()
  for i,v in ipairs(lcdLines) do
      setupEmptyLine(i)
  end
end

function setupEmptyLine(lineNumber)
  lcdLines[lineNumber].message = {71, 127, 21, (23 + lineNumber), 0, 69, 0}
  for i=8,76,1 do lcdLines[lineNumber].message[i]=32 end
end

function writeAllChars()
  --sends a demo text to the device
  --send_sysex(midi_out, {0x47,0x7F,0x15,0x18,0x00,0x45,0x00,0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x20,0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x28,0x29,0x30,0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x40,0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48,0x49,0x50,0x51,0x52,0x53,0x54,0x55,0x56,0x57,0x58,0x59,0x60,0x61,0x62,0x63,0x64,0x65,0x66,0x67})
  send_sysex(midi_out, {71, 127, 21, 24, 0, 69, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67})
  send_sysex(midi_out, {71, 127, 21, 25, 0, 69, 0, 124, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 0, 0, 0, 0, 0, 0, 0, 0, 0})
    
end
function init()
  midi_in.event = function(data)
      message = midi.to_msg(data)
      if message.type == "cc" then
        if message.cc == 71 then
          delta = (math.floor((message.val - 64)/math.abs(message.val - 64))* (64 - math.abs(message.val - 64))) --yeah i know
          enc(message.cc, delta)
        end
      end
  end

  setupEmptyScreen()
  pushScreenDirty = true
  send_sysex(midi_out, lcdLines[2].message)
  send_sysex(midi_out, lcdLines[3].message)
    
  --writeAllChars()

  -- Metro to call redraw()
  screen_refresh_metro = metro.init()
  screen_refresh_metro.event = function()
    if pushScreenDirty then
      pushScreenDirty = false
      lcdRedraw()
    end
  end
  screen_refresh_metro:start(1 / PUSH_SCREEN_FRAMERATE)
end

function lcdRedraw()
  for i = 1,4,1 do 
    if lcdLines[i].dirty then
      lcdLines[i].dirty = false
      send_sysex(midi_out, lcdLines[i].message)
    end
  end
end

function setLCDSlider(line, sliderValue)
  lcdLines[line].dirty = true
  pushScreenDirty = true
  onChar = math.ceil(sliderValue/3)
  partials = (sliderValue % 3)

  
  pos = 1
  
  for i=8,24,1 do
    if pos == onChar then
      if partials == 1 then
        lcdLines[line].message[i]=rightChar
      elseif partials ==  2 then
        lcdLines[line].message[i]=centerChar
      else
        lcdLines[line].message[i]=leftChar
      end
    else lcdLines[line].message[i]=emptyChar
    end

    pos = pos + 1
  end
  
end

function enc(n, delta)
  if n == 71 then
    sliderValue = math.min(math.max((sliderValue + (-1 * delta)),1), 51)
    setLCDSlider(1, sliderValue);
  end
end





