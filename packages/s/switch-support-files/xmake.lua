package("switch-support-files")
    set_description("Switch support scripts and files")

    add_urls("https://github.com/Arthapz/switch-support-files.git")
    add_versions("20230526-1", "14305d397e4b2ae857c60f11a83cdb7d5a7e9d4e")

    on_install("switch", function(package)
        os.cp("share", package:installdir())

        import("package.tools.xmake").install(package)
    end)
