# hanaworkshop-2024

SAP HANA on RHEL のデプロイと HA 構成を自動化する Ansible Playbook 集です。
RHEL System Roles と `community.sap_install` コレクションを活用し、NTP 同期からストレージ準備、HANA インストール、System Replication、Pacemaker クラスタ構成までを一貫して実行できます。

## 構成概要

```
hanaworkshop-2024/
├── all.sh                    # 全 Playbook を順次実行するラッパースクリプト
├── 00_run_script.yml         # 初期設定 (FQDN 解決、group_vars 生成、pkg_fix 配布)
├── 01_timesync_prep.yml      # NTP 時刻同期 (rhel-system-roles.timesync)
├── 02_storage_prep.yml       # HANA 用ファイルシステム作成 (data/log/shared/usr/sap)
├── 03_hostagent_prep.yml     # SAP Host Agent インストール
├── 04_sap_prep.yml           # SAP HANA 前提条件の適用 (sap_general/hana_preconfigure)
├── 05_hana_deploy.yml        # SAP HANA データベースインストール
├── 06_hsr.yml                # HANA System Replication 設定
├── 07_pacemaker.yml          # Pacemaker HA クラスタ構成
├── 07_pacemaker.com.yml      # Pacemaker (community.sap_install 版)
├── pkg_fix.sh                # RHSM 再登録 & SAP 用リポジトリ有効化スクリプト
├── list_ips.yml              # 全ホストの IP アドレス一覧表示
├── group_vars/               # Ansible グループ変数 (テンプレートから自動生成)
├── temp/                     # Jinja2 テンプレート (hanas, hosts.j2, 05_s4hana_deploy.yml)
├── s4-ap/                    # S/4HANA アプリケーションサーバー用 Playbook
│   ├── 02_s4_storage_prep.yml
│   ├── 03_s4_hostagent_prep.yml
│   ├── 04_s4_sap_prep.yml
│   └── 05_s4hana_deploy.yml
└── operations/               # 運用タスク (バックアップ、RFC 接続テスト等)
    ├── backup.yml
    ├── hdbuserstore_info.yml
    └── rfc.yml
```

## 前提条件

- RHEL 8 (E4S) ターゲットホスト
- Ansible 2.9+
- 以下のパッケージ / コレクション:
  - `rhel-system-roles`
  - `rhel-system-roles-sap`
  - `community.sap_install` (Ansible Galaxy)
  - `sap.sap_operations` (運用 Playbook で使用)
- SAP HANA インストールメディアが `/software/HANA_installation` に配置済み
- SAP Host Agent RPM が `/nfs/SAPHOSTAGENT` に配置済み
- ターゲットホストへの SSH 接続が確立済み

## 使い方

### 全ステップの一括実行

```sh
./all.sh
```

必要なパッケージのインストール、Ansible Galaxy コレクションの取得、および各 Playbook を順番に実行します。

### 個別 Playbook の実行

```sh
ansible-playbook 01_timesync_prep.yml
ansible-playbook 02_storage_prep.yml
# ... 以降同様
```

### S/4HANA アプリケーションサーバーのセットアップ

```sh
ansible-playbook s4-ap/02_s4_storage_prep.yml
ansible-playbook s4-ap/03_s4_hostagent_prep.yml
ansible-playbook s4-ap/04_s4_sap_prep.yml
ansible-playbook s4-ap/05_s4hana_deploy.yml
```

## 実行フロー

```
00_run_script.yml   環境固有の変数を生成し、パッケージ修正スクリプトを配布
        │
01_timesync_prep    NTP 時刻同期を設定
        │
02_storage_prep     /hana/data, /hana/log, /hana/shared, /usr/sap を作成
        │
03_hostagent_prep   SAP Host Agent をインストール
        │
04_sap_prep         RHEL を SAP HANA 用に最適化 (カーネルパラメータ等)
        │
05_hana_deploy      SAP HANA データベースをインストール
        │
06_hsr              HANA System Replication (Primary/Secondary) を構成
        │
07_pacemaker        Pacemaker クラスタを構成し、自動フェイルオーバーを有効化
```

## HANA クラスタ構成

- **SID**: RHE
- **インスタンス番号**: 00
- **ノード構成**: Primary (DC01) + Secondary (DC02)
- **HA クラスタ名**: hana-cluster

## 運用 Playbook

| Playbook | 内容 |
|---|---|
| `operations/backup.yml` | HANA フルバックアップ (SYSTEMDB + テナント) |
| `operations/hdbuserstore_info.yml` | HDB User Store キー情報の取得 |
| `operations/rfc.yml` | SAP RFC 接続テスト (PyRFC 経由) |

## 使用ロール / コレクション

| ロール / コレクション | 用途 |
|---|---|
| `rhel-system-roles.timesync` | NTP 時刻同期 |
| `rhel-system-roles.storage` | LVM / ファイルシステム管理 |
| `sap_general_preconfigure` | RHEL 汎用 SAP 前提条件 |
| `sap_hana_preconfigure` | HANA 固有の前提条件 |
| `sap_hostagent` | SAP Host Agent |
| `sap_hana_install` | HANA データベースインストール |
| `sap_ha_install_hana_hsr` | HANA System Replication |
| `sap_ha_prepare_pacemaker` | Pacemaker 前準備 |
| `sap_ha_install_pacemaker` | Pacemaker インストール |
| `sap_ha_set_hana` | Pacemaker HANA リソース設定 |
| `sap_ha_pacemaker_cluster` | Pacemaker クラスタ (community 版) |
| `sap_netweaver_preconfigure` | NetWeaver 前提条件 (S/4HANA AP 用) |

## 注意事項

- `group_vars/hanas` は `00_run_script.yml` によりテンプレートから自動生成されます。手動編集しないでください。
- `pkg_fix.sh` は RHSM を再登録し、SAP 用 E4S リポジトリを有効化します。環境に応じて Activation Key 等を変更してください。
- Pacemaker Playbook (`07_pacemaker.yml`) は `all.sh` ではコメントアウトされています。STONITH / Fencing の設定を確認してから個別に実行してください。
