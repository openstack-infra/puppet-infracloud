define infracloud::ssl_key(
  $key_content,
  $key_path = undef,
) {
  if $key_path == undef {
    $_key_path  = "/etc/${name}/ssl/private/${::fqdn}.pem"
  } else {
    $_key_path = $key_path
  }

  # If the user isn't providing an unexpected path, create the directory
  # structure.
  if $key_path == undef {
    file { "/etc/${name}/ssl":
      ensure => directory,
      owner  => $name,
      mode   => '0775',
    }
    file { "/etc/${name}/ssl/private":
      ensure  => directory,
      owner   => $name,
      mode    => '0755',
      require => File["/etc/${name}/ssl"],
      before  => File[$_key_path]
    }
  }

  file { $_key_path:
    ensure  => present,
    content => $key_content,
    owner   => $name,
    mode    => '0600',
  }
}
