#!/bin/bash

export LANG=C

ansible-playbook 00_run_script.yml
sleep 5
sudo yum install rhel-system-roles -y
sleep 5
ansible-playbook 01_timesync_prep.yml
sleep 5
ansible-playbook 02_storage_prep.yml
sleep 5
ansible-galaxy collection install community.sap_install
sleep 5
ansible-playbook 03_hostagent_prep.yml
sleep 5
sudo yum install rhel-system-roles-sap -y
sleep 5
ansible-playbook 04_sap_prep.yml
sleep 5
ansible-playbook 05_hana_deploy.yml
sleep 5
ansible-playbook 06_hsr.yml
#sleep 5
#ansible-playbook 07_pacemaker.yml


