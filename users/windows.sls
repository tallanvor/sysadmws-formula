{% if (pillar['windows_users'] is defined) and (pillar['windows_users'] is not none) %}
windows_scripts_admin_user:
  file.managed:
    - name: 'C:\Windows\System32\admin_user.ps1'
    - source: salt://users/scripts/admin_user.ps1

windows_scripts_starting_program:
  file.managed:
    - name: 'C:\Windows\System32\starting_program.ps1'
    - source: salt://users/scripts/starting_program.ps1

windows_scripts_session_params:
  file.managed:
    - name: 'C:\Windows\System32\session_params.ps1'
    - source: salt://users/scripts/session_params.ps1

windows_execution_policy_unrestrict:
  cmd.run:
    - name: powershell.exe Set-ExecutionPolicy -Force Unrestricted

  {%- for windows_user, user_params in pillar['windows_users'].items() %}
windows_user_present_{{ loop.index }}:
  user.present:
    - name: {{ windows_user }}
    - fullname: {{ user_params['fullname'] }}
    - remove_groups: {{ user_params['remove_groups'] }}
    - password: {{ user_params['password'] }}
    {%- if (user_params['groups'] is defined) and (user_params['groups'] is not none) %}
    - groups: {{ user_params['groups'] }}
    {%- endif %}

# update password is broken, pass never updates
# https://github.com/saltstack/salt/issues/41347
# so force pass each time
windows_user_pass_{{ loop.index }}:
  module.run:
    - name: user.setpassword
    - m_name: {{ windows_user }}
    - password:  {{ user_params['password'] }}

    {%- if user_params['account_disabled'] is defined and user_params['account_disabled'] is not none %}
windows_user_account_disabled_{{ loop.index }}:
  module.run:
    - name: user.update
    - m_name: {{ windows_user }}
    - account_disabled: {{ user_params['account_disabled'] }}
    {%- endif %}

    {%- if (user_params['password_never_expires'] is defined) and (user_params['password_never_expires'] is not none) and (user_params['password_never_expires']) %}
windows_user_password_never_expires_{{ loop.index }}:
  module.run:
    - name: user.update
    - m_name: {{ windows_user }}
    - password_never_expires: True
    {%- endif %}

    {%- if (user_params['description'] is defined) and (user_params['description'] is not none) %}
windows_user_description_{{ loop.index }}:
  module.run:
    - name: user.update
    - m_name: {{ windows_user }}
    - description: {{ user_params['description'] }}
    {%- endif %}

    {%- if (user_params['admin'] is defined) and (user_params['admin'] is not none) and (user_params['admin']) %}
windows_user_admin_user_{{ loop.index }}:
  cmd.run:
    - name: 'powershell.exe C:\Windows\system32\admin_user.ps1 {{ windows_user }}'
    {%- endif %}

    {%- if (user_params['starting_program'] is defined) and (user_params['starting_program'] is not none) %}
windows_user_starting_program_{{ loop.index }}:
  cmd.run:
      {%- if (user_params['start_in'] is defined) and (user_params['start_in'] is not none) %}
    - name: powershell.exe C:\Windows\system32\starting_program.ps1 '{{ windows_user }}' '{{ user_params['starting_program'] }}' '{{ user_params['start_in'] }}'
      {%- else %}
    - name: powershell.exe C:\Windows\system32\starting_program.ps1 '{{ windows_user }}' '{{ user_params['starting_program'] }}' ''
      {%- endif %}
    {%- endif %}

    {%- if (user_params['session_params'] is defined) and (user_params['session_params'] is not none) %}
      {%- set o_loop = loop %}
      {%- for session_params_key, session_params_val in user_params['session_params'].items() %}
windows_user_starting_program_{{ o_loop.index }}_{{ loop.index }}:
  cmd.run:
    - name: powershell.exe C:\Windows\system32\session_params.ps1 '{{ windows_user }}' '{{ session_params_key }}' '{{ session_params_val }}'
      {%- endfor %}
    {%- endif %}
  {%- endfor %}

  {%- if not ((pillar['windows_unrestricted'] is defined) and (pillar['windows_unrestricted'] is not none) and (pillar['windows_unrestricted'])) %}
# This should be in the end of file
windows_execution_policy_restrict:
  cmd.run:
    - name: powershell.exe Set-ExecutionPolicy -Force Restricted
  {%- endif %}
{% else %}
windows_users_nothing_to_do:
  test.configurable_test_state:
    - name: windows_users_nothing_to_do_info
    - changes: False
    - result: True
    - comment: |
         NOTICE: Pillar windows_users not defined, doing nothing.
{% endif %}
