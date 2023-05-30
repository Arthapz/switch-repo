package("switch-newlib")
    add_urls("https://github.com/Arthapz/newlib.git", {branch = "devkitPro"})
    add_versions("20230530", "f6759a064272826a6fb2e850ba20c324765fd758")

    add_defines("_GNU_SOURCE=1", "_LIBC", "_NEWLIB_VERSION=4.3.0", "__NEWLIB__=4")

    add_deps("switch-llvm", {host = true})

    on_load(function(package)
        package:set("links", "")
        package:add("ldflags", "-L" .. package:installdir("lib"), {force = true})
        package:add("ldflags", "-Wl,--start-group,-lc,-lm,-lpthread,-lsysbase,--end-group", {force = true})
        package:add("shflags", "-L" .. package:installdir("lib"), {force = true})
        package:add("shflags", "-Wl,--start-group,-lc,-lm,-lpthread,-lsysbase,--end-group", {force = true})
    end)

    on_install("switch", function(package)
        os.cp(path.join(package:scriptdir(), "port", "xmake.lua"), "xmake.lua")

        local opt = {mode = package:debug() and "debug" or "release"}
        import("package.tools.xmake").install(package, opt)
    end)