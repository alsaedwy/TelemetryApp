""""
The main driver for configparse
"""

import argparse
import inspect
import os
import re
import warnings
from glob import iglob

from . import backends

HOME = os.path.expanduser("~")

BACKENDS = tuple(filter(inspect.ismodule, vars(backends).values()))
EXT_CACHE = {backend: backend.get_registered_extensions() for backend in BACKENDS}


def files_in(directory):
    for file in os.listdir(directory):
        file = os.path.join(directory, file)
        if os.path.isfile(file):
            yield file


def get_config_files(prog):
    # check for an OS-specific configuration directory
    if os.name == "nt":  # windows
        config_dir = os.getenv("AppData")
    else:
        config_dir = os.getenv("XDG_CONFIG_HOME")

    # assume it's ~/.config otherwise
    if config_dir is None:
        config_dir = os.path.join(HOME, ".config")

    # get all files with the format ~/.config/{prog}.*
    for entry in iglob("{}/{}.*".format(config_dir, prog)):
        yield entry

    # add the program directory
    config_dir = os.path.join(config_dir, prog)

    # return all the files in the config directory
    if os.path.isdir(config_dir):
        yield from files_in(config_dir)

    # get all files with the format ~/.{prog}*
    for entry in iglob("{}/.{}*".format(HOME, prog)):
        # if it's a directory, return all the files in it
        if os.path.isdir(entry):
            yield from files_in(entry)
        else:
            # otherwise, return the file itself
            yield entry


def try_parse(file, default_ext):
    _, ext = os.path.splitext(file)
    if ext == "":
        ext = default_ext
    for (backend, exts) in EXT_CACHE.items():
        if ext in exts:
            with open(file) as f:
                return backend.load(f)

    warnings.warn(
        "did not find a registered backend for {}. could there be a plugin that's not installed?".format(
            file
        )
    )
    return {}


class Parser(argparse.ArgumentParser):
    default_ext = ".json"

    def __init__(self, *args, prog=None, **kwargs):
        if prog is not None:
            prog = re.sub(r"\.py$", "", prog)
        if prog is None or prog == "":
            raise ValueError(
                "need to know the name of the program to know which config file to parse. call ConfigParser(prog='myprog') to remove this error"
            )
        super().__init__(*args, prog=prog, **kwargs)

    def set_default_ext(self, extension):
        if not extension.startswith("."):
            extension = "." + extension
        self.default_ext = extension

    def parse_known_args(self, args=None, namespace=None):
        config = {}
        for file in get_config_files(self.prog):
            for key, value in try_parse(file, self.default_ext).items():
                if not isinstance(value, str):
                    warnings.warn(
                        "types are not supported in configuration files, use strings instead"
                    )
                    value = str(value)
                config[key] = value, file

        new_args = []
        for key, (val, _) in config.items():
            new_args.append("--" + key)
            new_args.append(val)

        # override configuration with argparse's builtin parsing
        # makes CLI options take precedence over config files
        # HACK: make all these not required to avoid argparse exiting
        # HACK: if there are too few args
        # see https://stackoverflow.com/a/59105511/7669110
        temp_actions = []
        for action in self._actions:
            if action.required:
                action.required = False
                temp_actions.append(action)
        parsed_config, unknown = super().parse_known_args(new_args, namespace)
        for action in temp_actions:
            action.required = True

        for key in unknown[::2]:
            key = key[2:]
            _, filename = config[key]
            warnings.warn("unknown option '%s' (from %s)" % (key, filename))

        return super().parse_known_args(args, parsed_config)
