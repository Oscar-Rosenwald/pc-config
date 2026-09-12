#!/usr/bin/env nu

def escape_path [] {
  $in | str replace -a -r '([ \(\)\[\]\{\}\&])' '\$1'
}

def unescape_path [] {
  $in | str replace -a '\' ''
}

# TODO: THIS DOESN'T WORK AND I'VE GONE INSANCE.

# Returns the list of names of the parent+pathSoFar path which may end in a
# partial file name.
# 
# Exporting this because I'm certain other defs will use it as completion.
export def path_completion [parent: path, pathSoFar: path] {
  let pathSoFar = $pathSoFar | unescape_path

  let dirSoFar = if ($pathSoFar | str ends-with '/') or ($pathSoFar == "" ) {
	$pathSoFar
  } else {
    ($pathSoFar | path dirname) + '/'
  }

  let path = $parent | path join $pathSoFar
  mut dir = ($path | path dirname) + '/'
  mut next = $path | path basename

  if ($path | path type) == 'dir' {
	$dir = $path
	$next = ''
  }

  ls $dir -s
  | where {|x|
    $x.name
    | str downcase
    | str starts-with ($next | str downcase)
  }
  | update name { |x|
    $dirSoFar | path join ($x.name + if $x.type == dir {'/'} else {''}) | escape_path
  }
  | get name
}

def vaion_completion [context: string] {
  path_completion ($env.VAION_PATH + '/') ($context | split row ' ' | skip 1 | str join ' ')
}

def private_completion [context: string] {
  path_completion ($env.PRIVATE_DIR + '/') ($context | split row ' ' | skip 1 | str join ' ')
}

def home_completion [context: string] {
  path_completion (('~' | path expand) + '/') ($context | split row ' ' | get 1)
}

def --env enter_dir [parent: string, where?: string] {
  if $where == null {
	cd $parent
  } else {
    cd ($parent)/($where)
  }
}

export def --env enter_vaion [where?: string@vaion_completion] {
  enter_dir $env.VAION_PATH $where
}

export def --env enter_private [where?: string@private_completion] {
  enter_dir $env.PRIVATE_DIR $where 
}

export def --env enter_home [where?: string@home_completion] {
    enter_dir ~ $where
}
