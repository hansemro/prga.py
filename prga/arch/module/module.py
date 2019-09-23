# -*- encoding: ascii -*-
# Python 2 and 3 compatible
from __future__ import division, absolute_import, print_function
from prga.compatible import *

from prga.arch.module.common import ModuleClass
from prga.exception import PRGAInternalError
from prga.util import Abstract, ReadonlyMappingProxy

from abc import abstractproperty, abstractmethod

__all__ = ['AbstractModule']

# ----------------------------------------------------------------------------
# -- Abstract Module ---------------------------------------------------------
# ----------------------------------------------------------------------------
class AbstractModule(Abstract):
    """Abstract base class for modules."""

    # == internal API ========================================================
    def __str__(self):
        return self.name

    def _add_port(self, port):
        """Add a port to this module.

        Args:
            port (`AbstractPort`):

        Returns:
            `AbstractPort`: Echoing back the added port
        """
        if port.is_physical and not self.is_physical:
            raise PRGAInternalError("Cannot add a physical port '{}' to a non-physical module '{}'"
                    .format(port, self))
        elif port.parent is not self:
            raise PRGAInternalError("Module '{}' is not the parent module of port '{}'"
                    .format(self, port))
        elif port.key in self.all_ports:
            raise PRGAInternalError("Key '{}' for port '{}' already exists in module '{}'"
                    .format(port.key, port, self))
        return self.all_ports.setdefault(port.key, port)

    def _add_instance(self, instance):
        """Add an instance to this module.

        Args:
            instance (`AbstractInstance`):

        Returns:
            `AbstractInstance`: Echoing back the added instance
        """
        if instance.is_physical and not self.is_physical:
            raise PRGAInternalError("Cannot add a physical instance '{}' to a non-physical module '{}'"
                    .format(instance, self))
        elif instance.parent is not self:
            raise PRGAInternalError("Module '{}' is not the parent module of instance '{}'"
                    .format(self, instance))
        elif instance.key in self.all_instances:
            raise PRGAInternalError("Key '{}' for instance '{}' already exists in module '{}'"
                    .format(instance.key, instance, self))
        return self.all_instances.setdefault(instance.key, instance)

    # == low-level API =======================================================
    @property
    def physical_ports(self):
        """:obj:`Mapping` [:obj:`Hashable`, `AbstractPort` ]: A mapping from some hashable indices to physical ports
        in this module."""
        return ReadonlyMappingProxy(self.all_ports, lambda kv: kv[1].is_physical)

    @property
    def physical_instances(self):
        """:obj:`Mapping` [:obj:`Hashable`, `AbstractPort` ]: A mapping from some hashable indices to physical
        instances in this module."""
        return ReadonlyMappingProxy(self.all_instances, lambda kv: kv[1].is_physical)

    # -- properties/methods to be implemented/overriden by subclasses --------
    @abstractproperty
    def all_ports(self):
        """:obj:`MutableMapping` [:obj:`Hashable`, `AbstractPort` ]: A mapping from some hashable indices to ports in
        this module. Note that physical/logical/user ports are mixed together in this mapping."""
        raise NotImplementedError

    @abstractproperty
    def all_instances(self):
        """:obj:`MutableMapping` [:obj:`Hashable`, `AbstractInstance` ]: A mapping from some hashable indices to
        instances in this module. Note that physical/logical/user instances are mixed together in this mapping."""
        raise NotImplementedError

    @property
    def is_physical(self):
        """:obj:`bool`: Test if this module is physical."""
        return True

    @property
    def is_leaf_module(self):
        """:obj:`bool`: Test if this module is a leaf-level module."""
        return False

    @abstractproperty
    def name(self):
        """:obj:`str`: Name of this module."""
        raise NotImplementedError

    @abstractproperty
    def module_class(self):
        """`ModuleClass`: Logical class of this module."""
        raise NotImplementedError

    @property
    def verilog_template(self):
        """:obj:`str`: Template used for generating Verilog model of this module."""
        return 'module.tmpl.v'

    @abstractproperty
    def verilog_source(self):
        """:obj:`str`: Path to the source file generated for this module."""
        raise NotImplementedError

    # == high-level API ======================================================
    @property
    def ports(self):
        """:obj:`Mapping` [:obj:`Hashable`, `AbstractPort` ]: A mapping from some hashable indices to user-accessible
        ports."""
        return ReadonlyMappingProxy(self.all_ports, lambda kv: kv[1].is_user_accessible)

    @property
    def instances(self):
        """:obj:`Mapping` [:obj:`Hashable`, `AbstractInstance` ]: A mapping from some hashable indices to
        user-accessible instances."""
        return ReadonlyMappingProxy(self.all_instances, lambda kv: kv[1].is_user_accessible)

# ----------------------------------------------------------------------------
# -- Abstract Leaf Module ----------------------------------------------------
# ----------------------------------------------------------------------------
class AbstractLeafModule(AbstractModule):
    """Abstract base class for leaf modules."""

    # == internal API ========================================================
    def _elaborate(self):
        """Verify all the ``clock`` and ``combinational_sources`` attributes are valid."""
        for port in itervalues(self.ports):
            if port.is_clock:
                continue
            if port.clock is not None:
                clock = self.ports.get(port.clock, None)
                if clock is None:
                    raise PRGAInternalError("Clock '{}' of port '{}' not found in primitive '{}'"
                            .format(port.clock, port, self))
                elif not clock.is_clock:
                    raise PRGAInternalError("Clock '{}' of port '{}' in primitive '{}' is not a clock"
                            .format(clock, port, self))
            if port.direction.is_input:
                continue
            for source_name in port.combinational_sources:
                source = self.ports.get(source_name, None)
                if source is None:
                    raise PRGAInternalError("Combinational source '{}' of port '{}' not found in primitive '{}'"
                            .format(source_name, port, self))
                elif not source.direction.is_input:
                    raise PRGAInternalError("Combinational source '{}' of port '{}' in primitive '{}' is not an input"
                            .format(source_name, port, self))

    def _add_instance(self):
        raise PRGAInternalError("Cannot add instance to leaf module '{}'"
                .format(self))

    # == low-level API =======================================================
    # -- implementing properties/methods required by superclass --------------
    @property
    def is_leaf_module(self):
        return True

    @property
    def all_instances(self):
        return ReadonlyMappingProxy({})
