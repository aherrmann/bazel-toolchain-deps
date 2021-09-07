# Toolchains Depending on Other Toolchains

Some compiler toolchains depend on other compiler toolchains. E.g. the Haskell
compiler GHC requires a C compiler and linker to build Haskell binaries.

In Bazel this can be expressed as a toolchain for the Haskell compiler and a
separate toolchain for the C compiler. However, one needs to take care to
express dependency between these toolchains correctly. Otherwise, Bazel will
resolve the wrong C toolchain in a cross compilation setup.

The correct setup is to have the final targets, i.e. the `haskell_binary` rule,
depend on both toolchains. *Not*, to have the Haskell toolchain depend on the C
toolchain.

This is illustrated in the following two examples:

## The Wrong Way

The example in `toolchain-on-toolchain` illustrates the wrong setup.

The following command asks Bazel to build `//:hs` on the current platform
(x86_64 Linux) targetting a different platform (ARM Linux).

```
$ bazel build //:hs --platforms //platform:linux_arm
...
! Haskell compiler
! Running on x86_64 linux
! Targetting arm linux
! Using CC bazel-out/host/bin/cc/cc_linux_x86_64
! CC compiler
! Running on x86_64 linux
! Targetting x86_64 linux
...
```

We can see that the Haskell compiler is resolved correctly. But, the C compiler
is not. The C compiler should run on x86_64 Linux but target ARM Linux.

The reason is that in this setup the Haskell toolchain itself depends on the C
toolchain. So, Bazel will not resolve the C toolchain targetting `//:hs`'s
target platform, but instead the platform which the Haskell toolchain is
supposed to *execute* on, in this case x86_64 Linux.

## The Correct Way

The example in `target-on-toolchain` illustrates the correct setup.

The following command asks Bazel to build `//:hs` on the current platform
(x86_64 Linux) targetting a different platform (ARM Linux).

```
$ bazel clean && bazel build //:hs --platforms //platform:linux_arm
...
! Haskell compiler
! Running on x86_64 linux
! Targetting arm linux
! Using CC bazel-out/host/bin/cc/cc_linux_x86_64_cross_arm
! CC compiler
! Running on x86_64 linux
! Targetting arm linux
...
```

We can see that the Haskell compiler is resolved correctly and the C compiler
as well. Both run on x86_64 Linux and target ARM Linux.

The reason is that in this setup it is the target, the `haskell_binary`
`//:hs`, that depends on both toolchains. So, Bazel will resolve both
toolchains to execute on the execution platform x86_64 Linux and to target the
target platform ARM Linux.
