#!/usr/local/bin/julia

@assert length(ARGS) == 1 "Version number required"

version = ARGS[1]

function release(name)
  println(name)
  to = replace(basename(name), "-signed", "")
  run(`aws cp junolab/release/$version/$to /junolab/latest/$name`)
  run(`aws put junolab/release/$version/$to?acl --public`)
end

release("signed/juno-mac-x64-signed.dmg")

for arch = ["x32", "x64"]
  release("juno-linux-$arch.zip")
  release("signed/juno-windows-$arch-signed.zip")
end
