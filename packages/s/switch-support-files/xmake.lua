package("switch-support-files")
    set_description("Switch support scripts and files")

    add_urls("https://github.com/Arthapz/switch-support-files.git")
    add_versions("20230529-2", "8a8a63b8093c71477021879d8c81347add35dae0")

    on_install("switch", function(package)
        os.cp("share", package:installdir()) -- TODO COPY .o FILES

        local opt = {mode = package:debug() and "debug" or "release"}
        opt.objectdir = package:installdir("lib")
        import("package.tools.xmake").install(package, opt)
    end)
