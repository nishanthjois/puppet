# Kubernetes global configuration files.
# They include data that's useful to all deployed services.
#
class profile::kubernetes::deployment_server::global_config(
    Hash[String, String] $clusters = lookup('kubernetes_clusters'),
    Hash[String, Any] $general_values=lookup('profile::kubernetes::deployment_server::general', {'default_value' => {}}),
    $general_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
    Array[Profile::Service_listener] $service_listeners = lookup('profile::services_proxy::envoy::listeners', {'default_value' => []}),
    Array[Stdlib::Fqdn] $prometheus_nodes = lookup('prometheus_all_nodes'),
    Hash[String, Any] $kafka_clusters = lookup('kafka_clusters', {'default_value' => {}}),
) {
    # General directory holding all configurations managed by puppet
    # that are used in helmfiles
    file { $general_dir:
        ensure => directory
    }

    # directory holding private data for services
    # This is only writable by root, and readable by group wikidev
    $general_private_dir = "${general_dir}/private"
    file { $general_private_dir:
        ensure => directory,
        owner  => 'root',
        group  => 'wikidev',
        mode   => '0750'
    }

    # Global data defining the services proxy upstreams
    # Services proxy list of definitions to use by our helm charts.
    # They come from two hiera data structures:
    # - profile::services_proxy::envoy::listeners
    # - service::catalog
    $services_proxy = wmflib::service::fetch()
    $proxies = $service_listeners.map |$listener| {
        $address = $listener['upstream'] ? {
            undef   => "${listener['service']}.discovery.wmnet",
            default => $listener['upstream'],
        }
        $svc = $services_proxy[$listener['service']]
        $upstream_port = $svc['port']
        $encryption = $svc['encryption']
        $retval = {
            $listener['name'] => {
                'keepalive' => $listener['keepalive'],
                'port' => $listener['port'],
                'http_host' => $listener['http_host'],
                'timeout'   => $listener['timeout'],
                'retry_policy' => $listener['retry'],
                'xfp' => $listener['xfp'],
                'upstream' => {
                    'address' => $address,
                    'port' => $upstream_port,
                    'encryption' => $encryption,
                }
            }.filter |$key, $val| { $val =~ NotUndef }
        }
    }.reduce({}) |$mem, $val| { $mem.merge($val) }


    # We'll render Kafka cluster connection info into all general-*.yaml files.
    $kafka_cluster_names = keys($kafka_clusters)
    # Convert the list of Kafka cluster names into a hash of
    # kafka_cluster_name => {...} including settings we need for services to use Kafka.
    $kafka_clusters_info = $kafka_cluster_names.reduce({}) |$infos, $kafka_cluster_name| {
        $kafka_cluster_config = kafka_config($kafka_cluster_name)

        # Kafka clients should only need the list of Kafka brokers as a string to connect to Kafka.
        # e.g.
        #   kafka-main1001.eqiad.wmnet:9092,kafka-main1002.eqiad.wmnet:9092,... # for plaintext
        # or
        #   kafka-jumbo1001.eqiad.wmnet:9093,kafka-jumbo1003.eqiad.wmnet:9093,.... # for ssl
        $kafka_cluster_info = {
            'brokers_list' => {
                'plaintext' => $kafka_cluster_config['brokers']['string'],
                'ssl' => $kafka_cluster_config['brokers']['ssl_string'],
            }
        }
        $infos + { $kafka_cluster_name => $kafka_cluster_info }
    }

    # TODO: remove this
    file { '/etc/helmfile-defaults/service-proxy.yaml':
        ensure  => present,
        content => to_yaml({'services_proxy' => $proxies}),
    }

    # Per-cluster general defaults.
    $clusters.each |String $environment, $dc| {
        $puppet_ca_data = file($facts['puppet_config']['localcacert'])

        $filtered_prometheus_nodes = $prometheus_nodes.filter |$node| { "${dc}.wmnet" in $node }.map |$node| { ipresolve($node) }

        unless empty($filtered_prometheus_nodes) {
            $deployment_config_opts = {
                'tls' => {
                    'telemetry' => {
                        'prometheus_nodes' => $filtered_prometheus_nodes
                    }
                },
                'puppet_ca_crt' => $puppet_ca_data,
            }
        } else {
            $deployment_config_opts = {
                'puppet_ca_crt' => $puppet_ca_data
            }
        }
        # Merge default and environment specific general values with deployment config and service proxies
        $opts = deep_merge(
            $general_values['default'],
            $general_values[$environment],
            $deployment_config_opts,
            {'services_proxy' => $proxies},
            {'kafka_clusters' => $kafka_clusters_info },
        )
        file { "${general_dir}/general-${environment}.yaml":
            content => to_yaml($opts),
            mode    => '0444'
        }

    }

}
