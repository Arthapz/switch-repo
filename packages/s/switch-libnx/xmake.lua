package("switch-libnx")
    add_urls("https://github.com/Arthapz/libnx.git", {branch = "main"})
    add_versions("20230523-3", "4921b6ab072e03fd5ae808aaa8abf1a8cde6109a")

    add_deps("switch-llvm", {kind = "binary", host = true})
    add_deps("switch-newlib")

    add_defines("LIBNX_NO_DEPRECATION")

    on_install("switch", function(package)
        import("package.tools.xmake").install(package)
    end)
