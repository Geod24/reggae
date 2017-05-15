module tests.it.runtime.dub;


import tests.it.runtime;
import reggae.reggae;
import std.path;


private string prepareTestPath(in string projectName) {
    const testPath = newTestDir;
    const projPath = buildPath(origPath, "tests", "projects", projectName);
    copyProjectFiles(projPath, testPath);
    return testPath;
}

@("dub project with no reggaefile ninja")
@Tags(["dub", "ninja"])
unittest {

    with(immutable ReggaeSandbox()) {
        copyProject("dub");
        shouldNotExist("reggaefile.d");
        runReggae("-b", "ninja", "--dflags=-g -debug");
        shouldExist("reggaefile.d");
        auto output = ninja.shouldExecuteOk(testPath);
        output.shouldContain("-g -debug");

        shouldSucceed("atest").shouldEqual(
            ["Why hello!",
             "",
             "[0, 0, 0, 4]",
             "I'm immortal!"]
        );

        // there's only one UT in main.d which always fails
        shouldFail("ut");
    }
}

@("dub project with no reggaefile tup")
@Tags(["dub", "tup"])
unittest {
    with(immutable ReggaeSandbox()) {
        copyProject("dub");
        runReggae("-b", "tup", "--dflags=-g -debug").
            shouldThrowWithMessage("dub integration not supported with the tup backend");
    }
}

@("dub project with no reggaefile and prebuild command")
@Tags(["dub", "ninja"])
unittest {
    with(immutable ReggaeSandbox()) {
        copyProject("dub_prebuild");
        runReggae("-b", "ninja", "--dflags=-g -debug");
        ninja.shouldExecuteOk(testPath);
        shouldSucceed("ut");
    }
}

@("dub project with no target type")
@Tags(["dub", "ninja"])
unittest {

    with(immutable ReggaeSandbox()) {
        writeFile("dub.json", `
{
  "name": "notargettype",
  "license": "MIT",
  "targetType": "none"
}`);

        runReggae("-b", "ninja", "--dflags=-g -debug").shouldThrowWithMessage(
        "Unsupported dub targetType 'none'");
    }
}

@("project with dependencies not on file system already")
@Tags(["dub", "ninja"])
unittest {

    import std.file: exists, rmdirRecurse;
    import std.process: environment;
    import std.path: buildPath;

    const cerealedDir = buildPath(environment["HOME"], ".dub/packages/cerealed-0.6.8");
    if(cerealedDir.exists)
        rmdirRecurse(cerealedDir);

    with(immutable ReggaeSandbox()) {
        writeFile("dub.json", `
{
  "name": "depends_on_cerealed",
  "license": "MIT",
  "targetType": "executable",
  "dependencies": { "cerealed": "==0.6.8" }
}`);

        runReggae("-b", "ninja");
    }
}
