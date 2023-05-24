package("switch-libcxx")
    set_homepage("https://llvm.org/")
    set_description("The LLVM Compiler Infrastructure, targetting Nintendo switch environment")

    set_urls("https://github.com/llvm/llvm-project.git", {branch = "main", depth = 1})
    add_versions("20230524-2", "bb4f88f9b97f8345c04afcea5323b1d26f022507")

    add_deps("cmake", {kind = "binary", host = true})
    add_deps("ninja", {kind = "binary", host = true})
    add_deps("switch-support-files")
    add_deps("switch-newlib")
    add_deps("switch-libnx")

    add_cxxflags("-nostdlib++")
    add_cxxflags("-nostdlibinc++")

    on_load(function(package)
        package:add("includedirs", path.join("include", "c++", "v1"))
    end)

    on_install("switch", function(package)
        local opt = {}
        opt.cmake_generator = "Ninja"

        local suffix = is_host("windows") and ".exe" or ""

        os.cd("libcxx")
        io.replace("CMakeLists.txt",
            'cmake_minimum_required(VERSION 3.13.4)',
            [[cmake_minimum_required(VERSION 3.13.4)
              string(APPEND CMAKE_C_FLAGS " -isystem ]] .. package:dep("switch-newlib"):installdir("include"):gsub("%\\", "/")
                                                          .. " -D_GNU_SOURCE=1"
                                                          .. " -DLIBC"
                                                          .. " -D_NEWLIB_VERSION=4.3.0"
                                                          .. " -D__NEWLIB__=4"
                                                          .. '")\n' ..
            'string(APPEND CMAKE_CXX_FLAGS " -isystem ' .. package:dep("switch-newlib"):installdir("include"):gsub("%\\", "/")
                                                          .. " -D_GNU_SOURCE=1"
                                                          .. " -DLIBC"
                                                          .. " -D_NEWLIB_VERSION=4.3.0"
                                                          .. " -D__NEWLIB__=4"
                                                          .. '")\n',
            {plain = true}
        )
        import("package.tools.cmake").install(package, {
            "-DCMAKE_BUILD_TYPE=Release",
            "-DCMAKE_MAKE_PROGRAM=" .. path.join(package:dep("ninja"):installdir("bin"), "ninja" .. suffix),
            "-DCMAKE_SYSTEM_NAME=NxOS",
            "-DLIBCXX_CXX_ABI=system-libcxxabi",
            "-DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON",
            "-DLIBCXX_CXX_ABI_INCLUDE_PATHS=" .. path.join(package:cachedir(), "source", "switch-libcxx", "libcxxabi", "include"),
            "-DLIBCXX_ENABLE_SHARED=NO",
            "-DLIBCXX_USE_COMPILER_RT=ON",
            "-DLIBCXX_INCLUDE_BENCHMARKS=OFF",
            "-DLIBCXX_ENABLE_EXPERIMENTAL_LIBRARY=YES",
            "-DLIBCXX_HAS_PTHREAD_API=ON",
            "-DLLVM_ENABLE_PIC=ON",
            "-DLLVM_ENABLE_MODULES=ON",
            "-DLLVM_BUILD_TESTS=OFF",
            "-DLLVM_ENABLE_OCAMLDOC=OFF",
            "-DLLVM_ENABLE_DOCS=OFF",
            "-DLLVM_ENABLE_BINDINGS=OFF",
            "-DLLVM_INCLUDE_TESTS=OFF",
            "-DLLVM_INCLUDE_EXAMPLES=OFF",
        }, opt)
    end)