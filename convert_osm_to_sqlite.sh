#! /bin/bash

set -o nounset
set -o errexit

ROOT=$(dirname $0)

NEW=1
DUPE=0

while getopts "rDo:d:" FLAG ; do
    case "$FLAG" in 
        r) NEW=0 ;;
        d) DATABASE_FILE=$OPTARG ;;
        o) OSM_FILE=$OPTARG ;;
        D) DUPE=1 ;;
    esac

done

if [[ $NEW = 1 ]] ; then
    echo "starting again"
    rm -f ${DATABASE_FILE}
    sqlite3 ${DATABASE_FILE} < ${ROOT}/create_database.sql
fi

#pv -N "extracting from osm" ${OSM_FILE} | python ${ROOT}/osm2tsvs.py

if [[ $DUPE = 1 ]] ; then
    sqlite3 ${DATABASE_FILE} < ${ROOT}/create_tmp_database.sql
fi

function import_file() {
    TABLE=$1
    rm -f fifo
    mkfifo fifo
    ( pv -N "importing $TABLE" ${TABLE}.tsv.gz | zcat > fifo ) &
    if [[ $DUPE = 0 ]] ; then
        if [[ $NEW = 1 ]] ; then
            echo -e ".separator \"\\\t\"\n.import fifo $TABLE" | sqlite3 ${DATABASE_FILE}
        elif [[ $NEW = 0 ]] ; then
            echo -e "create table tmp_${TABLE} as select * from ${TABLE} limit 0;\n.separator \"\\\t\"\n.import fifo tmp_$TABLE\ninsert or replace into ${TABLE} select * from tmp_${TABLE};" | sqlite3 ${DATABASE_FILE}
        fi
    elif [[ $DUPE = 1 ]] ; then
        echo -e ".separator \"\\\t\"\n.import fifo tmp_$TABLE" | sqlite3 ${DATABASE_FILE}
        rm -f fifo
        echo "removing duplicates from $TABLE..."
        sqlite3 ${DATABASE_FILE} "insert or ignore into ${TABLE} select * from tmp_${TABLE};"
    fi

    rm -f fifo
}

import_file nodes
import_file node_tags

import_file ways
import_file way_tags
import_file way_nodes

import_file relations
import_file relation_tags
import_file relation_members

rm -f nodes.tsv.gz node_tags.tsv.gz ways.tsv.gz way_tags.tsv.gz way_nodes.tsv.gz relations.tsv.gz relation_tags.tsv.gz relation_members.tsv.gz fifo

if [[ $DUPE = 1 ]] ; then
    sqlite3 ${DATABASE_FILE} "drop table tmp_nodes;"
    sqlite3 ${DATABASE_FILE} "drop table tmp_node_tags;"
    sqlite3 ${DATABASE_FILE} "drop table tmp_ways;"
    sqlite3 ${DATABASE_FILE} "drop table tmp_way_tags;"
    sqlite3 ${DATABASE_FILE} "drop table tmp_way_nodes;"
    sqlite3 ${DATABASE_FILE} "drop table tmp_relations;"
    sqlite3 ${DATABASE_FILE} "drop table tmp_relation_tags;"
    sqlite3 ${DATABASE_FILE} "drop table tmp_relation_members;"
fi

sqlite3 ${DATABASE_FILE} "VACUUM;"
