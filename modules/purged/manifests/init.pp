# == Class: purged
#
class purged (
    String $backend_addr,
    String $frontend_addr,
    Array[String] $mc_addrs,
    String $prometheus_addr,
    Integer $frontend_workers,
    Integer $backend_workers,
    Boolean $is_active,
    Optional[String] $host_regex                      = undef,
    # Kafka-related configurations
    Array[String] $kafka_topics                       = [],
    Array[String] $brokers                            = ['localhost:9092'],
    Stdlib::Absolutepath $stats_dir                   = '/var/cache/purged',
    Integer $stats_interval_ms                        = 60000,
    Stdlib::Absolutepath $kafka_conf_file             = '/etc/purged-kafka.conf',
    Enum['snappy', 'gzip', 'none'] $compression_codec = 'snappy',
    Optional[ATSkafka::TLS_settings] $tls             = undef,
) {
    package { 'purged':
        ensure => present,
    }

    $mcast_str = join($mc_addrs, ',')

    $ensure = $is_active? {
        true    => 'present',
        default => 'absent',
    }

    $enable_kafka = ($kafka_topics != [])
    if $enable_kafka {
        # We use the hostname as group id for now, as every purged
        # will consume the same messages
        $group_id = $::hostname
        file { $stats_dir:
            ensure => ensure_directory($ensure),
            mode   => '0755',
        }
        file { $kafka_conf_file:
            ensure  => $ensure,
            content => template('purged/purged-kafka.conf.erb'),
            mode    => '0444',
            notify  => Service['purged'],
        }
    }

    systemd::service { 'purged':
        ensure    => $ensure,
        content   => systemd_template('purged'),
        subscribe => Package['purged'],
        restart   => true,
    }
}
