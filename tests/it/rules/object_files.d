
module tests.it.rules.object_files;


import reggae;
import reggae.path: buildPath;
import unit_threaded;
import tests.it;
import std.file;
import std.stdio: File;


@("C++ files with template objectFiles") unittest {
    import reggae.buildgen;
    auto options = testProjectOptions("binary", "template_rules");
    string[] flags;

    getBuildObject!"template_rules.reggaefile"(options).shouldEqual(
        Build(Target("app",
                     Command(CommandType.link, assocListT("flags", flags)),
                     [Target("main" ~ objExt, compileCommand("main.cpp", ["-g", "-O0"]), [Target("main.cpp")]),
                      Target("maths" ~ objExt, compileCommand("maths.cpp", ["-g", "-O0"]), [Target("maths.cpp")])]
                  )));
}

@("C++ files with regular objectFiles") unittest {
    import reggae.config: options;
    import std.path: absolutePath;

    auto testPath = newTestDir.absolutePath;
    mkdir(buildPath(testPath, "proj"));
    foreach(fileName; ["main.cpp", "maths.cpp", "intermediate.hpp", "final.hpp" ]) {
        auto f = File(buildPath(testPath, "proj", fileName), "w");
        f.writeln;
    }

    string[] none;
    objectFiles(options, testPath, ["."], none, none, none, ["-g", "-O0"]).shouldBeSameSetAs(
        [Target(buildPath("proj/main" ~ objExt),
                compileCommand("proj/main.cpp", ["-g", "-O0"]),
                [Target(buildPath("proj/main.cpp"))]),
         Target(buildPath("proj/maths" ~ objExt),
                compileCommand("proj/maths.cpp", ["-g", "-O0"]),
                [Target(buildPath("proj/maths.cpp"))])]
    );
}
