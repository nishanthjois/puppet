# = Class: role::alerting_host
#
# Sets up a full production alerting host, including
# an icinga instance, tcpircbot, and certspotter
#
# = Parameters
#
class role::alerting_host {

    system::role{ 'alerting_host':
        description => 'central host for health checking and alerting'
    }

    include ::profile::standard
    include ::profile::base::firewall

    include ::profile::icinga
    include ::profile::tcpircbot
    include ::profile::certspotter
    include ::profile::scap::dsh

    include ::profile::dns::auth::monitoring::global
    include ::profile::mariadb::backup::check

    # Temporary until all hosts are on Buster
    # https://phabricator.wikimedia.org/T247966
    if os_version('debian >= buster') {
        include ::profile::alertmanager
        include ::profile::alertmanager::irc
    }

    class { '::httpd::mpm':
        mpm => 'prefork'
    }

    class { '::httpd':
        modules => ['headers', 'rewrite', 'authnz_ldap', 'authn_file', 'cgi', 'ssl'],
    }
}
