#!/bin/sh

# include as library

usermgmt_clean() {
    # shellcheck disable=SC3043
    local uname="$1" uid="$2" gid="$3"
    uname="$(printf '%s' "$uname" | sed 's#[.[\(*^$+?{|/]#\\&#g')"
    [ -e /etc/passwd ] &&
        sed -i- -E "/^($uname|([^:]*:){2}$uid|([^:]*:){3}$gid):/d" /etc/passwd
    [ -e /etc/shadow ] &&
        sed -i- -E "/^$uname:/d" /etc/shadow
    [ -e /etc/group ] &&
        sed -i- -E "/^($uname|([^:]*:){2}$gid|"`
            `"([^:]*:){3}([^,]*,)*$uname(,|$)):/d" /etc/group
    [ -e /etc/gshadow ] &&
        sed -i- -E "/^($uname|"`
            `"([^:]*:){3}([^,]*,)*$uname(,|:)|"`
            `"([^:]*:){4}([^,]*,)*$uname(,|$)):/d" /etc/gshadow
}

if grep -q 'ID=alpine' /etc/os-release; then
    usermgmt_add() {
        # shellcheck disable=SC3043
        local uname="$1" uid="$2" gid="$3"; shift 3
        addgroup -g "$gid" -S "$uname"
        adduser -g "$uname" -G "$uname" -D -u "$uid" "$uname" "$@"

    }
    usermgmt_add_system() {
        usermgmt_add "$@" -S -H -h /dev/null -s /sbin/nologin
    }
else
    usermgmt_add() {
        # shellcheck disable=SC3043
        local uname="$1" uid="$2" gid="$3" i no_create_home; shift 3
        groupadd --gid="$gid" "$uname"
        useradd --comment "$uname" --gid="$uname" \
                --uid="$uid" "$uname" "$@"
        no_create_home=
        for i in "$@"; do
            if [ "$i" = "--no-create-home" ] || [ "$i" = "-M" ]; then
                no_create_home=yes
            fi
        done
        if [ -z "$no_create_home" ]; then
            mkdir -p /home/"$uname"
        fi
    }
    usermgmt_add_system() {
        usermgmt_add "$@" --no-create-home \
                     --home-dir=/nonexistent \
                     --shell=/usr/sbin/nologin
    }
fi
