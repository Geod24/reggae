module tests.it.runtime.error_messages;

import reggae.reggae;
import unit_threaded;
import tests.it.runtime;

@("Non-existent directory error message") unittest {
    ReggaeSandbox().runReggae(["-b", "binary"], "/non/existent").shouldThrowWithMessage(
        "Could not find /non/existent/reggaefile.d"
    );
}

@("Non-existent build description error message") unittest {
    import reggae.path: buildPath;

    with(immutable ReggaeSandbox()) {
        writeFile("foo.txt");
        runReggae("-b", "binary").shouldThrowWithMessage(
            "Could not find " ~ buildPath(testPath, "reggaefile.d"));
    }
}


@("Too many languages") unittest {
    with(immutable ReggaeSandbox()) {
        writeFile("reggaefile.d");
        writeFile("reggaefile.py");

        runReggae("-b", "binary").shouldThrowWithMessage(
            "Reggae builds may only use one language. Found: D, Python"
            );

        writeFile("reggaefile.rb");
        runReggae("-b", "binary").shouldThrowWithMessage(
            "Reggae builds may only use one language. Found: D, Python, Ruby"
            );

        writeFile("reggaefile.js");
        runReggae("-b", "binary").shouldThrowWithMessage(
            "Reggae builds may only use one language. Found: D, Python, Ruby, JavaScript"
            );

        writeFile("reggaefile.lua");
        runReggae("-b", "binary").shouldThrowWithMessage(
            "Reggae builds may only use one language. Found: D, Python, Ruby, JavaScript, Lua"
            );
    }
}
