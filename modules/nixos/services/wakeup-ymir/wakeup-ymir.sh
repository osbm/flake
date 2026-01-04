#!/usr/bin/env bash

echo "Sending Wake-on-LAN packet to ymir at 6 AM..."
wakeonlan 04:7c:16:e6:d9:13
echo "WoL packet sent to ymir successfully"
