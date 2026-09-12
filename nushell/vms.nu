#!/usr/bin/env nu

def components [] { ['mgmt', 'db', 'router', 'access', 'ui', 'store', 'platform', 'authenticator', 'ana' ] }

def cluster_log [component?: string@components, node?: int, lines?: int] {
  let node = $node | default 1
  let lines = $lines | default 100
  let component = $component | default 'mgmt'
  let component = if $component == 'db' { 'postgres' } else { $component }

  try {
	^tail --retry -F -n $lines ~/cluster/($node)/($component).txt
  } catch { |e|
    $e | ignore
  }
}

def cluster_db [node?: int, --remote (-r)] {
  let node = $node | default 1
  mut port = 5432 + ($node - 1) * 4 | into int
  if $remote { $port = $port + 1 }

  try {
	^docker exec -it postgres_($node) psql -U postgres -d vaionmgmt -p $port
  } catch { |e|
    $e | ignore
  }
}