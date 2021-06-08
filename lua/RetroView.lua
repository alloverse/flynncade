local class = require('pl.class')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')
local vec3 = require("modules.vec3")
local mat4 = require("modules.mat4")
local ffi = require("ffi")

ffi.cdef[[

 /* Id values for LANGUAGE */
 enum retro_language
 {
    RETRO_LANGUAGE_ENGLISH             = 0,
    RETRO_LANGUAGE_JAPANESE            = 1,
    RETRO_LANGUAGE_FRENCH              = 2,
    RETRO_LANGUAGE_SPANISH             = 3,
    RETRO_LANGUAGE_GERMAN              = 4,
    RETRO_LANGUAGE_ITALIAN             = 5,
    RETRO_LANGUAGE_DUTCH               = 6,
    RETRO_LANGUAGE_PORTUGUESE_BRAZIL   = 7,
    RETRO_LANGUAGE_PORTUGUESE_PORTUGAL = 8,
    RETRO_LANGUAGE_RUSSIAN             = 9,
    RETRO_LANGUAGE_KOREAN              = 10,
    RETRO_LANGUAGE_CHINESE_TRADITIONAL = 11,
    RETRO_LANGUAGE_CHINESE_SIMPLIFIED  = 12,
    RETRO_LANGUAGE_ESPERANTO           = 13,
    RETRO_LANGUAGE_POLISH              = 14,
    RETRO_LANGUAGE_VIETNAMESE          = 15,
    RETRO_LANGUAGE_LAST,
 
    /* Ensure sizeof(enum) == sizeof(int) */
    RETRO_LANGUAGE_DUMMY          = 2147483647 
 };

 
 /* Keysyms used for ID in input state callback when polling RETRO_KEYBOARD. */
 enum retro_key
 {
    RETROK_UNKNOWN        = 0,
    RETROK_FIRST          = 0,
    RETROK_BACKSPACE      = 8,
    RETROK_TAB            = 9,
    RETROK_CLEAR          = 12,
    RETROK_RETURN         = 13,
    RETROK_PAUSE          = 19,
    RETROK_ESCAPE         = 27,
    RETROK_SPACE          = 32,
    RETROK_EXCLAIM        = 33,
    RETROK_QUOTEDBL       = 34,
    RETROK_HASH           = 35,
    RETROK_DOLLAR         = 36,
    RETROK_AMPERSAND      = 38,
    RETROK_QUOTE          = 39,
    RETROK_LEFTPAREN      = 40,
    RETROK_RIGHTPAREN     = 41,
    RETROK_ASTERISK       = 42,
    RETROK_PLUS           = 43,
    RETROK_COMMA          = 44,
    RETROK_MINUS          = 45,
    RETROK_PERIOD         = 46,
    RETROK_SLASH          = 47,
    RETROK_0              = 48,
    RETROK_1              = 49,
    RETROK_2              = 50,
    RETROK_3              = 51,
    RETROK_4              = 52,
    RETROK_5              = 53,
    RETROK_6              = 54,
    RETROK_7              = 55,
    RETROK_8              = 56,
    RETROK_9              = 57,
    RETROK_COLON          = 58,
    RETROK_SEMICOLON      = 59,
    RETROK_LESS           = 60,
    RETROK_EQUALS         = 61,
    RETROK_GREATER        = 62,
    RETROK_QUESTION       = 63,
    RETROK_AT             = 64,
    RETROK_LEFTBRACKET    = 91,
    RETROK_BACKSLASH      = 92,
    RETROK_RIGHTBRACKET   = 93,
    RETROK_CARET          = 94,
    RETROK_UNDERSCORE     = 95,
    RETROK_BACKQUOTE      = 96,
    RETROK_a              = 97,
    RETROK_b              = 98,
    RETROK_c              = 99,
    RETROK_d              = 100,
    RETROK_e              = 101,
    RETROK_f              = 102,
    RETROK_g              = 103,
    RETROK_h              = 104,
    RETROK_i              = 105,
    RETROK_j              = 106,
    RETROK_k              = 107,
    RETROK_l              = 108,
    RETROK_m              = 109,
    RETROK_n              = 110,
    RETROK_o              = 111,
    RETROK_p              = 112,
    RETROK_q              = 113,
    RETROK_r              = 114,
    RETROK_s              = 115,
    RETROK_t              = 116,
    RETROK_u              = 117,
    RETROK_v              = 118,
    RETROK_w              = 119,
    RETROK_x              = 120,
    RETROK_y              = 121,
    RETROK_z              = 122,
    RETROK_DELETE         = 127,
 
    RETROK_KP0            = 256,
    RETROK_KP1            = 257,
    RETROK_KP2            = 258,
    RETROK_KP3            = 259,
    RETROK_KP4            = 260,
    RETROK_KP5            = 261,
    RETROK_KP6            = 262,
    RETROK_KP7            = 263,
    RETROK_KP8            = 264,
    RETROK_KP9            = 265,
    RETROK_KP_PERIOD      = 266,
    RETROK_KP_DIVIDE      = 267,
    RETROK_KP_MULTIPLY    = 268,
    RETROK_KP_MINUS       = 269,
    RETROK_KP_PLUS        = 270,
    RETROK_KP_ENTER       = 271,
    RETROK_KP_EQUALS      = 272,
 
    RETROK_UP             = 273,
    RETROK_DOWN           = 274,
    RETROK_RIGHT          = 275,
    RETROK_LEFT           = 276,
    RETROK_INSERT         = 277,
    RETROK_HOME           = 278,
    RETROK_END            = 279,
    RETROK_PAGEUP         = 280,
    RETROK_PAGEDOWN       = 281,
 
    RETROK_F1             = 282,
    RETROK_F2             = 283,
    RETROK_F3             = 284,
    RETROK_F4             = 285,
    RETROK_F5             = 286,
    RETROK_F6             = 287,
    RETROK_F7             = 288,
    RETROK_F8             = 289,
    RETROK_F9             = 290,
    RETROK_F10            = 291,
    RETROK_F11            = 292,
    RETROK_F12            = 293,
    RETROK_F13            = 294,
    RETROK_F14            = 295,
    RETROK_F15            = 296,
 
    RETROK_NUMLOCK        = 300,
    RETROK_CAPSLOCK       = 301,
    RETROK_SCROLLOCK      = 302,
    RETROK_RSHIFT         = 303,
    RETROK_LSHIFT         = 304,
    RETROK_RCTRL          = 305,
    RETROK_LCTRL          = 306,
    RETROK_RALT           = 307,
    RETROK_LALT           = 308,
    RETROK_RMETA          = 309,
    RETROK_LMETA          = 310,
    RETROK_LSUPER         = 311,
    RETROK_RSUPER         = 312,
    RETROK_MODE           = 313,
    RETROK_COMPOSE        = 314,
 
    RETROK_HELP           = 315,
    RETROK_PRINT          = 316,
    RETROK_SYSREQ         = 317,
    RETROK_BREAK          = 318,
    RETROK_MENU           = 319,
    RETROK_POWER          = 320,
    RETROK_EURO           = 321,
    RETROK_UNDO           = 322,
 
    RETROK_LAST,
 
    RETROK_DUMMY          = 2147483647 /* Ensure sizeof(enum) == sizeof(int) */
 };
 
 enum retro_mod
 {
    RETROKMOD_NONE       = 0x0000,
 
    RETROKMOD_SHIFT      = 0x01,
    RETROKMOD_CTRL       = 0x02,
    RETROKMOD_ALT        = 0x04,
    RETROKMOD_META       = 0x08,
 
    RETROKMOD_NUMLOCK    = 0x10,
    RETROKMOD_CAPSLOCK   = 0x20,
    RETROKMOD_SCROLLOCK  = 0x40,
 
    RETROKMOD_DUMMY = 2147483647 /* Ensure sizeof(enum) == sizeof(int) */
 };
 
 
 enum retro_hw_render_interface_type
 {
    RETRO_HW_RENDER_INTERFACE_VULKAN = 0,
    RETRO_HW_RENDER_INTERFACE_DUMMY = 2147483647
 };
 
 /* Base struct. All retro_hw_render_interface_* types
  * contain at least these fields. */
 struct retro_hw_render_interface
 {
    enum retro_hw_render_interface_type interface_type;
    unsigned interface_version;
 };
 
 
 enum retro_hw_render_context_negotiation_interface_type
 {
    RETRO_HW_RENDER_CONTEXT_NEGOTIATION_INTERFACE_VULKAN = 0,
    RETRO_HW_RENDER_CONTEXT_NEGOTIATION_INTERFACE_DUMMY = 2147483647
 };
 
 /* Base struct. All retro_hw_render_context_negotiation_interface_* types
  * contain at least these fields. */
 struct retro_hw_render_context_negotiation_interface
 {
    enum retro_hw_render_context_negotiation_interface_type interface_type;
    unsigned interface_version;
 };
 
                                            /* const struct retro_hw_render_context_negotiation_interface * --
                                             * Sets an interface which lets the libretro core negotiate with frontend how a context is created.
                                             * The semantics of this interface depends on which API is used in SET_HW_RENDER earlier.
                                             * This interface will be used when the frontend is trying to create a HW rendering context,
                                             * so it will be used after SET_HW_RENDER, but before the context_reset callback.
                                             */
 
 /* Serialized state is incomplete in some way. Set if serialization is
  * usable in typical end-user cases but should not be relied upon to
  * implement frame-sensitive frontend features such as netplay or
  * rerecording. */
 
 /* The core must spend some time initializing before serialization is
  * supported. retro_serialize() will initially fail; retro_unserialize()
  * and retro_serialize_size() may or may not work correctly either. */
 
 /* Serialization size may change within a session. */
 
 /* Set by the frontend to acknowledge that it supports variable-sized
  * states. */
 
 /* Serialized state can only be loaded during the same session. */
 
 /* Serialized state cannot be loaded on an architecture with a different
  * endianness from the one it was saved on. */
 
 /* Serialized state cannot be loaded on a different platform from the one it
  * was saved on for reasons other than endianness, such as word size
  * dependence */
 
 
 
                                            /* uint64_t * --
                                             * Sets quirk flags associated with serialization. The frontend will zero any flags it doesn't
                                             * recognize or support. Should be set in either retro_init or retro_load_game, but not both.
                                             */
 
 
 
 
 
 
 
 
 
 
 struct retro_memory_descriptor
 {
    uint64_t flags;
 
    /* Pointer to the start of the relevant ROM or RAM chip.
     * It's strongly recommended to use 'offset' if possible, rather than 
     * doing math on the pointer.
     *
     * If the same byte is mapped my multiple descriptors, their descriptors 
     * must have the same pointer.
     * If 'start' does not point to the first byte in the pointer, put the 
     * difference in 'offset' instead.
     *
     * May be NULL if there's nothing usable here (e.g. hardware registers and 
     * open bus). No flags should be set if the pointer is NULL.
     * It's recommended to minimize the number of descriptors if possible,
     * but not mandatory. */
    void *ptr;
    size_t offset;
 
    /* This is the location in the emulated address space 
     * where the mapping starts. */
    size_t start;
 
    /* Which bits must be same as in 'start' for this mapping to apply.
     * The first memory descriptor to claim a certain byte is the one 
     * that applies.
     * A bit which is set in 'start' must also be set in this.
     * Can be zero, in which case each byte is assumed mapped exactly once. 
     * In this case, 'len' must be a power of two. */
    size_t select;
 
    /* If this is nonzero, the set bits are assumed not connected to the 
     * memory chip's address pins. */
    size_t disconnect;
 
    /* This one tells the size of the current memory area.
     * If, after start+disconnect are applied, the address is higher than 
     * this, the highest bit of the address is cleared.
     *
     * If the address is still too high, the next highest bit is cleared.
     * Can be zero, in which case it's assumed to be infinite (as limited 
     * by 'select' and 'disconnect'). */
    size_t len;
 
    /* To go from emulated address to physical address, the following 
     * order applies:
     * Subtract 'start', pick off 'disconnect', apply 'len', add 'offset'. */
 
    /* The address space name must consist of only a-zA-Z0-9_-, 
     * should be as short as feasible (maximum length is 8 plus the NUL),
     * and may not be any other address space plus one or more 0-9A-F 
     * at the end.
     * However, multiple memory descriptors for the same address space is 
     * allowed, and the address space name can be empty. NULL is treated 
     * as empty.
     *
     * Address space names are case sensitive, but avoid lowercase if possible.
     * The same pointer may exist in multiple address spaces.
     *
     * Examples:
     * blank+blank - valid (multiple things may be mapped in the same namespace)
     * 'Sp'+'Sp' - valid (multiple things may be mapped in the same namespace)
     * 'A'+'B' - valid (neither is a prefix of each other)
     * 'S'+blank - valid ('S' is not in 0-9A-F)
     * 'a'+blank - valid ('a' is not in 0-9A-F)
     * 'a'+'A' - valid (neither is a prefix of each other)
     * 'AR'+blank - valid ('R' is not in 0-9A-F)
     * 'ARB'+blank - valid (the B can't be part of the address either, because 
     *                      there is no namespace 'AR')
     * blank+'B' - not valid, because it's ambigous which address space B1234 
     *             would refer to.
     * The length can't be used for that purpose; the frontend may want 
     * to append arbitrary data to an address, without a separator. */
    const char *addrspace;
 
    /* TODO: When finalizing this one, add a description field, which should be
     * "WRAM" or something roughly equally long. */
 
    /* TODO: When finalizing this one, replace 'select' with 'limit', which tells
     * which bits can vary and still refer to the same address (limit = ~select).
     * TODO: limit? range? vary? something else? */
 
    /* TODO: When finalizing this one, if 'len' is above what 'select' (or
     * 'limit') allows, it's bankswitched. Bankswitched data must have both 'len'
     * and 'select' != 0, and the mappings don't tell how the system switches the
     * banks. */
 
    /* TODO: When finalizing this one, fix the 'len' bit removal order.
     * For len=0x1800, pointer 0x1C00 should go to 0x1400, not 0x0C00.
     * Algorithm: Take bits highest to lowest, but if it goes above len, clear
     * the most recent addition and continue on the next bit.
     * TODO: Can the above be optimized? Is "remove the lowest bit set in both
     * pointer and 'len'" equivalent? */
    
    /* TODO: Some emulators (MAME?) emulate big endian systems by only accessing
     * the emulated memory in 32-bit chunks, native endian. But that's nothing
     * compared to Darek Mihocka <http://www.emulators.com/docs/nx07_vm101.htm>
     * (section Emulation 103 - Nearly Free Byte Reversal) - he flips the ENTIRE
     * RAM backwards! I'll want to represent both of those, via some flags.
     * 
     * I suspect MAME either didn't think of that idea, or don't want the #ifdef.
     * Not sure which, nor do I really care. */
    
    /* TODO: Some of those flags are unused and/or don't really make sense. Clean
     * them up. */
 };
 
 /* The frontend may use the largest value of 'start'+'select' in a 
  * certain namespace to infer the size of the address space.
  *
  * If the address space is larger than that, a mapping with .ptr=NULL 
  * should be at the end of the array, with .select set to all ones for 
  * as long as the address space is big.
  *
  * Sample descriptors (minus .ptr, and RETRO_MEMFLAG_ on the flags):
  * SNES WRAM:
  * .start=0x7E0000, .len=0x20000
  * (Note that this must be mapped before the ROM in most cases; some of the 
  * ROM mappers 
  * try to claim $7E0000, or at least $7E8000.)
  * SNES SPC700 RAM:
  * .addrspace="S", .len=0x10000
  * SNES WRAM mirrors:
  * .flags=MIRROR, .start=0x000000, .select=0xC0E000, .len=0x2000
  * .flags=MIRROR, .start=0x800000, .select=0xC0E000, .len=0x2000
  * SNES WRAM mirrors, alternate equivalent descriptor:
  * .flags=MIRROR, .select=0x40E000, .disconnect=~0x1FFF
  * (Various similar constructions can be created by combining parts of 
  * the above two.)
  * SNES LoROM (512KB, mirrored a couple of times):
  * .flags=CONST, .start=0x008000, .select=0x408000, .disconnect=0x8000, .len=512*1024
  * .flags=CONST, .start=0x400000, .select=0x400000, .disconnect=0x8000, .len=512*1024
  * SNES HiROM (4MB):
  * .flags=CONST,                 .start=0x400000, .select=0x400000, .len=4*1024*1024
  * .flags=CONST, .offset=0x8000, .start=0x008000, .select=0x408000, .len=4*1024*1024
  * SNES ExHiROM (8MB):
  * .flags=CONST, .offset=0,                  .start=0xC00000, .select=0xC00000, .len=4*1024*1024
  * .flags=CONST, .offset=4*1024*1024,        .start=0x400000, .select=0xC00000, .len=4*1024*1024
  * .flags=CONST, .offset=0x8000,             .start=0x808000, .select=0xC08000, .len=4*1024*1024
  * .flags=CONST, .offset=4*1024*1024+0x8000, .start=0x008000, .select=0xC08000, .len=4*1024*1024
  * Clarify the size of the address space:
  * .ptr=NULL, .select=0xFFFFFF
  * .len can be implied by .select in many of them, but was included for clarity.
  */
 
 struct retro_memory_map
 {
    const struct retro_memory_descriptor *descriptors;
    unsigned num_descriptors;
 };
 
 struct retro_controller_description
 {
    /* Human-readable description of the controller. Even if using a generic 
     * input device type, this can be set to the particular device type the 
     * core uses. */
    const char *desc;
 
    /* Device type passed to retro_set_controller_port_device(). If the device 
     * type is a sub-class of a generic input device type, use the 
     * RETRO_DEVICE_SUBCLASS macro to create an ID.
     *
     * E.g. RETRO_DEVICE_SUBCLASS(RETRO_DEVICE_JOYPAD, 1). */
    unsigned id;
 };
 
 struct retro_controller_info
 {
    const struct retro_controller_description *types;
    unsigned num_types;
 };
 
 struct retro_subsystem_memory_info
 {
    /* The extension associated with a memory type, e.g. "psram". */
    const char *extension;
 
    /* The memory type for retro_get_memory(). This should be at 
     * least 0x100 to avoid conflict with standardized 
     * libretro memory types. */
    unsigned type;
 };
 
 struct retro_subsystem_rom_info
 {
    /* Describes what the content is (SGB BIOS, GB ROM, etc). */
    const char *desc;
 
    /* Same definition as retro_get_system_info(). */
    const char *valid_extensions;
 
    /* Same definition as retro_get_system_info(). */
    bool need_fullpath;
 
    /* Same definition as retro_get_system_info(). */
    bool block_extract;
 
    /* This is set if the content is required to load a game. 
     * If this is set to false, a zeroed-out retro_game_info can be passed. */
    bool required;
 
    /* Content can have multiple associated persistent 
     * memory types (retro_get_memory()). */
    const struct retro_subsystem_memory_info *memory;
    unsigned num_memory;
 };
 
 struct retro_subsystem_info
 {
    /* Human-readable string of the subsystem type, e.g. "Super GameBoy" */
    const char *desc;
 
    /* A computer friendly short string identifier for the subsystem type.
     * This name must be [a-z].
     * E.g. if desc is "Super GameBoy", this can be "sgb".
     * This identifier can be used for command-line interfaces, etc.
     */
    const char *ident;
 
    /* Infos for each content file. The first entry is assumed to be the 
     * "most significant" content for frontend purposes.
     * E.g. with Super GameBoy, the first content should be the GameBoy ROM, 
     * as it is the most "significant" content to a user.
     * If a frontend creates new file paths based on the content used 
     * (e.g. savestates), it should use the path for the first ROM to do so. */
    const struct retro_subsystem_rom_info *roms;
 
    /* Number of content files associated with a subsystem. */
    unsigned num_roms;
    
    /* The type passed to retro_load_game_special(). */
    unsigned id;
 };
 
 typedef void (*retro_proc_address_t)(void);
 
 /* libretro API extension functions:
  * (None here so far).
  *
  * Get a symbol from a libretro core.
  * Cores should only return symbols which are actual 
  * extensions to the libretro API.
  *
  * Frontends should not use this to obtain symbols to standard 
  * libretro entry points (static linking or dlsym).
  *
  * The symbol name must be equal to the function name, 
  * e.g. if void retro_foo(void); exists, the symbol must be called "retro_foo".
  * The returned function pointer must be cast to the corresponding type.
  */
 typedef retro_proc_address_t (*retro_get_proc_address_t)(const char *sym);
 
 struct retro_get_proc_address_interface
 {
    retro_get_proc_address_t get_proc_address;
 };
 
 enum retro_log_level
 {
    RETRO_LOG_DEBUG = 0,
    RETRO_LOG_INFO,
    RETRO_LOG_WARN,
    RETRO_LOG_ERROR,
 
    RETRO_LOG_DUMMY = 2147483647
 };
 
 /* Logging function. Takes log level argument as well. */
 typedef void (*retro_log_printf_t)(enum retro_log_level level,
       const char *fmt, ...);
 
 struct retro_log_callback
 {
    retro_log_printf_t log;
 };
 
 /* Performance related functions */
 
 /* ID values for SIMD CPU features */
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 typedef uint64_t retro_perf_tick_t;
 typedef int64_t retro_time_t;
 
 struct retro_perf_counter
 {
    const char *ident;
    retro_perf_tick_t start;
    retro_perf_tick_t total;
    retro_perf_tick_t call_cnt;
 
    bool registered;
 };
 
 /* Returns current time in microseconds.
  * Tries to use the most accurate timer available.
  */
 typedef retro_time_t (*retro_perf_get_time_usec_t)(void);
 
 /* A simple counter. Usually nanoseconds, but can also be CPU cycles.
  * Can be used directly if desired (when creating a more sophisticated 
  * performance counter system).
  * */
 typedef retro_perf_tick_t (*retro_perf_get_counter_t)(void);
 
 /* Returns a bit-mask of detected CPU features (RETRO_SIMD_*). */
 typedef uint64_t (*retro_get_cpu_features_t)(void);
 
 /* Asks frontend to log and/or display the state of performance counters.
  * Performance counters can always be poked into manually as well.
  */
 typedef void (*retro_perf_log_t)(void);
 
 /* Register a performance counter.
  * ident field must be set with a discrete value and other values in 
  * retro_perf_counter must be 0.
  * Registering can be called multiple times. To avoid calling to 
  * frontend redundantly, you can check registered field first. */
 typedef void (*retro_perf_register_t)(struct retro_perf_counter *counter);
 
 /* Starts a registered counter. */
 typedef void (*retro_perf_start_t)(struct retro_perf_counter *counter);
 
 /* Stops a registered counter. */
 typedef void (*retro_perf_stop_t)(struct retro_perf_counter *counter);
 
 /* For convenience it can be useful to wrap register, start and stop in macros.
  * E.g.:
  * #ifdef LOG_PERFORMANCE
  * 
  * 
  * 
  * #else
  * ... Blank macros ...
  * #endif
  *
  * These can then be used mid-functions around code snippets.
  *
  * extern struct retro_perf_callback perf_cb;  * Somewhere in the core.
  *
  * void do_some_heavy_work(void)
  * {
  *    RETRO_PERFORMANCE_INIT(cb, work_1;
  *    RETRO_PERFORMANCE_START(cb, work_1);
  *    heavy_work_1();
  *    RETRO_PERFORMANCE_STOP(cb, work_1);
  *
  *    RETRO_PERFORMANCE_INIT(cb, work_2);
  *    RETRO_PERFORMANCE_START(cb, work_2);
  *    heavy_work_2();
  *    RETRO_PERFORMANCE_STOP(cb, work_2);
  * }
  *
  * void retro_deinit(void)
  * {
  *    perf_cb.perf_log();  * Log all perf counters here for example.
  * }
  */
 
 struct retro_perf_callback
 {
    retro_perf_get_time_usec_t    get_time_usec;
    retro_get_cpu_features_t      get_cpu_features;
 
    retro_perf_get_counter_t      get_perf_counter;
    retro_perf_register_t         perf_register;
    retro_perf_start_t            perf_start;
    retro_perf_stop_t             perf_stop;
    retro_perf_log_t              perf_log;
 };
 
 /* FIXME: Document the sensor API and work out behavior.
  * It will be marked as experimental until then.
  */
 enum retro_sensor_action
 {
    RETRO_SENSOR_ACCELEROMETER_ENABLE = 0,
    RETRO_SENSOR_ACCELEROMETER_DISABLE,
 
    RETRO_SENSOR_DUMMY = 2147483647
 };
 
 /* Id values for SENSOR types. */
 
 
 
 
 typedef bool (*retro_set_sensor_state_t)(unsigned port, 
       enum retro_sensor_action action, unsigned rate);
 
 typedef float (*retro_sensor_get_input_t)(unsigned port, unsigned id);
 
 struct retro_sensor_interface
 {
    retro_set_sensor_state_t set_sensor_state;
    retro_sensor_get_input_t get_sensor_input;
 };
 
 enum retro_camera_buffer
 {
    RETRO_CAMERA_BUFFER_OPENGL_TEXTURE = 0,
    RETRO_CAMERA_BUFFER_RAW_FRAMEBUFFER,
 
    RETRO_CAMERA_BUFFER_DUMMY = 2147483647
 };
 
 /* Starts the camera driver. Can only be called in retro_run(). */
 typedef bool (*retro_camera_start_t)(void);
 
 /* Stops the camera driver. Can only be called in retro_run(). */
 typedef void (*retro_camera_stop_t)(void);
 
 /* Callback which signals when the camera driver is initialized 
  * and/or deinitialized.
  * retro_camera_start_t can be called in initialized callback.
  */
 typedef void (*retro_camera_lifetime_status_t)(void);
 
 /* A callback for raw framebuffer data. buffer points to an XRGB8888 buffer.
  * Width, height and pitch are similar to retro_video_refresh_t.
  * First pixel is top-left origin.
  */
 typedef void (*retro_camera_frame_raw_framebuffer_t)(const uint32_t *buffer, 
       unsigned width, unsigned height, size_t pitch);
 
 /* A callback for when OpenGL textures are used.
  *
  * texture_id is a texture owned by camera driver.
  * Its state or content should be considered immutable, except for things like 
  * texture filtering and clamping.
  *
  * texture_target is the texture target for the GL texture.
  * These can include e.g. GL_TEXTURE_2D, GL_TEXTURE_RECTANGLE, and possibly 
  * more depending on extensions.
  *
  * affine points to a packed 3x3 column-major matrix used to apply an affine 
  * transform to texture coordinates. (affine_matrix * vec3(coord_x, coord_y, 1.0))
  * After transform, normalized texture coord (0, 0) should be bottom-left 
  * and (1, 1) should be top-right (or (width, height) for RECTANGLE).
  *
  * GL-specific typedefs are avoided here to avoid relying on gl.h in 
  * the API definition.
  */
 typedef void (*retro_camera_frame_opengl_texture_t)(unsigned texture_id, 
       unsigned texture_target, const float *affine);
 
 struct retro_camera_callback
 {
    /* Set by libretro core. 
     * Example bitmask: caps = (1 << RETRO_CAMERA_BUFFER_OPENGL_TEXTURE) | (1 << RETRO_CAMERA_BUFFER_RAW_FRAMEBUFFER).
     */
    uint64_t caps; 
 
    /* Desired resolution for camera. Is only used as a hint. */
    unsigned width;
    unsigned height;
 
    /* Set by frontend. */
    retro_camera_start_t start;
    retro_camera_stop_t stop;
 
    /* Set by libretro core if raw framebuffer callbacks will be used. */
    retro_camera_frame_raw_framebuffer_t frame_raw_framebuffer;
 
    /* Set by libretro core if OpenGL texture callbacks will be used. */
    retro_camera_frame_opengl_texture_t frame_opengl_texture; 
 
    /* Set by libretro core. Called after camera driver is initialized and 
     * ready to be started.
     * Can be NULL, in which this callback is not called.
     */
    retro_camera_lifetime_status_t initialized;
 
    /* Set by libretro core. Called right before camera driver is 
     * deinitialized.
     * Can be NULL, in which this callback is not called.
     */
    retro_camera_lifetime_status_t deinitialized;
 };
 
 /* Sets the interval of time and/or distance at which to update/poll 
  * location-based data.
  *
  * To ensure compatibility with all location-based implementations,
  * values for both interval_ms and interval_distance should be provided.
  *
  * interval_ms is the interval expressed in milliseconds.
  * interval_distance is the distance interval expressed in meters.
  */
 typedef void (*retro_location_set_interval_t)(unsigned interval_ms,
       unsigned interval_distance);
 
 /* Start location services. The device will start listening for changes to the
  * current location at regular intervals (which are defined with 
  * retro_location_set_interval_t). */
 typedef bool (*retro_location_start_t)(void);
 
 /* Stop location services. The device will stop listening for changes 
  * to the current location. */
 typedef void (*retro_location_stop_t)(void);
 
 /* Get the position of the current location. Will set parameters to 
  * 0 if no new  location update has happened since the last time. */
 typedef bool (*retro_location_get_position_t)(double *lat, double *lon,
       double *horiz_accuracy, double *vert_accuracy);
 
 /* Callback which signals when the location driver is initialized 
  * and/or deinitialized.
  * retro_location_start_t can be called in initialized callback.
  */
 typedef void (*retro_location_lifetime_status_t)(void);
 
 struct retro_location_callback
 {
    retro_location_start_t         start;
    retro_location_stop_t          stop;
    retro_location_get_position_t  get_position;
    retro_location_set_interval_t  set_interval;
 
    retro_location_lifetime_status_t initialized;
    retro_location_lifetime_status_t deinitialized;
 };
 
 enum retro_rumble_effect
 {
    RETRO_RUMBLE_STRONG = 0,
    RETRO_RUMBLE_WEAK = 1,
 
    RETRO_RUMBLE_DUMMY = 2147483647
 };
 
 /* Sets rumble state for joypad plugged in port 'port'. 
  * Rumble effects are controlled independently,
  * and setting e.g. strong rumble does not override weak rumble.
  * Strength has a range of [0, 0xffff].
  *
  * Returns true if rumble state request was honored. 
  * Calling this before first retro_run() is likely to return false. */
 typedef bool (*retro_set_rumble_state_t)(unsigned port, 
       enum retro_rumble_effect effect, uint16_t strength);
 
 struct retro_rumble_interface
 {
    retro_set_rumble_state_t set_rumble_state;
 };
 
 /* Notifies libretro that audio data should be written. */
 typedef void (*retro_audio_callback_t)(void);
 
 /* True: Audio driver in frontend is active, and callback is 
  * expected to be called regularily.
  * False: Audio driver in frontend is paused or inactive. 
  * Audio callback will not be called until set_state has been 
  * called with true.
  * Initial state is false (inactive).
  */
 typedef void (*retro_audio_set_state_callback_t)(bool enabled);
 
 struct retro_audio_callback
 {
    retro_audio_callback_t callback;
    retro_audio_set_state_callback_t set_state;
 };
 
 /* Notifies a libretro core of time spent since last invocation 
  * of retro_run() in microseconds.
  *
  * It will be called right before retro_run() every frame.
  * The frontend can tamper with timing to support cases like 
  * fast-forward, slow-motion and framestepping.
  *
  * In those scenarios the reference frame time value will be used. */
 typedef int64_t retro_usec_t;
 typedef void (*retro_frame_time_callback_t)(retro_usec_t usec);
 struct retro_frame_time_callback
 {
    retro_frame_time_callback_t callback;
    /* Represents the time of one frame. It is computed as 
     * 1000000 / fps, but the implementation will resolve the 
     * rounding to ensure that framestepping, etc is exact. */
    retro_usec_t reference;
 };
 
 /* Pass this to retro_video_refresh_t if rendering to hardware.
  * Passing NULL to retro_video_refresh_t is still a frame dupe as normal.
  * */
 
 
 /* Invalidates the current HW context.
  * Any GL state is lost, and must not be deinitialized explicitly.
  * If explicit deinitialization is desired by the libretro core,
  * it should implement context_destroy callback.
  * If called, all GPU resources must be reinitialized.
  * Usually called when frontend reinits video driver.
  * Also called first time video driver is initialized, 
  * allowing libretro core to initialize resources.
  */
 typedef void (*retro_hw_context_reset_t)(void);
 
 /* Gets current framebuffer which is to be rendered to.
  * Could change every frame potentially.
  */
 typedef uintptr_t (*retro_hw_get_current_framebuffer_t)(void);
 
 /* Get a symbol from HW context. */
 typedef retro_proc_address_t (*retro_hw_get_proc_address_t)(const char *sym);
 
 enum retro_hw_context_type
 {
    RETRO_HW_CONTEXT_NONE             = 0,
    /* OpenGL 2.x. Driver can choose to use latest compatibility context. */
    RETRO_HW_CONTEXT_OPENGL           = 1, 
    /* OpenGL ES 2.0. */
    RETRO_HW_CONTEXT_OPENGLES2        = 2,
    /* Modern desktop core GL context. Use version_major/
     * version_minor fields to set GL version. */
    RETRO_HW_CONTEXT_OPENGL_CORE      = 3,
    /* OpenGL ES 3.0 */
    RETRO_HW_CONTEXT_OPENGLES3        = 4,
    /* OpenGL ES 3.1+. Set version_major/version_minor. For GLES2 and GLES3,
     * use the corresponding enums directly. */
    RETRO_HW_CONTEXT_OPENGLES_VERSION = 5,
 
    /* Vulkan, see RETRO_ENVIRONMENT_GET_HW_RENDER_INTERFACE. */
    RETRO_HW_CONTEXT_VULKAN           = 6,
 
    RETRO_HW_CONTEXT_DUMMY = 2147483647
 };
 
 struct retro_hw_render_callback
 {
    /* Which API to use. Set by libretro core. */
    enum retro_hw_context_type context_type;
 
    /* Called when a context has been created or when it has been reset.
     * An OpenGL context is only valid after context_reset() has been called.
     *
     * When context_reset is called, OpenGL resources in the libretro 
     * implementation are guaranteed to be invalid.
     *
     * It is possible that context_reset is called multiple times during an 
     * application lifecycle.
     * If context_reset is called without any notification (context_destroy),
     * the OpenGL context was lost and resources should just be recreated
     * without any attempt to "free" old resources.
     */
    retro_hw_context_reset_t context_reset;
 
    /* Set by frontend.
     * TODO: This is rather obsolete. The frontend should not
     * be providing preallocated framebuffers. */
    retro_hw_get_current_framebuffer_t get_current_framebuffer;
 
    /* Set by frontend.
     * Can return all relevant functions, including glClear on Windows. */
    retro_hw_get_proc_address_t get_proc_address;
 
    /* Set if render buffers should have depth component attached.
     * TODO: Obsolete. */
    bool depth;
 
    /* Set if stencil buffers should be attached.
     * TODO: Obsolete. */
    bool stencil;
 
    /* If depth and stencil are true, a packed 24/8 buffer will be added. 
     * Only attaching stencil is invalid and will be ignored. */
 
    /* Use conventional bottom-left origin convention. If false, 
     * standard libretro top-left origin semantics are used.
     * TODO: Move to GL specific interface. */
    bool bottom_left_origin;
    
    /* Major version number for core GL context or GLES 3.1+. */
    unsigned version_major;
 
    /* Minor version number for core GL context or GLES 3.1+. */
    unsigned version_minor;
 
    /* If this is true, the frontend will go very far to avoid 
     * resetting context in scenarios like toggling fullscreen, etc.
     * TODO: Obsolete? Maybe frontend should just always assume this ...
     */
    bool cache_context;
 
    /* The reset callback might still be called in extreme situations 
     * such as if the context is lost beyond recovery.
     *
     * For optimal stability, set this to false, and allow context to be 
     * reset at any time.
     */
    
    /* A callback to be called before the context is destroyed in a 
     * controlled way by the frontend. */
    retro_hw_context_reset_t context_destroy;
 
    /* OpenGL resources can be deinitialized cleanly at this step.
     * context_destroy can be set to NULL, in which resources will 
     * just be destroyed without any notification.
     *
     * Even when context_destroy is non-NULL, it is possible that 
     * context_reset is called without any destroy notification.
     * This happens if context is lost by external factors (such as 
     * notified by GL_ARB_robustness).
     *
     * In this case, the context is assumed to be already dead,
     * and the libretro implementation must not try to free any OpenGL 
     * resources in the subsequent context_reset.
     */
 
    /* Creates a debug context. */
    bool debug_context;
 };
 
 /* Callback type passed in RETRO_ENVIRONMENT_SET_KEYBOARD_CALLBACK. 
  * Called by the frontend in response to keyboard events.
  * down is set if the key is being pressed, or false if it is being released.
  * keycode is the RETROK value of the char.
  * character is the text character of the pressed key. (UTF-32).
  * key_modifiers is a set of RETROKMOD values or'ed together.
  *
  * The pressed/keycode state can be indepedent of the character.
  * It is also possible that multiple characters are generated from a 
  * single keypress.
  * Keycode events should be treated separately from character events.
  * However, when possible, the frontend should try to synchronize these.
  * If only a character is posted, keycode should be RETROK_UNKNOWN.
  *
  * Similarily if only a keycode event is generated with no corresponding 
  * character, character should be 0.
  */
 typedef void (*retro_keyboard_event_t)(bool down, unsigned keycode, 
       uint32_t character, uint16_t key_modifiers);
 
 struct retro_keyboard_callback
 {
    retro_keyboard_event_t callback;
 };
 
 /* Callbacks for RETRO_ENVIRONMENT_SET_DISK_CONTROL_INTERFACE.
  * Should be set for implementations which can swap out multiple disk 
  * images in runtime.
  *
  * If the implementation can do this automatically, it should strive to do so.
  * However, there are cases where the user must manually do so.
  *
  * Overview: To swap a disk image, eject the disk image with 
  * set_eject_state(true).
  * Set the disk index with set_image_index(index). Insert the disk again 
  * with set_eject_state(false).
  */
 
 /* If ejected is true, "ejects" the virtual disk tray.
  * When ejected, the disk image index can be set.
  */
 typedef bool (*retro_set_eject_state_t)(bool ejected);
 
 /* Gets current eject state. The initial state is 'not ejected'. */
 typedef bool (*retro_get_eject_state_t)(void);
 
 /* Gets current disk index. First disk is index 0.
  * If return value is >= get_num_images(), no disk is currently inserted.
  */
 typedef unsigned (*retro_get_image_index_t)(void);
 
 /* Sets image index. Can only be called when disk is ejected.
  * The implementation supports setting "no disk" by using an 
  * index >= get_num_images().
  */
 typedef bool (*retro_set_image_index_t)(unsigned index);
 
 /* Gets total number of images which are available to use. */
 typedef unsigned (*retro_get_num_images_t)(void);
 
 struct retro_game_info;
 
 /* Replaces the disk image associated with index.
  * Arguments to pass in info have same requirements as retro_load_game().
  * Virtual disk tray must be ejected when calling this.
  *
  * Replacing a disk image with info = NULL will remove the disk image 
  * from the internal list.
  * As a result, calls to get_image_index() can change.
  *
  * E.g. replace_image_index(1, NULL), and previous get_image_index() 
  * returned 4 before.
  * Index 1 will be removed, and the new index is 3.
  */
 typedef bool (*retro_replace_image_index_t)(unsigned index,
       const struct retro_game_info *info);
 
 /* Adds a new valid index (get_num_images()) to the internal disk list.
  * This will increment subsequent return values from get_num_images() by 1.
  * This image index cannot be used until a disk image has been set 
  * with replace_image_index. */
 typedef bool (*retro_add_image_index_t)(void);
 
 struct retro_disk_control_callback
 {
    retro_set_eject_state_t set_eject_state;
    retro_get_eject_state_t get_eject_state;
 
    retro_get_image_index_t get_image_index;
    retro_set_image_index_t set_image_index;
    retro_get_num_images_t  get_num_images;
 
    retro_replace_image_index_t replace_image_index;
    retro_add_image_index_t add_image_index;
 };
 
 enum retro_pixel_format
 {
    /* 0RGB1555, native endian.
     * 0 bit must be set to 0.
     * This pixel format is default for compatibility concerns only.
     * If a 15/16-bit pixel format is desired, consider using RGB565. */
    RETRO_PIXEL_FORMAT_0RGB1555 = 0,
 
    /* XRGB8888, native endian.
     * X bits are ignored. */
    RETRO_PIXEL_FORMAT_XRGB8888 = 1,
 
    /* RGB565, native endian.
     * This pixel format is the recommended format to use if a 15/16-bit
     * format is desired as it is the pixel format that is typically 
     * available on a wide range of low-power devices.
     *
     * It is also natively supported in APIs like OpenGL ES. */
    RETRO_PIXEL_FORMAT_RGB565   = 2,
 
    /* Ensure sizeof() == sizeof(int). */
    RETRO_PIXEL_FORMAT_UNKNOWN  = 2147483647
 };
 
 struct retro_message
 {
    const char *msg;        /* Message to be displayed. */
    unsigned    frames;     /* Duration in frames of message. */
 };
 
 /* Describes how the libretro implementation maps a libretro input bind
  * to its internal input system through a human readable string.
  * This string can be used to better let a user configure input. */
 struct retro_input_descriptor
 {
    /* Associates given parameters with a description. */
    unsigned port;
    unsigned device;
    unsigned index;
    unsigned id;
 
    /* Human readable description for parameters.
     * The pointer must remain valid until
     * retro_unload_game() is called. */
    const char *description; 
 };
 
 struct retro_system_info
 {
    /* All pointers are owned by libretro implementation, and pointers must 
     * remain valid until retro_deinit() is called. */
 
    const char *library_name;      /* Descriptive name of library. Should not 
                                    * contain any version numbers, etc. */
    const char *library_version;   /* Descriptive version of core. */
 
    const char *valid_extensions;  /* A string listing probably content 
                                    * extensions the core will be able to 
                                    * load, separated with pipe.
                                    * I.e. "bin|rom|iso".
                                    * Typically used for a GUI to filter 
                                    * out extensions. */
 
    /* If true, retro_load_game() is guaranteed to provide a valid pathname 
     * in retro_game_info::path.
     * ::data and ::size are both invalid.
     *
     * If false, ::data and ::size are guaranteed to be valid, but ::path 
     * might not be valid.
     *
     * This is typically set to true for libretro implementations that must 
     * load from file.
     * Implementations should strive for setting this to false, as it allows 
     * the frontend to perform patching, etc. */
    bool        need_fullpath;                                       
 
    /* If true, the frontend is not allowed to extract any archives before 
     * loading the real content.
     * Necessary for certain libretro implementations that load games 
     * from zipped archives. */
    bool        block_extract;     
 };
 
 struct retro_game_geometry
 {
    unsigned base_width;    /* Nominal video width of game. */
    unsigned base_height;   /* Nominal video height of game. */
    unsigned max_width;     /* Maximum possible width of game. */
    unsigned max_height;    /* Maximum possible height of game. */
 
    float    aspect_ratio;  /* Nominal aspect ratio of game. If
                             * aspect_ratio is <= 0.0, an aspect ratio
                             * of base_width / base_height is assumed.
                             * A frontend could override this setting,
                             * if desired. */
 };
 
 struct retro_system_timing
 {
    double fps;             /* FPS of video content. */
    double sample_rate;     /* Sampling rate of audio. */
 };
 
 struct retro_system_av_info
 {
    struct retro_game_geometry geometry;
    struct retro_system_timing timing;
 };
 
 struct retro_variable
 {
    /* Variable to query in RETRO_ENVIRONMENT_GET_VARIABLE.
     * If NULL, obtains the complete environment string if more 
     * complex parsing is necessary.
     * The environment string is formatted as key-value pairs 
     * delimited by semicolons as so:
     * "key1=value1;key2=value2;..."
     */
    const char *key;
    
    /* Value to be obtained. If key does not exist, it is set to NULL. */
    const char *value;
 };
 
 struct retro_game_info
 {
    const char *path;       /* Path to game, UTF-8 encoded.
                             * Sometimes used as a reference for building other paths.
                             * May be NULL if game was loaded from stdin or similar,
                             * but in this case some cores will be unable to load `data`.
                             * So, it is preferable to fabricate something here instead
                             * of passing NULL, which will help more cores to succeed.
                             * retro_system_info::need_fullpath requires
                             * that this path is valid. */
    const void *data;       /* Memory buffer of loaded game. Will be NULL 
                             * if need_fullpath was set. */
    size_t      size;       /* Size of memory buffer. */
    const char *meta;       /* String of implementation specific meta-data. */
 };
 
 
    /* The core will write to the buffer provided by retro_framebuffer::data. */
 
    /* The core will read from retro_framebuffer::data. */
 
    /* The memory in data is cached.
     * If not cached, random writes and/or reading from the buffer is expected to be very slow. */
 struct retro_framebuffer
 {
    void *data;                      /* The framebuffer which the core can render into.
                                        Set by frontend in GET_CURRENT_SOFTWARE_FRAMEBUFFER.
                                        The initial contents of data are unspecified. */
    unsigned width;                  /* The framebuffer width used by the core. Set by core. */
    unsigned height;                 /* The framebuffer height used by the core. Set by core. */
    size_t pitch;                    /* The number of bytes between the beginning of a scanline,
                                        and beginning of the next scanline.
                                        Set by frontend in GET_CURRENT_SOFTWARE_FRAMEBUFFER. */
    enum retro_pixel_format format;  /* The pixel format the core must use to render into data.
                                        This format could differ from the format used in
                                        SET_PIXEL_FORMAT.
                                        Set by frontend in GET_CURRENT_SOFTWARE_FRAMEBUFFER. */
 
    unsigned access_flags;           /* How the core will access the memory in the framebuffer.
                                        RETRO_MEMORY_ACCESS_* flags.
                                        Set by core. */
    unsigned memory_flags;           /* Flags telling core how the memory has been mapped.
                                        RETRO_MEMORY_TYPE_* flags.
                                        Set by frontend in GET_CURRENT_SOFTWARE_FRAMEBUFFER. */
 };
 
 /* Callbacks */
 
 /* Environment callback. Gives implementations a way of performing 
  * uncommon tasks. Extensible. */
 typedef bool (*retro_environment_t)(unsigned cmd, void *data);
 
 /* Render a frame. Pixel format is 15-bit 0RGB1555 native endian 
  * unless changed (see RETRO_ENVIRONMENT_SET_PIXEL_FORMAT).
  *
  * Width and height specify dimensions of buffer.
  * Pitch specifices length in bytes between two lines in buffer.
  *
  * For performance reasons, it is highly recommended to have a frame 
  * that is packed in memory, i.e. pitch == width * byte_per_pixel.
  * Certain graphic APIs, such as OpenGL ES, do not like textures 
  * that are not packed in memory.
  */
 typedef void (*retro_video_refresh_t)(const void *data, unsigned width,
       unsigned height, size_t pitch);
 
 /* Renders a single audio frame. Should only be used if implementation 
  * generates a single sample at a time.
  * Format is signed 16-bit native endian.
  */
 typedef void (*retro_audio_sample_t)(int16_t left, int16_t right);
 
 /* Renders multiple audio frames in one go.
  *
  * One frame is defined as a sample of left and right channels, interleaved.
  * I.e. int16_t buf[4] = { l, r, l, r }; would be 2 frames.
  * Only one of the audio callbacks must ever be used.
  */
 typedef size_t (*retro_audio_sample_batch_t)(const int16_t *data,
       size_t frames);
 
 /* Polls input. */
 typedef void (*retro_input_poll_t)(void);
 
 /* Queries for input for player 'port'. device will be masked with 
  * RETRO_DEVICE_MASK.
  *
  * Specialization of devices such as RETRO_DEVICE_JOYPAD_MULTITAP that 
  * have been set with retro_set_controller_port_device()
  * will still use the higher level RETRO_DEVICE_JOYPAD to request input.
  */
 typedef int16_t (*retro_input_state_t)(unsigned port, unsigned device, 
       unsigned index, unsigned id);
 
 /* Sets callbacks. retro_set_environment() is guaranteed to be called 
  * before retro_init().
  *
  * The rest of the set_* functions are guaranteed to have been called 
  * before the first call to retro_run() is made. */
 void retro_set_environment(retro_environment_t);
 void retro_set_video_refresh(retro_video_refresh_t);
 void retro_set_audio_sample(retro_audio_sample_t);
 void retro_set_audio_sample_batch(retro_audio_sample_batch_t);
 void retro_set_input_poll(retro_input_poll_t);
 void retro_set_input_state(retro_input_state_t);
 
 /* Library global initialization/deinitialization. */
 void retro_init(void);
 void retro_deinit(void);
 
 /* Must return RETRO_API_VERSION. Used to validate ABI compatibility
  * when the API is revised. */
 unsigned retro_api_version(void);
 
 /* Gets statically known system info. Pointers provided in *info 
  * must be statically allocated.
  * Can be called at any time, even before retro_init(). */
 void retro_get_system_info(struct retro_system_info *info);
 
 /* Gets information about system audio/video timings and geometry.
  * Can be called only after retro_load_game() has successfully completed.
  * NOTE: The implementation of this function might not initialize every 
  * variable if needed.
  * E.g. geom.aspect_ratio might not be initialized if core doesn't 
  * desire a particular aspect ratio. */
 void retro_get_system_av_info(struct retro_system_av_info *info);
 
 /* Sets device to be used for player 'port'.
  * By default, RETRO_DEVICE_JOYPAD is assumed to be plugged into all 
  * available ports.
  * Setting a particular device type is not a guarantee that libretro cores 
  * will only poll input based on that particular device type. It is only a 
  * hint to the libretro core when a core cannot automatically detect the 
  * appropriate input device type on its own. It is also relevant when a 
  * core can change its behavior depending on device type. */
 void retro_set_controller_port_device(unsigned port, unsigned device);
 
 /* Resets the current game. */
 void retro_reset(void);
 
 /* Runs the game for one video frame.
  * During retro_run(), input_poll callback must be called at least once.
  * 
  * If a frame is not rendered for reasons where a game "dropped" a frame,
  * this still counts as a frame, and retro_run() should explicitly dupe 
  * a frame if GET_CAN_DUPE returns true.
  * In this case, the video callback can take a NULL argument for data.
  */
 void retro_run(void);
 
 /* Returns the amount of data the implementation requires to serialize 
  * internal state (save states).
  * Between calls to retro_load_game() and retro_unload_game(), the 
  * returned size is never allowed to be larger than a previous returned 
  * value, to ensure that the frontend can allocate a save state buffer once.
  */
 size_t retro_serialize_size(void);
 
 /* Serializes internal state. If failed, or size is lower than
  * retro_serialize_size(), it should return false, true otherwise. */
 bool retro_serialize(void *data, size_t size);
 bool retro_unserialize(const void *data, size_t size);
 
 void retro_cheat_reset(void);
 void retro_cheat_set(unsigned index, bool enabled, const char *code);
 
 /* Loads a game. */
 bool retro_load_game(const struct retro_game_info *game);
 
 /* Loads a "special" kind of game. Should not be used,
  * except in extreme cases. */
 bool retro_load_game_special(
   unsigned game_type,
   const struct retro_game_info *info, size_t num_info
 );
 
 /* Unloads a currently loaded game. */
 void retro_unload_game(void);
 
 /* Gets region of game. */
 unsigned retro_get_region(void);
 
 /* Gets region of memory. */
 void *retro_get_memory_data(unsigned id);
 size_t retro_get_memory_size(unsigned id);


 ///////////// helper
 void core_log(enum retro_log_level level, const char *fmt, ...);
]]

