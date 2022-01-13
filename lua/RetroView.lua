local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local vec3 = require("modules.vec3")
local mat4 = require("modules.mat4")
local ffi = require("ffi")
local RetroMote = require("RetroMote")

ffi.cdef(require("cdef"))

class.RetroView(ui.VideoSurface)

--------------- setup ------------------


function RetroView:_init(bounds)
    self:super(bounds)

    self.speaker = self:addSubview(ui.Speaker(Bounds(0, 0.3, 0.2, 0,0,0)))

    self.sample_capacity = 960*32
    self.audiobuffer = ffi.new("int16_t[?]", self.sample_capacity)
    self.buffered_samples = 0
    self.audiodebug = io.open("debug.pcm", "wb")
    self.elapsed_videotime = 0
    self.elapsed_inaudiotime = 0
    self.elapsed_outaudiotime = 0
    self.soundVolume = 0.5

    --self:loadCore("nestopia")
    --self:loadGame("roms/NES/tmnt2/tmnt2.nes")
    self:loadCore("snes9x")
    self:loadGame("roms/SNES/sf2t/sf2t.sfc")
    --self:loadCore("genesis_plus_gx")
    --self:loadGame("roms/Genesis/sor3/sor3.smd")
end

function os.system(cmd)
    local f = assert(io.popen(cmd, 'r'))
    local s = assert(f:read('*a'))
    f:close()
    return s:match("^%s*(.-)%s*$")
  end

function _loadCore(coreName)
    local searchPaths = {
        "~/.config/retroarch/cores/"..coreName.."_libretro.so", -- apt install path
        "/usr/lib/x86_64-linux-gnu/libretro/"..coreName.."_libretro.so", -- gui install path linux
        "$HOME/Library/Application\\ Support/RetroArch/cores/"..coreName.."_libretro.dylib" -- gui install path mac
    }

    for i, path in ipairs(searchPaths) do
        print("Trying to load core from "..path)
        local corePath = os.system("echo "..path)
        ok, what = pcall(ffi.load, corePath, false)
        if ok then
            print("Success")
            return what
        else
            print("Failed: "..what)
        end
    end
    error("Core "..coreName.." not available anywhere :(")
end

function RetroView:loadCore(coreName)
    self.handle = _loadCore(coreName)
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
    self.handle.retro_set_controller_port_device(0, 1); -- controller port 0 is a joypad
    self.handle.retro_set_controller_port_device(1, 1); -- controller port 1 is a joypad
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
    self:setVideoFormat("h264")
end

function RetroView:getFps()
    return tonumber(self.av.timing.fps)
end


function RetroView:specification()
    local spec = VideoSurface.specification(self)
    spec.geometry.uvs = {{0.0, 1.0},           {1.0, 1.0},          {0.0, 0.0},           {1.0, 0.0}}
    return spec
end

----------------- running --------------------

function RetroView:poll()
    if not self.start_time then
        self.start_time = self.app:clientTime()
    end
    self.handle.retro_run()
    self:_sendBufferedAudio()
end

function RetroView:get_stats()
    return pretty.write({
        buffered_samples= self.buffered_samples,
        elapsed_realtime= self.app:clientTime() - self.start_time,
        elapsed_videotime= self.elapsed_videotime,
        elapsed_inaudiotime= self.elapsed_inaudiotime,
        elapsed_outaudiotime= self.elapsed_outaudiotime,
    })
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
        local fmtIndex = tonumber(fmt[0])
        local indexToFormat = {
            [0]= "rgb1555",
            [1]= "bgra", -- ?? supposed to be xrgb8
            [2]= "rgb565",
        }
        self.videoFormat = indexToFormat[fmtIndex]
        print("Emulator requested video format", fmtIndex, "aka", self.videoFormat)
        return true
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
    self.elapsed_videotime = self.elapsed_videotime + 1/self:getFps()
    if not self.trackId then
        return
    end
    if self.frame_id == nil then self.frame_id = 0 end
    self.frame_id = self.frame_id + 1
    if self.frame_id % 2 == 0 then return end

    pitch = tonumber(pitch)

    self.app.client.client:send_video(
        self.trackId, 
        ffi.string(data, pitch*height), 
        width, height, 
        self.videoFormat,
        pitch
    )
end

function RetroView:_audio_sample_batch(data, frames)
    local dest_samplerate = 48000
    local source_channel_count = 2
    local dest_channel_count = 1
    local dest_frames = (dest_samplerate/self.av.timing.sample_rate) * tonumber(frames) * 2 -- in case resampling requires multi-pass headroom
    self.elapsed_inaudiotime = self.elapsed_inaudiotime + tonumber(frames)/tonumber(self.av.timing.sample_rate)
    --if self.audiodebug then self.audiodebug:write(ffi.string(data, frames*2*source_channel_count)) end
    if self.buffered_samples + dest_frames*dest_channel_count >= self.sample_capacity then
        print("audio buffer overload: ", self.buffered_samples, "+", frames, "in", self.sample_capacity)
        self:_sendBufferedAudio()
        return frames
    end
    local converted_count = self.helper.flynn_resample(
        data, frames, self.av.timing.sample_rate, source_channel_count == 2 and true or false,
        self.audiobuffer + self.buffered_samples, dest_frames, dest_samplerate, dest_channel_count == 2 and true or false
    )
    --if self.audiodebug then self.audiodebug:write(ffi.string(self.audiobuffer + self.buffered_samples, converted_count*2*dest_channel_count)) end
    --print("in", frames, "out", dest_frames, "actual", converted_count)

    self.buffered_samples = self.buffered_samples + converted_count
    self:_sendBufferedAudio()
    return frames
end

local x = 0
function RetroView:_sendBufferedAudio()
    if not self.speaker.trackId then
        return
    end
    if self.buffered_samples < 960 then
        return
    end
    local left = ffi.new("int16_t[960]")
    for i=0,960-1 do
        left[i] = self.audiobuffer[i] * self.soundVolume
    end
    
    self.buffered_samples = self.buffered_samples - 960
    ffi.copy(self.audiobuffer, self.audiobuffer + 960, self.buffered_samples*2)

    local out = ffi.string(left, 960*2)

    --if self.audiodebug then self.audiodebug:write(out) end
    self.elapsed_outaudiotime = self.elapsed_outaudiotime + 960/48000
    self.app.client.client:send_audio(self.speaker.trackId, out)
	
    if self.buffered_samples > 960 then
        self:_sendBufferedAudio()
    end
end

function RetroView:_input_poll()
    -- todo
end

function RetroView:_input_state(port, device, index, id)
    if port >= #self.controllers then
        return false
    end
    return self.controllers[port+1].controllerStates[id+1]
end




return RetroView
