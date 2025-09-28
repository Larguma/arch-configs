#!/bin/bash

CURRENT_USER=larguma

pacman -Qqe > /home/$CURRENT_USER/Git/arch-configs/pkglist.txt

cd /home/$CURRENT_USER/Git/arch-configs

LOG_CONTENT=$(tail -n 300 /var/log/pacman.log 2>/dev/null)
TRANSACTION_START_LINE=$(echo "$LOG_CONTENT" | grep -n "transaction started" | tail -1 | cut -d: -f1)

if [[ -n "$TRANSACTION_START_LINE" ]]; then
    RECENT_OPS=$(echo "$LOG_CONTENT" | tail -n +$TRANSACTION_START_LINE | grep "\[ALPM\]" | grep -E "(installed|upgraded|removed)" | sed 's/.*\] //')
else
    RECENT_OPS=$(echo "$LOG_CONTENT" | grep "\[ALPM\]" | grep -E "(installed|upgraded|removed)" | tail -10 | sed 's/.*\] //')
fi

if [[ -z "$RECENT_OPS" ]]; then
    CURRENT_PKG="this should not happen"
else
    OP_COUNT=$(echo "$RECENT_OPS" | wc -l)
    
    if [[ $OP_COUNT -eq 1 ]]; then
        CURRENT_PKG="$RECENT_OPS"
    elif [[ $OP_COUNT -le 5 ]]; then
        OPERATION_TYPE=$(echo "$RECENT_OPS" | head -1 | grep -o "^[a-z]*")
        PACKAGE_NAMES=$(echo "$RECENT_OPS" | sed 's/^[a-z]* //' | sed 's/ (.*)//' | paste -sd, - | sed 's/,/, /g')
        CURRENT_PKG="${OPERATION_TYPE} ${OP_COUNT} packages: ${PACKAGE_NAMES}"
    else
        OPERATION_TYPE=$(echo "$RECENT_OPS" | head -1 | grep -o "^[a-z]*")
        CURRENT_PKG="${OPERATION_TYPE} ${OP_COUNT} packages"
    fi
fi

git add pkglist.txt
git commit -am "[pacman] $CURRENT_PKG"
git push || true