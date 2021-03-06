{% if pillar['bulk_log'] is defined and pillar['bulk_log'] is not none and pillar['bulk_log']['enabled'] is defined and pillar['bulk_log']['enabled'] is not none and pillar['bulk_log']['enabled'] %}

  {%- if salt['file.directory_exists']('/opt/sysadmws/bulk_log') %}
swsu_v1_bulk_log_cron_managed:
  cron.present:
    - name: '/opt/sysadmws/bulk_log/bulk_log.sh >> /opt/sysadmws/bulk_log/bulk_log.log'
    - identifier: bulk_log
    - user: root
    - minute: '*/2'

swsu_v1_bulk_log_logrotate:
  file.managed:
    - name: /etc/logrotate.d/bulk_log
    - user: root
    - group: root
    - mode: 600
    - source: /opt/sysadmws/bulk_log/bulk_log.logrotate
  {%- endif %}

{% else %}
bulk_log_nothing_done_info:
  test.configurable_test_state:
    - name: nothing_done
    - changes: False
    - result: True
    - comment: |
        INFO: This state was not configured for a minion of this type, so nothing has been done. But it is OK.
{% endif %}
