package("libnx")
    add_urls("https://github.com/Arthapz/libnx.git", {branch = "main"})
    add_versions("20230529", "2d4e057f469ca0439e6c92b08b6ea83b66c26ebd")

    add_deps("switch-llvm", {kind = "binary", host = true})

    add_patches("20230529", "patch/switch.diff")

    add_defines("LIBNX_NO_DEPRECATION")

    on_install("switch", function(package)
        os.cp(path.join(package:scriptdir(), "port", "xmake.lua"), "xmake.lua")

        local opt = {mode = package:debug() and "debug" or "release"}
        import("package.tools.xmake").install(package, opt)
    end)
