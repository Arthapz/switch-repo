package("switch-mesa")
    add_urls("https://github.com/devkitPro/mesa.git", {branch = "switch-20.1.0-rc3"})
    add_versions("20230527", "05fc4b1d449b8fe12cf1a47b46c4a1c1f4e4e3a6")

    add_deps("python 3.8", {kind = "binary", host = true})
    add_deps("switch-llvm", {kind = "binary", host = true})
    add_deps("meson", {kind = "binary", host = true})
    add_deps("ninja", {kind = "binary", host = true})
    add_deps("cmake", {kind = "binary", host = true})
    add_deps("bison", {kind = "binary", host = true})
    if is_host("windows") then
        add_deps("pkgconf", {kind = "binary", host = true})
    end

    add_deps("switch-llvm-runtimes", {debug = is_mode("debug")})
    add_deps("switch-support-files", {debug = is_mode("debug")})
    add_deps("switch-newlib", {debug = is_mode("debug")})
    add_deps("libnx", {debug = is_mode("debug")})
    add_deps("libdrm_nouveau", {debug = is_mode("debug")})

    on_load(function(package)
        package:set("links", "GLESv2", "EGL", "glapi")
    end)

    on_install("switch", function(package)
        os.runv("python3", {"-m", "pip", "install", "-U", "pip"})
        os.runv("python3", {"-m", "pip", "install", "mako"})

        local llvm_runtimes_package = package:dep("switch-llvm-runtimes")
        local newlib_package = package:dep("switch-newlib")
        local libnx_package = package:dep("libnx")
        local libdrm_nouveau_package = package:dep("libdrm_nouveau")
        local switch_support_files_package = package:dep("switch-support-files")

        local llvm_runtimes_lib_dir = llvm_runtimes_package:installdir("lib"):gsub("%\\", "/")
        local clang_rt_lib_dir = llvm_runtimes_package:installdir("lib", "linux"):gsub("%\\", "/")
        local newlib_lib_dir = newlib_package:installdir("lib"):gsub("%\\", "/")
        local libnx_lib_dir = libnx_package:installdir("lib"):gsub("%\\", "/")

        local includedirs = table.join(llvm_runtimes_package:installdir("lib", "clang", "17", "include"),
                                       newlib_package:installdir("include"),
                                       libnx_package:installdir("include"))

        local cflags = {'-nostdinc', '-nostdlib', "-fPIC"}
        local cxxflags = {'-nostdinc',
                          '-nostdlib',
                          '-nostdinc++',
                          '-nostdlib++',
                          '-isystem',
                          llvm_runtimes_package:installdir("include", "c++", "v1"), "-frtti"}
        if package:debug() then
            table.insert(cflags, "-g")
            table.insert(cxxflags, "-g")
        end
        for _, includedir in pairs(includedirs) do
            local dir = includedir:gsub("%\\", "/")
            table.join2(cflags, {'-isystem', dir})
            table.join2(cxxflags, {'-isystem', dir})
        end

        local ldflags = table.join({"-L" .. llvm_runtimes_lib_dir, "-L" .. clang_rt_lib_dir, "-lclang_rt.atomic-aarch64", "-lclang_rt.builtins-aarch64", "-lunwind"},
                                   {"-L" .. newlib_lib_dir, "-lc", "-lm", "-lpthread", "-lsysbase"},
                                   {"-L" .. libnx_lib_dir, "-lnx"},
                                   {"-lc++", "-lc++abi", "-lc++experimental"},
                                   switch_support_files_package:get("ldflags"))

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

        io.replace("meson.build",
            "dep_atomic = cc.find_library('atomic')",
            "dep_atomic = cc.find_library('clang_rt.builtins-aarch64')",
            {plain = true})

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
            cflags = cflags,
            cxxflags = cxxflags,
            ldflags = ldflags,
            envs = envs
        }

        io.replace("meson.build", "find_program('nm')", "find_program('llvm-nm')", {plain = true})

        meson.install(package, configs, opt)
    end)