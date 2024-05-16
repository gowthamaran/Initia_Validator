# validator_initia
Documentation to install validator_initia


## Hardware requirements
```py
- Memory: 16 GB RAM
- CPU: 4 cores
- Disk: 1 TB SSD
- Bandwidth: 1 Gbps
- Linux amd64 arm64 (Ubuntu LTS release)
```
## VPS Provider
Register on Contabo.Good VPS Provider

Register here ⬇️ https://tinyurl.com/CheapContaboVPS

My VPS config:
- ubuntu version: 22.04
- ubuntu-s-6vcpu-16gb-amd-sgp1-01 ($12.56/mo)


## Installation guide

### 1. Pre-Install
```bash
sudo apt install tmux git -y && tmux new -s initia
```

### 2. Install

```bash
curl -o install_initia.sh curl -o install_initia.sh https://raw.githubusercontent.com/gowthamaran/Initia_Validator/main/install_initia.sh
chmod +x install_initia.sh
```
- Change '**YOUR_NODE_NAME**' to your name:
```bash
./install_initia.sh YOUR_NODE_NAME
```

- Following script insctruction:

  - Backup your mnemonic and public key.
  - Go to: https://faucet.testnet.initia.xyz/ and claim faucet
  - Press Enter to continute...
    
    [<img src='assets\install_step_1.png' alt='step1' width= '80%'>]()

  - Waiting to it sync full block. (few hours)
  - Block left must be 0 and it will auto run next step

    [<img src='assets\install_step_2.png' alt='step1' width= '80%'>]()

- You can turn off terminal and check status later
  -  check logs: journalctl -t initiad -f -o cat

  - Check Blocks left: 
  ```bash
    local_height=$(/root/go/bin/initiad status | jq -r .sync_info.latest_block_height)
    network_height=$(curl -s https://rpc-initia-testnet.trusted-point.com/status | jq -r .result.sync_info.latest_block_height)
    blocks_left=$((network_height - local_height))
    echo ""
    echo "Your node height: $local_height"
    echo "Network height: $network_height"
    echo " => Blocks left: $blocks_left <="
  ```

    -  Access to tmux:
  ```bash
  tmux attach -t initia
  ```
## DONE ALL.
Check your validator:
- Go to: https://scan.testnet.initia.xyz/initiation-1/validators
- Search your '**YOUR_NODE_NAME**'

