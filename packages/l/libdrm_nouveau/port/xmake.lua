add_rules("mode.debug", "mode.release")

set_allowedplats("switch")
set_allowedarchs("switch|aarch64")

add_requires("switch-llvm", {host = true})
add_requires("switch-llvm-runtimes", "switch-newlib", "libnx", {debug = is_mode("debug")})

target("drm_nouveau")
    set_kind("static")
    add_rules("mode.debug", "mode.release")

    set_languages("gnu11")

    add_files("source/**.c")

    add_headerfiles("include/(**.h)")

    add_includedirs("include")

    add_packages("switch-llvm-runtimes")
    add_packages("switch-llvm", "switch-newlib", "libnx")