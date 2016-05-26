# == Class: mediawiki::firejail
#
# This Puppet class provides profile data for firejail, a sandbox to restrict
# an application environment. These profiles are used to contain the image
# scaling process (since imagemagick has a high risk security profile).
# It also provides a wrapper script to invoke imagemagick's convert via firejail.

class mediawiki::firejail {

    # This profile is used to contain the convert command of imagemagick
    file { '/etc/firejail/mediawiki-imagemagick.profile':
        source => 'puppet:///modules/mediawiki/mediawiki-imagemagick.profile',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    file { '/usr/local/bin/mediawiki-firejail-convert':
        source => 'puppet:///modules/mediawiki/mediawiki-firejail-convert',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
}
