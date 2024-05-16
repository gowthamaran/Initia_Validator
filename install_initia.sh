#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Please insert your MONIKER"
    exit 1
fi


# Setting
MONIKER="$1"  #ten Node

#######################
CHAIN_ID="initiation-1"
WALLET_NAME="wallet"
RPC_PORT="26657"
EXTERNAL_IP=$(wget -qO- eth0.me)
PROXY_APP_PORT="26658"
P2P_PORT="26656"
PPROF_PORT="6060"
API_PORT="1317"
GRPC_PORT="9090"
GRPC_WEB_PORT="9091"

# Update and install dependencies
sudo apt update && sudo apt install -y curl git jq build-essential gcc unzip wget lz4

ufw disable
# Install Golang
wget https://go.dev/dl/go1.22.3.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.22.3.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
go version

# Set file limit
ulimit -n 65535
echo -e "\n*                soft    nofile          65535\n*                hard    nofile          65535" | sudo tee -a /etc/security/limits.conf

# Install initia binary
git clone https://github.com/initia-labs/initia.git
cd initia
git checkout v0.2.14
make install
/root/go/bin/initiad version

# Set up environment variables
echo "export MONIKER=\"$MONIKER\"" >> ~/.bash_profile
echo "export CHAIN_ID=\"$CHAIN_ID\"" >> ~/.bash_profile
echo "export WALLET_NAME=\"$WALLET_NAME\"" >> ~/.bash_profile
echo "export RPC_PORT=\"$RPC_PORT\"" >> ~/.bash_profile
source ~/.bash_profile

# Initialize the node
cd $HOME
/root/go/bin/initiad init $MONIKER --chain-id $CHAIN_ID
/root/go/bin/initiad config set client chain-id $CHAIN_ID
/root/go/bin/initiad config set client node tcp://localhost:$RPC_PORT
/root/go/bin/initiad config set client keyring-backend test

cp /root/go/bin/initiad /usr/bin/initiad
# Download genesis.json
if [[ -f /root/.initia/config/genesis.json ]]; then
    rm -rf /root/.initia/config/genesis.json
fi

wget https://initia.s3.ap-southeast-1.amazonaws.com/initiation-1/genesis.json -O $HOME/.initia/config/genesis.json

# Add seeds and peers to the config.toml
PEERS="$(curl -sS https://initia-t-rpc.syanodes.my.id/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}' | sed -z 's|\n|,|g;s|.$||')"
SEEDS="2eaa272622d1ba6796100ab39f58c75d458b9dbc@34.142.181.82:26656,c28827cb96c14c905b127b92065a3fb4cd77d7f6@testnet-seeds.whispernode.com:25756"

sed -i -e "s|^persistent_peers *=.*|persistent_peers = \"$PEERS\"|" $HOME/.initia/config/config.toml
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/" $HOME/.initia/config/config.toml

# Change ports
sed -i \
    -e "s/\(proxy_app = \"tcp:\/\/\)\([^:]*\):\([0-9]*\).*/\1\2:$PROXY_APP_PORT\"/" \
    -e "s/\(laddr = \"tcp:\/\/\)\([^:]*\):\([0-9]*\).*/\1\2:$RPC_PORT\"/" \
    -e "s/\(pprof_laddr = \"\)\([^:]*\):\([0-9]*\).*/\1localhost:$PPROF_PORT\"/" \
    -e "/\[p2p\]/,/^\[/{s/\(laddr = \"tcp:\/\/\)\([^:]*\):\([0-9]*\).*/\1\2:$P2P_PORT\"/}" \
    -e "/\[p2p\]/,/^\[/{s/\(external_address = \"\)\([^:]*\):\([0-9]*\).*/\1${EXTERNAL_IP}:$P2P_PORT\"/; t; s/\(external_address = \"\).*/\1${EXTERNAL_IP}:$P2P_PORT\"/}" \
    $HOME/.initia/config/config.toml

sed -i \
  -e "/\[api\]/,/^\[/{s/\(address = \"tcp:\/\/\)\([^:]*\):\([0-9]*\)\(\".*\)/\1\2:$API_PORT\4/}" \
  -e "/\[grpc\]/,/^\[/{s/\(address = \"\)\([^:]*\):\([0-9]*\)\(\".*\)/\1\2:$GRPC_PORT\4/}" \
  -e "/\[grpc-web\]/,/^\[/{s/\(address = \"\)\([^:]*\):\([0-9]*\)\(\".*\)/\1\2:$GRPC_WEB_PORT\4/}" \
  $HOME/.initia/config/app.toml

