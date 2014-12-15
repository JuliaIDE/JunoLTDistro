#!/usr/local/bin/julia

using Lazy

# Notes:
#  * Julia binaries must be available in ../jl-windows and ../jl-mac
#  * Atom-shell must be available in deps/atom-$os

LTVER = "atom-shell"

plugins = [("one-more-minute/Julia-LT", "0.9.3"),
           ("one-more-minute/Juno-LT", "0.9.2"),
           ("one-more-minute/June-LT", "0.3.0"),
           ("one-more-minute/Reminisce", "0.3.2"),
           ("eldargab/LT-Opener", "0.2.0")]

disabled = Set(["LT-Opener"])

# Utils

copy(a, b) = run(`cp -a $a $b`)

function clone(url, branch = "master")
  run(`git clone $url`)
  cd(basename(url)) do
    run(`git checkout $branch`)
  end
end

function loadzip(url, folder = nothing)
  file = basename(url)
  !isfile(file) && run(`curl -O $url`)
  if endswith(file, ".zip")
    run(`unzip $file`)
  elseif endswith(file, ".tar.gz")
    run(`tar -xzf $file`)
  else
    error("can't unzip $file")
  end
  rm(file)
  if folder != nothing
    mv(folder, "temp")
    for f in readdir("temp")
      mv("temp/$f", "$f")
    end
    rm("temp", recursive = true)
  end
end

function rm_(f)
  if isdir(f) || isfile(f)
    try
      run(`rm -rf $f`)
    catch e
      run (`rm -rf $f`)
    end
  end
end

# Grab deps

!isdir("deps") && mkdir("deps")
cd("deps") do
  if !isdir("LightTable")
    clone("http://github.com/LightTable/LightTable", LTVER)
    cd("LightTable") do
      run(`lein clean` & `lein cljsbuild once`)
    end
  end

  for (repo, version) in plugins
    name = basename(repo)
    if !isdir(name)
      clone("http://github.com/$repo", version)
    end
  end

  # for (platform, url) in @d("mac"     => "0.7.0/LightTableMac.zip",
  #                           "windows" => "0.7.0/LightTableWin.zip",
  #                           "linux"   => "0.7.0/LightTableLinux.tar.gz")
  #   if !isdir("lt-$platform")
  #     mkdir("lt-$platform")
  #     cd("lt-$platform") do
  #       loadzip("http://d35ac8ww5dfjyg.cloudfront.net/playground/bins/$url", "LightTable")
  #     end
  #   end
  # end
end

# Build

rm_("dist")
mkdir("dist")

function app(folder)
  isdir(folder) || mkdir(folder)
  copy("deps/LightTable/deploy/core", folder)
  copy("example.behaviors", "$folder/core/User/user.behaviors")
  copy("deps/LightTable/deploy/settings", folder)
  copy("deps/LightTable/deploy/plugins", folder)
  copy("package.json", "$folder/package.json")
  copy("LightTable.html", "$folder/core/LightTable.html")
  copy("juno.png", "$folder/core/juno.png")
  copy("icons/julia.png", "$folder/core/img/icon.png")

  for (plugin, _) in plugins
    name = basename(plugin)
    name in disabled ||
      copy("deps/$name", "$folder/plugins")
  end
end

# Mac

copy("deps/atom-mac/Juno.app", "dist/Juno.app")

# copy("icons/julia.icns", "dist/Juno.app/Contents/Resources/app.icns")

# copy("Info.plist", "dist/Juno.app/Contents/Info.plist")

app("dist/Juno.app/Contents/Resources/app")
copy("deps/LT-Opener", "dist/Juno.app/Contents/Resources/app/plugins/LT-Opener/")

copy("../jl-mac", "dist/Juno.app/Contents/Resources/app/julia")

cd("dist") do
  mkdir("dmg")
  mv("Juno.app/", "dmg/Juno.app/")
  run(`ln -s /Applications dmg/Applications`)
  run(`hdiutil create Juno.dmg -size 400m -ov -volname "Juno" -imagekey zlib-level=9 -srcfolder dmg`)
  rm_("dmg")
end

# Windows

copy("deps/atom-win", "dist/windows")
# mv("dist/windows/atom.exe", "dist/windows/Juno.exe")
mkdir("dist/windows/resources/app")
app("dist/windows/resources/app")
copy("../jl-windows", "dist/windows/resources/app/julia")
rm("dist/windows/resources/app/julia/Uninstall.exe")
rm("dist/windows/resources/app/julia/julia.lnk")
copy("icons/julia.ico", "dist/windows/juno.ico")

cd("dist") do
  run(`zip -qr9 windows.zip windows`)
  rm_("windows")
end

# Linux

copy("deps/atom-linux", "dist/linux")
mv("dist/linux/atom", "dist/linux/Juno")
app("dist/linux/resources/app")
