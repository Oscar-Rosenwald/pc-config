#!/usr/bin/env nu

export def xrandr [--machine (-m)] {
  let output = ^xrandr
  | jc --xrandr -pr
  | from json
  | get screens.devices.0
  | where is_connected
  | default NULL resolution_width
  | default NULL resolution_height
  | default NULL offset_width
  | default NULL offset_height
  | insert position { |row| parse position $row }
  | insert current_resolution { |row| parse resolution $row }
  | insert enabled { |row| $row.current_resolution != 'N/A' }
  | update resolution_modes { |row| to resolution $row }

  if $machine {
    $output
    | select device_name resolution_width resolution_height enabled offset_width offset_height resolution_modes
    | rename monitor resolution_width resolution_height enabled pos_x pos_y resolution_options
  } else {
	$output
    | select device_name current_resolution enabled position resolution_modes
    | rename monitor resolution enabled position resolution_options
  }
}

def "parse position" [row: record] {
  if $row.offset_width == NULL {
    $env.config.table.missing_value_symbol
  } else {
    $"($row.offset_width)x($row.offset_height)"
  }
}

def "parse resolution" [row: record] {
  if $row.resolution_width == NULL {
    $env.config.table.missing_value_symbol
  } else {
    $"($row.resolution_width)x($row.resolution_height)"
  }
}

def "to resolution" [row: record] {
  $row.resolution_modes
  | insert resolution { |r| parse resolution $r }
  | get resolution
}

# Completion function which offers the names of connected screens which aren't
# already in `context`.
def "connected screens" [context: string] {
  let chosen = $context
  | split row ' '
  | skip 2 # 2 wors for the calling function 'switch screen'

  xrandr
  | get monitor
  | where { |m| $m not-in $chosen }
  | append 'me'
}

# Enable screens at their preferred resolutions, ordered physically in the order
# as given. If no screens are given, enables ONE external monitor. "me" is the
# alias for the buitin laptop screen.
export def "switch screen" [...enabledScreens: string@"connected screens"] {
  mut enabledScreens = $enabledScreens | each { |screen|
    if ($screen == 'me') { 'eDP-1' } else { $screen }
  }

  let connectedScreens = xrandr --machine
  mut enabledCommand = []
  mut last_x_position = 0

  if (($enabledScreens | length) == 0) {
	$enabledScreens = $enabledScreens | append ($connectedScreens
    | where monitor != 'eDP-1'
    | first
    | get monitor)
  }

  for screenName in $enabledScreens {
	if ($screenName == 'eDP-1') {
	  let resolution = if $env.WORK_COMPUTER {
		'--mode 1920x1200'
	  } else {
		'--mode 1920x1080'
	  }

	  $enabledCommand = $enabledCommand | append $"--output eDP-1 ($resolution) --pos ($last_x_position)x0"
	  $last_x_position = $last_x_position + 1920
	  continue
	}

	let monitorDetails = $connectedScreens | where monitor == $screenName

	let resolution = $monitorDetails
    | select resolution_options
    | first
	| get resolution_options
	| first

	let width = $monitorDetails
	| select resolution_width
    | update resolution_width { |row|
	    if ($row.resolution_width == NULL) { 0 } else { $row.resolution_width }
    }
    | get 0.resolution_width

    $enabledCommand = $enabledCommand
    | append $"--output ($screenName) --mode ($resolution) --pos ($last_x_position)x0 "

	$last_x_position = $last_x_position + $width
  }

  # Needed because it used to be mutable and we use it in a closure
  let enabledScreens = $enabledScreens
  let disabledCommand = $connectedScreens
  | get monitor
  | where { |m| $m not-in $enabledScreens }
  | each { |disabledScreen| $"--output ($disabledScreen) --off" }

  let enabledCommand = $enabledCommand
  | split row ' '
  | where { $in != '' }

  let disabledCommand = $disabledCommand
  | split row ' '
  | where { $in != '' }

  ^xrandr ...$enabledCommand ...$disabledCommand --dpi 96
}