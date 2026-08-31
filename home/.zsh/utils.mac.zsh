# Mac-specific utils
function list_ips() {
  ifconfig | awk '
    /^[a-z]/ {
      iface = $1
      sub(/:$/, "", iface)
    }
    /inet / && !/127.0.0.1/ {
      print iface ": " $2
    }
  '
}
