# xpr-build

`xpr-build` is the RC8 prototype for controlled K1OM source builds. It takes
an unpacked source-accounted XPR K1OM Toolkit, sets explicit target tools,
sysroot, build/host tuples, and an isolated pkg-config view, then runs a
normal configure/make/install flow.

It is deliberately not a package manager or dependency resolver. The first
validation target is a small external-style source project, followed by zlib.

```bash
tools/xpr-build/xpr-build env --toolkit /path/to/xpr-k1om-toolkit
tools/xpr-build/xpr-build configure --toolkit /path/to/xpr-k1om-toolkit \
  --source /path/to/source --build build/package
tools/xpr-build/xpr-build make --toolkit /path/to/xpr-k1om-toolkit --build build/package
tools/xpr-build/xpr-build stage --toolkit /path/to/xpr-k1om-toolkit --build build/package \
  --destdir stage/package
```

Use `inspect` on produced target executables before card transfer. Packages
and recipes are introduced only after the level-0 build proves this interface.
