/**
   Tests for non-dub projects that use dub
*/
module tests.it.runtime.dub.dependencies;


import tests.it.runtime;


// don't ask...
version(Windows)
    alias ArghWindows = Flaky;
else
    enum ArghWindows;


// A dub package that isn't at the root of the project directory
@("dubDependant.path.exe.default")
@ArghWindows
@Tags("dub", "ninja")
unittest {
    import reggae.rules.common: exeExt;
    with(immutable ReggaeSandbox()) {
        // a dub package we're going to depend on by path
        writeFile(
            "over/there/dub.sdl",
            [
                `name "foo"`,
                `targetType "library"`
            ]
        );
        // src code for the dub dependency
        writeFile(
            "over/there/source/foo.d",
            q{int twice(int i) { return i * 2; }}
        );
        // our main program, which will depend on a dub package by path
        writeFile(
            "src/app.d",
            q{
                import foo;
                void main() {
                    assert(5.twice == 10);
                }
            }
        );
        writeFile(
            "reggaefile.d",
            q{
                import reggae;
                alias app = dubDependant!(
                    TargetName("myapp"),
                    DubDependantTargetType.executable,
                    Sources!(Files("src/app.d")),
                    DubPath("over/there"),
                );
                mixin build!app;
            }
        );

        runReggae("-b", "ninja");
        ninja.shouldExecuteOk;
        shouldExist("myapp" ~ exeExt);
        shouldSucceed("myapp");
    }
}

// A dub package that isn't at the root of the project directory
@("dubDependant.path.exe.config")
@ArghWindows
@Tags("dub", "ninja")
unittest {
    import reggae.rules.common: exeExt;
    with(immutable ReggaeSandbox()) {
        // a dub package we're going to depend on by path
        writeFile(
            "over/there/dub.sdl",
            [
                `name "foo"`,
                `targetType "library"`,
                `configuration "default" {`,
                `}`,
                `configuration "weirdo" {`,
                `    versions "weird"`,
                `}`,
            ]
        );
        // src code for the dub dependency
        writeFile(
            "over/there/source/foo.d",
            q{
                int result(int i) {
                    version(weird)
                        return i * 3;
                    else
                        return i * 2;
                }
            }
        );
        // our main program, which will depend on a dub package by path
        writeFile(
            "src/app.d",
            q{
                import foo;
                void main() {
                    assert(5.result == 15);
                    assert(6.result == 18);
                }
            }
        );
        writeFile(
            "reggaefile.d",
            q{
                import reggae;
                alias app = dubDependant!(
                    TargetName("myapp"),
                    DubDependantTargetType.executable,
                    Sources!(Files("src/app.d")),
                    DubPath("over/there", Configuration("weirdo")),
                );
                mixin build!app;
            }
        );

        runReggae("-b", "ninja");
        ninja.shouldExecuteOk;
        shouldExist("myapp" ~ exeExt);
        shouldSucceed("myapp");
    }
}


// A dub package that isn't at the root of the project directory
@("dubDependant.path.lib")
@ArghWindows
@Tags("dub", "ninja")
unittest {
    import reggae.rules.common: libExt;
    with(immutable ReggaeSandbox()) {
        // a dub package we're going to depend on by path
        writeFile(
            "over/there/dub.sdl",
            [
                `name "foo"`,
                `targetType "library"`
            ]
        );
        // src code for the dub dependency
        writeFile(
            "over/there/source/foo.d",
            q{int twice(int i) { return i * 2; }}
        );
        // our main program, which will depend on a dub package by path
        writeFile(
            "src/app.d",
            q{
                import foo;
                void main() {
                    assert(5.twice == 10);
                }
            }
        );
        writeFile(
            "reggaefile.d",
            q{
                import reggae;
                alias app = dubDependant!(
                    TargetName("myapp"),
                    DubDependantTargetType.staticLibrary,
                    Sources!(Files("src/app.d")),
                    DubPath("over/there"),
                );
                mixin build!app;
            }
        );

        runReggae("-b", "ninja");
        ninja.shouldExecuteOk;
        shouldExist("myapp" ~ libExt);
        version(Posix)
            ["file", inSandboxPath("myapp" ~ libExt)]
                .shouldExecuteOk
                .shouldContain("archive");
    }
}

