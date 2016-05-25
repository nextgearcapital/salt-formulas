#######################################
##### Salt Formula For ngc-resolv #####
#######################################
{% if grains['kernel'] == 'Linux' %}

ngc-resolv-file:
  file.managed:
    - name: /etc/resolv.conf
    - user: root
    - group: root
    - mode: '0644'
    - source: salt://ngc-resolv/files/resolv.conf
    - template: jinja
    - replace: true
    - defaults:
        nameservers: {{ salt['pillar.get']('ngc-resolv:nameservers', ['8.8.8.8','8.8.4.4']) }}
        searchpaths: {{ salt['pillar.get']('ngc-resolv:searchpaths', [salt['grains.get']('domain'),]) }}
        domain: {{ salt['pillar.get']('ngc-resolv:domain', salt['grains.get']('domain')) }}
        options: {{ salt['pillar.get']('ngc-resolv:options', []) }}
{% endif %}
