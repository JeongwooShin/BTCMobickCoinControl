#!/usr/bin/env python3
# Public deterministic cross-check fixture for BTCMobickCoinControl.
# Uses only the well-known private scalar 1 test WIF and a fake UTXO.
# NEVER replace the WIF below with a real wallet key.

from bitcoinutils.setup import setup
from bitcoinutils.keys import PrivateKey, P2pkhAddress
from bitcoinutils.transactions import Transaction, TxInput, TxOutput
from bitcoinutils.script import Script

setup("mainnet")

WIF = "KwDiBf89QgGbjEhKnhXJuH7LrciVrZi3qYjgd9M7rFU73sVHnoWn"
ADDRESS = "1BgGZ9tcN4rm9KBzDn7KprQz87SZ26SAMH"
FAKE_TXID = "11" * 32
OUTPUT_SATS = 49_000

priv = PrivateKey(WIF)
pub = priv.get_public_key()
addr = P2pkhAddress(ADDRESS)
script_pub_key = addr.to_script_pub_key()

txin = TxInput(FAKE_TXID, 0)
txout = TxOutput(OUTPUT_SATS, script_pub_key)
tx = Transaction([txin], [txout])

sig = priv.sign_input(tx, 0, script_pub_key, sighash=0x01)
txin.script_sig = Script([sig, pub.to_hex()])
signed_hex = tx.serialize()

print(signed_hex)
