#!/usr/bin/env bash

export PGUSER=$1
export PGPASSWORD=$2
export PGHOST=$3

if [ ! "$PGHOST" ]; then
    echo "Usage is install.sh username password host"
    exit 1
fi

set -e

function script_dir {
  val="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  echo "$val"
}

base=$(script_dir)

echo
echo "Installing Database"
echo "Version: $(cat $base/VERSION.txt)"
echo "= = ="

if [ -z ${DATABASE_NAME+x} ]; then
  database=message_store
  echo "DATABASE_NAME is not set. Using: $database."
  export DATABASE_NAME=$database
else
  database=$DATABASE_NAME
fi

if [ -z ${PGOPTIONS+x} ]; then
  export PGOPTIONS='-c client_min_messages=warning'
fi

function create-schema {
  echo "» message_store schema"
  psql $database -q -f $base/schema/message-store.sql
}

function create-extensions {
  base=$(script_dir)

  echo "» pgcrypto extension"
  psql $database -q -f $base/extensions/pgcrypto.sql
}

function create-table {
  base=$(script_dir)

  echo "» messages table"
  psql $database -q -f $base/tables/messages.sql
}

echo

echo "Creating Schema"
echo "- - -"
create-schema
echo

echo "Creating Extensions"
echo "- - -"
create-extensions
echo

echo "Creating Table"
echo "- - -"
create-table
echo

# Install functions
source $base/install-functions.sh

# Install indexes
source $base/install-indexes.sh

# Install views
source $base/install-views.sh

echo "= = ="
echo "Done Installing Database"
echo "Version: $(cat $base/VERSION.txt)"
echo
