#!/usr/bin/env bash

function _md5()
{
  if which md5sum > /dev/null; then
    echo -n $1 | md5sum | cut -d " " -f1
  else
    md5 -q -s $1
  fi
}

USAGE="$(basename "$0") [-e] [-g] user -- Find the email address of any GitHub user

Where:
    -h, --help Help: display this help message
    -e Event log: show all emails that appear in the user's event log
    -g Gravatar match: attempt to match an event email to the user's Gravatar ID"

if [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ -z "$1" ] ; then
  echo "$USAGE"
  exit
fi

if [ "$1" == "-e" ] || [ "$1" == "-g" ] ; then
  if [ -z "$2" ] ; then
    echo "$USAGE"
    exit
  fi

  USER=$2
  EVENTRESPONSE=`curl -s https://api.github.com/users/$USER/events/public`
  EMAILS=`echo "$EVENTRESPONSE" | grep "\"email\":" | sed -e's/[,|"]//g' | sort | uniq -c | sort -n | awk '{print $(NF)}' | grep -v null`
  
  if [ "$1" == "-g" ] ; then
    PROFILERESPONSE=`curl -s https://api.github.com/users/$USER`
    GID=`echo "$PROFILERESPONSE" | grep "\"gravatar_id\":" | sed -e's/[,|"]//g' | awk '{print $(NF)}'`
    for EMAIL in $EMAILS ; do
      if [ $GID == `_md5 $EMAIL` ] ; then
        echo "$EMAIL"
      fi
    done
  else
    if [ -n "$EMAILS" ] ; then
      echo "$EMAILS"
    fi
  fi
  exit
fi

USER=$1
PROFILERESPONSE=`curl -s https://api.github.com/users/$USER`
EMAIL=`echo "$PROFILERESPONSE" | grep "\"email\":" | sed -e's/[,|"]//g' | awk '{print $(NF)}' | grep -v null`

if [ -z "$EMAIL" ] ; then
  EVENTRESPONSE=`curl -s https://api.github.com/users/$USER/events/public`
  EMAIL=`echo "$EVENTRESPONSE" | grep "\"email\":" | sed -e's/[,|"]//g' | sort | uniq -c | sort -n | awk '{print $(NF)}' | grep -v null | tail -n1`
fi

if [ -n "$EMAIL" ] ; then
  echo "$EMAIL"
  exit
fi

exit 1
