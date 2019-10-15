InnerInfo = provider(
    fields = ["execution", "target"],
)

def _inner_toolchain_impl(ctx):
    return [platform_common.ToolchainInfo(
        info = InnerInfo(
            execution = ctx.attr.execution,
            target = ctx.attr.target,
        ),
    )]

inner_toolchain = rule(
    _inner_toolchain_impl,
    attrs = {
        "execution": attr.string(),
        "target": attr.string(),
    },
)

OuterInfo = provider(
    fields = ["inner", "execution", "target"],
)

def _outer_toolchain_impl(ctx):
    return [platform_common.ToolchainInfo(
        info = OuterInfo(
            inner = ctx.toolchains["//:inner_toolchain_type"],
            execution = ctx.attr.execution,
            target = ctx.attr.target,
        ),
    )]

outer_toolchain = rule(
    _outer_toolchain_impl,
    attrs = {
        "execution": attr.string(),
        "target": attr.string(),
    },
    toolchains = ["//:inner_toolchain_type"],
)

def _consumer_impl(ctx):
    inner = ctx.toolchains["//:inner_toolchain_type"].info
    outer = ctx.toolchains["//:outer_toolchain_type"].info
    outer_inner = outer.inner.info
    print("""
inner:       {inner_execution} {inner_target}
outer:       {outer_execution} {outer_target}
outer_inner: {outer_inner_execution} {outer_inner_target}
""".format(
        inner_execution = inner.execution,
        inner_target = inner.target,
        outer_execution = outer.execution,
        outer_target = outer.target,
        outer_inner_execution = outer_inner.execution,
        outer_inner_target = outer_inner.target,
    ))
    return []

consumer = rule(
    _consumer_impl,
    toolchains = [
        "//:inner_toolchain_type",
        "//:outer_toolchain_type",
    ],
)
