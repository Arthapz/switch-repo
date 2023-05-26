package("switch-newlib")
    add_urls("https://github.com/Arthapz/newlib.git", {branch = "devkitPro"})
    add_versions("20230526-9", "4460d58a3de77b73982c46bfd3df5d8dd02620cd")

    add_defines("_GNU_SOURCE=1", "_LIBC", "_NEWLIB_VERSION=4.3.0", "__NEWLIB__=4")

    add_deps("switch-llvm", {kind = "binary", host = true})

    on_install("switch", function(package)
        import("package.tools.xmake").install(package)
    end)