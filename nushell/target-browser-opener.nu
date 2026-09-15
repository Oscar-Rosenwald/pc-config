#!/usr/bin/env nu

def domainListFile [] { '~/.browser-domains' | path expand }

def matchesDomain [targetDomain: string, mustMatch: string] {
  $targetDomain =~ ^https?://($mustMatch).*
}

def main [targetDomain: string, ...rest: string] {
  if not ($targetDomain =~ ^https?://) {
	exit 1
  }

  let matches = open (domainListFile)
    | lines
    | any {|storedDomain| matchesDomain $targetDomain $storedDomain }

  if $matches {
	^google-chrome $targetDomain ...$rest
  } else {
	^vivaldi $targetDomain ...$rest
  }
}
