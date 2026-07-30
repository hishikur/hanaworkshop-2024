#!/bin/bash
#
# all.sh - SAP HANA デプロイ全ステップ一括実行スクリプト
#
# 実行順序:
#   00: 環境固有設定の生成 (FQDN 解決、group_vars テンプレート展開)
#   01: NTP 時刻同期
#   02: HANA 用ストレージ (LVM + ファイルシステム) 作成
#   03: SAP Host Agent インストール
#   04: SAP HANA 前提条件の適用 (カーネルパラメータ、パッケージ等)
#   05: SAP HANA データベースインストール
#   06: HANA System Replication 構成
#   07: Pacemaker HA クラスタ (手動実行 — 下記参照)
#
# 注意: 07_pacemaker.yml は STONITH/Fencing 設定の事前確認が必要なため
#       コメントアウトしています。準備完了後に個別実行してください。

export LANG=en_US.UTF-8

# Phase 0: 環境固有の変数生成とパッケージ修正スクリプトの配布
ansible-playbook 00_run_script.yml
sleep 5

# Phase 1: NTP 時刻同期 (rhel-system-roles.timesync を使用)
sudo yum install rhel-system-roles -y
sleep 5
ansible-playbook 01_timesync_prep.yml
sleep 5

# Phase 2: HANA 用ファイルシステム作成 (/hana/data, /hana/log, /hana/shared, /usr/sap)
ansible-playbook 02_storage_prep.yml
sleep 5

# Phase 3: SAP Host Agent インストール (community.sap_install コレクションが必要)
ansible-galaxy collection install community.sap_install
sleep 5
ansible-playbook 03_hostagent_prep.yml
sleep 5

# Phase 4: SAP HANA 前提条件適用 (sap_general_preconfigure + sap_hana_preconfigure)
sudo yum install rhel-system-roles-sap -y
sleep 5
ansible-playbook 04_sap_prep.yml
sleep 5

# Phase 5: SAP HANA データベースインストール
ansible-playbook 05_hana_deploy.yml
sleep 5

# Phase 6: HANA System Replication (Primary/Secondary) 構成
ansible-playbook 06_hsr.yml

# Phase 7: Pacemaker HA クラスタ構成 (STONITH 設定後に手動実行)
#sleep 5
#ansible-playbook 07_pacemaker.yml