// A dub package that isn't at the root of the project directory
@("dubDependant.path.dll")
@ArghWindows
@Tags("dub", "ninja")
unittest {
    import reggae.rules.common: dynExt;
    with(immutable ReggaeSandbox()) {
        // a dub package we're going to depend on by path
        writeFile(
            "over/there/dub.sdl",
            [
                `name "foo"`,
                `targetType "library"`
            ]
        );
        // src code for the dub dependency
        writeFile(
            "over/there/source/foo.d",
            q{int twice(int i) { return i * 2; }}
        );
        // our main program, which will depend on a dub package by path
        writeFile(
            "src/app.d",
            q{
                import foo;
                void main() {
                    assert(5.twice == 10);
                }
            }
        );
        writeFile(
            "reggaefile.d",
            q{
                import reggae;
                alias app = dubDependant!(
                    TargetName("myapp"),
                    DubDependantTargetType.sharedLibrary,
                    Sources!(Files("src/app.d")),
                    DubPath("over/there"),
                );
                mixin build!app;
            }
        );

        runReggae("-b", "ninja");
        ninja.shouldExecuteOk;
        shouldExist("myapp" ~ dynExt);
        version(Posix)
            ["file", inSandboxPath("myapp" ~ dynExt)]
                .shouldExecuteOk
                .shouldContain("shared");
    }
}

@("dubDependant.flags.compiler")
@ArghWindows
@Tags("dub", "ninja")
unittest {
    with(immutable ReggaeSandbox()) {
        // a dub package we're going to depend on by path
        writeFile(
            "over/there/dub.sdl",
            [
                `name "foo"`,
                `targetType "library"`
            ]
        );
        // src code for the dub dependency
        writeFile("over/there/source/foo.d", "");
        // our main program, which will depend on a dub package by path
        writeFile(
            "src/app.d",
            q{
                import foo;
                void main() { }
            }
        );
        writeFile(
            "reggaefile.d",
            q{
                import reggae;
                alias app = dubDependant!(
                    TargetName("myapp"),
                    DubDependantTargetType.executable,
                    Sources!(Files("src/app.d")),
                    CompilerFlags("-foo", "-bar"),
                    DubPath("over/there"),
                );
                mixin build!app;
            }
        );

        runReggae("-b", "ninja");
        fileShouldContain("build.ninja", "flags = -foo -bar");
    }
}


@("dubDependant.flags.linker")
@ArghWindows
@Tags("dub", "ninja")
unittest {
    with(immutable ReggaeSandbox()) {
        // a dub package we're going to depend on by path
        writeFile(
            "over/there/dub.sdl",
            [
                `name "foo"`,
                `targetType "library"`
            ]
        );
        // src code for the dub dependency
        writeFile("over/there/source/foo.d", "");
        // our main program, which will depend on a dub package by path
        writeFile(
            "src/app.d",
            q{
                import foo;
                void main() { }
            }
        );
        writeFile(
            "reggaefile.d",
            q{
                import reggae;
                alias app = dubDependant!(
                    TargetName("myapp"),
                    DubDependantTargetType.executable,
                    Sources!(Files("src/app.d")),
                    CompilerFlags("-abc", "-def"),
                    LinkerFlags("-quux"),
                    DubPath("over/there"),
                );
                mixin build!app;
            }
        );

        runReggae("-b", "ninja");
        fileShouldContain("build.ninja", "flags = -quux");
    }
}


@("dubDependant.flags.imports")
@ArghWindows
@Tags("dub", "ninja")
unittest {
    with(immutable ReggaeSandbox()) {
        // a dub package we're going to depend on by path
        writeFile(
            "over/there/dub.sdl",
            [
                `name "foo"`,
                `targetType "library"`
            ]
        );
        // src code for the dub dependency
        writeFile("over/there/source/foo.d", "");
        // our main program, which will depend on a dub package by path
        writeFile(
            "src/app.d",
            q{
                import foo;
                void main() { }
            }
        );
        writeFile(
            "reggaefile.d",
            q{
                import reggae;
                alias app = dubDependant!(
                    TargetName("myapp"),
                    DubDependantTargetType.executable,
                    Sources!(Files("src/app.d")),
                    ImportPaths("leimports"),
                    DubPath("over/there"),
                );
                mixin build!app;
            }
        );

        runReggae("-b", "ninja");
        fileShouldContain("build.ninja", "-I" ~ inSandboxPath("leimports"));
    }
}

