#!/usr/bin/env nu

# Returns the path to the file where an SSH session is made available by "ssh
# background" and used by "ssh use".
def "control path" [host: string] {
  return $"ControlPath /tmp/($host)"
}

# Returns the path to where the last_used_CC_IP is stored - used by 'get_last_used_CC_IP'.
def "last_used_CC_path" [] { return /tmp/ssh-background-last-CC }

# Returns the last setup/used IP for any of the custom SSH CC commands.
def "get_last_used_CC_IP" [] {
  let pathToCcIp = last_used_CC_path

  if not ($pathToCcIp | path exists) {
	error make $"No CC IP stored in ($pathToCcIp). Specify IP manually. Lazy bastard."
  }

  return (open $pathToCcIp | lines | first)
}

# Stores [ip] in the file returned by 'last_used_CC_path'.
def "update_last_used_CC_IP" [ip: string] {
  $ip | save --force (last_used_CC_path)
}

# Opens an SSH session in the background and allows other SSH sessions on the
# same host to re-use its authentication so you don't need to type in the
# password all the time.
#
# Use "ssh use" to take advantage of this session. Use "ssh stop" to stop this
# session.
export def "ssh background" [
  host: string,         # IP or address of the target host.
  --user(-u) = "admin", # User on the host.
] {
  let user = $user
  echoc $"--> ssh ($user)@($host) -fMN -o '(control path $host)'"

  (
    ^ssh $"($user)@($host)"     # Open SSH session
    -f                          # Put the session to the background
    -M                          # Open in master mode - other SSH session will use this connections and auth
	-N                          # Allows us not to run any command in master mode, only open the master session
    -o $"(control path $host)"  # Set where this session will be available to other sessions
  )

  update_last_used_CC_IP $host
}

# Reuse the SSH session opened in the background by calling "ssh background".
export def --wrapped "ssh use" [
  --host(-h): string,         # IP or address of the target host. Defaults to the last used one.
  --user(-u) = "admin", # User on the host.
  --help,
  ...rest,              # Command to run + its arguments
] {
  let host = if ($host == null) { get_last_used_CC_IP } else { $host }

  let controlPath = control path $host
  let user = $user
  let logFile = "/tmp/ssh-use-log"

  echoc $"--> ssh ($user)@($host) -o '($controlPath)' -t ($rest | str join ' ') e> ($logFile)"

  (
    ^ssh $"($user)@($host)"         # Open SSH session
      -o $"($controlPath)"          # Where this session has been made available by "ssh background"
      -t                            # Pass stdin to the remote
      ...$rest                      # Command to run on the session
  ) e> $logFile

  if (get_last_used_CC_IP) != $host {
	update_last_used_CC_IP $host
  }
}

# Stop the SSH session created by "ssh background".
export def "ssh stop" [
  host?: string, # IP or address of the target host. Defaults to the last used one.
] {
  let host = if ($host == null) { get_last_used_CC_IP } else { $host }

  (
    ^ssh $host
    -O stop                     # Send the 'stop' command to the SSH session
    -o $"(control path $host)"  # The file where the SSH session was made available by "ssh background"
  )
}