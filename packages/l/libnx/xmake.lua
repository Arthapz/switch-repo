package("libnx")
    add_urls("https://github.com/Arthapz/libnx.git", {branch = "main"})
    add_versions("20230530", "b0e6258632f4f44888ba9b627b127b3d56579067")

    add_deps("switch-llvm", {kind = "binary", host = true})

    add_defines("LIBNX_NO_DEPRECATION")

    on_install("switch", function(package)
        os.cp(path.join(package:scriptdir(), "port", "xmake.lua"), "xmake.lua")

        io.replace("nx/source/runtime/newlib.c",
[[    tv->handle     = envGetMainThreadHandle();]],
[[    tv->handle     = envGetMainThreadHandle();
      void *ptr;
      __asm__ volatile  ("mrs %x[data], tpidrro_el0\n\t"
                         "ldr %x[data], [%x[data], #0x1F8]\n\t"
                         "msr tpidr_el0, %x[data]"
                         : [data] "=r" (ptr));]], {plain = true})

        local opt = {mode = package:debug() and "debug" or "release"}
        import("package.tools.xmake").install(package, opt)
    end)
