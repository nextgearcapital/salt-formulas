{% if grains['os_family'].lower() == 'debian' %}
datadog-apt-https:
  pkg.installed:
    - name: apt-transport-https
{% endif %}

{% if grains['os_family'].lower() == 'debian' %}
import-signing-key-datadog:
  cmd.run:
    - name: wget -qO - http://apt.nextgearcapital.com/aptly_repo_signing.key | sudo apt-key add -
{% endif %}

datadog-repo:
  pkgrepo.managed:
    - humanname: NGC datadog repo
    {% if grains['os_family'].lower() == 'debian' %}
    - name: deb http://apt.nextgearcapital.com/datadog-stable datadog-stable main
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

datadog-agent-service:
  service:
    - name: datadog-agent
    - running
    - enable: True
    - watch:
      - pkg: datadog-agent
