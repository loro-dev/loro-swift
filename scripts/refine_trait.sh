#!/bin/bash

set -euxo pipefail
THIS_SCRIPT_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
SWIFT_FOLDER="$THIS_SCRIPT_DIR/../gen-swift"
file_path="$SWIFT_FOLDER/loro.swift"

search_string="public protocol LoroValueLike : AnyObject {"
replace_string="public protocol LoroValueLike : Any {"


sed -i '' "s|$search_string|$replace_string|g" "$file_path"

search_string="public protocol ContainerIdLike : AnyObject {"
replace_string="public protocol ContainerIdLike : Any {"

sed -i '' "s|$search_string|$replace_string|g" "$file_path"
