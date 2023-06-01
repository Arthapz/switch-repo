package("libnx")
    add_urls("https://github.com/Arthapz/libnx.git", {branch = "main"})
    add_versions("20230530", "b0e6258632f4f44888ba9b627b127b3d56579067")

    add_deps("switch-llvm", {kind = "binary", host = true})

    add_patches("20230530", "patch/switch.diff")

    add_defines("LIBNX_NO_DEPRECATION")

    on_install("switch", function(package)
        os.cp(path.join(package:scriptdir(), "port", "xmake.lua"), "xmake.lua")

        local opt = {mode = package:debug() and "debug" or "release"}
        import("package.tools.xmake").install(package, opt)
    end)
