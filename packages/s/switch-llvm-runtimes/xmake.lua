package("switch-llvm-runtimes")
    set_urls("https://github.com/llvm/llvm-project.git", {branch = "main", depth = 1})
    add_versions("20230525", "5c082e7e15e38a2eea1f506725efe636a5b1bf8a")

    add_deps("cmake", {kind = "binary", host = true})
    add_deps("ninja", {kind = "binary", host = true})
    add_deps("switch-llvm", {kind = "binary", host = true})
    add_deps("switch-support-files")
    add_deps("switch-newlib")
    add_deps("switch-libnx")

    add_patches("20230525", "patch/switch.diff")

    on_load(function(package)
        package:add("linkdirs", "lib")
        package:add("linkdirs", path.join("lib", "linux"))

        package:add("includedirs", path.join("lib", "clang", "17", "include"))
        package:add("includedirs", path.join("include", "c++", "v1"))
    end)

    on_install("switch", function(package)
        local opt = {}
        opt.cmake_generator = "Ninja"

        local suffix = is_host("windows") and ".exe" or ""

        local cmakelist_replace_str =
            'cmake_minimum_required(VERSION 3.13.4)'

        local cmakelist_replaced_str =
            cmakelist_replace_str .. "\n" ..
            'string(APPEND CMAKE_C_FLAGS "'            .. " -isystem " .. package:dep("switch-newlib"):installdir("include"):gsub("%\\", "/")
                                                       .. " -D_GNU_SOURCE=1"
                                                       .. " -DLIBC"
                                                       .. " -D_NEWLIB_VERSION=4.3.0"
                                                       .. " -D__NEWLIB__=4"
                                                       .. " -isystem " .. package:dep("switch-libnx"):installdir("include"):gsub("%\\", "/")
                                                       .. '")\n' ..
            'string(APPEND CMAKE_CXX_FLAGS "'          .. " -isystem " .. package:dep("switch-newlib"):installdir("include"):gsub("%\\", "/")
                                                       .. " -D_GNU_SOURCE=1"
                                                       .. " -DLIBC"
                                                       .. " -D_NEWLIB_VERSION=4.3.0"
                                                       .. " -D__NEWLIB__=4"
                                                       .. " -isystem " .. package:dep("switch-libnx"):installdir("include"):gsub("%\\", "/")
                                                       .. '")\n',
            'string(APPEND STATIC_LIBRARY_FLAGS "'     .. " -L " .. package:dep("switch-newlib"):installdir("lib")
                                                       .. '")\n'

        io.replace("compiler-rt/CMakeLists.txt",
            cmakelist_replace_str,
            cmakelist_replaced_str,
            {plain = true})
        io.replace("libcxx/CMakeLists.txt",
            cmakelist_replace_str,
            cmakelist_replaced_str,
            {plain = true})
        io.replace("libcxxabi/CMakeLists.txt",
            cmakelist_replace_str,
            cmakelist_replaced_str,
            {plain = true})
        io.replace("libunwind/CMakeLists.txt",
            cmakelist_replace_str,
            cmakelist_replaced_str,
            {plain = true})

        os.cd("runtimes")
        import("package.tools.cmake").install(package, {
            -- cmake
            "-DCMAKE_BUILD_TYPE=Release",
            "-DCMAKE_MAKE_PROGRAM=" .. path.join(package:dep("ninja"):installdir("bin"), "ninja" .. suffix),
            "-DCMAKE_SYSTEM_NAME=NxOS",
            "-DCMAKE_C_COMPILER_TARGET=aarch64-nxos-elf",
            "-DCMAKE_CXX_COMPILER_TARGET=aarch64-nxos-elf",

            -- to avoid cmake trying to link to libclang_rt.builtins-aarch64 before it is built
            "-DCMAKE_C_COMPILER_WORKS=ON",
            "-DCMAKE_CXX_COMPILER_WORKS=ON",

            -- llvm
            "-DLLVM_ENABLE_PROJECTS=",
            '-DLLVM_ENABLE_RUNTIMES=compiler-rt;libcxx;libcxxabi;libunwind',
            "-DLLVM_TARGETS_TO_BUILD=AArch64",
            "-DLLVM_DEFAULT_TARGET_TRIPLE=aarch64-nxos-elf",
            "-DLLVM_INSTALL_UTILS=ON",
            "-DLLVM_ENABLE_PIC=ON",
            "-DLLVM_ENABLE_MODULES=OFF",
            "-DLLVM_BUILD_TESTS=OFF",
            "-DLLVM_ENABLE_OCAMLDOC=OFF",
            "-DLLVM_ENABLE_DOCS=OFF",
            "-DLLVM_ENABLE_BINDINGS=OFF",
            "-DLLVM_INCLUDE_TESTS=OFF",
            "-DLLVM_INCLUDE_EXAMPLES=OFF",

            -- compiler-rt
            "-DCOMPILER_RT_BAREMETAL_BUILD=ON",
            "-DCOMPILER_RT_BUILD_BUILTINS=ON",
            "-DCOMPILER_RT_BUILD_SANITIZERS=OFF",
            "-DCOMPILER_RT_BUILD_XRAY=OFF",
            "-DCOMPILER_RT_BUILD_LIBFUZZER=OFF",
            "-DCOMPILER_RT_BUILD_PROFILE=OFF",
            "-DCOMPILER_RT_BUILD_CRT=ON",
            "-DCOMPILER_RT_BUILTINS_ENABLE_PIC=ON",
            "-DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON",
            "-DCOMPILER_RT_DEFAULT_TARGET_ARCH=AArch64",
            "-DCOMPILER_RT_BUILD_SANITIZERS=OFF",
            "-DCOMPILER_RT_BUILD_MEMPROF=OFF",
            "-DCOMPILER_RT_BUILD_ORC=OFF",
            "-DCOMPILER_RT_BUILD_XRAY=OFF",

            -- libcxx
            "-DLIBCXX_CXX_ABI=system-libcxxabi",
            "-DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON",
            "-DLIBCXX_CXX_ABI_INCLUDE_PATHS=" .. path.join(package:cachedir(), "source", "switch-llvm-runtimes", "libcxxabi", "include"),
            "-DLIBCXX_ENABLE_SHARED=NO",
            "-DLIBCXX_USE_COMPILER_RT=ON",
            "-DLIBCXX_INCLUDE_BENCHMARKS=OFF",
            "-DLIBCXX_ENABLE_EXPERIMENTAL_LIBRARY=YES",
            "-DLIBCXX_HAS_PTHREAD_API=ON",

            -- libcxxabi
            "-DLIBCXXABI_USE_LLVM_UNWINDER=OFF",
            "-DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON",
            "-DLIBCXXABI_ENABLE_SHARED=OFF",
            "-DLIBCXXABI_USE_COMPILER_RT=ON",
            "-DLIBCXXABI_BAREMETAL=ON",
            "-DLIBCXXABI_LIBUNWIND_INCLUDES_INTERNAL=" .. path.join(package:cachedir(), "source", "switch-llvm-runtimes", "libunwind", "include"):gsub("%\\", "/"),

            -- libunwind
            "-DLIBUNWIND_ENABLE_SHARED=OFF",
            "-DLIBUNWIND_ENABLE_ARM_WMMX=ON",
            "-DLIBUNWIND_USE_COMPILER_RT=ON",
            "-DLIBUNWIND_IS_BAREMETAL=ON"
        }, opt)

        -- local base_options = {
            -- cmake
            -- "-DCMAKE_BUILD_TYPE=Release",
            -- "-DCMAKE_MAKE_PROGRAM=" .. path.join(package:dep("ninja"):installdir("bin"), "ninja" .. suffix),
            -- "-DCMAKE_SYSTEM_NAME=NxOS",
            -- "-DCMAKE_C_COMPILER_TARGET=aarch64-nxos-elf",
            -- "-DCMAKE_CXX_COMPILER_TARGET=aarch64-nxos-elf",

            -- to avoid cmake trying to link to libclang_rt.builtins-aarch64 before it is built
            -- "-DCMAKE_C_COMPILER_WORKS=ON",
            -- "-DCMAKE_CXX_COMPILER_WORKS=ON",

            -- llvm
            -- "-DLLVM_TARGETS_TO_BUILD=AArch64",
            -- "-DLLVM_DEFAULT_TARGET_TRIPLE=aarch64-nxos-elf",
            -- "-DLLVM_ENABLE_PIC=ON",
            -- "-DLLVM_ENABLE_MODULES=ON",
            -- "-DLLVM_BUILD_TESTS=OFF",
            -- "-DLLVM_ENABLE_OCAMLDOC=OFF",
            -- "-DLLVM_ENABLE_DOCS=OFF",
            -- "-DLLVM_ENABLE_BINDINGS=OFF",
            -- "-DLLVM_INCLUDE_TESTS=OFF",
            -- "-DLLVM_INCLUDE_EXAMPLES=OFF",
            -- "-DCMAKE_C_COMPILER_TARGET=aarch64-nxos-elf",
            -- "-DCMAKE_CXX_COMPILER_TARGET=aarch64-nxos-elf",
            -- "-DLLVM_CMAKE_DIR=" .. path.join(package:cachedir(), "source", "switch-llvm-runtimes", "llvm", "cmake", "modules")
        -- }

        -- os.cd("../compiler-rt")
        -- io.replace("CMakeLists.txt",
            -- 'cmake_minimum_required(VERSION 3.13.4)',
            -- "cmake_minimum_required(VERSION 3.13.4)\n" ..
            -- 'string(APPEND CMAKE_C_FLAGS "'            .. " -isystem " .. package:dep("switch-newlib"):installdir("include"):gsub("%\\", "/")
                                                       -- .. " -D_GNU_SOURCE=1"
                                                       -- .. " -DLIBC"
                                                       -- .. " -D_NEWLIB_VERSION=4.3.0"
                                                       -- .. " -D__NEWLIB__=4"
                                                       -- .. " -isystem " .. package:dep("switch-libnx"):installdir("include"):gsub("%\\", "/")
                                                       -- .. '")\n' ..
            -- 'string(APPEND CMAKE_CXX_FLAGS "'          .. " -isystem " .. package:installdir("include", "c++", "v1"):gsub("%\\", "/")
                                                       -- .. " -D_GNU_SOURCE=1"
                                                       -- .. " -DLIBC"
                                                       -- .. " -D_NEWLIB_VERSION=4.3.0"
                                                       -- .. " -D__NEWLIB__=4"
                                                       -- .. " -isystem " .. package:dep("switch-newlib"):installdir("include"):gsub("%\\", "/")
                                                       -- .. " -isystem " .. package:dep("switch-libnx"):installdir("include"):gsub("%\\", "/")
                                                       -- .. '")\n',
            -- {plain = true})
        -- import("package.tools.cmake").install(package, table.join({
            -- "-DCOMPILER_RT_BAREMETAL_BUILD=ON",
            -- "-DCOMPILER_RT_BUILD_BUILTINS=ON",
            -- "-DCOMPILER_RT_BUILD_SANITIZERS=OFF",
            -- "-DCOMPILER_RT_BUILD_XRAY=OFF",
            -- "-DCOMPILER_RT_BUILD_LIBFUZZER=OFF",
            -- "-DCOMPILER_RT_BUILD_PROFILE=OFF",
            -- "-DCOMPILER_RT_BUILD_CRT=ON",
            -- "-DCOMPILER_RT_BUILTINS_ENABLE_PIC=ON",
            -- "-DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON",
            -- "-DCOMPILER_RT_DEFAULT_TARGET_ARCH=AArch64",
            -- "-DCOMPILER_RT_BUILD_SANITIZERS=OFF",
            -- "-DCOMPILER_RT_BUILD_MEMPROF=OFF",
        -- }, base_options), opt)

        -- os.cd("libcxx")
        -- io.replace("CMakeLists.txt",
            -- 'cmake_minimum_required(VERSION 3.13.4)',
            -- "cmake_minimum_required(VERSION 3.13.4)\n" ..
            -- 'string(APPEND CMAKE_C_FLAGS "'            .. " -isystem " .. package:dep("switch-newlib"):installdir("include"):gsub("%\\", "/")
                                                       -- .. " -D_GNU_SOURCE=1"
                                                       -- .. " -DLIBC"
                                                       -- .. " -D_NEWLIB_VERSION=4.3.0"
                                                       -- .. " -D__NEWLIB__=4"
                                                       -- .. " -isystem " .. package:dep("switch-libnx"):installdir("include"):gsub("%\\", "/")
                                                       -- .. '")\n' ..
            -- 'string(APPEND CMAKE_CXX_FLAGS "'            .. " -isystem " .. package:dep("switch-newlib"):installdir("include"):gsub("%\\", "/")
                                                       -- .. " -D_GNU_SOURCE=1"
                                                       -- .. " -DLIBC"
                                                       -- .. " -D_NEWLIB_VERSION=4.3.0"
                                                       -- .. " -D__NEWLIB__=4"
                                                       -- .. " -isystem " .. package:dep("switch-libnx"):installdir("include"):gsub("%\\", "/")
                                                       -- .. '")\n',
        -- {plain = true})
        -- import("package.tools.cmake").install(package, table.join({
            -- "-DLIBCXX_CXX_ABI=system-libcxxabi",
            -- "-DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON",
            -- "-DLIBCXX_CXX_ABI_INCLUDE_PATHS=" .. path.join(package:cachedir(), "source", "switch-llvm-runtimes", "libcxxabi", "include"),
            -- "-DLIBCXX_ENABLE_SHARED=NO",
            -- "-DLIBCXX_USE_COMPILER_RT=ON",
            -- "-DLIBCXX_INCLUDE_BENCHMARKS=OFF",
            -- "-DLIBCXX_ENABLE_EXPERIMENTAL_LIBRARY=YES",
            -- "-DLIBCXX_HAS_PTHREAD_API=ON"
        -- }, base_options), opt)

        -- os.cd("../libcxxabi")
        -- io.replace("CMakeLists.txt",
            -- 'cmake_minimum_required(VERSION 3.13.4)',
            -- "cmake_minimum_required(VERSION 3.13.4)\n" ..
            -- 'string(APPEND CMAKE_C_FLAGS "'            .. " -isystem " .. package:dep("switch-newlib"):installdir("include"):gsub("%\\", "/")
                                                       -- .. " -D_GNU_SOURCE=1"
                                                       -- .. " -DLIBC"
                                                       -- .. " -D_NEWLIB_VERSION=4.3.0"
                                                       -- .. " -D__NEWLIB__=4"
                                                       -- .. " -isystem " .. package:dep("switch-libnx"):installdir("include"):gsub("%\\", "/")
                                                       -- .. '")\n' ..
            -- 'string(APPEND CMAKE_CXX_FLAGS "'          .. " -isystem " .. package:installdir("include", "c++", "v1"):gsub("%\\", "/")
                                                       -- .. " -D_GNU_SOURCE=1"
                                                       -- .. " -DLIBC"
                                                       -- .. " -D_NEWLIB_VERSION=4.3.0"
                                                       -- .. " -D__NEWLIB__=4"
                                                       -- .. " -isystem " .. package:dep("switch-newlib"):installdir("include"):gsub("%\\", "/")
                                                       -- .. " -isystem " .. package:dep("switch-libnx"):installdir("include"):gsub("%\\", "/")
                                                       -- .. '")\n',
        -- {plain = true})
        -- import("package.tools.cmake").install(package, table.join({
            -- "-DLIBCXXABI_USE_LLVM_UNWINDER=OFF",
            -- "-DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON",
            -- "-DLIBCXXABI_LIBUNWIND_INCLUDES_INTERNAL=" .. path.join(package:cachedir(), "source", "switch-llvm-runtimes", "libunwind", "include"):gsub("%\\", "/"),
            -- "-DLIBCXXABI_ENABLE_SHARED=OFF",
            -- "-DLIBCXXABI_USE_COMPILER_RT=ON",
            -- "-DLIBCXXABI_BAREMETAL=ON"
        -- }, base_options), opt)

        -- os.cd("../libunwind")
        -- io.replace("CMakeLists.txt",
            -- 'cmake_minimum_required(VERSION 3.13.4)',
            -- "cmake_minimum_required(VERSION 3.13.4)\n" ..
            -- 'string(APPEND CMAKE_C_FLAGS "'            .. " -isystem " .. package:dep("switch-newlib"):installdir("include"):gsub("%\\", "/")
                                                       -- .. " -D_GNU_SOURCE=1"
                                                       -- .. " -DLIBC"
                                                       -- .. " -D_NEWLIB_VERSION=4.3.0"
                                                       -- .. " -D__NEWLIB__=4"
                                                       -- .. " -isystem " .. package:dep("switch-libnx"):installdir("include"):gsub("%\\", "/")
                                                       -- .. '")\n' ..
            -- 'string(APPEND CMAKE_CXX_FLAGS "'          .. " -isystem " .. package:installdir("include", "c++", "v1"):gsub("%\\", "/")
                                                       -- .. " -D_GNU_SOURCE=1"
                                                       -- .. " -DLIBC"
                                                       -- .. " -D_NEWLIB_VERSION=4.3.0"
                                                       -- .. " -D__NEWLIB__=4"
                                                       -- .. " -isystem " .. package:dep("switch-newlib"):installdir("include"):gsub("%\\", "/")
                                                       -- .. " -isystem " .. package:dep("switch-libnx"):installdir("include"):gsub("%\\", "/")
                                                       -- .. " -isystem " .. package:installdir("include"):gsub("%\\", "/")
                                                       -- .. '")\n',
        -- {plain = true})
        -- import("package.tools.cmake").install(package, table.join({
            -- "-DLIBUNWIND_ENABLE_SHARED=OFF",
            -- "-DLIBUNWIND_ENABLE_ARM_WMMX=ON",
            -- "-DLIBUNWIND_USE_COMPILER_RT=ON",
            -- "-DLIBUNWIND_IS_BAREMETAL=ON"
        -- }, base_options), opt)
    end)