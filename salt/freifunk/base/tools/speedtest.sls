{% from 'config.jinja' import apache_ddos_prevent, apache_speedtest %}

{# backend server for speedtest.ffdd #}
{% if apache_ddos_prevent == '0' and apache_speedtest == '1' %}
apache2_speedtest_enable:
  service:
    - running
    - name: apache2
    - enable: True
    - restart: True
    - watch:
      - file: /etc/apache2/sites-available/speedtest-backend.conf
      - apache2_site_enable_speedtest-backend
    - require:
      - pkg: apache2
      - file: /etc/apache2/sites-available/speedtest-backend.conf
      - apache2_site_enable_speedtest-backend

speedtest-backend_repo:
  git.latest:
    - name: https://github.com/Freifunk-Dresden/speedtest-backend.git
    - rev: master
    - target: /var/www_speedtest
    - update_head: True
    - force_fetch: True
    - force_reset: True
    - require:
      - pkg: git

{# Apache2 config #}
/etc/apache2/sites-available/speedtest-backend.conf:
  file.managed:
    - source: salt://tools/etc/apache2/sites-available/speedtest-backend.conf.tmpl
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: apache2

apache2_site_enable_speedtest-backend:
  apache_site.enabled:
    - name: speedtest-backend
    - require:
      - pkg: apache2
      - file: /etc/apache2/sites-available/speedtest-backend.conf
      - speedtest-backend_repo

{% else %}
apache2_speedtest_disable:
  service:
    - running
    - name: apache2
    - enable: True
    - restart: True
    - watch:
      - apache2_site_disable_speedtest-backend
    - require:
      - pkg: apache2
      - apache2_site_disable_speedtest-backend

apache2_site_disable_speedtest-backend:
  apache_site.disabled:
    - name: speedtest-backend
    - require:
      - pkg: apache2

{% endif %}
