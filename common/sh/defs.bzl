def _sh_inline_impl(ctx):
    cmd = ctx.attr.cmd
    cmd = ctx.expand_location(cmd, ctx.attr.data)
    cmd = ctx.expand_make_variables("cmd", cmd, {})
    ctx.actions.expand_template(
        template = ctx.file._template,
        output = ctx.outputs.output,
        is_executable = True,
        substitutions = {
            "%cmd%": cmd,
        },
    )

    runfiles = ctx.runfiles(files = [ctx.outputs.output] + ctx.files.data)
    for data_dep in ctx.attr.data:
        runfiles = runfiles.merge(data_dep[DefaultInfo].default_runfiles)

    return DefaultInfo(
        files = depset([ctx.outputs.output]),
        runfiles = runfiles,
    )

_sh_inline = rule(
    _sh_inline_impl,
    attrs = {
        "cmd": attr.string(
            mandatory = True,
        ),
        "data": attr.label_list(
            allow_files = True,
        ),
        "output": attr.output(
            mandatory = True,
        ),
        "_template": attr.label(
            allow_single_file = True,
            default = "@common//sh:sh.tpl",
        ),
    },
)

def sh_inline_binary(
        name,
        cmd,
        data = [],
        toolchains = [],
        **kwargs):
    tags = kwargs.pop("tags", [])
    testonly = kwargs.pop("testonly", False)
    _sh_inline(
        name = name + "_script",
        cmd = cmd,
        output = name + ".sh",
        data = data,
        tags = tags,
        testonly = testonly,
        toolchains = toolchains,
    )
    native.sh_binary(
        name = name,
        data = data,
        deps = ["@bazel_tools//tools/bash/runfiles"],
        srcs = [name + ".sh"],
        tags = tags,
        testonly = testonly,
        **kwargs
    )
