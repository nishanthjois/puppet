# sets up additional Tor instances
# needs Tor >= 0.2.7.4-rc-1
define tor::instance(
    Stdlib::Host $address,
    String $nickname,
    String $contact,
    Stdlib::Port $controlport,
    String $controlpassword,
    Stdlib::Port $orport,
    Stdlib::Port $dirport,
    String $exit_policy,
    Array[String] $fingerprints,
) {

    if $name == 'default' {
        fail('The default name is reserved for /etc/tor/torrc')
    }

    $config = "/etc/tor/instances/${name}/torrc"

    exec { "tor-instance-${name}":
        command => "/usr/sbin/tor-instance-create ${name}",
        creates => $config,
        require => Package['tor'],
        before  => File[$config],
    }

    $family = join($fingerprints, ',')

    file { $config:
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('tor/torrc.erb'),
        require => Package['tor'],
    }

    File[$config] ~> Exec['tor-systemd-reload'] ~> Service['tor']
}
