package("switch-newlib")
    add_urls("https://github.com/Arthapz/newlib.git", {branch = "devkitPro"})
    add_versions("20230527", "92ac7b8e906a3d8c4e40c854fb0ac7697e172f8a")

    add_defines("_GNU_SOURCE=1", "_LIBC", "_NEWLIB_VERSION=4.3.0", "__NEWLIB__=4")

    add_deps("switch-llvm", {kind = "binary", host = true})

    on_install("switch", function(package)
        local opt ={ mode = package:debug() and "debug" or "release" }
        import("package.tools.xmake").install(package, opt)
    end)