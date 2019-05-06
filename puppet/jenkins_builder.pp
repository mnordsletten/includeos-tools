# Build system
package { [ "cmake" , "make", "nasm", "libssl-dev" ] :
  ensure => present,
}

# Compilers
package { [ "clang-6.0", "gcc-7", "g++-multilib", "gcc-7-aarch64-linux-gnu", "c++-7-aarch64-linux-gnu" ] :
  ensure => present,
}
# Jenkins node deps
package { "openjdk-8-jre-headless" :
  ensure => present,
}
package { [ "python3-pip", "python3-setuptools", "python3-dev" ] :
  ensure => present,
}
$pip_packages = [ "conan" ]
package { $pip_packages :
  ensure => present,
  provider => pip3,
}
