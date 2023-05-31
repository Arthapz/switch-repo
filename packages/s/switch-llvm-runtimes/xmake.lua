package("switch-llvm-runtimes")
    set_urls("https://github.com/llvm/llvm-project.git", {branch = "main", depth = 1})
    add_versions("20230530", "f81f32adc9a8e99a77dd4c5f5f83c5595b989a71")

    add_deps("cmake", {kind = "binary", host = true})
    add_deps("python 3.x", {kind = "binary", host = true})
    add_deps("ninja", {kind = "binary", host = true})
    add_deps("switch-llvm", {kind = "binary", host = true})

    add_deps("switch-newlib", {debug = is_mode("debug")})
    add_deps("libnx", {debug = is_mode("debug")})

    add_patches("20230530", "patch/switch.diff")

    add_configs("cxx_support", {description = "Enable C++ support", default = true, type = "boolean"})

    on_load(function(package)
        if package:config("cxx_support") then
            package:add("components", "cxx", {deps = "base"})
        end
        package:add("components", "base", {default = true})
    end)

    on_component("base", function(component)
        component:add("linkdirs", path.join("lib", "linux"))
        component:add("linkdirs", "lib")
        component:add("links", "clang_rt.atomic-aarch64", "clang_rt.builtins-aarch64", "unwind")

        component:add("includedirs", path.join("lib", "clang", "17", "include"))
    end)

    on_component("cxx", function(component)
        component:add("links", "c++", "c++abi", "c++experimental")

        component:set("includedirs", path.join("include", "c++", "v1"))
        component:add("includedirs", path.join("lib", "clang", "17", "include"))
    end)

    on_install("switch", function(package)
        import("lib.detect.find_tool")

        local opt = {}
        opt.cmake_generator = "Ninja"

        local ninja_exe = find_tool("ninja").program

        local suffix = is_host("windows") and ".exe" or ""

        local llvm_package = package:dep("switch-llvm")
        local newlib_package = package:dep("switch-newlib")
        local libnx_package = package:dep("libnx")

        local newlib_inc_dir = newlib_package:installdir("include"):gsub("%\\", "/")
        local libnx_inc_dir = libnx_package:installdir("include"):gsub("%\\", "/")

        local cmakelist_replace_str =
            'cmake_minimum_required(VERSION 3.20.0)'

        local cmakelist_replaced_str =
            cmakelist_replace_str .. "\n" ..
            'string(APPEND CMAKE_C_FLAGS "'            .. " -isystem " .. package:installdir("include"):gsub("%\\", "/")
                                                       .. " -isystem " .. newlib_inc_dir
                                                       .. " -isystem " .. libnx_inc_dir
                                                       .. " -D_GNU_SOURCE=1"
                                                       .. " -DLIBC"
                                                       .. " -D_NEWLIB_VERSION=4.3.0"
                                                       .. " -D__NEWLIB__=4"
                                                       .. " -fPIC"
                                                       .. '")\n' ..
            'string(APPEND CMAKE_CXX_FLAGS "'          .. " -isystem " .. package:installdir("include", "c++", "v1"):gsub("%\\", "/")
                                                       .. " -isystem " .. package:installdir("include"):gsub("%\\", "/")
                                                       .. " -isystem " .. newlib_inc_dir
                                                       .. " -isystem " .. libnx_inc_dir
                                                       .. " -D_GNU_SOURCE=1"
                                                       .. " -DLIBC"
                                                       .. " -D_NEWLIB_VERSION=4.3.0"
                                                       .. " -D__NEWLIB__=4"
                                                       .. " -fPIC"
                                                       .. '")\n' ..
            'string(APPEND CMAKE_SHARED_LINKER_FLAGS "'.. " -L" .. newlib_package:installdir("lib"):gsub("%\\", "/")
                                                       .. " -L" .. package:installdir("lib"):gsub("%\\", "/")
                                                       .. " -L" .. package:installdir("lib", "linux"):gsub("%\\", "/")
                                                       .. " -fPIC"
                                                       .. " -lclang_rt.atomic-aarch64 -lclang_rt.builtins-aarch64 -lunwind"
                                                       .. '")\n' ..
            'string(APPEND CMAKE_EXE_LINKER_FLAGS "'.. " -L" .. newlib_package:installdir("lib"):gsub("%\\", "/")
                                                       .. " -L" .. package:installdir("lib"):gsub("%\\", "/")
                                                       .. " -L" .. package:installdir("lib", "linux"):gsub("%\\", "/")
                                                       .. " -fPIC"
                                                       .. " -Wl,-pie"
                                                       .. " -lclang_rt.atomic-aarch64 -lclang_rt.builtins-aarch64 -lunwind"
                                                       .. '")\n'

        io.replace("compiler-rt/CMakeLists.txt",
                   cmakelist_replace_str,
                   cmakelist_replaced_str,
                   {plain = true})
        io.replace("compiler-rt/lib/builtins/CMakeLists.txt",
                   '${BUILTIN_TYPE}',
                   'STATIC')
        if package:config("cxx_support") then
            io.replace("libcxx/CMakeLists.txt",
                    cmakelist_replace_str,
                    cmakelist_replaced_str,
                    {plain = true})
            io.replace("libcxxabi/CMakeLists.txt",
                    cmakelist_replace_str,
                    cmakelist_replaced_str,
                    {plain = true})
        end
        io.replace("libunwind/CMakeLists.txt",
                   cmakelist_replace_str,
                   cmakelist_replaced_str,
                   {plain = true})
        io.replace("llvm/CMakeLists.txt",
                   cmakelist_replace_str,
                   cmakelist_replaced_str,
                   {plain = true})


        io.replace("clang/CMakeLists.txt",
                   cmakelist_replace_str,
                   cmakelist_replaced_str,
                   {plain = true})
        io.replace("clang/CMakeLists.txt",
                   "add_subdirectory(utils/TableGen)",
                   "",
                   {plain = true})

        local llvm_runtimes = {"compiler-rt", "libunwind"}
        if package:config("cxx_support") then
            table.join2(llvm_runtimes, {"libcxx", "libcxxabi"})
        end

        local runtime_options = {
            -- cmake
            "-DCMAKE_BUILD_TYPE=" .. (package:debug() and "Debug" or "Release"),
            "-DCMAKE_MAKE_PROGRAM=" .. ninja_exe,
            "-DCMAKE_SYSTEM_NAME=NxOS",
            "-DCMAKE_C_COMPILER_TARGET=aarch64-nxos-elf",
            "-DCMAKE_CXX_COMPILER_TARGET=aarch64-nxos-elf",

            -- to avoid cmake trying to link to libclang_rt.builtins-aarch64 before it is built
            "-DCMAKE_C_COMPILER_WORKS=ON",
            "-DCMAKE_CXX_COMPILER_WORKS=ON",

            -- llvm
            "-DLLVM_ENABLE_RUNTIMES=" .. table.concat(llvm_runtimes, ";"),
            "-DLLVM_DEFAULT_TARGET_TRIPLE=aarch64-nxos-elf",
            "-DLLVM_ENABLE_PIC=ON",
            "-DLLVM_ENABLE_MODULES=OFF",
            "-DLLVM_TABLEGEN_EXE=" .. path.join(llvm_package:installdir("bin"), "llvm-tblgen" .. suffix),

            -- compiler-rt
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
            "-DCOMPILER_RT_BUILD_STANDALONE_LIBATOMIC=ON",

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
            "-DLIBUNWIND_INCLUDE_DOCS=OFF",
            "-DLIBUNWIND_INCLUDE_TESTS=OFF",
        }

        if package:config("cxx_support") then
            table.join2(runtime_options, {
                -- libcxx
                "-DLIBCXX_INCLUDE_TESTS=OFF",
                "-DLIBCXX_ENABLE_DEBUG_MODE=" .. (package:debug() and "ON" or "OFF"),
                "-DLIBCXX_CXX_ABI=system-libcxxabi",
                "-DLIBCXX_ENABLE_STATIC=ON",
                "-DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON",
                "-DLIBCXX_CXX_ABI_INCLUDE_PATHS=" .. path.join(package:cachedir(), "source", "switch-llvm-runtimes", "libcxxabi", "include"),
                "-DLIBCXX_ENABLE_SHARED=NO",
                "-DLIBCXX_USE_COMPILER_RT=ON",
                "-DLIBCXX_INCLUDE_BENCHMARKS=OFF",
                "-DLIBCXX_HAS_PTHREAD_API=ON",

                -- libcxxabi
                "-DLIBCXXABI_USE_LLVM_UNWINDER=OFF",
                "-DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON",
                "-DLIBCXXABI_ENABLE_SHARED=OFF",
                "-DLIBCXXABI_USE_COMPILER_RT=ON",
                "-DLIBCXXABI_HAS_PTHREAD_API=ON",
                "-DLIBCXXABI_BAREMETAL=ON",
                "-DLIBCXXABI_ENABLE_PEDANTIC=ON",
                "-DLIBCXXABI_LIBUNWIND_INCLUDES_INTERNAL=" .. path.join(package:cachedir(), "source", "switch-llvm-runtimes", "libunwind", "include"),
                "-DLIBCXXABI_INCLUDE_TESTS=OFF",
                "-DLIBCXXABI_ENABLE_SHARED=OFF",
            })
        end

        os.cd("runtimes")
        import("package.tools.cmake").install(package, runtime_options, opt)

        os.cp(path.join(package:installdir("lib", "linux"), "libclang_rt.atomic-aarch64.a"), path.join(package:installdir("lib", "linux"), "libatomic.a"))

        local clang_options = {
            "-DCMAKE_BUILD_TYPE=" .. (package:debug() and "Debug" or "Release"),
            "-DCMAKE_MAKE_PROGRAM=" .. ninja_exe,
            "-DCMAKE_SYSTEM_NAME=NxOS",
            "-DCMAKE_C_COMPILER_TARGET=aarch64-nxos-elf",
            "-DCMAKE_CXX_COMPILER_TARGET=aarch64-nxos-elf",

            -- to avoid cmake trying to link to libclang_rt.builtins-aarch64 before it is built
            "-DCMAKE_C_COMPILER_WORKS=ON",
            "-DCMAKE_CXX_COMPILER_WORKS=ON",

            -- llvm
            "-DLLVM_ENABLE_PROJECTS=clang",
            "-DLLVM_ENABLE_RUNTIMES=",
            "-DLLVM_TARGETS_TO_BUILD=AArch64",
            "-DLLVM_HOST_TRIPLE=aarch64-nxos-elf",
            "-DLLVM_DEFAULT_TARGET_TRIPLE=aarch64-nxos-elf",
            "-DLLVM_INSTALL_UTILS=ON",
            "-DLLVM_ENABLE_PIC=ON",
            "-DLLVM_ENABLE_MODULES=OFF",
            "-DLLVM_BUILD_TESTS=OFF",
            "-DLLVM_ENABLE_OCAMLDOC=OFF",
            "-DLLVM_ENABLE_DOCS=OFF",
            "-DLLVM_ENABLE_BINDINGS=OFF",
            "-DLLVM_INCLUDE_TESTS=OFF",
            "-DLLVM_INCLUDE_DOCS=OFF",
            "-DLLVM_INCLUDE_EXAMPLES=OFF",
            "-DLLVM_ENABLE_LIBCXX=ON",
            "-DLLVM_BUILD_STATIC=ON",
            "-DLLVM_INCLUDE_TOOLS=ON",
            "-DLLVM_BUILD_TOOLS=OFF",
            "-DLLVM_TABLEGEN_EXE=" .. path.join(llvm_package:installdir("bin"), "llvm-tblgen" .. suffix),

            -- clang
            "-DCLANG_DEFAULT_CXX_STDLIB=libc++",
            "-DCLANG_DEFAULT_RTLIB=compiler-rt",
            "-DCLANG_DEFAULT_UNWINDLIB=libunwind",
            "-DCLANG_BUILD_TOOLS=OFF",
            "-DCLANG_ENABLE_STATIC_ANALYZER=OFF",
            "-DCLANG_ENABLE_ARCMT=OFF",
            "-DCLANG_TABLEGEN_EXE=" .. path.join(llvm_package:installdir("bin"), "clang-tblgen" .. suffix),

            -- libclang
            "-DLIBCLANG_BUILD_STATIC=ON"
        }

        os.cd("../llvm")

        import("package.tools.cmake").build(package, clang_options, table.join(opt, {target = "install-core-resource-headers"}))
        import("package.tools.cmake").build(package, clang_options, table.join(opt, {target = "install-arm-common-resource-headers"}))
        import("package.tools.cmake").build(package, clang_options, table.join(opt, {target = "install-aarch64-resource-headers"}))
    end)