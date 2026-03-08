### プライベートサブネットに配置したインスタンスにSSMからアクセスできず、LBのヘルスチェックも失敗する
【原因】すべてのパケットの通り抜けを拒否する設定が、userdataブロックで削除していたにも関わらず残っていたため

【確認方法】
```sh
# NAT機能（マスカレード）の確認
sudo iptables -t nat -L

Chain PREROUTING (policy ACCEPT)
target     prot opt source               destination

Chain INPUT (policy ACCEPT)
target     prot opt source               destination

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination

Chain POSTROUTING (policy ACCEPT)
target     prot opt source               destination
MASQUERADE  all  --  anywhere             anywhere  # MASQUERADEの記載があればOK
# NAT設定を削除したい場合
sudo iptables -F -t nat

# パケット通過（FORWARD）の確認
sudo iptables -L FORWARD

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination
REJECT     all  --  anywhere             anywhere             reject-with icmp-host-prohibited # これが原因

# 特定のルールを削除
sudo iptables -D FORWARD 1
# 全消去
sudo iptables -F FORWARD
# デフォルトポリシーを許可に変更
sudo iptables -P FORWARD ACCEPT
```

【なぜuser_dataに書いても消えなかったのか】
⇒Geminiの考え：
これにはOS（Amazon Linux 2023）の起動の仕組みによる「実行順序」の罠が関係しています。

理由1：iptables-services のデフォルト設定の上書き
user_data で dnf install -y iptables-services を実行すると、その瞬間にOS標準のデフォルト設定ファイル（/etc/sysconfig/iptables）が作成されます。このファイルの中に、例の REJECT ルールが最初から書かれています。

その後、systemctl start iptables をした瞬間にそのファイルが読み込まれ、ルールが適用されます。user_data の記述順序やタイミングによっては、「自分が追加したルール」よりも「OSが用意したデフォルトの拒否ルール」がリストの上位（優先順位が高い場所）に来てしまった、あるいはOSの起動処理と競合して設定がうまく保存されなかった可能性が高いです。

理由2：Amazon Linux 2023 の systemd との競合
AL2023は従来のOSよりも起動が高速化されており、user_data（cloud-init）が走るタイミングと、各種サービス（iptablesなど）が初期化されるタイミングが重なることがあります。
手動でコマンドを打った時は、すべての起動処理が終わった「落ち着いた状態」で実行したため、確実にルールを上書き・削除できたのだと考えられます。

【対策】userdataブロック内で、設定ファイルの内容ごと変える
使用したコマンド：
```sh
# INNER_EOFまでの内容を、ファイルに上書きする
cat <<'INNER_EOF' > <ファイルのパス>
<書きたい内容>
INNER_EOF
```

### APサーバを導入してブラウザからの確認はできたものの、ALBのヘルスチェックが403をたたき出す
【原因】`/var/www/html/`にindex.htmlがなく、セキュリティ設定によってはディレクトリの中身を見る機能がオフになっている場合があるため
⇒この状態でヘルスチェックのパスを`/`に指定していると、「見せられないよ！」とApacheから言われて403が出力される

【解決方法】
1. index.htmlを事前に作成するようにする
2. ヘルスチェックのパスを変更しておく

### APサーバをcloudmapに登録できず、webサーバ側がAPサーバを認識できずエラーが発生した
【原因】AWS の標準設定では、「**IMDSv2**」というセキュリティの厳しいモードが有効になっているから
IMDSv2（Instance Metadata Service Version 2）：AWS の EC2 インスタンスが自分自身の情報（インスタンス ID、IP アドレス、IAM ロールの認証情報など）を取得するための仕組み。より安全な最新バージョンがv2
⇒情報の取り出しに『トークン（合言葉）』が必要になった、セキュリティ強化版

【解決方法】
1. まずはトークン（合言葉）を取得する
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
              
2. トークンを使ってインスタンスIDとIPを取得する（以下はそのまま変数に格納）
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)

PRIVATE_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)

### APサーバをCloudmapに自動登録することはできたが、destroy時に自動解除が出来ずにエラーが出力されてしまう
【原因】TerraformがEC2の終了処理（シャットダウン）を待たずに、Cloud Mapを消しに行こうとしたから。Cloudmapのサービスは、登録されているインスタンスを解除しないと削除できない。

【検証内容】
1. systemdによって起動時・停止時に自動登録・解除をするスクリプトを作成する
```sh
#launch_template.tf内のuserdataブロックで、以下のように記載
cat <<INNER_EOF > /etc/systemd/system/cloudmap-register.service
              [Unit]
              Description=Cloud Map Register and Deregister
              After=network.target

              [Service]
              Type=oneshot
              ExecStart=/usr/bin/aws servicediscovery register-instance \
              --service-id ${aws_service_discovery_service.main.id} \
              --instance-id $INSTANCE_ID \
              --attributes AWS_INSTANCE_IPV4=$PRIVATE_IP,AWS_INSTANCE_PORT=80 \
              --region ap-northeast-1
              ExecStop=/usr/bin/aws servicediscovery deregister-instance \
              --service-id ${aws_service_discovery_service.main.id} \
              --instance-id $INSTANCE_ID \
              --region ap-northeast-1
              RemainAfterExit=yes

              [Install]
              WantedBy=multi-user.target
              INNER_EOF

              # 作成したサービスを有効化
              systemctl enable cloudmap-register.service
              systemctl start cloudmap-register.service
  EOF
  )

#エラー時の確認コマンド
systemctl status cloudmap-register.service
sudo journalctl -xeu cloudmap-register.service
vi /etc/systemd/system/cloudmap-register.service
```

2. ヘルスチェックを実施して、異常があれば自動で解除してもらうようにする
```sh
ExecStartPost=/usr/bin/bash -c "/usr/bin/aws servicediscovery update-instance-custom-health-status \
  --service-id ${aws_service_discovery_service.main.id} \
  --instance-id \$(curl -s http://169.254.169.254/latest/meta-data/instance-id) \
  --status HEALTHY \
  --region ap-northeast-1"
```

3. Terraform内部でデータや処理のタイミングを管理するリソースを使う
```sh
#cloudmap.tfに書き込み
resource "terraform_data" "cloudmap_cleanup" {
  input = aws_service_discovery_service.main.id

  provisioner "local-exec" {
    when    = destroy
    command = "for id in $(aws servicediscovery list-instances --service-id ${self.input} --query 'Instances[*].Id' --output text --region ap-northeast-1); do aws servicediscovery deregister-instance --service-id ${self.input} --instance-id $id --region ap-northeast-1; done"
  }
}
```

4. リソースごとに依存関係を付与するdepends_onを使用する
```sh
#auto_scaling.tfのAPサーバのブロックに記載
depends_on = [aws_service_discovery_service.main]
```

【結果】
1. 内部の自動解除スクリプトよりも先にサービスの消去が動いてしまった⇒**解決せず**
2. スクリプトがうまく動作せず、エラーを連発⇒**解決せず**
3. Terraformが掃除用のスクリプトを走らせるのとほぼ同時に、Cloud Mapサービス自体を消してしまった⇒**解決せず**
4. 依存関係が特に働かず、エラーが出力される⇒**解決せず**

【現状】
userdataで、自動登録だけ記載。消すときは手動で削除
今後、内部ALBに変更予定

