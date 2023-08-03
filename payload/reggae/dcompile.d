module reggae.dcompile;

import std.stdio;
import std.exception;
import std.process;
import std.conv;
import std.algorithm;
import std.getopt;
import std.array;


version(ReggaeTest) {}
else {
    int main(string[] args) {
        try {
            return dcompile(args);
        } catch(Exception ex) {
            stderr.writeln(ex.msg);
            return 1;
        }
    }
}

/**
Only exists in order to get dependencies for each compilation step.
 */
private int dcompile(string[] args) {

    version(Windows) {
        // expand any response files in args (`dcompile @file.rsp`)
        import std.array: appender;
        import std.file: readText;

        auto expandedArgs = appender!(string[]);
        expandedArgs.reserve(args.length);

        foreach (arg; args) {
            if (arg.length > 1 && arg[0] == '@') {
                expandedArgs ~= parseResponseFile(readText(arg[1 .. $]));
            } else {
                expandedArgs ~= arg;
            }
        }

        args = expandedArgs[];
    }

    string depFile, objFile;
    auto helpInfo = getopt(
        args,
        std.getopt.config.passThrough,
        "depFile", "The dependency file to write", &depFile,
        "objFile", "The object file to output", &objFile,
    );

    enforce(args.length >= 2, "Usage: dcompile --objFile <objFile> --depFile <depFile> <compiler> <compiler args>");
    enforce(!depFile.empty && !objFile.empty, "The --depFile and --objFile 'options' are mandatory");

    const makeDeps = "-makedeps=" ~ depFile;
    const compArgs = args[1..$] ~ makeDeps;
    const compRes = invokeCompiler(compArgs, objFile);

    if (compRes.status != 0) {
        stderr.writeln("Error compiling!");
        return compRes.status;
    }

    return 0;
}

private auto invokeCompiler(in string[] args, in string objFile) @safe {
    version(Windows) {
        static string quoteArgIfNeeded(string a) {
            return !a.canFind(' ') ? a : `"` ~ a.replace(`"`, `\"`) ~ `"`;
        }

        const rspFileContent = args[1..$].map!quoteArgIfNeeded.join("\n");

        // max command-line length (incl. args[0]) is ~32,767 on Windows
        if (rspFileContent.length > 32_000) {
            import std.file: mkdirRecurse, remove, write;
            import std.path: dirName;

            const rspFile = objFile ~ ".dcompile.rsp"; // Ninja uses `<objFile>.rsp`, don't collide
            mkdirRecurse(dirName(rspFile));
            write(rspFile, rspFileContent);
            const res = execute([quoteArgIfNeeded(args[0]), "@" ~ rspFile], /*env=*/null, Config.stderrPassThrough);
            remove(rspFile);
            return res;
        }
    }

    // pass through stderr, capture stdout with -v output
    return execute(args, /*env=*/null, Config.stderrPassThrough);
}


// Parses the arguments from the specified response file content.
version(Windows)
string[] parseResponseFile(in string data) @safe pure {
    import std.array: appender;
    import std.ascii: isWhite;

    auto args = appender!(string[]);
    auto currentArg = appender!(char[]);
    void pushArg() {
        if (currentArg[].length > 0) {
            args ~= currentArg[].idup;
            currentArg.clear();
        }
    }

    args.reserve(128);
    currentArg.reserve(512);

    char currentQuoteChar = 0;
    foreach (char c; data) {
        if (currentQuoteChar) {
            // inside quoted arg/fragment
            if (c != currentQuoteChar) {
                currentArg ~= c;
            } else {
                auto a = currentArg[];
                if (currentQuoteChar == '"' && a.length > 0 && a[$-1] == '\\') {
                    a[$-1] = c; // un-escape: \" => "
                } else { // closing quote
                    currentQuoteChar = 0;
                }
            }
        } else if (isWhite(c)) {
            pushArg();
        } else if (c == '"' || c == '\'') {
            // beginning of quoted arg/fragment
            currentQuoteChar = c;
        } else {
            // inside unquoted arg/fragment
            currentArg ~= c;
        }
    }

    pushArg();

    return args[];
}
