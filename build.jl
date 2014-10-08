LTVER = "0.6.7"

plugins = [("one-more-minute/Julia-LT", "0.9.1"),
           ("one-more-minute/Juno-LT", "0.9.0"),
           ("one-more-minute/June-LT", "0.3.0"),
           ("one-more-minute/Reminisce", "0.3.2"),
           ("eldargab/LT-Opener", "0.2.0")]

# Utils

copy(a, b) = run(`cp -r $a $b`)

function clone(url, branch = "master")
  run(`git clone $url`)
  cd(basename(url)) do
    run(`git checkout $branch`)
  end
end

function loadzip(url, folder = "LightTable")
  file = basename(url)
  run(`curl -O $url`)
  if endswith(file, ".zip")
    run(`unzip $file`)
  elseif endswith(file, ".tar.gz")
    run(`tar -xzf $file`)
  else
    error("can't unzip $file")
  end
  rm(file)
  mv(folder, "temp")
  for f in readdir("temp")
    mv("temp/$f", "$f")
  end
  rm("temp", recursive = true)
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

  for (platform, url) in ["mac"    =>"http://d35ac8ww5dfjyg.cloudfront.net/playground/bins/0.6.2/LightTableMac.zip",
                          "windows"=>"http://d35ac8ww5dfjyg.cloudfront.net/playground/bins/0.6.0/LightTableWin.zip",
                          "linux"  =>"http://d35ac8ww5dfjyg.cloudfront.net/playground/bins/0.6.0/LightTableLinux.tar.gz"]
    if !isdir(platform)
      mkdir(platform)
      cd(platform) do
        loadzip(url)
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
  copy("deps/LightTable/deploy/settings", folder)
  copy("package.json", "$folder/package.json")
  copy("Juno.html", "$folder/core/Juno.html")
  copy("juno.jpg", "$folder/core/juno.jpg")
  copy("icons/icon.png", "$folder/core/img/icon.png")
end

# Mac

copy("deps/mac", "dist/mac")
mv("dist/mac/LightTable.app", "dist/mac/Juno.app")
mv("dist/mac/light", "dist/mac/juno")

copy("icons/icon.icns", "dist/mac/Juno.app/Contents/Resources/app.icns")
copy("Info.plist", "dist/mac/Juno.app/Contents/Info.plist")

appnw("dist/mac/Juno.app/Contents/Resources/app.nw")

# Windows

copy("deps/windows", "dist/windows")
mv("dist/windows/LightTable.exe", "dist/windows/Juno.exe")
appnw("dist/windows")

# Linux

copy("deps/linux", "dist/linux")
mv("dist/linux/LightTable", "dist/linux/Juno")
appnw("dist/linux")
