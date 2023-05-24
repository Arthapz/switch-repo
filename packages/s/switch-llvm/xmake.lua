package("switch-llvm")
    set_kind("toolchain")
    set_homepage("https://llvm.org/")
    set_description("The LLVM Compiler Infrastructure, targetting Nintendo switch environment")

    set_urls("https://github.com/llvm/llvm-project.git", {branch = "main"})
    add_versions("20230524-1", "1894c741b0cadb8daf3b25d3e4896d14ecc7f35a")

    add_deps("cmake", {kind = "binary", host = true})
    add_deps("ninja", {kind = "binary", host = true})
    add_deps("python 3.x", {kind = "binary", host = true})
    add_deps("switch-support-files")

    add_configs("lldb", {description = "Build and install lldb", default = false, type = "boolean"})

    on_load(function(package)
        if is_host("windows") then
            package:add("linkdirs", path.join(package:installdir("lib"), "clang", "17", "lib", is_host("windows") and "windows" or "aarch64-none-elf"))
        end

        package:add("links", "clang_rt.builtins-aarch64")
    end)

    on_install("@windows", "@macos", "@linux", function(package)
        local opt = {}
        opt.cmake_generator = "Ninja"

        local projects = "clang;lld"
        if package:config("lldb") then
            projects = projects .. ";lldb"
        end

        os.cd("llvm")
        import("package.tools.cmake").install(package, {
            "-DCMAKE_BUILD_TYPE=Release",
            "-DLLVM_ENABLE_PROJECTS=" .. projects,
            "-DLLVM_ENABLE_RUNTIMES=compiler-rt",
            "-DLLVM_TARGETS_TO_BUILD=AArch64",
            "-DLLVM_DEFAULT_TARGET_TRIPLE=aarch64-nxos-elf",
            "-DLLVM_INSTALL_UTILS=ON",
            "-DLLVM_ENABLE_PIC=ON",
            "-DLLVM_ENABLE_MODULES=ON",
            "-DLLVM_BUILD_TESTS=OFF",
            "-DLLVM_ENABLE_OCAMLDOC=OFF",
            "-DLLVM_ENABLE_DOCS=OFF",
            "-DLLVM_ENABLE_BINDINGS=OFF",
            "-DLLVM_INCLUDE_TESTS=OFF",
            "-DLLVM_INCLUDE_EXAMPLES=OFF",
            "-DCLANG_DEFAULT_CXX_STDLIB=libc++",
            "-DCLANG_DEFAULT_RTLIB=compiler-rt",
            "-DCLANG_DEFAULT_UNWINDLIB=libunwind",
            "-DCOMPILER_RT_BAREMETAL_BUILD=ON",
            "-DCOMPILER_RT_BUILD_BUILTINS=ON",
            "-DCOMPILER_RT_BUILD_SANITIZERS=OFF",
            "-DCOMPILER_RT_BUILD_XRAY=OFF",
            "-DCOMPILER_RT_BUILD_LIBFUZZER=OFF",
            "-DCOMPILER_RT_BUILD_PROFILE=OFF"
        }, opt)
    end)

    on_test(function (package)
        os.vrun("llvm-config --version")
        os.vrun("clang --version")
    end)