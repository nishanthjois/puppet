# == Class: cassandra::metrics
#
# Configure metrics reporting for cassandra
#
# === Usage
# class { '::cassandra::metrics':
#     graphite_host => 'graphite.duh',
# }
#
# === Parameters
# [*graphite_prefix*]
#   The metrics prefix to use
#
# [*graphite_host*]
#   What host to send metrics to
#
# [*graphite_port*]
#   What port to send metrics to
#
# [*blacklist*]
#   Array of strings, each is a regular expression of metric names to blacklist
#   (i.e. don't send to graphite)
#
# [*whitelist*]
#   Array of strings, each is a regular expression of metric names to whitelist
#   (i.e. send to graphite, even if matched by a blacklist entry)

class cassandra::metrics(
    Wmflib::Ensure  $ensure          = present,
    String          $graphite_prefix = "cassandra.${::hostname}",
    Stdlib::Host    $graphite_host   = 'localhost',
    Stdlib::Port    $graphite_port   = 2003,
    Optional[Array] $blacklist       = undef,
    Optional[Array] $whitelist       = undef,
) {

    $target_cassandra_version = $::cassandra::target_version

    $filter_file   = '/etc/cassandra-metrics-collector/filter.yaml'
    $collector_jar = '/usr/local/lib/cassandra-metrics-collector/cassandra-metrics-collector.jar'

    # Backward incompatible changes to cassandra-metrics-collector were needed
    # to support Cassandra 2.2 and 3.x; Use the apropos version of the collector.
    if $target_cassandra_version == '2.1' {
        $collector_version = '2.1.1-20160520.211019-1'
    } elsif $target_cassandra_version == '2.2' {
        $collector_version = '3.1.4-20170427.001104-1'
    } else {
        $collector_version = '4.1.0'
    }

    scap::target { 'cassandra/metrics-collector':
        deploy_user  => 'deploy-service',
        manage_user  => true,
        service_name => 'cassandra-metrics-collector',
    }

    $ensure_directory = $ensure ? {
        absent  => $ensure,
        default => 'directory',
    }

    $ensure_link = $ensure ? {
        absent  => $ensure,
        default => 'link',
    }

    file { '/etc/cassandra-metrics-collector':
        ensure => $ensure_directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { $filter_file:
        ensure  => $ensure,
        content => template("${module_name}/metrics-filter.yaml.erb"),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    file { '/usr/local/lib/cassandra-metrics-collector':
        ensure => $ensure_directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { $collector_jar:
        ensure  => $ensure_link,
        target  => "/srv/deployment/cassandra/metrics-collector/lib/cassandra-metrics-collector-${collector_version}-jar-with-dependencies.jar",
        require => Scap::Target['cassandra/metrics-collector'],
    }

    systemd::service { 'cassandra-metrics-collector':
        ensure  => $ensure,
        content => systemd_template('cassandra-metrics-collector'),
        restart => true,
        require => [
            File[$collector_jar],
            File[$filter_file],
        ],
    }

    base::service_auto_restart { 'cassandra-metrics-collector':
        ensure => $ensure,
    }

    # built-in cassandra metrics reporter, T104208
    file { '/usr/share/cassandra/lib/metrics-graphite.jar':
        ensure => absent,
    }

    file { '/etc/cassandra/metrics.yaml':
        ensure => absent,
    }
}
