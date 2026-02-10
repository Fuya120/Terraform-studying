# このリポジトリの目的
Terraformの学習記録です。
社内技術のナレッジ共有ツールのインフラ構築を依頼された想定で、構成を考えドキュメント作成から始まり、インフラのコード化やLaravelのフレームワークを活用したWEBシステムの構築を行っていきます。詳細については下記の[概要](#概要)をご確認ください。2月末を目途に完成予定です。

## プロジェクトステータス
🚧 **開発中（2025年2月末完成予定）**

- [ ] インフラ設計完了

- [ ] Terraform構成完了
    - [o] provider.tf
    - [o] data.tf
    - [o] network.tf
    - [o] iam_role.tf
    - [o] security_group.tf
    - [o] nat_instance.tf
    
    - [ ] terraform.tf
    - [ ] variables.tf
    - [ ] terraform.tfvars
    - [ ] outputs.tf

- [ ] Laravelアプリケーション実装中
- [ ] ドキュメント整備完了

# ライセンス
このプロジェクトは [MIT License](./LICENSE) の下で公開されています。
## 作成者
- GitHub: [@Fuya120](https://github.com/Fuya120)
- 作成日: 2025年2月

# 概要
1. プロジェクトタイトル
社内技術ナレッジ共有ツールのための、**高可用・高セキュリティ**なインフラ基盤構築

2. プロジェクト概要
社内の技術的な知見を属人化させず、安全かつ安定して共有するためのWebアプリケーション用インフラストラクチャです。**Terraformを用いて構築を自動化**し、本番環境を見据えた3層アーキテクチャを採用しています。

3. 構成図
![Architecture Diagram](./docs/images/architecture.png)

4. 特徴
- **高可用性**：マルチAZ構成により、データセンターレベルの障害が発生してもサービスを継続可能です。

- **セキュリティ**：各サーバをプライベートサブネットに隔離し、外部からの直接アクセスを完全に遮断しています。また、SSMを使用することで安全にブラウザからプライベートサブネット内のインスタンスへアクセスすることが出来ます。

- **IaC（Infrastructure as Code）**：インフラ全体をコード化。環境の複製（ステージング環境の作成など）が数分で完了します。

- **メンテナンス性とコスト削減**：NATインスタンスを導入し、セキュリティを保ちつつOSやミドルウェアのアップデートが可能です。また、NATゲートウェイよりもコストがかからないため、費用の削減にもつながります。

5. 技術スタック

- IaC：Terraform

- Cloud：AWS（VPC, ALB, EC2, RDS, Route53, SSM）

- Application: Laravel（PHP 8.x）

- Database: MySQL 8.0

6. ドキュメント一覧
※詳細は「docs/」ディレクトリを参照ください。現在、鋭意作成中です。

| ドキュメント | 概要 |
|---|---|
| [要件定義書](./docs/requirements.md) | プロジェクトの背景・目的・機能要件 |
| [インフラ設計書](./docs/infra-design.md) | ネットワーク構成、セキュリティ設計 |
| [構築手順書](./docs/setup-guide.md) | 環境構築の詳細手順 |
| [ADR](./docs/adr/) | アーキテクチャ意思決定記録 |

7. クイックスタート
```Bash
# リポジトリのクローン
git clone https://github.com/Fuya120/Terraform-studying.git

# インフラの構築
cd terraform
terraform init
terraform apply
```

8. 想定コスト

このインフラを稼働させた場合の月額概算（東京リージョン）：

| サービス | 構成 | 月額 |
|---|---|---|
| EC2 (Web) | t3.micro × 2台 | $15 |
| EC2 (AP) | t3.micro × 2台 | $15 |
| NAT Instance | t3.nano × 2台 | $6 |
| RDS | db.t3.micro (Multi-AZ) | $30 |
| ALB | 1台 | $20 |
| Route 53 | ホストゾーン1つ | $0.5 |
| データ転送 | 小規模想定 | $5 |
| **合計** | | **約$91.5/月** |

※AWS無料枠適用前の概算です  
※検証後は必ず `terraform destroy` でリソース削除してください

