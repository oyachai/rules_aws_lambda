load("@build_bazel_rules_nodejs//:providers.bzl", "DeclarationInfo", "JSModuleInfo")

def _remove_external_dir(path):
    if path.startswith("external/"):
        return "/".join(path.split("/")[3:])
    return path

def _remove_external_dir_node(path):
    if path.startswith("external/npm"):
        return "/".join(path.split("/")[2:])
    return path

def _remove_bazel_out_dir(path):
    if path.startswith("bazel-out/"):
        return "/".join(path.split("/")[3:])
    return path


def _py_lambda(ctx):
    binary = ctx.files.py_library

    zipper_args = ctx.actions.args()
    zipper_args.add("c", ctx.outputs.zip.path)

    runfiles = ctx.attr.py_library.default_runfiles.files.to_list()
    modules = {}
    for x in runfiles:
        if not x.path.startswith("external"):
            dirs = x.path.split("/")[:-1]
            current_dir = ""
            for directory in dirs:
                modules[current_dir + directory + "/"] = 1
                current_dir += directory + "/"
        zipper_args.add("{}={}".format(_remove_external_dir(x.path), x.path))

    # Add __init__.py files to all the non-external modules we've discovered
    for module in modules.keys():
        zipper_args.add("{}=".format(module + "__init__.py"))

    zipper_inputs = [x for x in binary]
    zipper_inputs += runfiles

    ctx.actions.run(
        inputs = zipper_inputs,
        outputs = [ctx.outputs.zip],
        executable = ctx.executable._zipper,
        arguments = [zipper_args],
        progress_message = "Creating zip...",
        mnemonic = "zipper",
    )
    return [DefaultInfo(files = depset([ctx.outputs.zip]))]


def _nodejs_lambda(ctx):
    binary = ctx.files.nodejs_library
    zipper_args = ctx.actions.args()
    zipper_args.add("c", ctx.outputs.zip.path)

    runfiles = ctx.attr.nodejs_library[JSModuleInfo].sources.to_list()
    runfiles += ctx.attr.nodejs_library[DeclarationInfo].transitive_declarations.to_list()
    modules = {}
    for x in runfiles:
        zip_path = _remove_external_dir_node(_remove_bazel_out_dir(x.path))
        if not x.is_source:
            zip_path = ctx.workspace_name + '/' + zip_path
        zipper_args.add("{}={}".format(zip_path, x.path))

    zipper_inputs = [x for x in binary]
    zipper_inputs += runfiles

    ctx.actions.run(
        inputs = zipper_inputs,
        outputs = [ctx.outputs.zip],
        executable = ctx.executable._zipper,
        arguments = [zipper_args],
        progress_message = "Creating zip...",
        mnemonic = "zipper",
    )
    return [DefaultInfo(files = depset([ctx.outputs.zip]))]


def _lambda_impl(ctx):
    if ctx.attr.py_library:
        return _py_lambda(ctx)
    elif ctx.attr.nodejs_library:
        return _nodejs_lambda(ctx)


aws_lambda_package = rule(
    attrs = {
        "py_library": attr.label(),
        "nodejs_library": attr.label(),
        "_zipper": attr.label(default = Label("@bazel_tools//tools/zip:zipper"), cfg = "host", executable=True),
    },
    outputs = {"zip": "%{name}.zip"},
    implementation = _lambda_impl,
)