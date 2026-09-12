#!/usr/bin/env nu

def branch_path [] { '~/Private/cache/branches.csv' | path expand }

def statuses [] {
  [free active pipeline long-term]
}

def parse_branches [] {
  branch_path
  | open -r
  | from csv --flexible --noheaders
  | rename branch status task
  | default "" task
}

def list_branches [] {
  parse_branches | get branch | append me
}

export def "current branch" [] {
  ^git rev-parse --abbrev-ref HEAD
}

export def b [
  branch?: string@list_branches
  --table (-t)
] {
  let table = if ($branch != null) { true } else { $table }
  let currentBranch = current branch

  let branchTable = parse_branches
  | update branch {|row|
    if $table {
	  return $row.branch
	}
  
    if $row.branch == $currentBranch {
      $"(ansi red)($row.branch)(ansi reset)"
    } else {
      $row.branch
    }
  }
  | update status {|x|
    if $table {
	  return $x.status
	}
  
	let status = $x.status
	let colour = if $status == 'free' {
	  'green'
	} else if $status == 'active' {
	  'red'
	} else if $status == 'pipeline' {
	  'yellow'
	} else {
	  'blue'
	}

	$"(ansi $colour)($status)(ansi reset)"
  }

  if $branch != null {
    let branch = if $branch == this { $currentBranch } else { $branch }
	$branchTable | where branch == $branch
  } else {
    $branchTable
  }
}

# Update details about a branch. Branch can be "me". Task is optional.
export def "b update" [
  branch: string@list_branches
  status: string@statuses
  --task (-t): string
] {
  let branch = if $branch == me { current branch } else { $branch }

  parse_branches
  | update status { |row|
    if $row.branch == $branch {
      $status
    } else {
      $row.status
    }
  }
  | update task { |row|
    if $task == null {
	  return $row.task
	}

    if $row.branch != $branch {
	  return $row.task
	}

    $task
  }
  | to csv --noheaders
  | collect
  | save (branch_path) --force

  b $branch
}

export def "b del" [branch: string@list_branches] {
  b update $branch free -t ""
}

export def "git branch" [] {
  ^git branch
  | lines
  | split column --regex " +" checked_out branch_name
  | update branch_name { |row|
	if $row.checked_out == "*" {
	$"(ansi red_bold)($row.branch_name)(ansi reset)"
	} else {
	$row.branch_name
	}
  }
  | reject checked_out
}

# Commit git changes and optionally push to the remote.
export def "commit today" [
  message?: string  # Overrides default commit message
  --all (-a)        # All all unstaged files first 
  --keep (-k)       # Make the commit but don't push
] {
  if $all { git add . }

  let commitMessage = if $message == null {
	let now = date now | format date "%d.%m. %Y, %H:%M"
	if $env.WORK_COMPUTER { 'WORK: ' + $now } else { 'HOME: ' + $now }
  } else { $message }

  git commit -m $"($commitMessage)"
  if $keep == false { git push }
}

export def gl [
  --table (-t) # For programmatical use, keep at table. Otherwise displays as a more human-readable string
] {
  git log --oneline --decorate -n 10
  | lines
  | parse -r '^(?P<hash>\w+)\s+(?:\((?P<branch>.*?)\)\s+)?(?P<message>.*)$'
  | upsert branch {|row| 
    $row.branch
    | default "" 
    | split row ", " 
    | each { str replace -r '.* -> ' '' }
	| each { |x|
	  if ($x | str starts-with 'origin/') {
		$"(ansi blue)($x)(ansi reset)"
	  } else if ($x | str starts-with 'tag: ') {
		$"(ansi green)($x | str replace -r '^tag: ' '')(ansi reset)"
	  } else {
        $"(ansi white)($x)(ansi reset)"
	  }
	}
    | where ($it | is-not-empty)
	| str join (char nl)
  }
  | update hash { |row| $"(ansi yellow_bold)($row.hash)(ansi reset)" }
  | update message { |row| $"(ansi cyan)($row.message)(ansi reset)" }
  | enumerate
  | flatten
}

export def git_push [
  --simple (-s) # Push without any options
  --force (-f)  # Use --force instead of --force-with-lease
] {
  let currentBranch = current branch
  let newBranch = $currentBranch | str replace -r '^cs_' '' | str replace -r '-' '_'

  if $simple {
    ^git push origin $"($currentBranch):cs_($newBranch)"
  } else if $force {
    ^git push --force origin $"($currentBranch):cs_($newBranch)"
  } else {
    ^git push --force-with-lease origin $"($currentBranch):cs_($newBranch)"
  }

  if $env.LAST_EXIT_CODE != 0 {
	^dunstify -a failure "Git push FAILED"
	return
  }

  ^dunstify -a success "Git push SUCCESS"

  if (b --table | any { $in.branch == $currentBranch }) == false {
	# This means the current branch isn't in the branch list. That's okay.
    return
  }

  let currentStatus = b --table | where branch == $currentBranch | get status
  if ($currentStatus | is-empty) {
	error make $"no status on branch '$currentBranch'"
  }

  if $currentStatus == 'active' {
	b update $currentBranch 'pipeline'
  } else if $currentStatus == 'free' {
	b update $currentBranch 'pipeline' --task (input "What is the new task: ")
  }
}

# Prints the files which contain a merge conflict.
export def flict [] {
  ^git diff --check
    | lines
    | str replace --regex '^([^:]+)(:.*)' '$1'
    | uniq
}

# Commit current changes and push them to the remote.
export def "jj today" [
  message?: string # Optional message (default to current time)
] {
  let commitMessage = if $message == null {
	let now = date now | format date "%d.%m. %Y, %H:%M"
	if $env.WORK_COMPUTER { 'WORK: ' + $now } else { 'HOME: ' + $now }
  } else {
    $message
  }

  jj desc -m $"($commitMessage)"
  jj bookmark advance master
  jj git push -b master
}

export def "jj push" [
  bookmarkName?: string # Optional name of the bookmark to push
] {
  let bookmarkName = if $bookmarkName == null {
	# We'll assume this is what the user wants because nothing else makes much
	# sense, does it?
	jj bookmark advance

	let branchNames = (jj log
      -r @
      --template 'bookmarks.join("\n")'
      --no-graph
      --no-pager )
      | lines

	if ($branchNames | length) != 1 {
	  error make $"Found ($branchNames | length) bookmarks, wanted 1: ($branchNames | str join ', ')"
	}

	$branchNames | first
  } else {
    $bookmarkName
  }

  jj git push --bookmark $bookmarkName
}