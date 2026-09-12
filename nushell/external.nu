#!/usr/bin/env nu

def "nu-complete cloudvmsctl" [context: string, offset: int] {
    # Get the command string up to the cursor's current position
    let prefix = ($context | str substring 0..$offset)
    
    # Split by spaces. If you type a trailing space, this creates an empty string at the end.
    # Cobra explicitly requires that empty string to know you are starting a new word.
    let words = ($prefix | split row ' ')
    let args = ($words | skip 1)
    
    # Call the binary. We wrap this in `complete` to safely catch any errors 
    # so a crashing binary doesn't break your terminal UI.
    let raw_output = (do -i { ^cloudvmsctl __complete ...$args } | complete | get stdout | lines)
    
    if ($raw_output | is-empty) {
        return []
    }
    
    # Drop the Cobra directive (the last line)
    let completions = ($raw_output | drop 1)
    
    # Parse the tab-separated outputs
    $completions | each { |line|
        let parts = ($line | split row "\t")
        if ($parts | length) > 1 {
            { value: $parts.0, description: $parts.1 }
        } else {
            { value: $parts.0 }
        }
    }
}

extern cloudvmsctl [
  ...args: string@"nu-complete cloudvmsctl"
]

extern log-viewer [
  file?: path,				# Which file to read from
  -s						# Read from stdin instead
  --known-source: string	# Read from a known special source (like CC through SSH)
  --id						# Enable ID translation
  --startup					# Highlight startup messages
  --session-file: path		# Use this session file
  --id-store (-i): path		# Use this ID-to-name store file
  --name (-n): string       # Name this session
  --no-scroll               # Enable/disable autoscroll in stdin mode (true by default)
  --help (-h)
]