class.RetroView(ui.VideoSurface)

local me = nil

function core_environment(cmd, data)
    if cmd == 27 then -- RETRO_ENVIRONMENT_GET_LOG_INTERFACE
        local cb = ffi.cast("struct retro_log_callback*", data)
        cb.log = me.helper.core_log
        return true
    elseif cmd == 3 then -- RETRO_ENVIRONMENT_GET_CAN_DUPE
        return false
    elseif cmd == 10 then -- RETRO_ENVIRONMENT_SET_PIXEL_FORMAT
        local fmt = ffi.cast("enum retro_pixel_format*", data)
        return fmt[0] == 1 -- XRGB
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
    print("Yo video", width, height)
end

function RetroView:loadCore(corePath)
    self.handle = ffi.load(corePath, false)
    self.helper = ffi.load("lua/libhelper.so", false)
    assert(self.handle)
    self.handle.retro_set_environment(core_environment)
    self.handle.retro_set_video_refresh(core_video_refresh)
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
    print("Yo data", self.info, #data)
    local ok = self.handle.retro_load_game(self.info)
    assert(ok)

    self.av = ffi.new("struct retro_system_av_info")
    self.handle.retro_get_system_av_info(self.av)
    
end

function RetroView:_init(bounds)
    self:super(bounds)
    me = self
    self:loadCore("/home/nevyn/.config/retroarch/cores/nestopia_libretro.so")
    self:loadGame("roms/tmnt.nes")
end

return RetroView
