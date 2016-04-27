class mirrors::serve {
    # HTTP
    include ::nginx

    letsencrypt::cert::integrated { 'mirrors':
        subjects   => 'mirrors.wikimedia.org,ubuntu.wikimedia.org',
        puppet_svc => 'nginx',
        system_svc => 'nginx',
    }

    require sslcert::dhparam
    $ssl_settings = ssl_ciphersuite('nginx', 'compat', '365')

    nginx::site { 'mirrors':
        content => template('mirrors/mirrors.wikimedia.org.conf.erb'),
    }

    file { '/srv/mirrors/index.html':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/mirrors/index.html',
    }
}
