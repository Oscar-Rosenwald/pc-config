#!/usr/bin/env nu

use std/util "path add"

path add /usr/bin
path add /usr/local/bin
path add /bin
path add /usr/sbin
path add /sbin
path add /snap/bin
path add $env.HOME + '/.cargo/bin'

let goBin = $env.HOME + '/go/bin/'
if ($goBin | path exists) { path add $goBin }

let localBin = $env.HOME + '/.local/bin/'
if ($localBin | path exists) { path add $localBin }

let voltaBin = $env.HOME + '/.volta/bin'
if ($voltaBin | path exists) { path add $voltaBin }

let bunBin = $env.HOME + '/.bun/bin'
if ($bunBin | path exists) { path add $bunBin }

let toolsetScripts = $env.VAION_PATH + '/../toolset/scripts'
if ($toolsetScripts | path exists ) { path add $toolsetScripts }

let postgresBin = '/usr/lib/postgresql/16/bin'
if ($postgresBin | path exists) { path add $postgresBin }

let vaionScripts = $env.VAION_PATH + '/scripts'
if ($vaionScripts | path exists) { path add $vaionScripts }

let logViewer = $env.HOME + '/log-viewer/target/release'
if ($logViewer | path exists) { path add $logViewer }