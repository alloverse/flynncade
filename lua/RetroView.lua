local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local vec3 = require("modules.vec3")
local mat4 = require("modules.mat4")
local ffi = require("ffi")

ffi.cdef(require("cdef"))

class.RetroView(ui.VideoSurface)

--------------- setup ------------------

function RetroView:_init(bounds, cores)
    self:super(bounds)

    self.speaker = self:addSubview(ui.Speaker())

    self.frame_capacity = 960*8
    self.audiobuffer = ffi.new("int16_t[?]", self.frame_capacity)
    self.buffered_frames = 0

    self:loadCore(cores.."/fceumm_libretro.so")
    self:loadGame("roms/met.nes")
end

function RetroView:loadCore(corePath)
    self.handle = ffi.load(corePath, false)
    self.helper = ffi.load("lua/libhelper.so", false)
    assert(self.handle)
    self.handle.retro_set_environment(function(cmd, data)
        return self:_environment(cmd, data)
    end)
    self.handle.retro_set_input_poll(function()
        return self:_input_poll()
    end)
	self.handle.retro_set_input_state(function(port, device, index, id)
        return self:_input_state(port, device, index, id)
    end)
    self.handle.retro_set_video_refresh(function(data, width, height, pitch)
        return self:_video_refresh(data, width, height, pitch)
    end)
    self.handle.retro_set_audio_sample_batch(function(data, frames)
        return self:_audio_sample_batch(data, frames)
    end)
    self.handle.retro_init()
end

function RetroView:loadGame(gamePath)
    self.system = ffi.new("struct retro_system_info")
    self.handle.retro_get_system_info(self.system)

    self.info = ffi.new("struct retro_game_info")
    self.info.path = gamePath
    local f = io.open(gamePath, "rb")
    local data = f:read("*a")
    self.info.data = data
    self.info.size = #data
    local ok = self.handle.retro_load_game(self.info)
    assert(ok)

    self.av = ffi.new("struct retro_system_av_info")
    self.handle.retro_get_system_av_info(self.av)
    print(
        "Emulator AV info:\n\tVideo dimensions:", 
        self.av.geometry.base_width, "x", self.av.geometry.base_height,
        "\n\tVideo frame rate:", self.av.timing.fps,
        "\n\tAudio sample rate:", self.av.timing.sample_rate
    )
    self:setResolution(self.av.geometry.base_width, self.av.geometry.base_height)
end

function RetroView:getFps()
    return self.av.timing.fps
end


function RetroView:specification()
    local spec = VideoSurface.specification(self)
    spec.geometry.uvs = {{0.0, 1.0},           {1.0, 1.0},          {0.0, 0.0},           {1.0, 0.0}}
    return spec
end

----------------- running --------------------

function RetroView:poll()
    self.handle.retro_run()
end

-------- libretro emulator callbacks -----------

function RetroView:_environment(cmd, data)
    if cmd == 27 then -- RETRO_ENVIRONMENT_GET_LOG_INTERFACE
        local cb = ffi.cast("struct retro_log_callback*", data)
        cb.log = self.helper.core_log
        return true
    elseif cmd == 3 then -- RETRO_ENVIRONMENT_GET_CAN_DUPE
        local out = ffi.cast("bool*", data)
        out[0] = true
        return true
    elseif cmd == 10 then -- RETRO_ENVIRONMENT_SET_PIXEL_FORMAT
        local fmt = ffi.cast("enum retro_pixel_format*", data)
        print("Emulator requested video format", fmt[0])
        return tonumber(fmt[0]) == 1 -- XRGB8888
    elseif cmd == 9 then -- RETRO_ENVIRONMENT_GET_SYSTEM_DIRECTORY
        local sptr = ffi.cast("const char **", data)
        sptr[0] = "."
        return true
    elseif cmd == 31 then -- RETRO_ENVIRONMENT_GET_SAVE_DIRECTORY
        local sptr = ffi.cast("const char **", data)
        sptr[0] = "."
        return true
    end

    --print("Unhandled env", cmd)
    return false
end

local OR, XOR, AND = 1, 3, 4
function bop(a, oper, b)
   local r, m, s = 0, 2^31
   repeat
      s,a,b = a+b+m, a%m, b%m
      r,m = r + m*oper%(s-a-b), m/2
   until m < 1
   return r
end

function RetroView:_video_refresh(data, width, height, pitch)
    if not self.trackId then
        return
    end
    if self.frame_id == nil then self.frame_id = 0 end
    self.frame_id = self.frame_id + 1
    if self.frame_id % 8 ~= 0 then return end
    --ffi.fill(ffi.cast("char*", data), pitch*height, 128)
    pitch = tonumber(pitch)

    self.app.client.client:send_video(
        self.trackId, 
        ffi.string(data), 
        width, height, 
        "xrgb8",
        pitch
    )
end

-- pitch2 = width * 4
-- local pix1 = ffi.cast("uint8_t*", data)
-- local pix2 = ffi.new("uint8_t[?]", width*height*4)
-- for y=0, height-1 do
--     for x=0, width-1 do
--         local r = bop(pix1[(y*width+x)*2], AND, 0b11111000) / 8
--         local g = bop(pix1[(y*width+x)*2], AND, 0b00000111) * 8 + bop(pix1[(y*width+x)*2 + 1], AND, 0b11100000) / 32
--         local b = bop(pix1[(y*width+x)*2 + 1], AND, 0b00011111) / 8
--         pix2[(y*width+x)*4 + 0] = r
--         pix2[(y*width+x)*4 + 1] = g
--         pix2[(y*width+x)*4 + 2] = b
--         pix2[(y*width+x)*4 + 3] = 255
--     end
-- end

function RetroView:_audio_sample_batch(data, frames)
    if self.buffered_frames + frames >= self.frame_capacity then
        print("audio buffer overload: ", self.buffered_frames, "+", frames, "in", self.frame_capacity)
        self:_sendBufferedAudio()
        return frames
    end
    ffi.copy(self.audiobuffer + self.buffered_frames, data, frames*2)
    self.buffered_frames = self.buffered_frames + frames
    self:_sendBufferedAudio()
    return frames
end

local x = 0
function RetroView:_sendBufferedAudio()
    if not self.speaker.trackId then
        return
    end
    if self.buffered_frames < 960*2 then
        return
    end
    local left = ffi.new("int16_t[960]")
    for i=0,960-1 do
        --left[i] = .8*0x8000*math.sin(2*3.141*440*x/48000); x = x + 1
        left[i] = self.audiobuffer[i*2]
    end
    
    self.buffered_frames = self.buffered_frames - 960*2
    ffi.copy(self.audiobuffer, self.audiobuffer+960*2, self.buffered_frames)

    self.app.client.client:send_audio(self.speaker.trackId, ffi.string(left, 960*2))
	
    if self.buffered_frames > 960*2 then
        self:_sendBufferedAudio()
    end
end

function RetroView:_input_poll()
    -- todo
end

function RetroView:_input_state(port, device, index, id)
    --print("input state")
    return 0
end

return RetroView
