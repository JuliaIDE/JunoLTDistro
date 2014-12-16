#!/usr/local/bin/julia

function upload(f)
  println(f)
  `aws put junolab/$(basename(f)) $f --public --progress` |> run
end

upload("dist/juno.dmg")
upload("dist/windows.zip")
