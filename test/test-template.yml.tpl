---
- hosts: localhost
  gather_facts: no
  tasks:
    - include: '{{ setup_playbook }}'

- include: '{{ test_playbook }}'

- hosts: localhost
  gather_facts: no
  tasks:
    - include: '{{ teardown_playbook }}'

