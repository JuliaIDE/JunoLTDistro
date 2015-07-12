#!/usr/local/bin/julia3

# Notes:
#  * Julia binaries must be available in ../julia/jl-[mac|[windows|linux][32|64]]
#  * Atom-shell must be available in deps/lt/lighttable-0.8.0-$os

plugins = [("one-more-minute/Julia-LT", "0.9.3"),
           ("one-more-minute/Juno-LT", "0.9.2"),
           ("one-more-minute/June-LT", "0.3.0"),
           ("one-more-minute/Reminisce", "0.3.2"),
           ("eldargab/LT-Opener", "0.2.0")]

disabled = Set(["LT-Opener"])

packages = ["Jewel", "Gadfly", "DataFrames"]

# Utils

copy(a, b) = run(`cp -a $a $b`)

function clone(url, branch = "master")
  run(`git clone $url`)
  cd(basename(url)) do
    run(`git checkout $branch`)
  end
end

function rm_(f)
  if isdir(f) || isfile(f)
    try
      run(`rm -rf $f`)
    catch e
      run(`rm -rf $f`)
    end
  end
end

# Grab deps

!isdir("deps") && mkdir("deps")
cd("deps") do
  for (repo, version) in plugins
    name = basename(repo)
    if !isdir(name)
      println("Cloning plugin $name")
      clone("http://github.com/$repo", version)
    end
  end
end

# Packages

ENV["JULIA_PKGDIR"] = "packages"
Pkg.init()
for package in packages
  Pkg.add(package)
end
Pkg.update()

# Build

rm_("dist")
mkdir("dist")

function app(folder)
  isdir(folder) || mkdir(folder)
  copy("example.behaviors", "$folder/core/User/user.behaviors")
  copy("package.json", "$folder/package.json")
  copy("LightTable.html", "$folder/core/LightTable.html")
  copy("juno.png", "$folder/core/juno.png")
  copy("icons/julia.png", "$folder/core/img/icon.png")

  for (plugin, _) in plugins
    name = basename(plugin)
    name in disabled ||
      run(`cp -aH deps/$name $folder/plugins`)
  end

  mkdir("$folder/julia/packages")
  copy("packages/v0.3/", "$folder/julia/packages/")
end

# Mac

println("Oh Sex")

copy("deps/lt/LightTable.app", "dist/Juno.app")
copy("icons/julia.icns", "dist/Juno.app/Contents/Resources/app.icns")
copy("Info.plist", "dist/Juno.app/Contents/Info.plist")
copy("../julia/jl-mac", "dist/Juno.app/Contents/Resources/app/julia")
copy("deps/LT-Opener", "dist/Juno.app/Contents/Resources/app/plugins/LT-Opener/")

app("dist/Juno.app/Contents/Resources/app")

cd("dist") do
  mkdir("dmg")
  mv("Juno.app/", "dmg/Juno.app/")
  run(`ln -s /Applications dmg/Applications`)
  run(`hdiutil create juno.dmg -size 500m -ov -volname "Juno" -imagekey zlib-level=9 -srcfolder dmg`)
  rm_("dmg")
end

# Windows

for a = ["32", "64"]
  println("Windows x$a")
  copy("deps/lt/lighttable-0.8.0-windows$a", "dist/juno-windows$a")
  copy("icons/julia.ico", "dist/juno-windows$a/juno.ico")

  copy("../julia/jl-windows$a", "dist/juno-windows$a/resources/app/julia")
  rm("dist/juno-windows$a/resources/app/julia/Uninstall.exe")
  rm("dist/juno-windows$a/resources/app/julia/julia.lnk")

  app("dist/juno-windows$a/resources/app")

  mv("dist/juno-windows$a/LightTable.exe", "dist/juno-windows$a/Juno.exe")

  cd("dist") do
    run(`zip -qr9 juno-windows$a.zip juno-windows$a`)
    rm_("juno-windows$a")
  end
end

# Linux

for a = ["32", "64"]
  println("Linux x$a")
  copy("deps/lt/lighttable-0.8.0-linux$a", "dist/juno-linux$a")
  mv("dist/juno-linux$a/LightTable", "dist/juno-linux$a/Juno")

  copy("../julia/jl-linux$a", "dist/juno-linux$a/resources/app/julia")

  app("dist/juno-linux$a/resources/app")

  cd("dist") do
    run(`zip -qr9 juno-linux$a.zip juno-linux$a`)
    rm_("juno-linux$a")
    rm_("linux$a")
  end
end
