from os.path import dirname, basename, isfile, join
from glob import glob
from importlib import import_module

modules = glob(join(dirname(__file__), "*.py"))
backends = map(
    lambda f: f[:-3],
    filter(lambda f: not f.startswith("_"), map(basename, filter(isfile, modules))),
)
__all__ = []
for module in backends:
    try:
        globals()[module] = import_module("." + module, __package__)
        __all__.append(module)
    except ImportError:
        print("failed to import " + module)
        pass
