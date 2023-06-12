package("switch-mesa")
    set_policy("package.strict_compatibility", true)
    add_urls("https://github.com/devkitPro/mesa.git", {branch = "switch-20.1.0-rc3"})
    add_versions("20230527", "05fc4b1d449b8fe12cf1a47b46c4a1c1f4e4e3a6")

    add_configs("debug", {description = "Build mesa in debug mode.", default = false, readonly = true})

    add_deps("python 3.8", {kind = "binary", host = true})
    add_deps("meson", {host = true})
    add_deps("ninja", {host = true})
    add_deps("cmake", {host = true})
    add_deps("bison", {host = true})

    if is_host("windows") then
        add_deps("pkgconf", {host = true})
    end

    add_deps("switch-llvm-sysroot", "libdrm_nouveau")

    on_load(function(package)
        package:set("links", "GLESv2", "EGL", "glapi")
    end)

    on_install("switch", function(package)
        os.runv("python3", {"-m", "pip", "install", "-U", "pip"})
        os.runv("python3", {"-m", "pip", "install", "mako"})

        local machinefile = [[
[build_machine]
system = 'windows'
cpu_family = 'x86-64'
cpu = 'x86-64'
endian = 'little'

[host_machine]
system = 'horizon'
cpu_family = 'aarch64'
cpu = 'cortex-a57'
endian = 'little'

[target_machine]
system = 'horizon'
cpu_family = 'aarch64'
cpu = 'cortex-a57'
endian = 'little'
]]

        io.writefile("machinefile.ini", machinefile)

        local configs = {
            "--cross-file=" .. "machinefile.ini",
            "-Ddefault_library=" .. (package:config("shared") and "shared" or "static")
        }

        import("package.tools.meson")
        local envs = meson.buildenvs(package)
        envs.PATH = package:dep("python"):installdir("bin") .. (envs.PATH and (path.envsep() .. envs.PATH) or "")
        if is_host("windows") then
            for _, dep in ipairs(package:orderdeps()) do
                if not string.match(dep:installdir(), "python\\3%.11.*") then
                    envs.PATH = dep:installdir("bin") .. (envs.PATH and (path.envsep() .. envs.PATH) or "")
                end
            end
        end
        local opt = {
            envs = envs
        }

        io.replace("meson.build", "find_program('nm')", "find_program('llvm-nm')", {plain = true})
        meson.install(package, configs, opt)
    end)