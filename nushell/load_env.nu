#!/usr/bin/env nu

$env.config.buffer_editor = ["emacsclient", "--create-frame", "-t"]
$env.config.table.mode = "thin"
$env.PRIVATE_DIR = $env.HOME + "/Private"
$env.WORK_COMPUTER = (ls /home/ | any { $in.name == '/home/ncx843' } )
$env.VAION_PATH = $env.HOME + '/go/src/repo.jazznetworks.com/vaion/vaion'
$env.GIT_PAGER = "bat"

if $env.WORK_COMPUTER {
  $env.VAION_XUSER = 'admin'
  $env.USE_GKE_GCLOUD_AUTH_PLUGIN = 'True'
  $env.HOST = 'ncx843@ds.mot.com'
  $env.GOPATH = $env.HOME + '/go'
  $env.JIRA_IN_COMMIT = 1 # Requires that all commits have a Jira associated with them.
  $env.DOCKER_API_VERSION = '1.44'

  # Used by the dev docker container in which I may or may not be building my
  # codez.
  $env.GITLAB_TOKEN = 'eW5qkDyA9TtT_iWzGmCbC286MQp1OjVjCA.01.0y1gfqyej'

  # Used to be $VAION_PATH/bazel-vaion/external/go_sdk/ on 8.1 and before.
  # To return to those times (or when you check out those versions):
  #  1. $> $env.GOROOT = $env.VAION_PATH + '/bazel-vaion/external/go_sdk/'
  #  2. $> emacs
  #  3. Profit
  $env.GOROOT = $env.VAION_PATH + "/bazel-vaion/external/rules_go~~go_sdk~main___download_0/"
} else {
  $env.GOROOT = '/usr/local/go'
  $env.GOPATH = $env.HOME + '/go'
  $env.GOBIN = $env.GOPATH + '/bin'
}
