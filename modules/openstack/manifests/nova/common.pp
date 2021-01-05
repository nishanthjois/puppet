class openstack::nova::common(
    $version,
    $region,
    $db_user,
    $db_pass,
    $db_host,
    $db_name,
    $db_name_api,
    $openstack_controllers,
    $keystone_api_fqdn,
    $scheduler_filters,
    $ldap_user_pass,
    $rabbit_user,
    $rabbit_pass,
    $metadata_proxy_shared_secret,
    $compute_workers,
    $metadata_workers,
    Stdlib::Port $metadata_listen_port,
    Stdlib::Port $osapi_compute_listen_port,
    String       $dhcp_domain,
    ) {

    class { "openstack::nova::common::${version}::${::lsbdistcodename}": }

    # For some reason the Mitaka nova-common package installs
    #  a logrotate rule for nova/*.log and also a nova/nova-manage.log.
    #  This is redundant and makes log-rotate unhappy.
    # Not to mention, nova-manage.log is very low traffic and doesn't
    #  really need to be rotated anyway.
    file { '/etc/logrotate.d/nova-manage':
        ensure  => 'absent',
        require => Package['nova-common'],
    }

    file { '/etc/nova/policy.json':
        ensure => absent,
    }

    # vendor data needs to be in json format. vendordata.txt
    #  contains all of our cloud-init settings and firstboot script;
    #  jamming it all into one giant json field seems to work.
    $vendordata_file_contents = file('openstack/nova/vendordata.txt')
    $vendor_data = {
        'domain'     => $dhcp_domain,
        'cloud-init' => $vendordata_file_contents,
    }

    file { '/etc/nova/policy.yaml':
        source  => "puppet:///modules/openstack/${version}/nova/common/policy.yaml",
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        require => Package['nova-common'],
    }

    file {
        '/etc/nova/nova.conf':
            content   => template("openstack/${version}/nova/common/nova.conf.erb"),
            owner     => 'nova',
            group     => 'nogroup',
            mode      => '0440',
            show_diff => false,
            require   => Package['nova-common'];
        '/etc/nova/vendor_data.json':
            content => to_json_pretty($vendor_data),
            owner   => 'nova',
            group   => 'nogroup',
            mode    => '0444',
            require => Package['nova-common'];
    }

    if debian::codename::ge('buster') {
        # The Buster version of the Rocky packages creates the nova user
        #  with a weird high-number uid.  Try to head it off by creating here
        #  ahead of time.
        group { 'nova':
            ensure => 'present',
            name   => 'nova',
            system => true,
        }

        user { 'nova':
            ensure     => 'present',
            name       => 'nova',
            comment    => 'nova system user',
            gid        => 'nova',
            managehome => true,
            before     => Package['nova-common'],
            system     => true,
        }
    }


}
