# Copyright (c) 2010-2023 IQGeo Group Plc. Use subject to conditions at $MYWORLD_HOME/Docs/legal.txt

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from myworldapp.core.server.startup.myw_routing_handler import MywRoutingHandler


def add_routes(config: "MywRoutingHandler") -> None:
    """
    Add REST API routes for this module
    """

    # config.add_route("/modules/custom/trace", "trace_controller", "index")

    pass
