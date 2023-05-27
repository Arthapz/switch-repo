package("switch-libnx")
    add_urls("https://github.com/Arthapz/libnx.git", {branch = "main"})
    add_versions("20230527", "404487b17d284766da0a33a2124dd1a84cb343fa")

    add_deps("switch-llvm", {kind = "binary", host = true})
    add_deps("switch-newlib", {debug = is_mode("debug")})

    add_defines("LIBNX_NO_DEPRECATION")

    on_install("switch", function(package)
        local opt ={ mode = package:debug() and "debug" or "release" }
        import("package.tools.xmake").install(package, opt)
    end)
