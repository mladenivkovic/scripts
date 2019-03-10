#!/bin/bash

# This scripts expects a path type variable
# and adds newlines when a new directory starts.


echo "$1" | sed 's/:/\n/g'
