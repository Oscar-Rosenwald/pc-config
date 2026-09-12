#!/usr/bin/env nu

# Returns the path to the file where an SSH session is made available by "ssh
# background" and used by "ssh use".
def "control path" [host: string] {
  return $"ControlPath /tmp/($host)"
}

# Opens an SSH session in the background and allows other SSH sessions on the
# same host to re-use its authentication so you don't need to type in the
# password all the time.
#
# Use "ssh use" to take advantage of this session. Use "ssh stop" to stop this
# session.
export def "ssh background" [
  host: string,         # IP or address of the target host.
  --user(-u): string,   # User on the host. Defaults to "admin".
] {
  let user = $user | default "admin"
  echoc $"--> ssh ($user)@($host) -fMN -o '(control path $host)'"

  (
    ^ssh $"($user)@($host)"     # Open SSH session
    -f                          # Put the session to the background
    -M                          # Open in master mode - other SSH session will use this connections and auth
	-N                          # Allows us not to run any command in master mode
    -o $"(control path $host)"  # Set where this session will be available to other sessions
  )
}

# Reuse the SSH session opened in the background by calling "ssh background".
export def --wrapped "ssh use" [
  host: string,         # IP or address of the target host.
  --user(-u): string,   # User on the host. Defaults to "admin".
  ...rest,              # Command to run
] {
  let controlPath = control path $host
  let user = $user | default "admin"

  echoc $"--> ssh ($user)@($host) -o '($controlPath)' -n ($rest | str join ' ')"

  (
    ^ssh $"($user)@($host)"         # Open SSH session
      -o $"($controlPath)"          # Where this session has been made available by "ssh background"
      -n                            # Don't accept any stdin input on this session
      ...$rest                      # Command to run on the session
  )
}

# Stop the SSH session created by "ssh background".
export def "ssh stop" [
  host: string, # IP or address of the target host.
] {
  (
    ^ssh $host
    -O stop                     # Send the 'stop' command to the SSH session
    -o $"(control path $host)"  # The file where the SSH session was made available by "ssh background"
  )
}