# -*- encoding: ascii -*-
# Python 2 and 3 compatible
from __future__ import division, absolute_import, print_function
from prga.compatible import *

from ...core.common import NetClass, ModuleClass, ModuleView
from ...core.context import Context
from ...netlist.net.common import PortDirection
from ...netlist.net.util import NetUtils
from ...netlist.module.module import Module
from ...netlist.module.util import ModuleUtils
from ...passes.translation import AbstractSwitchDatabase
from ...util import Object

import os
from collections import OrderedDict

__all__ = ['Scanchain']

ADDITIONAL_TEMPLATE_SEARCH_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'templates')

# ----------------------------------------------------------------------------
# -- Switch Database ---------------------------------------------------------
# ----------------------------------------------------------------------------
class ScanchainSwitchDatabase(Object, AbstractSwitchDatabase):
    """Switch database for scanchain configuration circuitry."""

    __slots__ = ["context", "cfg_width"]
    def __init__(self, context, cfg_width):
        self.context = context
        self.cfg_width = cfg_width

    def get_switch(self, width, module = None):
        key = (ModuleClass.switch, width)
        try:
            return self.context.database[ModuleView.logical, key]
        except KeyError:
            pass
        try:
            cfg_bitcount = width.bit_length()
        except AttributeError:
            cfg_bitcount = len(bin(width).lstrip('-0b'))
        switch = Module('sw' + str(width), key = key, ports = OrderedDict(), allow_multisource = True,
                module_class = ModuleClass.switch, cfg_bitcount = cfg_bitcount)
        # switch inputs/outputs
        i = ModuleUtils.create_port(switch, 'i', width, PortDirection.input_, net_class = NetClass.switch)
        o = ModuleUtils.create_port(switch, 'o', 1, PortDirection.output, net_class = NetClass.switch)
        NetUtils.connect(i, o, fully = True)
        # configuration circuits
        cfg_clk = ModuleUtils.create_port(switch, 'cfg_clk', 1, PortDirection.input_,
                is_clock = True, net_class = NetClass.cfg)
        cfg_e = ModuleUtils.create_port(switch, 'cfg_e', 1, PortDirection.input_, net_class = NetClass.cfg)
        cfg_i = ModuleUtils.create_port(switch, 'cfg_i', self.cfg_width, PortDirection.input_,
                net_class = NetClass.cfg)
        cfg_o = ModuleUtils.create_port(switch, 'cfg_o', self.cfg_width, PortDirection.output,
                net_class = NetClass.cfg)
        return self.context.database.setdefault((ModuleView.logical, key), switch)

# ----------------------------------------------------------------------------
# -- Scanchain Configuration Circuitry Main Entry ----------------------------
# ----------------------------------------------------------------------------
class Scanchain(object):
    """Scanchain configuration circuitry entry point."""

    @classmethod
    def new_context(cls, cfg_width = 1):
        context = Context(cfg_width = cfg_width)
        context._switch_database = ScanchainSwitchDatabase(context, cfg_width)

        # register luts
        for i in range(2, 9):
            lut = Module('lut' + str(i),
                    ports = OrderedDict(),
                    allow_multisource = True,
                    module_class = ModuleClass.primitive)
            # user ports
            in_ = ModuleUtils.create_port(lut, 'in', i, PortDirection.input_, net_class = NetClass.primitive)
            out = ModuleUtils.create_port(lut, 'out', 1, PortDirection.output, net_class = NetClass.primitive)
            NetUtils.connect(in_, out, fully = True)

            # configuration ports
            cfg_clk = ModuleUtils.create_port(lut, 'cfg_clk', 1, PortDirection.input_,
                    is_clock = True, net_class = NetClass.cfg)
            cfg_e = ModuleUtils.create_port(lut, 'cfg_e', 1, PortDirection.input_, net_class = NetClass.cfg)
            cfg_i = ModuleUtils.create_port(lut, 'cfg_i', cfg_width, PortDirection.input_,
                    net_class = NetClass.cfg)
            cfg_o = ModuleUtils.create_port(lut, 'cfg_o', cfg_width, PortDirection.output,
                    net_class = NetClass.cfg)
            context._database[ModuleView.logical, lut.key] = lut

        # register flipflops
        while True:
            flipflop = Module('flipflop',
                    ports = OrderedDict(),
                    allow_multisource = True,
                    module_class = ModuleClass.primitive)
            ModuleUtils.create_port(flipflop, 'clk', 1, PortDirection.input_,
                    is_clock = True, net_class = NetClass.primitive)
            ModuleUtils.create_port(flipflop, 'D', 1, PortDirection.input_,
                    clock = 'clk', net_class = NetClass.primitive)
            ModuleUtils.create_port(flipflop, 'Q', 1, PortDirection.output,
                    clock = 'clk', net_class = NetClass.primitive)
            context._database[ModuleView.logical, flipflop.key] = flipflop
            break

        # register single-bit configuration filler
        while True:
            cfg_bit = Module('cfg_bit',
                    ports = OrderedDict(),
                    allow_multisource = True,
                    module_class = ModuleClass.config)
            cfg_clk = ModuleUtils.create_port(cfg_bit, 'cfg_clk', 1, PortDirection.input_,
                    is_clock = True, net_class = NetClass.cfg)
            cfg_e = ModuleUtils.create_port(cfg_bit, 'cfg_e', 1, PortDirection.input_,
                    net_class = NetClass.cfg)
            cfg_i = ModuleUtils.create_port(cfg_bit, 'cfg_i', cfg_width, PortDirection.input_,
                    net_class = NetClass.cfg)
            cfg_o = ModuleUtils.create_port(cfg_bit, 'cfg_o', cfg_width, PortDirection.output,
                    net_class = NetClass.cfg)
            cfg_d = ModuleUtils.create_port(cfg_bit, 'cfg_d', 1, PortDirection.output,
                    net_class = NetClass.cfg)
            break

        return context

    @classmethod
    def inject_
