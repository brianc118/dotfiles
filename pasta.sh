if [ $# -eq 0 ]; then
    paste.amazon.com --keep 300days
else
    if [[ "$1" == http* ]]; then
        pastUrl="$1"
        [[ "$pastUrl" != *.text ]] && pastUrl="${pastUrl}.text"
    else
        pastUrl="https://paste.amazon.com/show/$USER/$1.text"
    fi
    kcurl -s "$pastUrl"
fi

