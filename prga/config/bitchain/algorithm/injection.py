# -*- encoding: ascii -*-
# Python 2 and 3 compatible
from __future__ import division, absolute_import, print_function
from prga.compatible import *

from prga.arch.net.port import ConfigClockPort, ConfigInputPort, ConfigOutputPort
from prga.arch.module.common import ModuleClass
from prga.arch.module.instance import RegularInstance
from prga.config.bitchain.design.primitive import ConfigBitchain
from prga.util import Abstract

from abc import abstractmethod

__all__ = ['ConfigBitchainLibraryDelegate', 'inject_config_chain']

# ----------------------------------------------------------------------------
# -- Configuration Bitchain Library Delegate ---------------------------------
# ----------------------------------------------------------------------------
class ConfigBitchainLibraryDelegate(Abstract):
    """Configuration bitchain library supplying configuration bitchain modules for instantiation."""

    # == low-level API =======================================================
    # -- properties/methods to be implemented/overriden by subclasses --------
    @abstractmethod
    def get_or_create_bitchain(self, width):
        """Get a configuration bitchain module.

        Args:
            width (:obj:`int`):
        """
        raise NotImplementedError

# ----------------------------------------------------------------------------
# -- Algorithms for Injecting Config Circuitry into Modules ------------------
# ----------------------------------------------------------------------------
def inject_config_chain(lib, module, top = True):
    """Inject configuration bitchain into ``module`` and its sub-modules.
    
    Args:
        lib (`ConfigBitchainLibraryDelegate`):
        module (`AbstractModule`): The module in which configuration circuitry is to be injected
        top (:obj:`bool`): If set, bitchain is instantiated and connected to other instances; otherwise, configuration
            ports are created and left to the module up in the hierarchy to connect
    """
    # Injection: Intermediate-level modules have cfg_i (serial configuration input port) exclusive-or cfg_d (parallel
    # configuration input port
    instances_requiring_serial_config_port = []
    parallel_config_sinks = []
    for instance in itervalues(module.logical_instances):
        if instance.module_class is ModuleClass.config:
            continue    # no configuration circuitry for config and extension module types
        if 'cfg_i' not in instance.logical_pins and 'cfg_d' not in instance.logical_pins:
            if instance.module_class not in (ModuleClass.primitive, ModuleClass.switch):
                inject_config_chain(lib, instance.model, False)
            else:
                continue
        if 'cfg_i' in instance.logical_pins:                    # check for serial ports
            # flush pending parallel ports
            for sink in parallel_config_sinks:
                bitchain = module._add_instance(RegularInstance(module,
                    lib.get_or_create_bitchain(len(sink)), 'cfg_chain_{}'.format(sink.parent.name)))
                sink.logical_source = bitchain.logical_pins['cfg_d']
                instances_requiring_serial_config_port.append(bitchain)
            parallel_config_sinks = []
            instances_requiring_serial_config_port.append(instance)
        elif 'cfg_d' in instance.logical_pins:                  # check for parallel ports
            parallel_config_sinks.append(instance.logical_pins['cfg_d'])
    if instances_requiring_serial_config_port or top:
        # flush pending parallel ports
        for sink in parallel_config_sinks:
            bitchain = module._add_instance(RegularInstance(module,
                lib.get_or_create_bitchain(len(sink)), 'cfg_chain_{}'.format(sink.parent.name)))
            sink.logical_source = bitchain.logical_pins['cfg_d']
            instances_requiring_serial_config_port.append(bitchain)
        if not instances_requiring_serial_config_port:
            return
        cfg_clk = module._add_port(ConfigClockPort(module, 'cfg_clk'))
        cfg_e = module._add_port(ConfigInputPort(module, 'cfg_e', 1))
        cfg_we = module._add_port(ConfigInputPort(module, 'cfg_we', 1))
        cfg_i = module._add_port(ConfigInputPort(module, 'cfg_i', 1))
        for instance in instances_requiring_serial_config_port:
            instance.logical_pins['cfg_clk'].logical_source = cfg_clk
            instance.logical_pins['cfg_e'].logical_source = cfg_e
            instance.logical_pins['cfg_we'].logical_source = cfg_we
            instance.logical_pins['cfg_i'].logical_source = cfg_i
            cfg_i = instance.logical_pins['cfg_o']
        module._add_port(ConfigOutputPort(module, 'cfg_o', 1)).logical_source = cfg_i
    elif parallel_config_sinks:
        cfg_pins = [bit for sink in parallel_config_sinks for bit in sink]
        cfg_d = module._add_port(ConfigInputPort(module, 'cfg_d', len(cfg_pins)))
        for source, sink in zip(cfg_d, cfg_pins):
            sink.logical_source = source
