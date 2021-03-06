# == Class: bird
#
# Installs Bird
#
# Only supports v4 Bird instance but can be extended to support v6 when the need arises.
# Installs its prometheus metrics exporter
#
# === Parameters
#
# [*neighbors*]
#   List of directly connected BGP neighbors (no-multihop)
#
# [*config_template*]
#   Specifiy which Bird config to use.
#   Only anycast exists for now, but it could be extended in the future.
#
# [*bfd*]
#   Enables BFD with the BGP peer (300ms*3)
#
# [*bind_service*]
#   Allows to bind the bird service to another service (watchdog-like)
#
# [*routerid*]
#   The router ID of the bird instance
#
#
class bird(
  $neighbors,
  $config_template,
  $bfd = true,
  Optional[String] $bind_service = undef,
  $routerid= $::ipaddress,
  ){

  ensure_packages(['bird', 'prometheus-bird-exporter'])

  if $bind_service != '' {
    exec { 'bird-systemd-reload-enable':
        command     => 'systemctl daemon-reload; systemctl enable bird.service',
        path        => [ '/usr/bin', '/bin', '/usr/sbin' ],
        refreshonly => true,
    }
    file { '/lib/systemd/system/bird.service':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('bird/bird.service.erb'),
        require => Package['bird'],
        notify  => Exec['bird-systemd-reload-enable'],
    }
  }

  service { 'bird':
      enable  => true,
      restart => 'service bird reload',
      require => Package['bird'],
  }

  service { 'bird6':
      ensure  => stopped,
      enable  => false,
      restart => 'service bird6 reload',
      require => Package['bird'],
  }

  file { '/etc/bird/bird.conf':
      ensure  => present,
      owner   => 'bird',
      group   => 'bird',
      mode    => '0640',
      content => template($config_template),
      notify  => Service['bird'],
  }

  service { 'prometheus-bird-exporter':
      ensure     => running,
      enable     => true,
      hasrestart => true,
      require    => Package['prometheus-bird-exporter'],
  }

  file { '/etc/default/prometheus-bird-exporter':
      ensure => present,
      owner  => 'root',
      group  => 'root',
      mode   => '0444',
      source => 'puppet:///modules/bird/prometheus-bird-exporter.default',
      notify => Service['prometheus-bird-exporter'],
  }

  nrpe::monitor_service { 'bird':
      ensure       => present,
      description  => 'Bird Internet Routing Daemon',
      nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:2 -C bird',
      notes_url    => 'https://wikitech.wikimedia.org/wiki/Anycast#Bird_daemon_not_running',
  }
}
