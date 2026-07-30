#!/bin/bash
#
# pkg_fix.sh - RHSM 再登録 & SAP 用リポジトリ有効化
#
# Satellite 登録済みのホストを Red Hat CDN に再登録し、
# SAP HANA / NetWeaver に必要な E4S リポジトリを有効化する。
# 環境に応じて --org / --activationkey / --set リリースを変更すること。

# Satellite 設定のバックアップを取り、CDN 用設定に切り替え
sudo cp /etc/rhsm/rhsm.conf /etc/rhsm/rhsm.conf.sat-backup
sudo cp /etc/rhsm/rhsm.conf.kat-backup /etc/rhsm/rhsm.conf

# 既存の登録情報をクリーンアップ
sudo subscription-manager remove --all
sudo subscription-manager unregister
sudo subscription-manager clean
sudo yum clean all
sudo rm -rf /var/cache/yum/*
sudo rm -rf /var/cache/dnf

# Satellite (Katello) の CA 証明書を削除
sudo yum remove katello-ca-consumer-labsat.opentlc.com -y

# Red Hat CDN に再登録し、RHEL 8.6 E4S にピン留め
sudo subscription-manager register --org=11594663 --activationkey=tempkey
sudo subscription-manager release --set=8.6
sudo insights-client --register

# SAP HANA / NetWeaver に必要な E4S リポジトリを有効化
sudo subscription-manager repos \
--enable="rhel-8-for-$(uname -m)-baseos-e4s-rpms" \
--enable="rhel-8-for-$(uname -m)-appstream-e4s-rpms" \
--enable="rhel-8-for-$(uname -m)-sap-solutions-e4s-rpms" \
--enable="rhel-8-for-$(uname -m)-sap-netweaver-e4s-rpms"
