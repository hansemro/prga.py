# -*- encoding: ascii -*-
# Python 2 and 3 compatible
from __future__ import division, absolute_import, print_function
from prga.compatible import *

from prga.rtlgen.rtlgen import VerilogGenerator
from prga.flow.flow import AbstractPass
from prga.flow.util import analyze_hierarchy
from prga.util import Object

import os

__all__ = ['GenerateVerilog']

# ----------------------------------------------------------------------------
# -- Generate Verilog --------------------------------------------------------
# ----------------------------------------------------------------------------
class GenerateVerilog(Object, AbstractPass):
    """Generate Verilog for all physical modules.
    
    Args:
        prefix (:obj:`str`): Prefix to the verilog files
    """

    __slots__ = ['prefix']
    def __init__(self, prefix = ''):
        self.prefix = prefix

    @property
    def key(self):
        """Key of this pass."""
        return "rtl.verilog"

    def run(self, context):
        makedirs(self.prefix)
        vgen = VerilogGenerator(context._additional_template_search_paths +
                context.config_circuitry_delegate.additional_template_search_paths)
        hierarchy = analyze_hierarchy(context)
        visited = set()
        queue = {context.top.name: context.top}
        while queue:
            name, module = queue.popitem()
            visited.add(name)
            f = module.verilog_source = os.path.abspath(os.path.join(self.prefix, name + '.v'))
            vgen.generate_module(open(f, OpenMode.w), module)
            for subname, sub in iteritems(hierarchy[name]):
                if subname in visited or subname in queue or not sub.in_physical_domain:
                    continue
                queue[subname] = sub
