alias fn_enable="echo 0 | sudo tee /sys/module/hid_apple/parameters/fnmode"

alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'

alias vpn_config='openvpn3 config-import --config ~/workarea/banqi/vpn/client.ovpn --name banqi'
alias vpn_start='openvpn3 session-start --config banqi'
alias vpn_list='openvpn3 sessions-list'
alias vpn_disconnect='openvpn3 session-manage --config banqi --disconnect'