# Configure pruning to save storage (Optional)
sed -i -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.15uinit,0.01uusdc\"/" $HOME/.initia/config/app.toml

# Set min gas price
sed -i -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.15uinit,0.01uusdc\"/" $HOME/.initia/config/app.toml

# Create a service file
sudo tee /etc/systemd/system/initiad.service > /dev/null <<EOF
[Unit]
Description=Initia Node
After=network.target

[Service]
User=root
Type=simple
ExecStart=/root/go/bin/initiad start --home /root/.initia
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# Start node
sudo systemctl daemon-reload
sudo systemctl enable initiad
sudo systemctl restart initiad
#
if sudo systemctl is-active --quiet initiad && ! sudo systemctl is-failed initiad; then
    echo -e "\n Initiad service start successfully."
else
    echo -e "\n OH SHIT ERORRRRRRRRRRRRRRRR"
    echo " rune command to check error => sudo journalctl -u initiad -f -o cat"
    exit 1  
fi

echo -e "\n Create a wallet for your validator"
/root/go/bin/initiad keys add $WALLET_NAME
echo -e "\n---------------------------------------------\n"
echo "DO NOT FORGET TO SAVE THE SEED PHRASE"
echo "Go to: https://faucet.testnet.initia.xyz/  => Claim faucet"
echo -e "\n---------------------------------------------\n"

read -p "Press Enter to continue..."
echo ''
echo '

888b     d888                                   
8888b   d8888                                   
88888b.d88888                                   
888Y88888P888  8888b.  888d888 8888b.  88888b.  
888 Y888P 888     "88b 888P"      "88b 888 "88b 
888  Y8P  888 .d888888 888    .d888888 888  888 
888   "   888 888  888 888    888  888 888  888 
888       888 "Y888888 888    "Y888888 888  888 
                                                
                                                
                                                '

# echo "\nDownloading snapshot"
# cd $HOME
# wget https://rpc-initia-testnet.trusted-point.com/latest_snapshot.tar.lz4
# sudo systemctl stop initiad
# cp $HOME/.initia/data/priv_validator_state.json $HOME/.initia/priv_validator_state.json.backup
# /root/go/bin/initiad tendermint unsafe-reset-all --home $HOME/.initia --keep-addr-book
# lz4 -d -c ./latest_snapshot.tar.lz4 | tar -xf - -C $HOME/.initia
# mv $HOME/.initia/priv_validator_state.json.backup $HOME/.initia/data/priv_validator_state.json
# sudo systemctl restart initiad


echo "Waiting to sync block..."
while true; do
    #should be fail
    if [ "$(/root/go/bin/initiad status | jq -r .sync_info.catching_up)" == "false" ]; then
        break
    fi
    local_height=$(/root/go/bin/initiad status | jq -r .sync_info.latest_block_height)
    network_height=$(curl -s https://rpc-initia-testnet.trusted-point.com/status | jq -r .result.sync_info.latest_block_height)
    blocks_left=$((network_height - local_height))
    echo ""
    echo "Your node height: $local_height"
    echo "Network height: $network_height"
    echo " => Blocks left: $blocks_left <="
    sleep 30
done



echo "create-validator"
initiad tx mstaking create-validator \
  --amount=1000000uinit \
  --pubkey=$(initiad tendermint show-validator) \
  --moniker=$MONIKER \
  --chain-id=$CHAIN_ID \
  --commission-rate=0.05 \
  --commission-max-rate=0.10 \
  --commission-max-change-rate=0.01 \
  --from=$WALLET_NAME \
  --identity="" \
  --website="" \
  --details="on it" \
  --gas=2000000 --fees=300000uinit \
  -y



echo "Delegate tokens to your validator"
sleep 3
initiad tx mstaking delegate $(initiad keys show $WALLET_NAME --bech val -a)  10000000uinit --from $WALLET_NAME --gas=2000000 --fees=300000uinit -y


echo " DONE ALL "