[Submit The Validator Initiation Form](https://docs.google.com/forms/d/e/1FAIpQLSc09Kl6mXyZHOL12n_6IUA8MCcL6OqzTqsoZn9N8gpptoeU_Q/viewform)

## --------------------------------------------------
## Helpful command

### 1. Stop the node
```bash
sudo systemctl stop initiad
```
### 2. Backup priv_validator_state.json 
```bash
cp $HOME/.initia/data/priv_validator_state.json $HOME/.initia/priv_validator_state.json.backup
```
### 3. Reset DB
```bash
initiad tendermint unsafe-reset-all --home $HOME/.initia --keep-addr-book
```
### 4. Setup required variables (One command)
```bash
PEERS="a63a6f6eae66b5dce57f5c568cdb0a79923a4e18@peer-initia-testnet.trusted-point.com:26628" && \
RPC="https://rpc-initia-testnet.trusted-point.com:443" && \
LATEST_HEIGHT=$(curl -s --max-time 3 --retry 2 --retry-connrefused $RPC/block | jq -r .result.block.header.height) && \
TRUST_HEIGHT=$((LATEST_HEIGHT - 1500)) && \
TRUST_HASH=$(curl -s --max-time 3 --retry 2 --retry-connrefused "$RPC/block?height=$TRUST_HEIGHT" | jq -r .result.block_id.hash) && \

if [ -n "$PEERS" ] && [ -n "$RPC" ] && [ -n "$LATEST_HEIGHT" ] && [ -n "$TRUST_HEIGHT" ] && [ -n "$TRUST_HASH" ]; then
    sed -i.bak \
        -e "/\[statesync\]/,/^\[/{s/\(enable = \).*$/\1true/}" \
        -e "/^rpc_servers =/ s|=.*|= \"$RPC,$RPC\"|;" \
        -e "/^trust_height =/ s/=.*/= $TRUST_HEIGHT/;" \
        -e "/^trust_hash =/ s/=.*/= \"$TRUST_HASH\"/" \
        -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" \
        $HOME/.initia/config/config.toml
    echo -e "\nLATEST_HEIGHT: $LATEST_HEIGHT\nTRUST_HEIGHT: $TRUST_HEIGHT\nTRUST_HASH: $TRUST_HASH\nPEERS: $PEERS\n\nALL IS FINE"
else
    echo -e "\nError: One or more variables are empty. Please try again or change RPC\nExiting...\n"
fi
```
### 4. Move priv_validator_state.json back
```bash
mv $HOME/.initia/priv_validator_state.json.backup $HOME/.initia/data/priv_validator_state.json
```
### 5. Start the node
```bash
sudo systemctl restart initiad && sudo journalctl -u initiad -f -o cat
```
You should see the following logs. It may take up to 5 minutes for the snapshot to be discovered. If doesn't work, try downloading [snapshot](#download-snapshot)
```py
2:39PM INF sync any module=statesync msg="Discovering snapshots for 15s" server=node
2:39PM INF Discovered new snapshot format=3 hash="?^��I��\r�=�O�E�?�CQD�6�\x18�F:��\x006�" height=602000 module=statesync server=node
2:39PM INF Discovered new snapshot format=3 hash="%���\x16\x03�T0�v�f�C��5�<TlLb�5��l!�M" height=600000 module=statesync server=node
2:42PM INF VerifyHeader hash=CFC07DAB03CEB02F53273F5BDB6A7C16E6E02535B8A88614800ABA9C705D4AF7 height=602001 module=light server=node
```
After some time you should see the following logs. It make take 5 minutes for the node to catch up the rest of the blocks
```py
2:43PM INF indexed block events height=602265 module=txindex server=node
2:43PM INF executed block height=602266 module=state num_invalid_txs=0 num_valid_txs=0 server=node
2:43PM INF commit synced commit=436F6D6D697449447B5B31313720323535203139203132392031353920313035203136352033352031353320313220353620313533203139352031372036342034372033352034372032333220373120313939203720313734203620313635203338203336203633203235203136332039203134395D3A39333039417D module=server
2:43PM INF committed state app_hash=75FF13819F69A523990C3899C311402F232FE847C707AE06A526243F19A30995 height=602266 module=state num_txs=0 server=node
2:43PM INF indexed block events height=602266 module=txindex server=node
2:43PM INF executed block height=602267 module=state num_invalid_txs=0 num_valid_txs=0 server=node
2:43PM INF commit synced commit=436F6D6D697449447B5B323437203134322032342031313620323038203631203138362032333920323238203138312032333920313039203336203420383720323238203236203738203637203133302032323220313431203438203337203235203133302037302032343020313631203233372031312036365D3A39333039427D module=server
```
### 6. Check the synchronization status
```bash
initiad status | jq -r .sync_info
```
### 7. Disable state sync
```bash
sed -i.bak -e "/\[statesync\]/,/^\[/{s/\(enable = \).*$/\1false/}" $HOME/.initia/config/app.toml
```
## Download fresh addrbook.json

### 1. Stop the node and use `wget` to download the file
```bash
sudo systemctl stop initiad && \
wget -O $HOME/.initia/config/addrbook.json https://rpc-initia-testnet.trusted-point.com/addrbook.json
```
### 2. Restart the node
```bash
sudo systemctl restart initiad && sudo journalctl -u initiad -f -o cat
```
### 3. Check the synchronization status
```bash
initiad status | jq -r .sync_info
```
The file is being updated every 5 minutes

## Add fresh persistent peers

### 1. Extract persistent_peers from our endpoint
```bash
PEERS=$(curl -s --max-time 3 --retry 2 --retry-connrefused "https://rpc-initia-testnet.trusted-point.com/peers.txt")
if [ -z "$PEERS" ]; then
    echo "No peers were retrieved from the URL."
else
    echo -e "\nPEERS: "$PEERS""
    sed -i "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" "$HOME/.initia/config/config.toml"
    echo -e "\nConfiguration file updated successfully.\n"
fi
```
### 2. Restart the node
```bash
sudo systemctl restart initiad && sudo journalctl -u initiad -f -o cat
```
### 3. Check the synchronization status
```bash
initiad status | jq -r .sync_info
```
Peers are being updated every 5 minutes

## Download Snapshot

### 1. Download latest snapshot from our endpoint
```bash
wget https://rpc-initia-testnet.trusted-point.com/latest_snapshot.tar.lz4 -O latest_snapshot.tar.lz4
```
### 2. Stop the node
```bash
sudo systemctl stop initiad
```
### 3. Backup priv_validator_state.json 
```bash
cp $HOME/.initia/data/priv_validator_state.json $HOME/.initia/priv_validator_state.json.backup
```
### 4. Reset DB
```bash
initiad tendermint unsafe-reset-all --home $HOME/.initia --keep-addr-book
```
### 5. Extract files fromt the arvhive 
```bash
lz4 -d -c ./latest_snapshot.tar.lz4 | tar -xf - -C $HOME/.initia
```
### 6. Move priv_validator_state.json back
```bash
mv $HOME/.initia/priv_validator_state.json.backup $HOME/.initia/data/priv_validator_state.json
```
### 7. Restart the node
```bash
sudo systemctl restart initiad && sudo journalctl -u initiad -f -o cat
```
### 8. Check the synchronization status
```bash
initiad status | jq -r .sync_info
```
Snapshot is being updated every 3 hours

## Useful commands
### Check node status 
```bash
initiad status | jq
```
### Query your validator
```bash
initiad q mstaking validator $(initiad keys show $WALLET_NAME --bech val -a) 
```
### Query missed blocks counter & jail details of your validator
```bash
initiad q slashing signing-info $(initiad tendermint show-validator)
```
### Unjail your validator 
```bash
initiad tx slashing unjail --from $WALLET_NAME --gas=2000000 --fees=300000uinit -y
```
### Delegate tokens to your validator 
```bash 
initiad tx mstaking delegate $(initiad keys show $WALLET_NAME --bech val -a)  <AMOUNT>uinit --from $WALLET_NAME --gas=2000000 --fees=300000uinit -y
```
### Get your p2p peer address
```bash
initiad status | jq -r '"\(.NodeInfo.id)@\(.NodeInfo.listen_addr)"'
```
### Edit your validator
```bash 
initiad tx mstaking edit-validator --website="<WEBSITE>" --details="<DESCRIPTION>" --moniker="<NEW_MONIKER>" --from=$WALLET_NAME --gas=2000000 --fees=300000uinit -y
```
### Send tokens between wallets 
```bash
initiad tx bank send $WALLET_NAME <TO_WALLET> <AMOUNT>uinit --gas=2000000 --fees=300000uinit -y
```
### Query your wallet balance 
```bash
initiad q bank balances $WALLET_NAME
```
### Monitor server load
```bash 
sudo apt update
sudo apt install htop -y
htop
```
### Query active validators
```bash
initiad q mstaking validators -o json --limit=1000 \
| jq '.validators[] | select(.status=="BOND_STATUS_BONDED")' \
| jq -r '.voting_power + " - " + .description.moniker' \
| sort -gr | nl
```
### Query inactive validators
```bash
initiad q mstaking validators -o json --limit=1000 \
| jq '.validators[] | select(.status=="BOND_STATUS_UNBONDED")' \
| jq -r '.voting_power + " - " + .description.moniker' \
| sort -gr | nl
```
### Check logs of the node
```bash
sudo journalctl -u initiad -f -o cat
```
### Restart the node
```bash
sudo systemctl restart initiad
```
### Stop the node
```bash
sudo systemctl stop initiad
```
### Delete the node from the server
```bash
# !!! IF YOU HAVE CREATED A VALIDATOR, MAKE SURE TO BACKUP `priv_validator_key.json` file located in $HOME/.initia/config/ 
sudo systemctl stop initiad
sudo systemctl disable initiad
sudo rm /etc/systemd/system/initiad.service
rm -rf $HOME/.initia
sudo rm /usr/local/bin/initiad
```
### Example gRPC usage
```bash
wget https://github.com/fullstorydev/grpcurl/releases/download/v1.7.0/grpcurl_1.7.0_linux_x86_64.tar.gz
tar -xvf grpcurl_1.7.0_linux_x86_64.tar.gz
chmod +x grpcurl
./grpcurl  -plaintext  localhost:$GRPC_PORT list
### MAKE SURE gRPC is enabled in app.toml
# grep -A 3 "\[grpc\]" $HOME/.initia/config/app.toml
```
### Example REST API query
```bash
curl localhost:$API_PORT/cosmos/mstaking/v1beta1/validators
### MAKE SURE API is enabled in app.toml
# grep -A 3 "\[api\]" $HOME/.initia/config/app.toml
```
### Source
- https://github.com/trusted-point/initia-tools
