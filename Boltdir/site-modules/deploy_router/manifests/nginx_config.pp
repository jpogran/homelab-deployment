# Configures NGINX
class deploy_router::nginx_config {
  class { 'nginx':
    stream => true,
  }

# Reverse HTTPS Proxy for Gitlab Server
  nginx::resource::server { 'gitlab_server' :
    ensure      => present,
    server_name => [
      $::gitlab_external_url,
    ],
    listen_port => 443,
    ssl         => true,
    ssl_cert    => "/etc/letsencrypt/live/${::gitlab_external_url}/fullchain.pem",
    ssl_key     => "/etc/letsencrypt/live/${::gitlab_external_url}/privkey.pem",
    proxy       => 'https://10.99.0.25',
  }

# Reverse TCP Proxy for Gitlab SSH
  nginx::resource::streamhost {'gitlab_ssh':
    ensure      => present,
    listen_ip   => '10.45.0.11',
    listen_port => $::gitlab_ssh_port,
    proxy       => 'gitlab_ssh_upstream'
  }

  nginx::resource::upstream {'gitlab_ssh_upstream':
    ensure  => present,
    context => 'stream',
    members => {
      "10.99.0.25:${::gitlab_ssh_port}" => {
        server => '10.99.0.25',
        port   => 22,
      },
    },
  }

# Reverse TCP Proxy for the K8s Control Plane
  nginx::resource::streamhost {'k8s_controlplane':
    ensure      => present,
    listen_ip   => '10.45.0.11',
    listen_port => 6443,
    proxy       => 'k8s_controlplane_upstream'
  }

  nginx::resource::upstream {'k8s_controlplane_upstream':
    ensure  => present,
    context => 'stream',
    members => {
      '10.99.0.20:6443' => {
        server => '10.99.0.20',
        port   => 6443,
      },
    },
  }

# Reverse TCP Proxy for the Gitlab Container Registry
  nginx::resource::upstream {'gitlab_registry_upstream':
    ensure  => present,
    context => 'stream',
    members => {
      "10.99.0.25:${::gitlab_registry_port}" => {
        server => '10.99.0.25',
        port   => $::gitlab_registry_port,
      },
    },
  }

  nginx::resource::streamhost {'gitlab_registry':
    ensure      => present,
    listen_ip   => '10.45.0.11',
    listen_port => $::gitlab_registry_port,
    proxy       => 'gitlab_registry_upstream'
  }

# Serve the NGINX directory for LetsEncrypt certs
  nginx::resource::server { '10.99.0.1':
    www_root  => '/opt/certs',
    listen_ip => '10.99.0.1',
  }

### EVERYTHING BELOW THIS LINE SHOULD BE FOR APPLICATIONS ONLY.
### THIS WILL BE BROKEN OUT INTO SEPARATE FILES LATER.
# Reverse HTTPS Proxy for Testing MetalLB with an NGINX container.
  nginx::resource::server { 'nginx_metallb_testing' :
    ensure      => present,
    server_name => [
      $::gitlab_external_url,
    ],
    listen_port => 8080,
    proxy       => 'http://10.99.0.150',
  }
}
