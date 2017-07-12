# == Class: ptgbot
#
class ptgbot(
  $nick,
  $password,
  $channel,
  $vhost_name,
) {

  user { 'ptgbot':
    ensure     => present,
    home       => '/home/ptgbot',
    shell      => '/bin/bash',
    gid        => 'ptgbot',
    managehome => true,
    require    => Group['ptgbot'],
  }

  group { 'ptgbot':
    ensure => present,
  }

  vcsrepo { '/opt/ptgbot':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://git.openstack.org/openstack/ptgbot',
  }

  exec { 'install_ptgbot' :
    command     => 'pip3 install /opt/ptgbot',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/ptgbot'],
  }

  file { '/etc/init.d/ptgbot':
    ensure  => present,
    group   => 'root',
    mode    => '0555',
    owner   => 'root',
    require => Vcsrepo['/opt/ptgbot'],
    source  => 'puppet:///modules/ptgbot/ptgbot.init',
  }

  service { 'ptgbot':
    enable     => true,
    hasrestart => true,
    require    => File['/etc/init.d/ptgbot'],
    subscribe  => [
      Vcsrepo['/opt/ptgbot'],
      File['/etc/ptgbot/ptgbot_config.json'],
    ],
  }

  file { '/etc/ptgbot':
    ensure => directory,
  }

  file { '/var/log/ptgbot':
    ensure  => directory,
    owner   => 'ptgbot',
    group   => 'ptgbot',
    mode    => '0775',
    require => User['ptgbot'],
  }

  file { '/var/run/ptgbot':
    ensure  => directory,
    owner   => 'ptgbot',
    group   => 'ptgbot',
    mode    => '0775',
    require => User['ptgbot'],
  }

  file { '/var/lib/ptgbot':
    ensure  => directory,
    owner   => 'ptgbot',
    group   => 'ptgbot',
    mode    => '0775',
    require => User['ptgbot'],
  }

  file { '/var/lib/ptgbot/www':
    ensure  => directory,
    owner   => 'ptgbot',
    group   => 'ptgbot',
    mode    => '0775',
    require => [File['/var/lib/ptgbot'],
                User['ptgbot']]
  }

  file { '/var/lib/ptgbot/www/ptg.html':
    ensure    => present,
    group     => 'ptgbot',
    mode      => '0440',
    owner     => 'root',
    replace   => true,
    require   => [File['/var/lib/ptgbot/www'],
                  User['ptgbot']],
    source    => '/opt/ptgbot/html/ptg.html',
    subscribe => Vcsrepo['/opt/ptgbot'],
  }

  file { '/var/lib/ptgbot/www/ptg.js':
    ensure    => present,
    group     => 'ptgbot',
    mode      => '0440',
    owner     => 'root',
    replace   => true,
    require   => [File['/var/lib/ptgbot/www'],
                  User['ptgbot']],
    source    => '/opt/ptgbot/html/ptg.js',
    subscribe => Vcsrepo['/opt/ptgbot'],
  }

  file { '/etc/ptgbot/logging.config':
    ensure  => present,
    group   => 'ptgbot',
    mode    => '0440',
    owner   => 'root',
    replace => true,
    require => User['ptgbot'],
    source  => 'puppet:///modules/ptgbot/logging.config',
  }

  file { '/etc/ptgbot/ptgbot_config.json':
    ensure  => present,
    content => template('ptgbot/ptgbot_config.json.erb'),
    group   => 'ptgbot',
    mode    => '0440',
    owner   => 'root',
    replace => true,
    require => User['ptgbot'],
  }

  ::httpd::vhost { $vhost_name:
    port       => 80,
    docroot    => '/var/lib/ptgbot/www',
    priority   => '50',
    template   => 'ptgbot/vhost.erb',
    require    => File['/var/lib/ptgbot/www'],
    vhost_name => $vhost_name,
  }

}

# vim:sw=2:ts=2:expandtab:textwidth=79
