local flags = {
    "-fno-builtin",
    "-Wno-implicit-function-declaration",
    "-Wno-int-conversion",
    "-nostdlibinc",
    "-nostdlib"
}

add_cxflags(flags)
add_asflags(flags)

add_rules("mode.debug", "mode.release")

set_allowedplats("switch")
set_allowedarchs("switch|aarch64")

target("newlib")
    set_kind("headeronly")

    -- detect it instead of hardcode it
    set_configvar("_MB_CAPABLE", 1)
    set_configvar("_MB_LEN_MAX", 8)
    set_configvar("_ATEXIT_DYNAMIC_ALLOC", 1)
    set_configvar("_FSEEK_OPTIMIZATION", 1)
    set_configvar("_FVWRITE_IN_STREAMIO", 1)
    set_configvar("_HAVE_CC_INHIBIT_LOOP_TO_LIBCALL", 1)
    set_configvar("_HAVE_INITFINI_ARRAY", 1)
    set_configvar("_HAVE_INIT_FINI", 1)
    set_configvar("_HAVE_LONG_DOUBLE", 1)
    set_configvar("_REENT_CHECK_VERIFY", 1)
    set_configvar("_UNBUF_STREAM_OPT", 1)
    set_configvar("_WANT_IO_LONG_LONG", 1)
    set_configvar("_WANT_USE_GDTOA", 1)
    set_configvar("_WANT_IO_POS_ARGS", 1)

    add_configfiles("newlib/newlib.hin", {filename = 'newlib.h'})

    set_configvar("_NEWLIB_VERSION", "4.3.0")
    set_configvar("__NEWLIB__", 4)
    set_configvar("__NEWLIB_MINOR__", 3)
    set_configvar("__NEWLIB_PATCHLEVEL__", 0)

    add_defines("__NO_SYSCALLS__", "__DYNAMIC_REENT__", "REENTRANT_SYSCALLS_PROVIDED", "_HAVE_INIT_FINI", "HAVE_CONFIG_H", "__DEFAULT_UTF8__")
    add_defines("_GNU_SOURCE=1", "_LIBC", "_NEWLIB_VERSION=4.3.0", "__NEWLIB__=4", {public = true})

    add_configfiles("newlib/_newlib_version.hin", {filename = "_newlib_version.h"})

    add_headerfiles("$(buildir)/newlib.h")
    add_headerfiles("$(buildir)/_newlib_version.h")
    add_includedirs("$(buildir)", {public = true})

target("libm")
    set_kind("$(kind)")

    add_packages("switch-llvm")

    add_files("newlib/libm/common/**.c")
    add_files("newlib/libm/complex/**.c")
    add_files("newlib/libm/fenv/**.c")
    add_files("newlib/libm/machine/aarch64/*.c")
    add_files("newlib/libm/math/**.c")

    add_defines("__NO_SYSCALLS__", "__DYNAMIC_REENT__", "REENTRANT_SYSCALLS_PROVIDED", "_HAVE_INIT_FINI", "HAVE_CONFIG_H", "__DEFAULT_UTF8__")
    add_includedirs("newlib/libm/common")

    set_prefixname("")

    set_extension(".a")

    set_exceptions("no-cxx")

    add_sysincludedirs("newlib/libc/machine/aarch64/", {public = true})
    add_sysincludedirs("newlib/libc/machine/aarch64/sys", {public = true})
    add_sysincludedirs("newlib/libc/sys/arm", {public = true})
    add_sysincludedirs("newlib/libc/include", {public = true})

    add_deps("newlib")

