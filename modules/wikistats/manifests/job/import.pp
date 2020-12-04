# a timer (job) to import a list of wikis into a wikistats table
define wikistats::job::import(
    String $weekday,
    String $project = $name,
    Integer $hour = 11,
    Integer $minute = 11,
    Wmflib::Ensure $ensure = 'present',
){

    systemd::timer::job { "wikistats-import-${name}":
        ensure            => $ensure,
        user              => 'wikistatsuser',
        description       => "import a fresh list of wikis into table ${name}",
        command           => "/usr/local/bin/wikistats/import_${project}.sh",
        logging_enabled   => true,
        logfile_basedir   => '/var/log/wikistats/',
        logfile_name      => "import-${project}.log",
        syslog_identifier => 'wikistats',
        interval          => {'start' => 'OnCalendar', 'interval' => "${weekday} *-*-* ${hour}:${minute}:00"},
    }
}
