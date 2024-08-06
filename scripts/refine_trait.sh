#!/bin/bash

file_path="Sources/Loro/loroFFI.swift"

search_string="public protocol LoroValueLike : AnyObject {"
replace_string="public protocol LoroValueLike : Any {"


sed -i '' "s|$search_string|$replace_string|g" "$file_path"