target("libc")
    set_kind("$(kind)")

    add_packages("switch-llvm")

    add_files("newlib/libc/argz/**.c")
    add_files("newlib/libc/ssp/*.c")
    add_files("newlib/libc/machine/aarch64/**.c")

    if is_mode("release") then
        remove_files("newlibc/machine/aarch64/memchr.c")
        remove_files("newlibc/machine/aarch64/memcmp.c")
        remove_files("newlibc/machine/aarch64/memcpy.c")
        remove_files("newlibc/machine/aarch64/memmove.c")
        remove_files("newlibc/machine/aarch64/memset.c")

        remove_files("newlibc/machine/aarch64/stpcpy.c")
        remove_files("newlibc/machine/aarch64/strchr.c")
        remove_files("newlibc/machine/aarch64/strchrnul.c")
        remove_files("newlibc/machine/aarch64/strcmp.c")
        remove_files("newlibc/machine/aarch64/strcpy.c")
        remove_files("newlibc/machine/aarch64/strlen.c")
        remove_files("newlibc/machine/aarch64/strncmp.c")
        remove_files("newlibc/machine/aarch64/strnlen.c")
        remove_files("newlibc/machine/aarch64/strrchr.c")

        remove_files("newlibc/machine/aarch64/rawmemchr.c")

        add_files("newlib/libc/machine/aarch64/**.S")
    else
        add_files("newlib/libc/machine/aarch64/setjmp.S")
    end

    add_files("newlib/libc/syscalls/*.c")
    remove_files("newlib/libc/syscalls/sysfcntl.c")
    add_files("newlib/libc/misc/*.c")
    add_files("newlib/libc/reent/*.c")
    add_files("newlib/libc/string/*.c")
    add_files("newlib/libc/locale/**.c")
    add_files("newlib/libc/stdio/*.c")
    remove_files("newlib/libc/stdio/nano-*.c")
    add_files("newlib/libc/search/*.c")
    add_files("newlib/libc/ctype/**.c")
    add_files("newlib/libc/stdlib/*.c")
    add_files("newlib/libc/errno/*.c")
    add_files("newlib/libc/time/*.c")
    add_files("newlib/libc/signal/*.c")

    add_defines("__NO_SYSCALLS__", "__DYNAMIC_REENT__", "REENTRANT_SYSCALLS_PROVIDED", "_HAVE_INIT_FINI", "HAVE_CONFIG_H", "__DEFAULT_UTF8__")

    set_prefixname("")

    set_extension(".a")

    set_exceptions("no-cxx")

    add_headerfiles("newlib/libc/include/(**.h)")
    add_headerfiles("newlib/libc/sys/arm/(sys/*.h)")

    add_sysincludedirs("newlib/libc/machine/aarch64/", {public = true})
    add_sysincludedirs("newlib/libc/machine/aarch64/sys", {public = true})
    add_sysincludedirs("newlib/libc/sys/arm", {public = true})
    add_sysincludedirs("newlib/libc/include", {public = true})

    add_deps("newlib", "libm")

target("libgloss")
    set_kind("headeronly")

    -- detect it instead of hardcode it
    set_configvar("HAVE_ASM_POPSECTION_DIRECTIVE", 1)
    set_configvar("HAVE_ASM_PREVIOUS_DIRECTIVE", 1)
    set_configvar("HAVE_ELF", 1)
    set_configvar("HAVE_GNU_LD", 0)
    set_configvar("HAVE_SECTION_ATTRIBUTES", 1)
    set_configvar("PACKAGE_BUGREPORT", "")
    set_configvar("PACKAGE_NAME", "libgloss")
    set_configvar("PACKAGE_STRING", "libgloss LIBGLOSS_VERSION")
    set_configvar("PACKAGE_TARNAME", "libgloss")
    set_configvar("PACKAGE_URL", "")
    set_configvar("PACKAGE_VERSION", "LIBGLOSS_VERSION")
    set_configvar("__SYMBOL_PREFIX", "")

    add_defines("HAVE_CONFIG_H", {public = true})


    add_sysincludedirs("newlib/libc/machine/aarch64/", {public = true})
    add_sysincludedirs("newlib/libc/machine/aarch64/sys", {public = true})
    add_sysincludedirs("newlib/libc/sys/arm", {public = true})
    add_sysincludedirs("newlib/libc/include", {public = true})

    add_configfiles("libgloss/config.h.in")
    add_headerfiles("$(buildir)/config.h")
    add_includedirs("$(buildir)", {public = true})
    add_includedirs(".", {public = true})

local modules = {
    librdimon = {
        dir = "aarch64",
        defines = {"SEMIHOST_V2", "ARM_RDI_MONITOR"},
        files = {"**.c", "*.S"}
    },
    libobjs = {
        dir = "aarch64",
        defines = {"SEMIHOST_V2"},
        files = {"*.S"}
    },
    libnosys = {
        dir = "libnosys",
        files = {"**.c"}
    },
    libsysbase = {
        dir = "libsysbase",
        defines = {"_BUILDING_LIBSYSBASE"},
        files = {"**.c"}
    }
}

for name, infos in pairs(modules) do
    target(name)
        set_kind("$(kind)")

        for _, filetype in ipairs(infos.files) do
            add_files(path.join("libgloss", infos.dir, filetype))
        end

        remove_files("libgloss/libsysbase/pthread.c")

        set_prefixname("")

        set_extension(".a")

        set_exceptions("no-cxx")

        add_includedirs(path.join("libgloss", infos.dir))

        if infos.defines then
            add_defines(table.unwrap(infos.defines))
        end

        add_deps("libgloss")
        add_packages("switch-llvm")
end

target("libpthread")
    set_kind("static")

    add_files("libgloss/libsysbase/pthread.c")

    set_prefixname("")

    set_extension(".a")

    set_exceptions("no-cxx")

    add_defines("_BUILDING_LIBSYSBASE")

    add_deps("libgloss")
    add_packages("switch-llvm")