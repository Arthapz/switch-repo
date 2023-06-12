package("borealis")
    set_policy("package.strict_compatibility", true)
    add_urls("https://github.com/natinusala/borealis.git", {branch = "main"})
    add_versions("20230527", "20e2d33b6c4ffce139ce304c503c04f5b94da920")

    add_deps("meson", {host = true})
    add_deps("ninja", {host = true})

    add_deps("switch-llvm-sysroot", "switch-mesa", "glm", "glfw")

    on_install("switch", function(package)
        local opt = {}
        table.insert(opt, "-Ddefault_library=" .. (package:config("shared") and "shared" or "static"))

        if package:debug() then
            table.insert(opt, "--debug")
        end

        import("package.tools.meson").install(package, opt)
    end)