load("@bazel_skylib//lib:paths.bzl", "paths")
load("@common//sh:defs.bzl", "sh_inline_binary")

# --------------------------------------------------------------------
# Toolchain

# This defines a dummy compiler for illustration purposes.

_cc_compiler_template = """\
set -euo pipefail
# USAGE: compiler OUT PRELUDE MESSAGE
OUT="$$1"
PRE="$$2"
MSG="$${{@:3}}"
cat >&2 <<EOF
! CC compiler
! Running on {EXEC_CPU} {EXEC_OS}
! Targetting {TARGET_CPU} {TARGET_OS}
EOF
cat >"$$OUT" <<EOF
#!/usr/bin/env bash
set -euo pipefail
echo -n "$$PRE" >&2
cat >&2 <<PRE
! CC binary
! Compiled on {EXEC_CPU} {EXEC_OS}
! Running on {TARGET_CPU} {TARGET_OS}
PRE
echo "$$MSG"
EOF
chmod +x "$$OUT"
"""

def cc_compiler(
        name,
        exec_cpu,
        exec_os,
        target_cpu,
        target_os):
    sh_inline_binary(
        name = name,
        cmd = _cc_compiler_template.format(
            EXEC_CPU = exec_cpu,
            EXEC_OS = exec_os,
            TARGET_CPU = target_cpu,
            TARGET_OS = target_os,
        ),
    )

CcToolchainInfo = provider()

def _cc_toolchain_impl(ctx):
    toolchain_info = platform_common.ToolchainInfo(
        cc_info = CcToolchainInfo(compiler = ctx.attr.compiler),
    )
    return [toolchain_info]

cc_toolchain = rule(
    _cc_toolchain_impl,
    attrs = {
        "compiler": attr.label(
            executable = True,
            cfg = "host",
        ),
    },
)

# --------------------------------------------------------------------
# Rules

def _cc_binary_impl(ctx):
    cc_info = ctx.toolchains["//cc:toolchain_type"].cc_info
    cc_compiler = cc_info.compiler[DefaultInfo].files_to_run.executable
    (inputs, input_manifests) = ctx.resolve_tools(tools = [
        cc_info.compiler,
    ])

    executable = ctx.actions.declare_file("{}.sh".format(ctx.label.name))
    ctx.actions.run(
        outputs = [executable],
        inputs = inputs,
        input_manifests = input_manifests,
        executable = cc_compiler,
        arguments = [executable.path, "", ctx.attr.message],
        mnemonic = "CcCompile",
        progress_message = "Compiling Cc binary {}".format(executable.short_path),
    )

    return [DefaultInfo(
        executable = executable,
        files = depset(direct = [executable]),
    )]

cc_binary = rule(
    _cc_binary_impl,
    attrs = {
        "message": attr.string(),
    },
    executable = True,
    toolchains = ["//cc:toolchain_type"],
)
