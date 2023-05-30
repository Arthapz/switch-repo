package("switch-newlib")
    add_urls("https://github.com/natinusala/borealis.git", {branch = "main"})
    add_versions("20230527", "20e2d33b6c4ffce139ce304c503c04f5b94da920")

    add_deps("switch-llvm", {kind = "binary", host = true})
    add_deps("meson", {kind = "binary", host = true})
    add_deps("ninja", {kind = "binary", host = true})

    add_deps("switch-llvm-runtimes", {debug = is_mode("debug")})
    add_deps("switch-newlib", {debug = is_mode("debug")})
    add_deps("switch-libnx", {debug = is_mode("debug")})

    on_install("switch", function(package)
        local opt = {}
        table.insert(opt, "-Ddefault_library=" .. (package:config("shared") and "shared" or "static"))

        if package:debug() then
            table.insert(opt, "--debug")
        end
        import("package.tools.meson").install(package, opt)
    end)