package("switch-support-files")
    set_description("Switch support scripts and files")

    add_urls("https://github.com/Arthapz/switch-support-files.git")
    add_versions("20230532", "c425b2bbd42aef7a72938d25ba25aea54f553755")

    on_load(function(package)
        local object_dir = package:installdir("lib", "switch-support-files", "switch", "aarch64", is_mode("debug") and "debug" or "release", "src")
        local link_scripts_dir = package:installdir("share", "link-scripts")

        local linker_script = path.join(link_scripts_dir, "nro.ld")
        package:set("ldflags", "-Wl,-T," .. linker_script, path.join(object_dir, "crti.S.o"), path.join(object_dir, "crtn.S.o"), {force = true})

        linker_script = path.join(link_scripts_dir, "nso.ld")
        package:set("shflags", "-Wl,-T," .. linker_script, {force = true})
    end)

    on_install("switch", function(package)
        os.cp("share", package:installdir())

        local opt = {mode = package:debug() and "debug" or "release"}
        opt.objectdir = package:installdir("lib")
        import("package.tools.xmake").install(package, opt)
    end)
