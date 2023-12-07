#!/bin/python
import os
import subprocess
import argparse

import rclpy
from rclpy.node import Node

class RefboxNode(Node):
    def __init__(self):
        super().__init__('refbox_node')
        self.declare_parameters(
            namespace='',
            parameters=[
                ('terminal', 'gnome-terminal'),
                ('shell', 'bash'),
            ]
        )


    def get_terminal_command(self, terminal, shell, commands, tab_names=None):
        if terminal == 'tmux':
            term_command = f"{terminal} new-session -s refbox -d; {terminal} set-window-option -g remain-on-exit on"
            for i, cmd in enumerate(commands):
                tab_name = f"-n \"{tab_names[i]}\"" if tab_names else ""
                term_command += f"; {terminal} new-window {tab_name} '{shell} -i -c \"{cmd}\"'"
        else:  # Assuming gnome-terminal as the default
            term_command = f"{terminal} --tab"
            for i, cmd in enumerate(commands):
                tab_name = f"--title=\"{tab_names[i]}\"" if tab_names else ""
                term_command += f" --tab {tab_name} -e '{shell} -i -c \"{cmd}\"'"
        return term_command


def main():
    rclpy.init()
    node = RefboxNode()

    try:
        # Use the parameters in your script
        terminal = node.get_parameter('terminal').value
        shell = node.get_parameter('shell').value
        tab_names = ['refbox', 'refbox-frontend']
        print(terminal, shell)
        print(terminal, shell)
        print(terminal, shell)

        # Construct the terminal command using the parameters
        term_command = node.get_terminal_command(terminal, shell, tab_names)
        subprocess.run(term_command, shell=True)
        # Rest of your code...

    finally:
        node.destroy_node()
        rclpy.shutdown()

if __name__ == "__main__":
    main()

