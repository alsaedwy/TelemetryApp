from configparser import ConfigParser, MissingSectionHeaderError


def get_registered_extensions():
    return [".ini"]


def load(fd):
    parser = ConfigParser(dict_type=dict)
    try:
        parser.read_file(fd)
        return parser
    except MissingSectionHeaderError:
        parser.read_string("[dummy_section]\n" + fd.read())
        return parser["dummy_section"]
