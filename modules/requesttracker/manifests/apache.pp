# sets up Apache site for a WMF RT install
class requesttracker::apache($apache_site) {

    # avoid [warn] _default_ VirtualHost overlap
    file { '/etc/apache2/ports.conf':
        ensure => present,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/requesttracker/ports.conf.ssl',
    }
}

