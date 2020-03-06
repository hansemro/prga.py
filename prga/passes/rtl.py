# -*- encoding: ascii -*-
# Python 2 and 3 compatible
from __future__ import division, absolute_import, print_function
from prga.compatible import *

from .base import AbstractPass
from ..core.common import ModuleView
from ..util import Object

import os

__all__ = ['VerilogCollection']

# ----------------------------------------------------------------------------
# -- Verilog Collection ------------------------------------------------------
# ----------------------------------------------------------------------------
class VerilogCollection(Object, AbstractPass):
    """Collecting Verilog generation tasks."""

    __slots__ = ['renderer', 'output_dir', 'view', 'visited']
    def __init__(self, renderer, output_dir = ".", view = ModuleView.logical):
        self.renderer = renderer
        self.output_dir = output_dir
        self.view = view

    def _process_module(self, module):
        if module.key in self.visited:
            return
        self.visited.add(module.key)
        self.renderer.add_verilog(module, os.path.join(os.path.abspath(self.output_dir), module.name + ".v"),
                getattr(module, "verilog_template", "module.tmpl.v"))
        for instance in itervalues(module.instances):
            self._process_module(instance.model)

    @property
    def key(self):
        return "rtl.verilog"

    @property
    def dependences(self):
        if self.view.is_logical:
            return ("translation", )
        else:
            return ("translation", "materialization")

    @property
    def is_readonly_pass(self):
        return True

    def run(self, context):
        makedirs(os.path.abspath(self.output_dir))
        top = context.database[self.view, context.top.key]
        self.visited = set()
        self._process_module(top)
