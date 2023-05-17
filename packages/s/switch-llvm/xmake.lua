package("switch-llvm")
    set_kind("toolchain")
    set_homepage("https://llvm.org/")
    set_description("The LLVM Compiler Infrastructure, targetting Nintendo switch environment")

    add_urls("20230517", "https://github.com/llvm/llvm-project.git")

    add_deps("cmake")
    add_deps("python 3.x")

    add_configs("use_ninja", {description = "Use ninja as cmake backend", default = false, type = "boolean"})

    on_install(function(package)
        local opt

        if has_config("use_ninja") then
            opt = opt or {}
            opt.cmake_generator = "Ninja"
        end

        import("package.tools.cmake").build({}, {
            "-DCMAKE_BUILD_TYPE=Release",
            "-DLLVM_ENABLE_PROJECTS=clang;lld;lldb",
            "-DLLVM_ENABLE_RUNTIMES=compiler-rt",
            "-DLLVM_TARGETS_TO_BUILD=AArch64",
            "-DLLVM_DEFAULT_TARGET_TRIPLE=aarch64-none-elf",
            "-DLLVM_INSTALL_UTILS=ON",
            "-DLLVM_ENABLE_PIC=ON",
            "-DLLVM_ENABLE_MODULES=ON",
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