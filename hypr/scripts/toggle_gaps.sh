# #!/bin/bash
#
# echo "$(date) - Running script" >> /tmp/hyprland_debug.log
#
# # Get current gap value
# current_gap=$(hyprctl hyprland_get gaps)
# echo "$(date) - Current gap: $current_gap" >> /tmp/hyprland_debug.log
#
# # Get current corner rounding value
# current_rounding=$(hyprctl hyprland_get border_radius)
# echo "$(date) - Current border radius: $current_rounding" >> /tmp/hyprland_debug.log
#
# # Toggle gaps and corner rounding
# if [[ "$current_gap" == "0" ]]; then
#     hyprctl hyprland_set gaps 20
#     echo "$(date) - Gaps set to 20" >> /tmp/hyprland_debug.log
# else
#     hyprctl hyprland_set gaps 0
#     echo "$(date) - Gaps set to 0" >> /tmp/hyprland_debug.log
# fi
#
# if [[ "$current_rounding" == "0" ]]; then
#     hyprctl hyprland_set border_radius 10
#     echo "$(date) - Border radius set to 10" >> /tmp/hyprland_debug.log
# else
#     hyprctl hyprland_set border_radius 0
#     echo "$(date) - Border radius set to 0" >> /tmp/hyprland_debug.log
# fi











#!/usr/bin/env bash

# Full path for hyprctl
HYPRCTL=$(which hyprctl)

# Ensure hyprctl is available
if [ -z "$HYPRCTL" ]; then
    echo "Error: hyprctl not found. Please ensure it's installed and in your PATH."
    exit 1
fi

# Get the current gap and rounding values using hyprctl
current_gap_in=$($HYPRCTL -j getoption general:gaps_in | jq '.int')
current_gap_out=$($HYPRCTL -j getoption general:gaps_out | jq '.int')
current_rounding=$($HYPRCTL -j getoption decoration:rounding | jq '.int')

# Function to set gaps to 0 and rounding to 0
set_no_gaps() {
    echo "Setting gaps to 0 and border rounding to 0"
    $HYPRCTL keyword general:gaps_in 0
    $HYPRCTL keyword general:gaps_out 0
    $HYPRCTL keyword decoration:rounding 0
}

# Function to set gaps to a default value and rounding to 10 (or whatever you want)
set_default_gaps() {
    echo "Setting gaps to default (in: 4, out: 10) and border rounding to 10"
    $HYPRCTL keyword general:gaps_in 4
    $HYPRCTL keyword general:gaps_out 10
    $HYPRCTL keyword decoration:rounding 10
}

# Check if gaps are currently 0; if so, set them to default values, else set them to 0
if [[ "$current_gap_in" -eq 0 && "$current_gap_out" -eq 0 && "$current_rounding" -eq 0 ]]; then
    set_default_gaps
else
    set_no_gaps
fi

