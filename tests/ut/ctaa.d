module tests.ut.ctaa;

import unit_threaded;
import reggae.ctaa;


@("Empty") unittest {
    auto aa = AssocList!(string, string)();
    aa.get("foo", "ohnoes").shouldEqual("ohnoes");
}

@("Conversion") unittest {
    auto aa = assocList([assocEntry("foo", "true")]);
    aa.get("foo", false).shouldBeTrue();
    aa.get("bar", false).shouldBeFalse();
    aa.get("bar", true).shouldBeTrue();
}

@("opIndex") unittest {
    static struct MyInt { int i; }
    auto aa = assocList([assocEntry("one", MyInt(1)), assocEntry("two", MyInt(2))]);
    aa["one"].shouldEqual(MyInt(1));
    aa["two"].shouldEqual(MyInt(2));
}


@("String to strings") unittest {
    auto aa = assocList([assocEntry("includes", ["-I$project/headers"]),
                         assocEntry("flags", ["-m64", "-fPIC", "-O3"])]);
    aa["flags"].shouldEqual(["-m64", "-fPIC", "-O3"]);
    string[] emp;
    aa.get("flags", emp).shouldEqual(["-m64", "-fPIC", "-O3"]);
}

@("keys") unittest {
    auto aa = assocListT("includes", ["-I$project/headers"],
                         "flags", ["-m64", "-fPIC", "-O3"]);
    aa.keys.shouldEqual(["includes", "flags"]);
}


@("in") unittest {
    auto aa = assocListT("foo", 3, "bar", 5);
    ("foo" in aa).shouldBeTrue;
    ("bar" in aa).shouldBeTrue;
    ("asda" in aa).shouldBeFalse;
}

@("Convert to runtime AA")
unittest {
    assocListT("foo", "bar", "toto", "baz").toAA.shouldEqual(
        ["foo": "bar", "toto": "baz"]);
    assocListT("foo", 3, "toto", 5).toAA.shouldEqual(
        ["foo": 3, "toto": 5]);

}

@("Convert from runtime AA")
unittest {
    fromAA(["foo": "bar"]).shouldEqual(assocListT("foo", "bar"));
    fromAA(["foo": 5]).shouldEqual(assocListT("foo", 5));
}
