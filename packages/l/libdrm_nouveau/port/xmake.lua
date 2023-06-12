add_rules("mode.debug", "mode.release")

set_allowedplats("switch")
set_allowedarchs("switch|aarch64")

add_requires("switch-llvm-sysroot")

target("drm_nouveau")
    set_kind("static")
    add_rules("mode.debug", "mode.release")

    set_languages("gnu11")

    add_files("source/**.c")

    add_headerfiles("include/(**.h)")

    add_includedirs("include")

    add_packages("switch-llvm-sysroot")