{% if grains['os_family'].lower() == 'debian' %}
datadog-apt-https:
  pkg.installed:
    - name: apt-transport-https
{% endif %}

datadog-repo:
  pkgrepo.managed:
    - humanname: "Datadog, Inc."
    {% if grains['os_family'].lower() == 'debian' %}
    - name: deb https://apt.datadoghq.com/ stable main
    - keyserver: keyserver.ubuntu.com
    - keyid: C7A7DA52
    - file: /etc/apt/sources.list.d/datadog.list
    - require:
      - pkg: datadog-apt-https
    {% elif grains['os_family'].lower() == 'redhat' %}
    - name: datadog
    - baseurl: https://yum.datadoghq.com/rpm/{{ grains['cpuarch'] }}
    - gpgcheck: '1'
    - gpgkey: https://yum.datadoghq.com/DATADOG_RPM_KEY.public
    - sslverify: '1'
    {% endif %}
 
datadog-pkg:
  pkg.latest:
    - name: datadog-agent
    - refresh: True
    - require:
      - pkgrepo: datadog-repo
 
datadog-example:
  cmd.run:
    - name: cp /etc/dd-agent/datadog.conf.example /etc/dd-agent/datadog.conf
    # copy just if datadog.conf does not exists yet and the .example exists
    - onlyif: test ! -f /etc/dd-agent/datadog.conf -a -f /etc/dd-agent/datadog.conf.example
    - require:
      - pkg: datadog-pkg
 
datadog-conf:
 file.managed:
   - name: {{ salt['pillar.get']('datadog:config_file_path', '/etc/dd-agent/datadog.conf') }}
   - source: salt://datadog/files/datadog_conf.jinja
   - template: jinja
   - user: root
   - group: root
   - mode: 644
   - watch:
     - pkg: datadog-pkg
   - require:
     - cmd: datadog-example
   {% if salt['pillar.get']('datadog:overwrite', default=True) == False %}
   - unless:
     - test -e {{ salt['pillar.get']('datadog:config_file_path', '/etc/dd-agent/datadog.conf') }}
   {% endif %}

datadog-tags:
  file.append:
    - name: /etc/dd-agent/datadog.conf
    - text:
      - "tags: {{ pillar['datadog']['tags'] }}"

datadog-agent-service:
  service:
    - name: datadog-agent
    - running
    - enable: True
    - watch:
      - pkg: datadog-agent
