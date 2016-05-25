#######################################
##### Salt Formula For ngc-resolv #####
#######################################
{% if grains['kernel'] == 'Linux' %}

{%- from "ngc-resolv/map.jinja" import mdb with context -%}

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
        nameservers: {{ salt['pillar.get']('ngc-resolv:nameservers', []) }}
        searchpaths: {{ salt['pillar.get']('ngc-resolv:searchpaths', []) }}
        domain: {{ salt['pillar.get']('ngc-resolv:domain', []) }}
        options: {{ salt['pillar.get']('ngc-resolv:options', []) }}
{% endif %}
