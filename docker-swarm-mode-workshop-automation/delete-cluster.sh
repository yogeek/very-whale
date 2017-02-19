#!/bin/bash

NODES_LIST=("${MANAGERS_LIST[@]}" "${WORKERS_LIST[@]}")

# Deleting machines
for node in ${NODES_LIST[@]}; do
	dm rm -f $node
done

echo "Cluster deleted !"
dm use -u