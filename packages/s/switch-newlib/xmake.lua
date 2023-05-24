package("switch-newlib")
    add_urls("https://github.com/Arthapz/newlib.git", {branch = "devkitPro"})
    add_versions("20230526-6", "76a553cd2909fe9bf2fac22c5d789ecbc681a9d5")

    add_defines("_GNU_SOURCE=1", "_LIBC", "_NEWLIB_VERSION=4.3.0", "__NEWLIB__=4")

    on_install("switch", function(package)
        import("package.tools.xmake").install(package)
    end)