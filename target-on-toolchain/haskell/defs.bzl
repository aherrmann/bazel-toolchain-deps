load("@bazel_skylib//lib:paths.bzl", "paths")
load("@common//sh:defs.bzl", "sh_inline_binary")

# --------------------------------------------------------------------
# Toolchain

# This defines a dummy compiler for illustration purposes.

_haskell_compiler_template = """\
#!/usr/bin/env bash
set -euo pipefail
# USAGE: compiler CC OUT MESSAGE
CC="$$1"
OUT="$$2"
MSG="$${{@:3}}"
cat >&2 <<EOF
! Haskell compiler
! Running on {EXEC_CPU} {EXEC_OS}
! Targetting {TARGET_CPU} {TARGET_OS}
! Using CC $$CC
EOF
PRE="! Haskell binary
! Compiled on {EXEC_CPU} {EXEC_OS}
! Running on {TARGET_CPU} {TARGET_OS}
! Using CC $$CC
"
"$$CC" "$$OUT" "$$PRE" "$$MSG"
"""

def haskell_compiler(
        name,
        exec_cpu,
        exec_os,
        target_cpu,
        target_os):
    sh_inline_binary(
        name = name,
        cmd = _haskell_compiler_template.format(
            EXEC_CPU = exec_cpu,
            EXEC_OS = exec_os,
            TARGET_CPU = target_cpu,
            TARGET_OS = target_os,
        ),
    )

HaskellToolchainInfo = provider()

def _haskell_toolchain_impl(ctx):
    toolchain_info = platform_common.ToolchainInfo(
        haskell_info = HaskellToolchainInfo(compiler = ctx.attr.compiler),
    )
    return [toolchain_info]

haskell_toolchain = rule(
    _haskell_toolchain_impl,
    attrs = {
        "compiler": attr.label(
            executable = True,
            cfg = "host",
        ),
    },
)

# --------------------------------------------------------------------
# Rules

def _haskell_binary_impl(ctx):
    cc_info = ctx.toolchains["//cc:toolchain_type"].cc_info
    haskell_info = ctx.toolchains["//haskell:toolchain_type"].haskell_info
    cc_compiler = cc_info.compiler[DefaultInfo].files_to_run.executable
    haskell_compiler = haskell_info.compiler[DefaultInfo].files_to_run.executable
    (inputs, input_manifests) = ctx.resolve_tools(tools = [
        cc_info.compiler,
        haskell_info.compiler,
    ])

    executable = ctx.actions.declare_file("{}.sh".format(ctx.label.name))
    ctx.actions.run(
        outputs = [executable],
        inputs = inputs,
        input_manifests = input_manifests,
        executable = haskell_compiler,
        arguments = [
            cc_compiler.path,
            executable.path,
            ctx.attr.message,
        ],
        mnemonic = "HaskellCompile",
        progress_message = "Compiling Haskell binary {}".format(executable.short_path),
    )
    return [DefaultInfo(
        executable = executable,
        files = depset(direct = [executable]),
    )]

haskell_binary = rule(
    _haskell_binary_impl,
    attrs = {
        "message": attr.string(),
    },
    executable = True,
    toolchains = [
        "//cc:toolchain_type",
        "//haskell:toolchain_type",
    ],
)
