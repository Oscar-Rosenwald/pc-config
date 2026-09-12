#!/usr/bin/env nu

# Run bazel tests.
#
# Filtering is done by either pasting the name of the filter or by a series of . and /
# Every '.' means "keep this part of the filter" and every '/' is a delimiter.
#
# First filter
#   sometest/inner/small
#
# Second filter
#   .       -> filter is "sometest"
#   ./.     -> filter is "sometest/inner"
#   ./other -> filter is "sometest/other"
#
# You are allowed to chain filters. Every new filter argument overrides the
# previous one. This includes the 'a' option which stands for 'all' and wipes
# all previous filters.
export def tests [
  testTarget: string # The path to the test. All versions are accepted.
  ...args: string    # runs (r), jobs (j), output (o), timeout (t), race (R), filter (f), no filter (a)
  --recursive (-r)   # Run all tests in given directory
  --help (-h)
] {
  cd $env.VAION_PATH

  let mainTest = parse race ...$args
  let args = $args | where {|x| $x != 'R'}

  let options = parse options ...$args
  let testTarget = ($testTarget | str trim --char '/')

  echoc $"runs: ($options.runsPerTest)"
  echoc $"jobs: ($options.jobs)"
  echoc $"output: ($options.output)"
  echoc $"timeout: ($options.timeoutSecs)s"
  echoc $"filter: ($options.filter)"

  with-env {
    TEST_TARGETS: (test target $testTarget $recursive),
    EXTRA_TEST_OPTIONS: ($"--test_filter=($options.filter) "
      + $"--runs_per_test=($options.runsPerTest) "
      + $"--jobs=($options.jobs) "
      + $"--test_output=($options.output) "
      + $"--test_timeout=($options.timeoutSecs) "
      + $"--test_env=POSTGRES_PORT=5432 "
      + $"--nocache_test_results"),
  } {
    scream { bash -c $"make ($mainTest)" e+o>| tee { save --force /tmp/testoutput } } tests
  }
}

def "test target" [target: string, recursive: bool] {
  let target = $target
  | str replace ":go_default_test" ''
  | str replace  '//' '/'
  | str trim --left -c '/'

  if $recursive {
    $"//($target)/..."
  } else {
    $"//($target):go_default_test"
  }
}

def "parse race" [...args: string] {
  if ( $args | any { |x| $x == 'R' } ) {
	'main_test_race'
  } else {
    'main_test'
  }
}

def "parse options" [...args: string] {
  mut runsPerTest = 1
  mut jobs = '1'
  mut output = 'errors'
  mut timeoutSecs = 90
  mut filters = []
  
  for window in ($args | window 2 --stride 1) {
	let first = $window.0
	let second = $window.1

	if ($first == 'r') { $runsPerTest = $second; continue }
	if ($first == 'j') { $jobs = $second; continue }
	if ($first == 'o') { $output = $second; continue }
	if ($first == 't') { $timeoutSecs = $second; continue }

	if ($first != 'f') {
	  if ($second == 'a') { $filters = []; continue }
	  continue
	}

	let newFilter = $second | split row /
	if (($newFilter | get 0) != '.') {
	  $filters = $newFilter
	  continue
	}

    let keepFilterParentCount = $newFilter | where $it == '.' | length
	let newParts = $newFilter | skip $keepFilterParentCount
	$filters = $filters | first $keepFilterParentCount | append $newParts
  }

  let filter = $filters | str join '/'

  return {
    runsPerTest: $runsPerTest,
    jobs: $jobs,
    output: $output,
    timeoutSecs: $timeoutSecs,
    filter: $filter,
  }
}