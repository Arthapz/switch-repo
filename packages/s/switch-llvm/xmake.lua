local buildflags = {
    "-march=armv8-a+crc+crypto+simd",
    "-mcpu=cortex-a57",
    "-mtune=cortex-a57",
    "-ftls-model=local-exec",
    "-ffunction-sections",
    "-fdata-sections",
    "-fstack-protector-strong",
    "-fPIC",
    "-mtp=el0",
    "-fvectorize"
}

local sharedlinkflags = {
    "-Wl,-Bdynamic",
    "-fPIC",
    "-Wl,--gc-sections",
    "-Wl,-z,text",
    "-Wl,--build-id=sha1",
    "-Wl,--no-undefined",
    "-Wl,--no-dynamic-linker",
    "-Wl,--as-needed",
    "-Wl,--eh-frame-hdr",
    "-fvisibility=hidden"
}

local executablelinkflags = {
    "-Wl,-Bsymbolic",
    "-fPIE",
    "-Wl,-pie",
    "-Wl,--gc-sections",
    "-Wl,-z,text",
    "-Wl,--build-id=sha1",
    "-Wl,--no-dynamic-linker",
    "-Wl,--as-needed",
    "-Wl,--eh-frame-hdr",
    "-fvisibility=hidden"
}

local defines = {
    "__SWITCH__=1",
    "__SWITCH=1",
    "LIBNX_NO_DEPRECATION",
    "_GNU_SOURCE=1",
    "_LIBC",
    "_NEWLIB_VERSION=4.3.0",
    "__NEWLIB__=4"
}

package("switch-llvm")
    set_kind("toolchain")
    set_homepage("https://llvm.org/")
    set_description("The LLVM Compiler Infrastructure, targetting Nintendo switch environment")

    set_urls("https://github.com/Arthapz/switch-llvm.git", {branch = "main"})
    add_versions("20230602", "668b3a7b5df747df52297796b754a71e74bfc7e2")

    add_deps("cmake", {kind = "binary", host = true})
    add_deps("ninja", {kind = "binary", host = true})
    add_deps("python 3.x", {kind = "binary", host = true})

    add_configs("lldb", {description = "Build and install lldb", default = false, type = "boolean"})

    add_defines(defines)
    add_cxflags(buildflags)
    add_asflags(buildflags)
    add_ldflags(executablelinkflags)
    add_shflags(sharedlinkflags)

    on_load(function(package)
        package:add("links", nx)
    end)

    on_install("@windows", "@macosx", "@linux", function(package)
        import("lib.detect.find_tool")

        local suffix = is_host("windows") and ".exe" or ""

        local opt = {}
        opt.cmake_generator = "Ninja"
        opt.jobs = 20

        local llvm_projects = {"clang", "lld"}
        if package:config("lldb") then
            table.insert(llvm_projects, "lldb")
        end

        os.cd("llvm-project/llvm")
        import("package.tools.cmake").install(package, {
            "-DCMAKE_BUILD_TYPE=Release",
            "-DLLVM_ENABLE_PROJECTS=" .. table.concat(llvm_projects, ";"),
            "-DLLVM_ENABLE_RUNTIMES=",
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
            "-DCLANG_DEFAULT_CXX_STDLIB=libc++",
            "-DCLANG_DEFAULT_RTLIB=compiler-rt",
            "-DCLANG_DEFAULT_UNWINDLIB=libunwind"
        }, opt)

        os.cd("../../newlib")
        os.cp(path.join(package:scriptdir(), "ports", "newlib", "xmake.lua"), "xmake.lua")

        opt = {
            arch = "aarch64",
            mode = package:debug() and "debug" or "release",
            cxflags = table.concat(buildflags, " ") .. " " .. table.concat(defines, " "):gsub("([^ ]+)", "-D%1"),
            ldflags = table.concat(executablelinkflags, " "),
            shflags = table.concat(sharedlinkflags, " "),
            cc = path.join(package:installdir("bin"),"clang" .. suffix),
            cxx = path.join(package:installdir("bin"), "clang++" .. suffix),
            as = path.join(package:installdir("bin"), "clang++" .. suffix),
            ld = path.join(package:installdir("bin"), "clang++" .. suffix),
            sh = path.join(package:installdir("bin"), "clang++" .. suffix),
            ar = path.join(package:installdir("bin"), "llvm-ar" .. suffix),
            ranlib = path.join(package:installdir("bin"), "llvm-ranlib" .. suffix),
            mrc = path.join(package:installdir("bin"), "llvm-rc" .. suffix)}
        import("package.tools.xmake").install(package, opt)

        os.cd("../../libnx")
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

        os.cd("../llvm-project")

        local opt = {mode = package:debug() and "debug" or "release"}
        opt.cmake_generator = "Ninja"

        local ninja_exe = find_tool("ninja").program

        local suffix = is_host("windows") and ".exe" or ""

        local newlib_package = package:dep("switch-newlib")
        local libnx_package = package:dep("libnx")

        local newlib_inc_dir = newlib_package:installdir("include"):gsub("%\\", "/")
        local libnx_inc_dir = libnx_package:installdir("include"):gsub("%\\", "/")

        io.replace("compiler-rt/lib/builtins/CMakeLists.txt",
                   '${BUILTIN_TYPE}',
                   'STATIC')
        io.replace("clang/CMakeLists.txt",
                   "add_subdirectory(utils/TableGen)",
                   "",
                   {plain = true})

        local llvm_runtimes = {"compiler-rt", "libunwind", "libcxx", "libcxxabi"}
        local runtime_options = {
            -- cmake
            "-DCMAKE_BUILD_TYPE=" .. (package:debug() and "Debug" or "Release"),
            "-DCMAKE_MAKE_PROGRAM=" .. ninja_exe,
            "-DCMAKE_SYSTEM_NAME=NxOS",
            "-DCMAKE_C_COMPILER_TARGET=aarch64-nxos-elf",
            "-DCMAKE_CXX_COMPILER_TARGET=aarch64-nxos-elf",

            "-DCMAKE_C_FLAGS=" .. table.concat(buildflags, " ") .. " " .. table.concat(defines, " "):gsub("([^ ]+)", "-D%1"),
            "-DCMAKE_CXX_FLAGS=" .. table.concat(buildflags, " ") .. " " .. table.concat(defines, " "):gsub("([^ ]+)", "-D%1"),
            "-DCMAKE_AS_FLAGS=" .. table.concat(buildflags, " ") .. " " .. table.concat(defines, " "):gsub("([^ ]+)", "-D%1"),
            "-DCMAKE_EXE_LINKER_FLAGS=" .. table.concat(executablelinkflags, " "),
            "-DCMAKE_SHARED_LINKER_FLAGS=" .. table.concat(sharedlinkflags, " "),
            "-DCMAKE_REQUIRED_FLAGS=" .. table.concat(executablelinkflags, " "),

            -- llvm
            "-DLLVM_ENABLE_PROJECTS=",
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
            "-DLIBCXX_ENABLE_STD_MODULE=ON",

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
        }

        os.cd("runtimes")
        opt = {}
        opt.cmake_generator = "Ninja"
        opt.jobs = 20
        import("package.tools.cmake").install(package, runtime_options, opt)

        os.cp(path.join(package:installdir("lib", "linux"), "libclang_rt.atomic-aarch64.a"), path.join(package:installdir("lib", "linux"), "libatomic.a"))
    end)

    on_test(function (package)
        os.vrun("llvm-config --version")
        os.vrun("clang --version")
    end)
