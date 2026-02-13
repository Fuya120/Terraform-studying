- プライベートサブネットに配置したインスタンスにSSMからアクセスできず、LBのヘルスチェックも失敗する
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

- APサーバを導入してブラウザからの確認はできたものの、ALBのヘルスチェックが403をたたき出す
【原因】`/var/www/html/`にindex.htmlがなく、セキュリティ設定によってはディレクトリの中身を見る機能がオフになっている場合があるため
⇒この状態でヘルスチェックのパスを`/`に指定していると、「見せられないよ！」とApacheから言われて403が出力される

【解決方法】
1. index.htmlを事前に作成するようにする
2. ヘルスチェックのパスを変更しておく
