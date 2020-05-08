{# uci - config management helper #}
uci_repo:
  git.latest:
    - name: https://git.openwrt.org/project/uci.git
    - rev: ec8d3233948603485e1b97384113fac9f1bab5d6
    - target: /opt/uci
    - update_head: True
    - force_fetch: True
    - force_reset: True
    - require:
      - pkg: git

libubox_repo:
  git.latest:
    - name: https://github.com/xfguo/libubox.git
    - rev: 0d399543c8618b5030fe73d1d335602ff75c563d
    - target: /opt/libubox
    - update_head: True
    - force_fetch: True
    - force_reset: True
    - require:
      - pkg: git


libubox_make:
  cmd.run:
    - name: |
        cd /opt/libubox
        mkdir build ; cd build ; cmake .. ; make ubox
        mkdir -p /usr/local/include/libubox
        cp ../*.h /usr/local/include/libubox
        cp libubox.so /usr/local/lib
        ldconfig
    - require:
      - pkg: devel
      - libubox_repo
    - onchanges:
      - pkg: devel
      - libubox_repo

uci_make:
  cmd.run:
    - name: |
        cd /opt/uci
        cmake [-D BUILD_LUA:BOOL=OFF] . ; make uci cli
        mkdir -p /usr/local/include/uci
        cp uci.h uci_config.h /usr/local/include/uci
        cp uci_blob.h ucimap.h /usr/local/include/uci
        cp libuci.so /usr/local/lib
        cp uci /usr/local/bin
        ldconfig
    - require:
      - pkg: devel
      - uci_repo
      - libubox_repo
    - onchanges:
      - pkg: devel
      - uci_repo
      - libubox_repo

{# config #}
/etc/config/ffdd:
  file.managed:
    - source: salt://uci/etc/config/ffdd
    - makedirs: true
    - user: root
    - group: root
    - mode: 644
    - replace: false

{# sample config (default) #}
/etc/config/ffdd_sample:
  file.managed:
    - source: salt://uci/etc/config/ffdd
    - makedirs: true
    - user: root
    - group: root
    - mode: 644