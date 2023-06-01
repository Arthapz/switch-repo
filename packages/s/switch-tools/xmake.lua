package("switch-tools")
    set_kind("binary")
    add_urls("https://github.com/Arthapz/switch-tools.git", {branch = "devkitPro"})
    add_versions("20230526", "3e4b878b53927c8ea0de684ca13cab50e931cb72")

    on_install("@windows", "@linux", "@macosx", function(package)
        import("package.tools.xmake").install(package)
    end)