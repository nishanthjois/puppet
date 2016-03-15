# == Class role::analytics_cluster::database::meta::backup_dest
#
class role::analytics_cluster::database::meta::backup_dest {
    file { [
            '/srv/backup',
            '/srv/backup/mysql',
            '/srv/backup/mysql/analytics-meta',
        ]:
        ensure => 'directory',
        owner  => 'root',
        group  => 'analytics-admins',
        mode   => '0750',
    }

    # This will allow $hosts_allow to host public data files
    # generated by the analytics cluster.
    # Note that this requires that cdh::hadoop::mount
    # be present and mounted at /mnt/hdfs
    rsync::server::module { 'backup':
        path        => '/srv/backup',
        read_only   => 'no',
        list        => 'no',
        # These are probably the same host, but in case they
        # aren't, allow either use of this rsync server module.
        hosts_allow => [
            hiera('cdh::hive::metastore_host'),
            hiera('cdh::oozie::oozie_host'),
        ],
    }
}
