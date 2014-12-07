#!/usr/local/bin/julia

@osx_only settings = "$(homedir())/Library/Application Support/Juno"

isdir(settings) && rm(settings, recursive = true)
