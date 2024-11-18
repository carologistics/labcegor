import os

from ament_index_python.packages import get_package_share_directory

from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, SetEnvironmentVariable
from launch.actions import OpaqueFunction
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node

pkg_name = "labcegor-bringup"

def launch_with_context(context, *args, **kwargs):
    labcegor_dir = get_package_share_directory(pkg_name)
    manager_config = LaunchConfiguration("manager_config")
    log_level = LaunchConfiguration('log_level')
    manager_config_file = os.path.join(labcegor_dir, "params", manager_config.perform(context)) 
    if not os.path.isfile(manager_config_file):
        logger = get_logger(pkg_name)
        logger.warning(f"Parameter file path is not a file: {manager_config_file}")
    cx_node = Node(
        package='cx_bringup',
        executable='cx_node',
        output='screen',
        emulate_tty=True,
        parameters=[
            manager_config_file,
        ],
        arguments=['--ros-args', '--log-level', log_level]
    )
    return [cx_node]

def generate_launch_description():
    declare_log_level_ = DeclareLaunchArgument(
        "log_level",
        default_value='info',
        description="Logging level for cx_node executable",
    )
    declare_manager_config = DeclareLaunchArgument(
        "manager_config",
        default_value="clips_env_manager.yaml",
        description="Name of the CLIPS environment manager configuration",
    )

    # The lauchdescription to populate with defined CMDS
    ld = LaunchDescription()

    ld.add_action(declare_log_level_)
    ld.add_action(declare_manager_config)
    ld.add_action(OpaqueFunction(function=launch_with_context))
   
    return ld
