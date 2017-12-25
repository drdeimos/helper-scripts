#!/bin/bash

# This script clone index settings and mapping FROM ES
# TO another ES in template.
# Create empty index wit date in name.
# Create alias on new index.
# Copy index data via reindex API
# ES bash replication! (facepalm)

# Requirements:
# * Elasticsearch (tested on 5.6)
# * Reindex permissions in elasticsearch.yml like that:
#   reindex.remote.whitelist: [ "192.168.12.36", "192.168.49.135", "192.168.49.134", "192.168.49.133"]

FROM='192.168.49.135:9200'
TO='192.168.12.36:9200'

function copy_indice_data {
  INDEX=${1}

  curl \
    -s \
    -f \
    --connect-timeout 7200 \
    -XPOST '#{to}/_reindex?pretty' \
    -H 'Content-Type: application/json' \
    -d '{
          "source": {
            "remote": {
              "host": "http://'${FROM}'"
            },
            "index": "'${INDEX}'",
            "size": 10000
          },
          "dest": {
            "index": "'${INDEX}'"
          }
        }'
}

function get_indices {
  URL=${1}
  curl -s http://${URL}/_cat/indices|awk '{print $3}'|grep -vE '\.kibana'
}

function get_index_settings {
  URL=${1}
  INDEX=${2}

  curl -s http://${URL}/${INDEX}/_settings | \
    jq ".${INDEX}.settings" | \
    jq 'del(.index.creation_date)' | \
    jq 'del(.index.provided_name)' | \
    jq 'del(.index.uuid)' | \
    jq 'del(.index.version)' | \
    jq '.index.number_of_replicas = "0"' | \
    jq -cM ''
}

function get_index_mappings {
  URL=${1}
  INDEX=${2}

  curl -s http://${URL}/${INDEX}/_mappings |jq -cM ".${INDEX}.mappings"
}

function create_template {
  URL=${1}
  INDEX=${2}
  SETTINGS=${3}
  MAPPINGS=${4}

  curl -s -X PUT http://${URL}/_template/${INDEX} \
    -d '{
          "template": "'${INDEX}'*",
          "settings": '${SETTINGS}',
          "mappings": '${MAPPINGS}'
        }'
}

function create_index {
  URL=${1}
  INDEX=${2}
  DATE=${3}

  curl -s -X PUT "http://${URL}/${INDEX}-${DATE}"
}

function delete_alias {
  URL=${1}
  INDEX=${2}

  curl -s -X DELETE "http://${URL}/${INDEX}*/_alias/${INDEX}"
}

function create_alias {
  URL=${1}
  INDEX=${2}
  DATE=${3}

  curl -s -X POST "${TO}/_aliases?pretty" -d'
    {
        "actions" : [
            { "add" : { "index" : "'${INDEX}-${DATE}'", "alias" : "'${INDEX}'" } }
        ]
    }'
}

function reindex {
  FROM=${1}
  TO=${2}
  INDEX=${3}

  curl -XPOST "http://${TO}/_reindex?pretty" -H 'Content-Type: application/json' -d'
  {
    "source": {
      "remote": {
        "host": "http://'${FROM}'"
      },
      "index": "'${INDEX}'"
    },
    "dest": {
      "index": "'${INDEX}'"
    }
  }'
}


# Main

DATE=$(date  '+%Y.%m.%d.%H.%M')

for INDEX in $(get_indices ${FROM}); do
  SETTINGS=$(get_index_settings ${FROM} ${INDEX})
  MAPPINGS=$(get_index_mappings ${FROM} ${INDEX})

  # Create template
  echo "### Create template for ${INDEX}"
  create_template ${TO} ${INDEX} ${SETTINGS} ${MAPPINGS} | jq ''

  # Create indices
  echo "### Create index ${INDEX}"
  create_index ${TO} ${INDEX} ${DATE} | jq ''

  # Delete old alias
  echo "### Delete old alias ${INDEX}"
  delete_alias ${TO} ${INDEX} | jq ''

  # Create new alias
  echo "### Create new alias ${INDEX}"
  create_alias ${TO} ${INDEX} ${DATE} | jq ''

  # Copy index data via reindex api
  echo '### Copy index data via reindex api'
  reindex ${FROM} ${TO} ${INDEX}
done
