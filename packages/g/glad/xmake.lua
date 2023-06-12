package("glad")
    set_policy("package.strict_compatibility", true)
    set_homepage("https://glad.dav1d.de/")
    set_description("Multi-Language Vulkan/GL/GLES/EGL/GLX/WGL Loader-Generator based on the official specs.")
    set_license("MIT")

    set_urls("https://github.com/devkitPro/switch-glad.git")
    add_versions("v0.1.27", "b8d8d43ba72c7f362eb0379e104053b587be31f8")

    add_deps("switch-llvm-sysroot", "switch-mesa")

    on_install("switch", function (package)
        os.cp(path.join(package:scriptdir(), "port", "xmake.lua"), "xmake.lua")

        local opt = {mode = package:debug() and "debug" or "release"}
        import("package.tools.xmake").install(package)
    end)
