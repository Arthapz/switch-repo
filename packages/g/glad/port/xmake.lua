add_rules("mode.debug", "mode.release")

set_allowedplats("switch")
set_allowedarchs("switch|aarch64")

add_requires("switch-llvm-sysroot", "switch-mesa")

target("glad")
    set_kind("static")

    set_languages("gnu11")

    add_files("source/**.c")

    add_headerfiles("include/(**.h)")

    add_includedirs("include")

    add_packages("switch-llvm-sysroot", "switch-mesa")
