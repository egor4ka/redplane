#import necessary libraries
import std/os
import std/strformat
import std/strutils
import parseopt

var
  p = initOptParser()
  yesToAll = ""
  yn = ""
  multiplePkgs = ""
  allPkgs = newSeq[string]
  
#create procedures
proc errorPrompt(err: string): int =
  echo fmt"KABOOM! plane crash: {err}"
  quit(1)
proc pacmanInstall(pkg: string): int =
  if execShellCmd(fmt"sudo pacman -S {pkg}") != 0:
    return 1
proc mkfiles(): int =
  discard execShellCmd("touch to-update")
  return 0
proc clonePkg(pkg: string): int =
  discard execShellCmd(fmt"git clone https://aur.archlinux.org/{pkg}")
proc makePkg(pkg: string): int =
  discard execShellCmd(fmt"(cd {pkg} && makepkg PKGBUILD)")
  return 0
proc cleanUp(pkg: string): int =
  discard execShellCmd(fmt"rm -rf {pkg}")
  return 0
proc addToUpdateScript(pkg: string): int =
  discard execShellCmd(fmt"tee -a {pkg} to-update")
  return 0
proc installPkg(pkg: string): int =
  if pacmanInstall(pkg) != 0:
    discard clonePkg(pkg)
    discard makePkg(pkg)
    discard cleanUp(pkg)
    discard addToUpdateScript(pkg)
  else:
    echo "pacman has successfully installed the package."

#create files
discard mkfiles()

#check the parameters and execute accordingly
when declared(commandLineParams):




  if commandLineParams().contains(param) or commandLineParams().contains(longParam):
  
  else:
    yesToAll = "no"

  param = "-i"
  longParam = "--install"
  var paraminput = find(commandLineParams(), param)
  var allPkgs = commandLineParams()[paraminput + 1].split(",")

  if commandLineParams().contains(param) or commandLineParams().contains(longParam):
    for i in commandLineParams()[paraminput + 1]:
       if multiplePkgs == "yes":
      for i in allPkgs:
        if pacmanInstall(i) != 0:
          if yesToAll == "no":
            echo "pacman fckd up. wanna try aur? [y/n]: "
            var yn = stdin.readLine()
            if yn == "y":
              discard clonePkg(i)
              discard makePkg(i)
              discard cleanUp(i)
              discard addToUpdateScript(i)
              quit(0)
            else:
              quit(0)
          else:
            discard clonePkg(i)
            discard makePkg(i)
            discard cleanUp(i)
            discard addToUpdateScript(i)
    else:
      if pacmanInstall(commandLineParams()[paraminput + 1]) != 0:
        if yesToAll == "no":
          echo "pacman fckd up. wanna try aur? [y/n]: "
          var yn = stdin.readLine()
          if yn == "y":
            discard clonePkg(commandLineParams()[paraminput + 1])
            discard makePkg(commandLineParams()[paraminput + 1])
            discard cleanUp(commandLineParams()[paraminput + 1])
            discard addToUpdateScript(commandLineParams()[paraminput + 1])
            quit(0)
          else:
            quit(0)
        else:
          discard clonePkg(commandLineParams()[paraminput + 1])
          discard makePkg(commandLineParams()[paraminput + 1])
          discard cleanUp(commandLineParams()[paraminput + 1])
          discard addToUpdateScript(commandLineParams()[paraminput + 1])

  param = "-u"
  longParam = "--update"
  if commandLineParams().contains(param) or commandLineParams().contains(longParam):
    if yesToAll == "no":
      yn = stdin.readLine()
      if yn == "y":
        for line in lines("to-update"):
          discard clonePkg(line)
          discard makePkg(line)
          discard cleanUp(line)
      else:
        quit(0)
    else:
      for line in lines("to-update"):
        discard clonePkg(line)
        discard makePkg(line)
        discard cleanUp(line)

if commandLineParams().len == 0:
  discard errorPrompt("no option specified")

while true:
  p.next
  case p.key
  of "t":
    putEnv("MAKEFLAGS", fmt"-j{p.val}" 
  of "y":
    yesToAll = "yes"
  of "i":
    for i in p.val:
      if i == ',':
        echo "multiple packages detected! attempting parse"
        multiplePkgs = "yes"
        allPkgs = p.val.split(",")
    if multiplePkgs == "yes":
      if yesToAll == "yes":
        for i in allPkgs:
          installPkg(i)
      else:
        echo "would you like to install those packages [y/n]: ", allPkgs
        yn = readLine(stdin)
        if yn == "y":
          for i in allPkgs:
            installPkg(i)
        else:
          echo yn
          quit(0)
    else:
      if yesToAll == "yes":
        installPkg(p.val)
      else:
        echo "would you like to install this package [y/n]: ", p.val
        yn = readLine(stdin)
        if yn == "y":
          installPkg(p.val)
        else:
          echo yn
          quit(0)