@("dubDependant.flags.stringImports")
@ArghWindows
@Tags("dub", "ninja")
unittest {
    with(immutable ReggaeSandbox()) {
        // a dub package we're going to depend on by path
        writeFile(
            "over/there/dub.sdl",
            [
                `name "foo"`,
                `targetType "library"`
            ]
        );
        // src code for the dub dependency
        writeFile("over/there/source/foo.d", "");
        // our main program, which will depend on a dub package by path
        writeFile(
            "src/app.d",
            q{
                import foo;
                void main() { }
            }
        );
        writeFile(
            "reggaefile.d",
            q{
                import reggae;
                alias app = dubDependant!(
                    TargetName("myapp"),
                    DubDependantTargetType.executable,
                    Sources!(Files("src/app.d")),
                    StringImportPaths("lestrings"),
                    DubPath("over/there"),
                );
                mixin build!app;
            }
        );

        runReggae("-b", "ninja");
        fileShouldContain("build.ninja", "-J" ~ inSandboxPath("lestrings"));
    }
}

@("dubDependency.exe.naked")
@Tags("dub", "ninja")
unittest {
    with(immutable ReggaeSandbox()) {
        writeFile(
            "over/there/dub.sdl",
            [
                `name "foo"`,
                `targetType "executable"`,
            ]
       );
        writeFile(
            "over/there/source/app.d",
            q{
                int main(string[] args) {
                    import std.conv: to;
                    return args[1].to!int;
                }
            }
        );
        writeFile(
            "reggaefile.d",
            q{
                import reggae;
                alias dubDep = dubDependency!(DubPath("over/there"));
                mixin build!dubDep;
            }
        );

        runReggae("-b", "ninja");
        ninja.shouldExecuteOk;
        shouldSucceed("over/there/foo", "0");
        shouldFail(   "over/there/foo", "1");
    }
}

@ShouldFail
@("dubDependency.exe.phony")
@Tags("dub", "ninja")
unittest {
    import std.format;
    with(immutable ReggaeSandbox()) {
        writeFile(
            "over/there/dub.sdl",
            [
                `name "foo"`,
                `targetType "executable"`,
            ]
       );
        writeFile(
            "over/there/source/app.d",
            q{
                int main(string[] args) {
                    import std.conv: to;
                    return args[1].to!int;
                }
            }
        );
        const foo = inSandboxPath("over/there/foo");
        writeFile(
            "reggaefile.d",
            q{
                import reggae;

                alias dubDep = dubDependency!(DubPath("over/there"));
                alias yay = phony!("yay", "%s 0", dubDep);
                alias nay = phony!("nay", "%s 1", dubDep);
                mixin build!(yay, nay);
            }.format(foo, foo)
        );

        runReggae("-b", "ninja");
        ninja(["yay"]).shouldExecuteOk;
        ninja(["nay"]).shouldFailToExecute;
    }
}


@("dubDependency.lib.config")
@Tags("dub", "ninja")
unittest {
    import reggae.rules.common: exeExt;
    with(immutable ReggaeSandbox()) {
        writeFile(
            "over/there/dub.sdl",
            [
                `name "foo"`,
                `targetType "library"`,
                `configuration "default" {`,
                `}`,
                `configuration "unittest" {`,
                `    targetName "ut"`,
                `    targetPath "bin"`,
                `    mainSourceFile "ut_main.d"`,
                `}`,
            ]
       );
        writeFile("over/there/source/foo.d", "");
        writeFile("over/there/ut_main.d", "void main() {}");
        writeFile(
            "reggaefile.d",
            q{
                import reggae;
                alias dubDep = dubDependency!(
                    DubPath("over/there", Configuration("unittest")),
                );
                mixin build!dubDep;
            }
        );

        runReggae("-b", "ninja");
        ninja.shouldExecuteOk;
        shouldSucceed("over/there/bin/ut" ~ exeExt);
    }
}
