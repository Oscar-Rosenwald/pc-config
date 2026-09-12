#!/usr/bin/env nu

export def rem_ [] {
  let inputFiles = find files

  for file in $inputFiles {
	process file $file
	^goimports -w $file
	^gofumpt -w $file
  }

  if ($inputFiles | length) > 0 {
    ^bazel run //:gazelle
  }

  echoc "Done"
}

def "find files" [] {
  ^git grep --name-only -EI "(___|~~~)" -- go/
  | lines
  | where { |file| $file != "go/apps/vms_log_parser/vms_log_parser.go" }
}

def "process file" [file: path] {
  echoc $"Processing file ($file)"
  
  mut lines = (open $file | lines)
  mut newLines = []
  mut inBlock = false

  for line in $lines {
	if ($line | str contains '___{{') {
	  $inBlock = true
	  continue
	}

	if ($line | str contains '___}}') {
	  $inBlock = false
	  continue
	}

	if $inBlock {
	  continue
	}

	if ($line | str contains '___') {
	  continue
	}

	if ($line | str contains '~~~') {
	  $newLines = $newLines | append ($line | str replace --regex '^([ \t]*)// (.*)~~~$' '$1$2')
	} else {
	  $newLines = $newLines | append $line
	}
  }

  $newLines | str join (char newline) | save -f $file
}
