module reggae.dub.interop.exec;

import reggae.from;

@safe:


package string callDub(T)(
    auto ref T output,
    in from!"reggae.options".Options options,
    in string[] rawArgs,
    from!"std.typecons".Flag!"maybeNoDeps" maybeNoDeps = from!"std.typecons".No.maybeNoDeps)
{
    import reggae.io: log;
    import std.process: execute, Config;
    import std.exception: enforce;
    import std.conv: text;
    import std.string: join, split;
    import std.path: buildPath;
    import std.file: exists;

    const hasSelections = buildPath(options.projectPath, "dub.selections.json").exists;
    string[] emptyArgs;
    const noDepsArgs = hasSelections && maybeNoDeps ? ["--nodeps", "--skip-registry=all"] : emptyArgs;
    const archArg = rawArgs[1] == "fetch" || rawArgs[1] == "upgrade"
        ? emptyArgs
        : ["--arch=" ~ options.dubArch.text];
    const args = rawArgs ~ noDepsArgs ~ dubEnvArgs ~ archArg;
    const string[string] env = null;
    Config config = Config.none;
    size_t maxOutput = size_t.max;
    const workDir = options.projectPath;

    output.log("Calling `", args.join(" "), "`");
    const ret = execute(args, env, config, maxOutput, workDir);
    enforce(ret.status == 0,
            text("Error calling `", args.join(" "), "` (", ret.status, ")", ":\n",
                 ret.output));

    return ret.output;
}


package string[] dubEnvArgs() {
    import std.process: environment;
    import std.string: split;
    return environment.get("REGGAE_DUB_ARGS", "").split(" ");
}


package void dubFetch(T)(auto ref T output,
                         in from!"reggae.options".Options options)
    @trusted
{
    import reggae.io: log;
    import reggae.dub.interop.exec: callDub, dubEnvArgs;
    import std.array: join, replace;
    import std.stdio: writeln;
    import std.path: buildPath;
    import std.json: parseJSON, JSONType;
    import std.file: readText;

    const fileName = buildPath(options.projectPath, "dub.selections.json");
    auto json = parseJSON(readText(fileName));

    auto versions = json["versions"];

    foreach(dubPackage, versionJson; versions.object) {

        // skip the ones with a defined path
        if(versionJson.type != JSONType.string) continue;

        // versions are usually `==1.2.3`, so strip the sign
        const version_ = versionJson.str.replace("==", "");

        if(!needDubFetch(dubPackage, version_)) continue;


        const cmd = ["dub", "fetch", dubPackage, "--version=" ~ version_] ~ dubEnvArgs;

        try
            callDub(output, options, cmd);
        catch(Exception ex) {
            // local packages can't be fetched, so it's normal to get an error
            if(!options.dubLocalPackages)
                throw ex;
        }
    }
}

// dub fetch can sometimes take >10s (!) despite the package already being
// on disk
private bool needDubFetch(in string dubPackage, in string version_) {
    import reggae.path: dubPackagesDir;
    import std.path: buildPath;
    import std.file: exists;

    return !buildPath(dubPackagesDir,
                      dubPackage ~ "-" ~ version_, dubPackage ~ ".lock")
        .exists;
}
