# === Class puppet_compiler::packages
#
# Installs all the needed packages
class puppet_compiler::packages {

    $java_version = $facts['os']['release']['major'] ? {
        /10/    => '11',
        default => '8',
    }
    ensure_packages([
        'python-yaml', 'python-requests', 'python-jinja2', 'nginx',
        'ruby-httpclient', 'ruby-ldap', 'ruby-rgen', "openjdk-${java_version}-jdk"
        ])
    if debian::codename::eq('buster') {
        # Required to resolve PUP-8715
        ensure_packages('ruby-multi-json')
    }
    # Required to fix PUP-8187
    file {'/usr/lib/ruby/vendor_ruby/puppet/application/master.rb':
        ensure  => present,
        content => file('puppet_compiler/puppet_master_pup-8187.rb.nocheck'),
    }
}
