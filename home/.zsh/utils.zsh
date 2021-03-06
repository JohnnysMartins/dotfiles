function extract() {
  if [ -f $1 ]; then
    case $1 in
    *.tar.bz2) tar xvjf $1 ;;
    *.tar.gz) tar xvzf $1 ;;
    *.tbz2) tar xvjf $1 ;;
    *.tar) tar xvf $1 ;;
    *.bz2) bunzip2 $1 ;;
    *.rar) unrar x $1 ;;
    *.tgz) tar xvzf $1 ;;
    *.zip) unzip $1 ;;
    *.gz) gunzip $1 ;;
    *.7z) 7z x $1 ;;
    *.Z) uncompress $1 ;;
    *) echo "'$1' cannot be extracted via >extract<" ;;
    esac
  else
    echo "'$1' is not a valid file!"
  fi
}

function find_file() {
  local file=$1
  find / -name $file 2>/dev/null
}

function source_if_exists() {
  local file=$1

  if [[ -f "$file" ]]; then
    source "$file" &> /dev/null
  fi
}
