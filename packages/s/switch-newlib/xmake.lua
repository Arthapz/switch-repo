package("switch-newlib")
    add_urls("https://github.com/Arthapz/newlib.git", {branch = "devkitPro"})
    add_versions("20230519", "aaa8c961627e09dc4de8b73063c3f8ef5ff0e6ad")

    on_install("switch", function(package)
        import("package.tools.xmake").install(package)
    end)