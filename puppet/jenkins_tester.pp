# Import all build dependencies from other script
import 'jenkins_builder.pp'

# Test system dependencies
package { [ "qemu-system", "lcov" ] :
  ensure => present,
}

# Test tools
package { [ "arping", "httperf", "hping3", "iperf3", "dnsmasq", "dosfstools", "grub2", "xorriso" ] :
        ensure => present,
}

$pip_packages = [ "wheel", "jsonschema", "psutil", "ws4py" ]
package { $pip_packages :
  ensure => present,
  provider => pip3,
}

service { 'dnsmasq' :
        ensure => running,
        require => Package['dnsmasq'],
}

# This requires the bridge to be configured
exec { "modify-dnsmasq" :
        path => "/opt/puppetlabs/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin",
        command => 'echo "interface=bridge43 \ndhcp-range=10.0.0.2,10.0.0.200,12h\nport=0" >> /etc/dnsmasq.conf',
        unless => 'grep -q bridge43 /etc/dnsmasq.conf',
        notify => Service['dnsmasq'],
}
