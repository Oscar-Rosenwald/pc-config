module kubectl {
  def prod-namespace [] { 'clouddemo-vcloud-prod' }
  def beta-namespace [] { 'clouddemo-vcloud-beta' }
  def opp-namespace [] { 'clouddemo-vcloud-opp' }
  def latest-namespace [] { 'clouddemo-vcloud-latest' }

  def vmsComponents [] {
	[ mgmt db ui router authenticator streamer norm ]
  }

  def all-contexts [] {
	[
	  ao1
	  ho1
	  lf1
	  lf2
	  lf3
	  lf4
	  lf5
	  lf6
	  lf7
	  lf8
	  lf9
	  lf10
	  lf11
	  lf12
	  lf13
	  lf14
	  lf15
	  lf16
	  lf17
	  lf18
	  lf19
	  aw1
	  aw2
	  sw1
	]
  }

  def mgmt-extension [] { '-0' }
  def db-extension [] { '-db-0' }
  
  # Constructs a full namespace from the namespace suffix.
  def namespace [suffix: string] { $"clouddemo-vcloud-($suffix)" }

  def namespace-complete [] {
	[ 'prod' 'beta' 'opp' 'latest']
  }

  # Returns the name of the VMS pod corresponding to the VMS component.
  # Ensures there is only one such pod.
  def "generic pod name" [
	vmsName: string,
	component: string,
	context: string,
	namespaceSuffix: string,
  ] {
	let validComponent = (vmsComponents) | any { $in == $component }
	if not $validComponent {
	  error make $"Invalid component ($component)."
	}

	let podName = if $component == db {
	  db pod $vmsName --context $context --namespace-suffix $namespaceSuffix
	} else {
	  mgmt pod $vmsName --context $context --namespace-suffix $namespaceSuffix
	}

	assert one pod $podName

	return $podName
  }	

  # Retrieve the name of a pod given by the arguments.
  def "pod name" [
    vmsName: string, # Part of the name of the VMS.
    context: string,
    namespace: string, # Full namespace of the VMS.
    podExtension: string, # Either -0 or -db-0, to be appended to the three-word VMS serial.
  ] {
	validate $context $namespace

    let kubeOutput = (kubectl get ingress
      --context=$"($context)"
      --namespace=$"($namespace)"
      -o json
    )

    let podNames = $kubeOutput
      | from json
      | get items.metadata
      | where labels.domain-prefix =~ $vmsName
      | select name
      | update name { [ $in $podExtension ] | str join }

    if ($podNames | length) == 1 {
      $podNames | get 0.name
    } else {
      $podNames
    }
  }

  def "assert one pod" [ podNames: any ] {
	if ( $podNames | describe ) != 'string' {
	  error make $"Need only one pod, found ($podNames | length)"
	}
  }

  def validate [
	context: string,
	namespace: string,
  ] {
	let validNamespace = [ (prod-namespace) (beta-namespace) (opp-namespace) (latest-namespace) ] | any { $in == $namespace }
	if not $validNamespace {
	  error make $"Invalid namespace ($namespace)"
	}

	if not (all-contexts | any { $in == $context }) {
	  error make $"Invalid context ($context)"
	}
  }

  # Get the name of the MGMT pod of a VMS.
  export def "mgmt pod" [
	vmsName: string,  # Any substring of the VMS name.
	--context(-c): string@all-contexts, # Defaults to "aw1"
	--namespace-suffix(-n): string@namespace-complete, # Defaults to Prod
  ] {
	let context = if $context == null { "aw1" } else { $context }
	let namespace_suffix = if $namespace_suffix == null { "prod" } else { $namespace_suffix }
	pod name $vmsName $context (namespace $namespace_suffix) (mgmt-extension)
  }

  # Get the name of the DB pod of a VMS.
  export def "db pod" [
	vmsName: string,  # Any substring of the VMS name.
	--context(-c): string@all-contexts, # Defaults to "aw1"
	--namespace-suffix(-n): string@namespace-complete, # Defaults to Prod
  ] {
	let context = if $context == null { "aw1" } else { $context }
	let namespace_suffix = if $namespace_suffix == null { "prod" } else { $namespace_suffix }
	pod name $vmsName $context (namespace $namespace_suffix) (db-extension)
  }

  # Executes into a VMS's component.
  export def "kube exec" [
	vmsName: string, # Unique substring of the VMS name.
	component: string@vmsComponents, # One of the components of the VMS
	--context(-c): string@all-contexts, # Defaults to "aw1"
	--namespace-suffix(-n): string@namespace-complete, # Defaults to Prod
  ] {
	let context = if $context == null { "aw1" } else { $context }
	let namespace_suffix = if $namespace_suffix == null { "prod" } else { $namespace_suffix }
	let podName = generic pod name $vmsName $component $context $namespace_suffix

	let entrypoint = if ( [db ui mgmt] | any {$in == $component} ) {
	  'sh'
	} else {
	  'bash'
	}

	(
	  ^kubectl exec $"($podName)"
      --namespace $"(namespace $namespace_suffix)"
      --context $"($context)"
	  --container $"($component)"
	  -it
	  --
	  ($entrypoint)
	)
  }

  export def "vms version" [
	vmsName: string, # Unique substring of the VMS name.
	--context(-c): string@all-contexts, # Defaults to "aw1"
	--namespace-suffix(-n): string@namespace-complete, # Defaults to Prod
	--friendly(-f), # Print the friendly version instead of the SHA
	--only-manifest(-m), # Print the whole manifest instead of the version
  ] {
	let namespace_suffix = if $namespace_suffix == null { 'prod' } else { $namespace_suffix }
	let podName = mgmt pod $vmsName --namespace-suffix $namespace_suffix --context $context
	assert one pod $podName

	let manifest = (
	  kubectl get pod
      $"($podName)"
      --namespace $"clouddemo-vcloud-($namespace_suffix)"
      --context $"($context)"
      -o json
	)
    | from json
    | get spec.containers
    | where name == 'mgmt'
    | get 0.env
    | where name == 'VAION_MANIFEST'
    | get value.0
    | from json
	| get manifest

	if $only_manifest {
	  $manifest
	} else if $friendly {
	  $manifest | get version
	} else {
	  $manifest | get applicationSha
	}
  }

  # Logs into the database of the given VMS.
  export def "vms db" [
	vmsName: string, # Unique substring of the VMS name.
	--context(-c): string@all-contexts, # Defaults to "aw1"
	--namespace-suffix(-n): string@namespace-complete, # Defaults to Prod
  ] {
	let namespace_suffix = if $namespace_suffix == null { 'prod' } else { $namespace_suffix }
	let podName = db pod $vmsName --namespace-suffix $namespace_suffix --context $context
	assert one pod $podName
	
	(
	  kubectl exec $"($podName)"
	  --namespace $"(namespace $namespace_suffix)"
	  --context $"($context)"
	  --container db
	  -it
	  --
	  psql -U postgres -p 5432 -d vaionmgmt
	)
  }

  # Print logs from a VMS.
  export def "vms logs" [
	vmsName: string, # Unique substring of the VMS name.
	component: string@vmsComponents, # One of the components of the VMS
	--context(-c): string@all-contexts, # Defaults to "aw1"
	--namespace-suffix(-n): string@namespace-complete, # Defaults to Prod
	--tail(-t) = 100, # How many lines to print
	--no-follow(-f), # Inhibit following the logs
  ] {
	let context = if $context == null { "aw1" } else { $context }
	let namespace_suffix = if $namespace_suffix == null { "prod" } else { $namespace_suffix }
	let podName = generic pod name $vmsName $component $context $namespace_suffix
	
	if $no_follow {
	  (
		kubectl logs $"($podName)"
		--container $"($component)"
	    --namespace $"(namespace $namespace_suffix)"
	    --context $"($context)"
	    --tail $"($tail)"
	  )
	} else {
	  (
		kubectl logs $"($podName)"
		--container $"($component)"
	    --namespace $"(namespace $namespace_suffix)"
	    --context $"($context)"
	    --tail $"($tail)"
		-f
	  )
	}
  }
}

export use kubectl *