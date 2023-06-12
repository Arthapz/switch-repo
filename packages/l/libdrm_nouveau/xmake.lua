package("libdrm_nouveau")
    set_policy("package.strict_compatibility", true)
    add_urls("https://github.com/devkitPro/libdrm_nouveau/archive/refs/tags/v1.0.1.zip")
    add_versions("9.9.99", "326a06f70afc6134fe9af8a8d2a83bb7af10a2bbd105716c8a7a933a87c470fa")

    add_deps("switch-llvm-sysroot")

    on_install("switch", function(package)
        os.cp(path.join(package:scriptdir(), "port", "xmake.lua"), "xmake.lua")

        local opt = {mode = package:debug() and "debug" or "release"}
        import("package.tools.xmake").install(package, opt)
    end)