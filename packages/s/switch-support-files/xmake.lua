package("switch-support-files")
    set_description("Switch support scripts and files")

    add_urls("https://github.com/Arthapz/switch-support-files.git")
    add_versions("20230524", "c5563852df75d64bef0a9ce55b18176a026c9eaf")

    on_install(function(package)
        os.cp("share", package:installdir())
        os.cp("lib", package:installdir())
    end)

