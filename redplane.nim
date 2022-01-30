#import necessary libraries
import std/os
import std/strformat
import std/strutils
import system

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

#create files
discard mkfiles()

#check the parameters and execute accordingly
when declared(commandLineParams):
  var param = "-y"
  var longParam = "--yes"
  var yesToAll = ""
  var yn = ""
  var multiplePkgs = ""

  if commandLineParams().len == 0:
    discard errorPrompt("no option specified")

  if commandLineParams().contains(param) or commandLineParams().contains(longParam):
    yesToAll = "yes"
  else:
    yesToAll = "no"

  param = "-i"
  longParam = "--install"
  var paraminput = find(commandLineParams(), param)
  var allPkgs = commandLineParams()[paraminput + 1].split(",")

  if commandLineParams().contains(param) or commandLineParams().contains(longParam):
    for i in commandLineParams()[paraminput + 1]:
      if i == ',':
        echo "multiple packages detected! attempting parse"
        multiplePkgs = "yes"
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

  param = "-h"
  longParam = "--help"
  if commandLineParams().contains(param) or commandLineParams().contains(longParam):
    echo "usage:\n -u or --update: update\n -i or --install: install (tip: you can install multiple pkgs by separating them with a comma)\n -h: help\n -t or --threads: specify amount of threads\n -y or --yes: answer yes to all prompts\n -h or --help: view usage"

  param = "-t"
  longParam = "--threads"
  if commandLineParams().contains(param) or commandLineParams().contains(longParam):
      putEnv("MAKEFLAGS", "-j" & commandLineParams()[paraminput + 2])
