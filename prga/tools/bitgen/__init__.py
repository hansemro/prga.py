# -*- encoding: ascii -*-

from ..util import create_argparser, docstring_from_argparser
import argparse

def def_argparser(name):
    parser = create_argparser(name,
            description="PRGA bitstream generator")

    parser.add_argument("-c", "--summary", metavar="summary",
            help="Pickled PRGA architecture context summary")
    parser.add_argument("-f", "--fasm", metavar="fasm",
            help="Raw FASM input")
    parser.add_argument("-o", "--output", metavar="output",
            help="Output file")
    parser.add_argument("--verif", action="store_true",
            help="Generate verification bitstream instead of raw bitstream")

    return parser

__doc__ = docstring_from_argparser(def_argparser(__name__))
__all__ = []