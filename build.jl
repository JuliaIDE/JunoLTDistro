#!/usr/local/bin/julia

# Notes:
#  * Julia binaries must be available in deps/jl-windows and deps/jl-mac
#  * The OS X Julia binaries seem to double in size when copied this way,
#    so best to repeat manually.

LTVER = "0.6.7"

plugins = [("one-more-minute/Julia-LT", "0.9.1"),
           ("one-more-minute/Juno-LT", "0.9.0"),
           ("one-more-minute/June-LT", "0.3.0"),
           ("one-more-minute/Reminisce", "0.3.2"),
           ("eldargab/LT-Opener", "0.2.0")]

disabled = Set(["LT-Opener"])

# Utils

copy(a, b) = run(`cp -r $a $b`)

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

# Grab deps

!isdir("deps") && mkdir("deps")
cd("deps") do
  if !isdir("LightTable")
    clone("http://github.com/LightTable/LightTable", LTVER)
    cd(name) do
      run(`lein clean` & `lein cljsbuild once`)
    end
  end

  for (repo, version) in plugins
    name = basename(repo)
    if !isdir(name)
      clone("http://github.com/$repo", version)
    end
  end

  for (platform, url) in ["mac"     => "0.6.2/LightTableMac.zip",
                          "windows" => "0.6.0/LightTableWin.zip",
                          "linux"   => "0.6.0/LightTableLinux.tar.gz"]
    if !isdir("lt-$platform")
      mkdir("lt-$platform")
      cd("lt-$platform") do
        loadzip("http://d35ac8ww5dfjyg.cloudfront.net/playground/bins/$url", "LightTable")
      end
    end
  end

  for (platform, url) in ["mac"     => "osx/x64/0.3/julia-0.3.1-osx10.7+.dmg",
                          "windows" => "winnt/x86/0.3/julia-0.3.1-win32.exe"]
    if !isdir("jl-$platform")
      mkdir("jl-$platform")
      cd("jl-$platform") do
        run(`curl -O https://s3.amazonaws.com/julialang/bin/$url`)
      end
    end
  end
end

# Build

if isdir("dist")
  try
    run(`rm -rf dist`) # Sometimes gives rm: dist: Directory not empty
  catch e
    run(`rm -rf dist`)
  end
end
mkdir("dist")

function appnw(folder)
  copy("deps/LightTable/deploy/core", folder)
  copy("example.behaviors", "$folder/core/misc/example.behaviors")
  copy("deps/LightTable/deploy/settings", folder)
  copy("package.json", "$folder/package.json")
  copy("Juno.html", "$folder/core/Juno.html")
  copy("juno.png", "$folder/core/juno.jpg")
  copy("icons/icon.png", "$folder/core/img/icon.png")

  for (plugin, _) in plugins
    name = basename(plugin)
    name in disabled ||
      copy("deps/$name", "$folder/plugins/$name/")
  end
end

# Mac

copy("deps/lt-mac/LightTable.app", "dist/Juno.app")

copy("icons/icon.icns", "dist/Juno.app/Contents/Resources/app.icns")
copy("Info.plist", "dist/Juno.app/Contents/Info.plist")
copy("deps/LT-Opener", "dist/Juno.app/Contents/Resources/app.nw/plugins/LT-Opener/")

appnw("dist/Juno.app/Contents/Resources/app.nw")

copy("deps/jl-mac", "dist/Juno.app/Contents/Resources/app.nw/julia")

# Windows

copy("deps/lt-windows", "dist/windows")
mv("dist/windows/LightTable.exe", "dist/windows/Juno.exe")
appnw("dist/windows")
copy("deps/jl-windows", "dist/windows/julia")
rm("dist/windows/julia/Uninstall.exe")
rm("dist/windows/julia/julia.lnk")
copy("icons/icon.ico", "dist/windows/juno.ico")

# Linux

copy("deps/lt-linux", "dist/linux")
mv("dist/linux/LightTable", "dist/linux/Juno")
appnw("dist/linux")
