package("glad")

    set_homepage("https://glad.dav1d.de/")
    set_description("Multi-Language Vulkan/GL/GLES/EGL/GLX/WGL Loader-Generator based on the official specs.")
    set_license("MIT")

    add_urls("https://github.com/devkitPro/switch-glad.git")
    add_versions("v0.1.27", "b8d8d43ba72c7f362eb0379e104053b587be31f8")

    add_deps("switch-llvm-runtimes", {debug = is_mode("debug")})
    add_deps("switch-newlib", {debug = is_mode("debug")})
    add_deps("libnx", {debug = is_mode("debug")})
    add_deps("switch-mesa", {debug = is_mode("debug")})

    on_install("switch", function (package)
        io.writefile("xmake.lua", [[
add_rules("mode.debug", "mode.release")

set_allowedplats("switch")
set_allowedarchs("switch|aarch64")

add_requires("switch-llvm", {host = true})
add_requires("switch-llvm-runtimes", "switch-newlib", "libnx", "switch-mesa", {debug = is_mode("debug")})

target("glad")
    set_kind("static")

    set_languages("gnu11")

    add_files("source/**.c")

    add_headerfiles("include/(**.h)")

    add_includedirs("include")

    add_packages("switch-llvm", "switch-llvm-runtimes", "switch-newlib", "libnx", "switch-mesa")
        ]])
        import("package.tools.xmake").install(package)
    end)
