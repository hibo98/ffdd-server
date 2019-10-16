{# Packages without needed Configuration #}
install_pkg:
  pkg.installed:
    - refresh: True
    - names:
      - dbus
      - lsb-release
      - dmidecode
      - irqbalance
      - cpufrequtils

      - htop
      - screen
      - tmux
      - rsync
      - most
      - nano
      - vim
      - less

      - gnupg
      - wget
      - curl
      - git

      - gawk
      - tar
      - bzip2
      - zip
      - unzip
      - gzip
      {# purge old kernels #}
      - byobu

      - net-tools
      - grepcidr
      - ethtool
      - psmisc
      - bridge-utils
      - tcpdump
      - lftp
      - iputils-ping
      - dnsutils
      - whois
      - ltrace
      - strace
      - mtr-tiny
      - bwm-ng
      - iptraf

      - python-apt
      - jq

{% if grains['os'] == 'Debian' %}
      - firmware-linux

{% elif grains['os'] == 'Ubuntu' %}
      - linux-firmware

      - software-properties-common
      - python-pycurl
{% endif %}
