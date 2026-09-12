#!/usr/bin/env nu

def echoc [...msg: string] {
  print $"(ansi red)($msg | str join ' ')(ansi reset)"
}

# Executes an external command with cpu and/or memory limits.
def --wrapped limit [
  -c: int             # Percentage of CPU quota.
  -m: string          # Memory specification, e.g. 100M
  command: string 	  # Command to run.
  ...args: string  	  # Args of the command
] {
  let cpuQuota = $c | default 50
  let memoryMax = $m | default 512M
  echoc $"--> Running in cgroup: CPU limited to ($cpuQuota)%, Memory limited to ($memoryMax)."
  run-external 'systemd-run' '--user' '--scope' '-p' $"CPUQuota=($cpuQuota)%" '-p' $"MemoryMax=($memoryMax)" $command ...$args
}

def small_chrome [] {
  job spawn {
    limit -m 4G -c 200 google-chrome-stable o+e>|ignore # ignore chrome output
  } | ignore # ignore 'job spawn' output
}

def small_vivaldi [] {
  job spawn {
    limit -m 4G -c 200 vivaldi o+e>|ignore # ignore vivaldi output
  } | ignore # ignore 'job spawn' output
}

# Send system notifications about the success or failure of the command.
def scream [command: closure, commandName: string] {
  let commandName = $commandName | default 'Command'

  try {
	do $command
  } catch { |e|
    print --stderr $e.msg
    $env.LAST_EXIT_CODE = 1
  }

  if $env.LAST_EXIT_CODE == 0 {
	^dunstify -a success $"($commandName) SUCCEEDED"
  } else {
	^dunstify -a failure $"($commandName) FAILED"
  }
}

def phones [] {
  scream { ^bluetoothctl connect 2C:27:9E:71:45:69 } Bluetooth
}

def fix_sinks [] {
  let sink = ^pactl list short sinks | ^grep sofhdadsp__sink | split column --regex \s+ --collapse-empty | get column1 | get 0
  ^pactl set-default-sink $sink | complete
}

# Limit the width of a column of some table
def limit-col [
    column: string    # The name of the column to target
    limit: int        # The maximum width
] {
    # $in represents the incoming table from the pipeline
    $in | update $column { |row|
        let text = ($row | get $column | into string)
        if ($text | str length) > $limit {
            ($text | str substring 0..($limit - 3)) + "..."
        } else {
            $text
        }
    }
}

# Like unzip, but tar. Fuck xzfv.
def untar [
  fromPath: string # the .tar or .tgz file to untar.
  targetPath?: string # where to untar the file into.
] {
  scream {
    if ($targetPath | is-not-empty) {
	  mkdir $targetPath
	}
  
    ^tar xzfv $fromPath -C ($targetPath | default './')
  } $"untarring + ($fromPath)"
}

def scroll-wheel [] {
  let mouseId = xinput list | grep "input-remapper Getech HUGE.*pointer" | split words | get 7
  xinput set-prop $mouseId "libinput Scroll Method Enabled" 0, 0, 1
  xinput set-prop $mouseId "libinput Button Scrolling Button" 1
}

def postgrestest [] {
  bazel run //go/vms/db:db_image
  cp go/vms/db/postgresql.conf /tmp/postgrestest.conf
  (
	^docker run
    --rm
    --network="host"
    --tmpfs /var/lib/postgresql/data:rw,noexec,nosuid,size=1G
    -v /tmp/postgrestest.conf:/etc/postgresql/postgresql.conf
    -e DB_PORT=5434
    -e POSTGRES_PASSWORD=pass
    -e NO_GRPC_SERVER=true
    --name postgrestest
    bazel/go/vms/db:db_image
  )
}

# Starts the nix VM.
#
# Username: william
# Password: pass
def nix [] {
  let kvm = '-enable-kvm'
  let cpu = 'host,-svm'
  let mem = '20G'
  let smp = '16'
  let bios = '/usr/share/ovmf/OVMF.fd'
  let file = 'file=/home/ncx843@ds.mot.com/vm/nixos/nixos.qcow2,format=qcow2,if=virtio'
  let screen = 'qxl-vga,vgamem_mb=256,xres=3440,yres=1440'
  let display = 'gtk,gl=on,show-cursor=on'
  let device = 'virtio-balloon'
  let nic = 'nic,model=virtio'
  let host = 'user,hostfwd=tcp::2222-:22'
  let virtio = 'virtio-serial'
  let intel = 'intel-hda'
  let hda = 'hda-duplex'
  let usb = 'usb-tablet'
  ^qemu-system-x86_64 $kvm -cpu $cpu -m $mem -smp $smp -bios $bios -drive $file -device $screen -display $display -device $device -net $nic -net $host -device $virtio -device $intel -device $hda -usb -device $usb
}

# Prints a certificate file in human-readable form
def "read cert" [pemFile: string] {
  ^openssl x509 -in $pemFile -text -noout
}