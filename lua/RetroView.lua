local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local vec3 = require("modules.vec3")
local mat4 = require("modules.mat4")
local ffi = require("ffi")

ffi.cdef(require("cdef"))

class.RetroView(ui.VideoSurface)

function RetroView:_init(bounds)
    self:super(bounds)
    self.speaker = self:addSubview(ui.Speaker())
    self:loadCore("/home/nevyn/.config/retroarch/cores/nestopia_libretro.so")
    self:loadGame("roms/tmnt.nes")
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
    print("Using resolution", self.av.geometry.base_width, self.av.geometry.base_height)
    self:setResolution(self.av.geometry.base_width, self.av.geometry.base_height)
end

function RetroView:poll()
    self.handle.retro_run()
end

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
        print("Using video format", fmt[0])
        return fmt[0] == 1 -- XRGB8888
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

function RetroView:_video_refresh(data, width, height, pitch)
    if not self.trackId then
        return
    end
    self.app.client.client:send_video(
        self.trackId, 
        ffi.string(data), 
        width, height, 
        "xrgb8",
        tonumber(pitch)
    )
end

function RetroView:_audio_sample_batch(data, frames)
    if frames < 960*2 then
        --print("not enough audio")
        return 0
    end
    if not self.speaker.trackId then
        print("no speaker")
        return 0
    end
    local stereo = ffi.cast("int16_t*")
    local left = ffi.new("int16_t[960]")
    for i=0,960 do
        left[i] = stereo[i*2]
    end
    print("sending ", #left, "frames")
    self.app.client.client:send_audio(self.speaker.trackId, left)
	return 960*2
end

function RetroView:_input_poll()
    -- todo
end

function RetroView:_input_state(port, device, index, id)
    print("input state")
    return 0
end

return RetroView
