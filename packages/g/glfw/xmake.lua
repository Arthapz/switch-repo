package("glfw")
    set_policy("package.strict_compatibility", true)
    add_urls("https://github.com/natinusaladevkitPro/glfw.git", {branch = "main"})
    add_versions("20210618", "4f942ab8e16a36a3956f39c6a64f7285d7eb60c9")

    add_deps("cmake", {host = true})

    add_deps("switch-llvm-sysroot", "switch-mesa", "glm")

    on_install("switch", function(package)
        import("package.tools.cmake").install(package)
    end)