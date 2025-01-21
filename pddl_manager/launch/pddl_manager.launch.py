#!/bin/env/python
import os

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.actions import OpaqueFunction
from launch.substitutions import LaunchConfiguration
from rclpy.logging import get_logger
from launch.actions import TimerAction, EmitEvent
from launch_ros.actions import LifecycleNode
from launch_ros.events.lifecycle import ChangeState
from lifecycle_msgs.msg import Transition

def launch_with_context(context, *args, **kwargs):
    bringup_dir = get_package_share_directory("pddl_manager")

    namespace = LaunchConfiguration("namespace")

    log_level = LaunchConfiguration("log_level")
    pddl_manager_node = LifecycleNode(
            package='pddl_manager',
            executable='pddl_manager.py',
            name='pddl_manager',
            namespace='',
            emulate_tty=True,
            output='screen',
        )
    return [pddl_manager_node,
    TimerAction(period=1.0, actions=[EmitEvent(event=ChangeState(
        lifecycle_node_matcher=lambda node: node == pddl_manager_node,
        transition_id=Transition.TRANSITION_CONFIGURE,
    ))]),
    TimerAction(period=2.0, actions=[EmitEvent(event=ChangeState(
        lifecycle_node_matcher=lambda node: node == pddl_manager_node,
        transition_id=Transition.TRANSITION_ACTIVATE,
    ))]),
            ]


def generate_launch_description():

    declare_log_level_ = DeclareLaunchArgument(
        "log_level",
        default_value="info",
        description="Logging level for cx_node executable",
    )

    declare_namespace_ = DeclareLaunchArgument("namespace", default_value="", description="Default namespace")

    # The lauchdescription to populate with defined CMDS
    ld = LaunchDescription()

    ld.add_action(declare_log_level_)

    ld.add_action(declare_namespace_)
    ld.add_action(OpaqueFunction(function=launch_with_context))

    return ld
