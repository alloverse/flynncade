local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local vec3 = require("modules.vec3")
local mat4 = require("modules.mat4")
local ffi = require("ffi")

ffi.cdef(require("cdef"))

class.RetroView(ui.VideoSurface)

local me = nil

function core_environment(cmd, data)
    if cmd == 27 then -- RETRO_ENVIRONMENT_GET_LOG_INTERFACE
        local cb = ffi.cast("struct retro_log_callback*", data)
        cb.log = me.helper.core_log
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

function core_video_refresh(data, width, height, pitch)
    if not me.trackId then
        return
    end
    me.app.client.client:send_video(
        me.trackId, 
        ffi.string(data), 
        width, height, 
        "xrgb8",
        tonumber(pitch)
    )
end

function core_audio_sample_batch(data, frames)
    if frames < 960*2 then
        print("not enough audio")
        return 0
    end
    if not me.speaker.trackId then
        print("no speaker")
        return 0
    end
    local stereo = ffi.cast("int16_t*")
    local left = ffi.new("int16_t[960]")
    for i=0,960 do
        left[i] = stereo[i*2]
    end
    print("sending ", #left, "frames")
    me.app.client.client:send_audio(me.speaker.trackId, left)
	return 960*2
end

function core_input_poll()
    -- todo
end

function core_input_state(port, device, index, id)
    print("input state")
    return 0
end

function RetroView:loadCore(corePath)
    self.handle = ffi.load(corePath, false)
    self.helper = ffi.load("lua/libhelper.so", false)
    assert(self.handle)
    self.handle.retro_set_environment(core_environment)
    self.handle.retro_set_input_poll(core_input_poll)
	self.handle.retro_set_input_state(core_input_state)
    self.handle.retro_set_video_refresh(core_video_refresh)
    self.handle.retro_set_audio_sample_batch(core_audio_sample_batch)
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

function RetroView:_init(bounds)
    self:super(bounds)
    self.speaker = self:addSubview(ui.Speaker())
    me = self
    self:loadCore("/home/nevyn/.config/retroarch/cores/nestopia_libretro.so")
    self:loadGame("roms/tmnt.nes")
end

return RetroView
