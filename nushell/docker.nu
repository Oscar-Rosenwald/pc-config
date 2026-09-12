#!/usr/bin/env nu

def "docker ps" [--all (-a)] {
  let containers = if $all {
	^docker ps --all --format json
  } else {
	^docker ps --format json
  }

  $containers
  | from json --objects
  | select Names Status Ports Image Command
  | update Ports { split row -r ', ' }
  | update Image { str replace '/' $"/\n" --all }
}