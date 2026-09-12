#!/usr/bin/env nu

def get_http [endpoint: string, port?: int] {
  http get http://localhost:($port | default 8080)/api/v1/($endpoint)
}

def post_http [endpoint: string, data: string, port?: int] {
  http post http://localhost:($port | default 8080)/api/v1/($endpoint) data
}

def "get db port" [node: int, replica: bool] {
  let port = 5432 + ($node - 1) * 4
  if $replica {
    $port + 1
  } else {
	$port
  }
}

# Retrieve the list of disks from node's database.
export def "list disks" [
  node: int       # Node to query
  --replica (-r)  # Read from the replica's database
] {
  let container = $"postgres_($node)"
  let port = (get db port $node $replica)
  let sql = "SELECT * FROM disks WHERE serial ~ '^[0-9]+$' ORDER BY serial DESC"

  ^docker ...[
    exec $container
    psql -U postgres -d vaionmgmt -p $port
    -c sql
  ]
  | from ssv
}

# Checks that both given nodes (defaults are 3 and 4) contain the same disks in
# their replica databases.
export def "check disks in nodes" [...nodes: int] {
  let nodeOne = $nodes | get -o 0 | default 3
  let nodeTwo = $nodes | get -o 1 | default 4

  let nodeOneDisks = list disks $nodeOne --replica | length
  let nodeTwoDisks = list disks $nodeTwo --replica | length

  if $nodeOneDisks != $nodeTwoDisks {
	error make {
      msg: $"Bad! Node ($nodeOne) has '($nodeOneDisks)'; node ($nodeTwo) has '($nodeTwoDisks)'"
	}
  }

  print $"Matching last disk '($nodeOneDisks)' on both ($nodeOne) and ($nodeTwo)"
}

# Insert a new disks into node's local database. By default inserts a disk with
# a serial 1 higher than the last one.
export def "insert node" [node: int, disk?: string] {
  let diskSerial = 1 + if ($disk != null) { $disk } else {
    list disks $node
    | first
    | get -o serial
    | default '0'
    | into int
  }

  let container = $"postgres_($node)"
  let port = (get db port $node false)
  let sql = "INSERT INTO disk (serial, name, size, present, node_id) VALUES ("
    + $"'($diskSerial)', '($diskSerial)', 1, true, "
    + "(SELECT id FROM site_nodes WHERE master != true LIMIT 1));"

  ^docker ...[
    exec $container
    psql -U postgres -d vaionmgmt -p $port
    -c $sql
  ]

  print $"Inserted disk with serial ($diskSerial)"
}

export def "find db file" [node: int, file: string, parentDir?: path] {
  let parentDir = $parentDir | default '/var/lib/postgresql/data/'

  ^docker ...[
    exec $"postgres_($node)"
    bash -c $"ls -1 ($parentDir)($file)"
  ]
  | lines
  | any { |x| $x | str contains $file }
}

export def "ha running" [] {
  2..4
  | each { |x|
      let running = find db file $x ha_enabled
      let remote = find db file $x remote
      let slave = find db file $x standby.signal /var/lib/postgresql/data/remote/pg16
  
      if not $running {
        print $"(ansi red)Node ($x) not running HA(ansi reset)"
	    return
	  }
  
      if not $remote {
        print $"Node ($x) is a (ansi blue)MASTER(ansi reset)"
	    return
	  }
  
      if $slave {
        print $"Node ($x) is a (ansi green)SLAVE(ansi reset)"
	    return
	  }
  
      print $"Node ($x) is (ansi yellow)WITHOUT QUORUM(ansi reset)"
    }
}