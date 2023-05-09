#!/usr/bin/env bash

# 设置各变量
WSPATH=${WP:-'argo'}
UUID=${UUID:-'de04add9-5c68-8bab-950c-08cd5320df18'}
WEB_USERNAME=${WU:-'admin'}
WEB_PASSWORD=${WPD:-'password'}

generate_config() {
  cat > /tmp/config.json << EOF
{
    "log":{
        "access":"/dev/null",
        "error":"/dev/null",
        "loglevel":"none"
    },
    "inbounds":[
        {
            "port":8080,
            "protocol":"vless",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}",
                        "flow":"xtls-rprx-vision"
                    }
                ],
                "decryption":"none",
                "fallbacks":[
                    {
                        "dest":3001
                    },
                    {
                        "path":"${WSPATH}l",
                        "dest":3002
                    },
                    {
                        "path":"${WSPATH}",
                        "dest":3003
                    },
                    {
                        "path":"${WSPATH}j",
                        "dest":3004
                    },
                    {
                        "path":"${WSPATH}s",
                        "dest":3005
                    }
                ]
            },
            "streamSettings":{
                "network":"tcp"
            }
        },
        {
            "port":3001,
            "listen":"127.0.0.1",
            "protocol":"vless",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}"
                    }
                ],
                "decryption":"none"
            },
            "streamSettings":{
                "network":"ws",
                "security":"none"
            }
        },
        {
            "port":3002,
            "listen":"127.0.0.1",
            "protocol":"vless",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}",
                        "level":0
                    }
                ],
                "decryption":"none"
            },
            "streamSettings":{
                "network":"ws",
                "security":"none",
                "wsSettings":{
                    "path":"${WSPATH}l"
                }
            },
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls"
                ],
                "metadataOnly":false
            }
        },
        {
            "port":3003,
            "listen":"127.0.0.1",
            "protocol":"vmess",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}",
                        "alterId":0
                    }
                ]
            },
            "streamSettings":{
                "network":"ws",
                "wsSettings":{
                    "path":"${WSPATH}"
                }
            },
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls"
                ],
                "metadataOnly":false
            }
        },
        {
            "port":3004,
            "listen":"127.0.0.1",
            "protocol":"trojan",
            "settings":{
                "clients":[
                    {
                        "password":"${UUID}"
                    }
                ]
            },
            "streamSettings":{
                "network":"ws",
                "security":"none",
                "wsSettings":{
                    "path":"${WSPATH}j"
                }
            },
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls"
                ],
                "metadataOnly":false
            }
        },
        {
            "port":3005,
            "listen":"127.0.0.1",
            "protocol":"shadowsocks",
            "settings":{
                "clients":[
                    {
                        "method":"chacha20-ietf-poly1305",
                        "password":"${UUID}"
                    }
                ],
                "decryption":"none"
            },
            "streamSettings":{
                "network":"ws",
                "wsSettings":{
                    "path":"${WSPATH}s"
                }
            },
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls"
                ],
                "metadataOnly":false
            }
        }
    ],
    "dns":{
        "servers":[
            "https+local://8.8.8.8/dns-query"
        ]
    },
    "outbounds":[
        {
            "protocol":"freedom"
        },
        {
            "tag":"WARP",
            "protocol":"wireguard",
            "settings":{
                "secretKey":"uOAJ/35jV6/jMTUBx1zLpCw1qXkIqD0tSBizAg0flG0=",
                "address":[
                    "172.16.0.2/32",
                    "fd01:5ca1:ab1e:823e:e094:eb1c:ff87:1fab/128"
                ],
                "peers":[
                    {
                        "publicKey":"bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
                        "endpoint":"162.159.193.10:2408"
                    }
                ]
            }
        }
    ],
    "routing":{
        "domainStrategy":"AsIs",
        "rules":[
            {
                "type":"field",
                "domain":[
                    "domain:openai.com",
                    "domain:ai.com"
                ],
                "outboundTag":"WARP"
            }
        ]
    }
}
EOF
}

