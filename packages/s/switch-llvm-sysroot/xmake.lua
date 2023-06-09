local triple = "aarch64-unknown-none-elf"

package("switch-llvm-sysroot")
    set_description("A switch homebrew sysroot based on LLVM libc++, newlib libc and libnx")

    set_urls("https://github.com/Arthapz/switch-llvm.git", {branch = "main"})
    add_versions("20230610", "2683db06474f4ba4f34916c5af16a89b9f7b7e54")

    add_deps("cmake", {host = true})
    add_deps("ninja", {host = true})

    add_patches("20230610", "patch/switch.diff")

    on_load(function(package)
        --package:set("includedirs", "")
        package:set("links", "")
    end)

    on_install("@windows", "@macosx", "@linux", function(package)
        os.cp("nro.ld", package:installdir("share"))

        os.cd("newlib")
        os.cp(path.join(package:scriptdir(), "ports", "newlib", "xmake.lua"), "xmake.lua")

        local cxflags = {"--sysroot=" .. package:installdir()}

        local ldflags = {"-Wl,--sysroot=" .. package:installdir(),
                         "-L" .. package:installdir("lib", "nxos"),
                         "-lsysbase", "-lnx", "-lpthread"}

        local opt = {cxflags = table.concat(cxflags, " "),
                     asflags = table.concat(cxflags, " "),
                     ldflags = table.concat(ldflags, " "),
                     shflags = table.concat(ldflags, " ")}

        import("package.tools.xmake").install(package, opt)

        os.cd("../libnx")
        os.cp(path.join(package:scriptdir(), "ports", "libnx", "xmake.lua"), "xmake.lua")

        io.replace("nx/source/runtime/newlib.c",
[[    tv->handle     = envGetMainThreadHandle();]],
[[    tv->handle     = envGetMainThreadHandle();
      void *ptr;
      __asm__ volatile  ("mrs %x[data], tpidrro_el0\n\t"
                         "ldr %x[data], [%x[data], #0x1F8]\n\t"
                         "msr tpidr_el0, %x[data]"
                         : [data] "=r" (ptr));]], {plain = true})

        import("package.tools.xmake").install(package, opt)

        os.cd("../crt")
        import("package.tools.xmake").install(package, opt)

        local crt_lib_dir = package:installdir("lib", "nxos")

        local crt_o_dir = path.join(package:buildir(), ".objs", "switch-crt", "switch", "aarch64", package:debug() and "debug" or "release", "src")
        vprint("copy " .. path.join(crt_o_dir, "crti.S.o") .. " to " .. path.join(crt_lib_dir, "crti.o"))
        os.cp(path.join(crt_o_dir, "crti.S.o"), path.join(crt_lib_dir, "crti.o"))

        vprint("copy " .. path.join(crt_o_dir, "crtn.S.o") .. " to " .. path.join(crt_lib_dir, "crtn.o"))
        os.cp(path.join(crt_o_dir, "crtn.S.o"), path.join(crt_lib_dir, "crtn.o"))

        os.cd("../llvm-project")
        io.replace("compiler-rt/lib/builtins/CMakeLists.txt",
                   '${BUILTIN_TYPE}',
                   'STATIC',
                   {plain = true})
        io.replace("clang/CMakeLists.txt",
                   "add_subdirectory(utils/TableGen)",
                   "",
                   {plain = true})
        os.cd("runtimes")

        opt = { cmake_generator = "Ninja" }
        local llvm_runtimes = {"compiler-rt", "libunwind", "libcxx", "libcxxabi"}
        local runtime_options = {
            -- cmake
            "-DCMAKE_BUILD_TYPE=" .. (package:debug() and "Debug" or "Release"),
            "-DCMAKE_SYSROOT=" .. package:installdir(),
            "-DCMAKE_SYSTEM_NAME=NxOS",
            "-DCMAKE_CROSSCOMPILING=ON",
            "-DCMAKE_C_COMPILER_TARGET=" .. triple,
            "-DCMAKE_CXX_COMPILER_TARGET=" .. triple,
            -- "-DCMAKE_C_COMPILER=clang",
            -- "-DCMAKE_CXX_COMPILER=clang++",
            "-DCMAKE_C_COMPILER_WORKS=ON",
            "-DCMAKE_CXX_COMPILER_WORKS=ON",
            "-DCMAKE_C_FLAGS=" .. table.concat(cxflags, " "),
            "-DCMAKE_CXX_FLAGS=" .. table.concat(cxflags, " "),
            "-DCMAKE_ASM_FLAGS=" .. table.concat(cxflags, " "),
            "-DCMAKE_EXE_LINKER_FLAGS=" .. table.concat(ldflags, " "),
            "-DCMAKE_SHARED_LINKER_FLAGS=" .. table.concat(ldflags, " "),
            "-DCMAKE_REQUIRED_FLAGS=" .. table.concat(ldflags, " "),

            -- llvm
            "-DLLVM_ENABLE_PROJECTS=",
            "-DLLVM_ENABLE_RUNTIMES=" .. table.concat(llvm_runtimes, ";"),
            "-DLLVM_DEFAULT_TARGET_TRIPLE=" .. triple,
            "-DLLVM_ENABLE_PIC=ON",
            "-DLLVM_ENABLE_MODULES=OFF",
            "-DLLVM_INCLUDE_TESTS=OFF",
            "-DLLVM_BUILD_TESTS=OFF",
            "-DLLVM_INCLUDE_DOCS=OFF",
            "-DLLVM_BUILD_DOCS=OFF",

            -- compiler-rt
            "-DCOMPILER_RT_DEBUG=" .. (package:debug() and "ON" or "OFF"),
            "-DCOMPILER_RT_OS_DIR=nxos",
            "-DCOMPILER_RT_BAREMETAL_BUILD=ON",
            "-DCOMPILER_RT_BUILD_BUILTINS=ON",
            "-DCOMPILER_RT_BUILD_SANITIZERS=OFF",
            "-DCOMPILER_RT_BUILD_XRAY=OFF",
            "-DCOMPILER_RT_BUILD_LIBFUZZER=OFF",
            "-DCOMPILER_RT_BUILD_PROFILE=OFF",
            "-DCOMPILER_RT_BUILD_CRT=ON",
            "-DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON",
            "-DCOMPILER_RT_DEFAULT_TARGET_ARCH=AArch64",
            "-DCOMPILER_RT_BUILD_SANITIZERS=OFF",
            "-DCOMPILER_RT_BUILD_MEMPROF=OFF",
            "-DCOMPILER_RT_BUILD_ORC=OFF",
            "-DCOMPILER_RT_BUILD_XRAY=OFF",
            "-DCOMPILER_RT_INCLUDE_TESTS=OFF",
            "-DCOMPILER_RT_BUILD_TESTS=OFF",
            "-DCOMPILER_RT_INCLUDE_DOCS=OFF",
            "-DCOMPILER_RT_BUILD_DOCS=OFF",

            -- libc
            -- "-DLIBC_INCLUDE_DOCS=OFF",
            -- "-DLIBC_INCLUDE_BENCHMARKS=OFF",
            -- "-DLLVM_LIBC_FULL_BUILD=ON",

            -- libunwind
            "-DLIBUNWIND_ENABLE_SHARED=ON",
            "-DLIBUNWIND_ENABLE_SHARED=OFF",
            "-DLIBUNWIND_ENABLE_ARM_WMMX=ON",
            "-DLIBUNWIND_USE_COMPILER_RT=ON",
            "-DLIBUNWIND_IS_BAREMETAL=ON",
            "-DLIBUNWIND_ENABLE_ARM_WMMX=ON",
            "-DLIBUNWIND_INCLUDE_TESTS=OFF",
            "-DLIBUNWIND_BUILD_TESTS=OFF",
            "-DLIBUNWIND_INCLUDE_DOCS=OFF",
            "-DLIBUNWIND_BUILD_DOCS=OFF",

            -- libcxx
            "-DLIBCXX_INCLUDE_TESTS=OFF",
            "-DLIBCXX_ENABLE_DEBUG_MODE=" .. (package:debug() and "ON" or "OFF"),
            "-DLIBCXX_CXX_ABI=system-libcxxabi",
            "-DLIBCXX_ENABLE_STATIC=ON",
            "-DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON",
            "-DLIBCXX_CXX_ABI_INCLUDE_PATHS=" .. path.join(package:cachedir(), "source", "switch-llvm-sysroot", "llvm-project", "libcxxabi", "include"),
            "-DLIBCXX_ENABLE_SHARED=NO",
            "-DLIBCXX_USE_COMPILER_RT=ON",
            "-DLIBCXX_INCLUDE_BENCHMARKS=OFF",
            "-DLIBCXX_HAS_PTHREAD_API=ON",
            "-DLIBCXX_ENABLE_STD_MODULE=ON",
            "-DLIBCXX_INCLUDE_TESTS=OFF",
            "-DLIBCXX_BUILD_TESTS=OFF",
            "-DLIBCXX_INCLUDE_DOCS=OFF",
            "-DLIBCXX_BUILD_DOCS=OFF",

            -- libcxxabi
            "-DLIBCXXABI_USE_LLVM_UNWINDER=OFF",
            "-DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON",
            "-DLIBCXXABI_ENABLE_SHARED=OFF",
            "-DLIBCXXABI_USE_COMPILER_RT=ON",
            "-DLIBCXXABI_HAS_PTHREAD_API=ON",
            "-DLIBCXXABI_BAREMETAL=ON",
            "-DLIBCXXABI_ENABLE_PEDANTIC=ON",
            "-DLIBCXXABI_LIBUNWIND_INCLUDES_INTERNAL=" .. path.join(package:cachedir(), "source", "switch-llvm-sysroot", "llvm-project", "libunwind", "include"),
            "-DLIBCXXABI_ENABLE_SHARED=OFF",
            "-DLIBCXXABI_INCLUDE_TESTS=OFF",
            "-DLIBCXXABI_BUILD_TESTS=OFF",
            "-DLIBCXXABI_INCLUDE_DOCS=OFF",
            "-DLIBCXXABI_BUILD_DOCS=OFF"
        }

        import("package.tools.cmake").install(package, runtime_options, opt)

        if is_host("windows") then
            -- os.cp(path.join(crt_lib_dir, "libclang_rt.builtins-aarch64.a"), path.join(crt_lib_dir, "libatomic.a"))
        else
            -- os.ln(path.join(crt_lib_dir, "libclang_rt.builtins-aarch64.a"), path.join(crt_lib_dir, "libatomic.a"))
        end
    end)
