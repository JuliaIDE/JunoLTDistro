#!/usr/local/bin/julia

@osx_only settings = "$(homedir())/Library/Application Support/Juno-LT"

isdir(settings) && rm(settings, recursive = true)
