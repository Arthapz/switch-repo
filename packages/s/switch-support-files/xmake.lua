package("switch-support-files")
    set_description("Switch support scripts and files")

    add_urls("https://github.com/Arthapz/switch-support-files.git")
    add_versions("20230529-1", "bb82905fd9a8baca8501f3dcf2918522c79c4de1")

    on_install("switch", function(package)
        os.cp("share", package:installdir()) -- TODO COPY .o FILES

        local opt = {mode = package:debug() and "debug" or "release"}
        opt.objectdir = package:installdir("lib")
        import("package.tools.xmake").install(package, opt)
    end)