generate_argo() {
  cat > /tmp/argo.sh << ABC
#!/usr/bin/env bash

argo_type() {
  [[ \$ARGO_AUTH =~ TunnelSecret ]] && echo \$ARGO_AUTH > /tmp/tunnel.json && cat > /tmp/tunnel.yml << EOF
tunnel: \$(cut -d\" -f12 <<< \$ARGO_AUTH)
credentials-file: /tmp/tunnel.json
protocol: h2mux

ingress:
  - hostname: \$ARGO_DOMAIN
    service: http://localhost:8080
  - hostname: \$WEB_DOMAIN
    service: http://localhost:3000
EOF

  [ -n "\${SSH_DOMAIN}" ] && cat >> /tmp/tunnel.yml << EOF
  - hostname: \$SSH_DOMAIN
    service: http://localhost:2222
EOF
      
  cat >> /tmp/tunnel.yml << EOF
    originRequest:
      noTLSVerify: true
  - service: http_status:404
EOF
}

export_list() {
  VMESS="{ \"v\": \"2\", \"ps\": \"Choreo-VM-$v4l$v4\", \"add\": \"2606:4700::\", \"port\": \"443\", \"id\": \"${UUID}\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"${ARGO_DOMAIN}\", \"path\": \"/${WSPATH}?ed=2048\", \"tls\": \"tls\", \"sni\": \"${ARGO_DOMAIN}\", \"alpn\": \"\" }"

  cat > /tmp/list << EOF
*******************************************
V2-rayN:
----------------------------
vless://${UUID}@[2606:4700::]:443?encryption=none&security=tls&sni=${ARGO_DOMAIN}&type=ws&host=${ARGO_DOMAIN}&path=%2F${WSPATH}l?ed=2048#Choreo-Vl-$v4l$v4
----------------------------
vmess://\$(echo \$VMESS | base64 -w0)
----------------------------
trojan://${UUID}@[2606:4700::]:443?security=tls&sni=${ARGO_DOMAIN}&type=ws&host=${ARGO_DOMAIN}&path=%2F${WSPATH}t?ed=2048#Choreo-TJ-$v4l$v4
----------------------------
ss://$(echo "chacha20-ietf-poly1305:${UUID}@[2606:4700::]:443" | base64 -w0)@[2606:4700::]:443#Choreo-SS-$v4l$v4
由于该软件导出的链接不全，请自行处理如下: 传输协议: WS ， 伪装域名: \${ARGO_DOMAIN} ，路径: ${WSPATH}s?ed=2048 ， 传输层安全: tls ， sni: \${ARGO_DOMAIN}
*******************************************
小火箭:
----------------------------
vless://${UUID}@[2606:4700::]:443?encryption=none&security=tls&type=ws&host=${ARGO_DOMAIN}&path=/${WSPATH}l?ed=2048&sni=${ARGO_DOMAIN}#Choreo-Vl-$v4l$v4
----------------------------
vmess://$(echo "none:${UUID}@[2606:4700::]:443" | base64 -w0)?remarks=Choreo-VM-$v4l$v4&obfsParam=${ARGO_DOMAIN}&path=/${WSPATH}?ed=2048&obfs=websocket&tls=1&peer=${ARGO_DOMAIN}&alterId=0
----------------------------
trojan://${UUID}@[2606:4700::]:443?peer=${ARGO_DOMAIN}&plugin=obfs-local;obfs=websocket;obfs-host=${ARGO_DOMAIN};obfs-uri=/${WSPATH}j?ed=2048#Choreo-TJ-$v4l$v4
----------------------------
ss://$(echo "chacha20-ietf-poly1305:${UUID}@[2606:4700::]:443" | base64 -w0)?obfs=wss&obfsParam=${ARGO_DOMAIN}&path=/${WSPATH}s?ed=2048#Choreo-SS-$v4l$v4
*******************************************
Clash:
----------------------------
- {name: Choreo-Vl-$v4l$v4, type: vless, server: 2606:4700::, port: 443, uuid: ${UUID}, tls: true, servername: ${ARGO_DOMAIN}, skip-cert-verify: false, network: ws, ws-opts: {path: /${WSPATH}-vless?ed=2048, headers: { Host: ${ARGO_DOMAIN}}}, udp: true}
----------------------------
- {name: Choreo-VM-$v4l$v4, type: vmess, server: 2606:4700::, port: 443, uuid: ${UUID}, alterId: 0, cipher: none, tls: true, skip-cert-verify: true, network: ws, ws-opts: {path: /${WSPATH}-vmess?ed=2048, headers: {Host: ${ARGO_DOMAIN}}}, udp: true}
----------------------------
- {name: Choreo-TJ-$v4l$v4, type: trojan, server: 2606:4700::, port: 443, password: ${UUID}, udp: true, tls: true, sni: ${ARGO_DOMAIN}, skip-cert-verify: false, network: ws, ws-opts: { path: /${WSPATH}-trojan?ed=2048, headers: { Host: ${ARGO_DOMAIN} } } }
----------------------------
- {name: Choreo-SS-$v4l$v4, type: ss, server: [2606:4700::], port: 443, cipher: chacha20-ietf-poly1305, password: ${UUID}, plugin: v2ray-plugin, plugin-opts: { mode: websocket, host: ${ARGO_DOMAIN}, path: /${WSPATH}-shadowsocks?ed=2048, tls: true, skip-cert-verify: false, mux: false } }
*******************************************
EOF
  cat /tmp/list
}

argo_type
export_list
ABC
}

generate_pm2_file() {
  [[ $ARGO_AUTH =~ TunnelSecret ]] && ARGO_ARGS="tunnel --edge-ip-version auto --config /tmp/tunnel.yml run"
  [[ $ARGO_AUTH =~ ^[A-Z0-9a-z=]{120,250}$ ]] && ARGO_ARGS="tunnel --edge-ip-version auto --protocol h2mux run --token ${ARGO_AUTH}"

  TLS=${NEZHA_TLS:+'--tls'}

  cat > /tmp/ecosystem.config.js << EOF
module.exports = {
  "apps":[
      {
          "name":"web",
          "script":"/home/choreouser/web.js run -c /tmp/config.json"
      },
      {
          "name":"argo",
          "script":"cloudflared",
          "args":"${ARGO_ARGS}"
EOF

  [[ -n "${NEZHA_SERVER}" && -n "${NEZHA_PORT}" && -n "${NEZHA_KEY}" ]] && cat >> /tmp/ecosystem.config.js << EOF
      },
      {
          "name":"nezha",
          "script":"/home/choreouser/nezha-agent",
          "args":"-s ${NEZHA_SERVER}:${NEZHA_PORT} -p ${NEZHA_KEY} ${TLS}"
EOF
  
  [ -n "${SSH_DOMAIN}" ] && cat >> /tmp/ecosystem.config.js << EOF
      },
      {
          "name":"ttyd",
          "script":"/home/choreouser/ttyd",
          "args":"-c ${WEB_USERNAME}:${WEB_PASSWORD} -p 2222 bash"
EOF

  cat >> /tmp/ecosystem.config.js << EOF
      }
  ]
}
EOF
}

UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36" &&\
v4=$(curl -s4m6 ip.sb -k) &&\
v4l=`curl -sm6 --user-agent "${UA_Browser}" http://ip-api.com/json/$v4?lang=zh-CN -k | cut -f2 -d"," | cut -f4 -d '"'` &&\  

generate_config
generate_argo
generate_pm2_file

[ -e /tmp/argo.sh ] && bash /tmp/argo.sh
[ -e /tmp/ecosystem.config.js ] && pm2 start /tmp/ecosystem.config.js
