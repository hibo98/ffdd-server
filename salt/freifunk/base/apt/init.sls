{# Package Management System #}
apt:
  pkg.installed:
    - refresh: True
    - names:
      - apt
      - ca-certificates
      - unattended-upgrades
{% if grains['os'] == 'Debian' and not grains['oscodename'] == 'buster' %}
      - apt-transport-https
{% endif %}


{# sources.list #}
{% if grains['os'] == 'Debian' and grains['oscodename'] == 'stretch' %}
/etc/apt/sources.list:
  file.managed:
    - contents: |
        ##### Debian Main Repos #####
        deb http://deb.debian.org/debian/ stretch main contrib non-free
        deb-src http://deb.debian.org/debian/ stretch main contrib non-free
        # stable-updates
        deb http://deb.debian.org/debian/ stretch-updates main contrib non-free
        deb-src http://deb.debian.org/debian/ stretch-updates main contrib non-free
        # security-updates
        deb http://deb.debian.org/debian-security stretch/updates main contrib non-free
        deb-src http://deb.debian.org/debian-security stretch/updates main contrib non-free
    - user: root
    - group: root
    - mode: 600

{% elif grains['os'] == 'Debian' and grains['oscodename'] == 'buster' %}
/etc/apt/sources.list:
  file.managed:
    - contents: |
        ##### Debian Main Repos #####
        deb http://deb.debian.org/debian/ buster main contrib non-free
        deb-src http://deb.debian.org/debian/ buster main contrib non-free
        # stable-updates
        deb http://deb.debian.org/debian/ buster-updates main contrib non-free
        deb-src http://deb.debian.org/debian/ buster-updates main contrib non-free
        # security-updates
        deb http://deb.debian.org/debian-security buster/updates main contrib non-free
        deb-src http://deb.debian.org/debian-security buster/updates main contrib non-free
    - user: root
    - group: root
    - mode: 600
{% endif %}

{# Configuration #}
/etc/apt/apt.conf.d/20auto-upgrades:
  file.managed:
    - source: salt://apt/etc/apt/apt.conf.d/20auto-upgrades
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: apt

/etc/apt/apt.conf.d/50unattended-upgrades:
  file.managed:
    - source: salt://apt/etc/apt/apt.conf.d/50unattended-upgrades
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: apt

{# automatic security upgrades #}
unattended-upgrades:
  service:
    - running
    - enable: True
    - watch:
      - file: /etc/apt/apt.conf.d/50unattended-upgrades
    - require:
      - pkg: apt
      - pkg: unattended-upgrades
      - file: /etc/apt/apt.conf.d/50unattended-upgrades

{# purge_old_kernels and update grub #}
/etc/cron.d/purge-old-kernels:
  file.managed:
    - contents: |
        ### This file managed by Salt, do not edit by hand! ###
        SHELL=/bin/sh
        PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
        MAILTO=""
        #
        23 5 * * *  root  /usr/bin/purge-old-kernels --keep 2 -qy ; update-grub2
    - user: root
    - group: root
    - mode: 600
    - require:
      - pkg: install_pkg
      - pkg: cron
