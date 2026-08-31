# Linux-specific utils
function list_ips() {
  ip -4 addr show scope global | awk '
    /^[0-9]+:/ {
      iface = $2
      sub(/:$/, "", iface)
    }
    /inet / {
      ip = $2
      sub(/\/.*/, "", ip)
      print iface ": " ip
    }
  '
}
