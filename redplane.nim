#Import necessary libraries
import os, strformat, strutils, parseopt

#Declare variables
var
  p = initOptParser()
  yesToAll = ""
  yn = ""
  multiplePkgs = ""
  allPkgs = newSeq[string]
  usageString = """
  -h: return help
  -u: update packages in to-update file
  -i: install package  (value required) (can install multiple if separated by a comma, example: obs,telegram-desktop,linux-lqx)
  -y: answer yes to all prompts
  tip: use the flags that requite a value like -flag:value, not -flag value
"""

#Create the required procedures
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
  else:
    echo "pacman has successfully installed the package."

#Create required files
discard mkfiles()

#Check if there are parameters
if commandLineParams().len == 0:
  discard errorPrompt("no option specified")

#Parse options and execute
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
          discard installPkg(i)
          discard addToUpdateScript(i)
      else:
        echo "would you like to install those packages [y/n]: ", allPkgs
        yn = readLine(stdin)
        if yn == "y":
          for i in allPkgs:
            discard installPkg(i)
            discard addToUpdateScript(i)
        else:
          echo yn
          quit(0)
    else:
      if yesToAll == "yes":
        discard installPkg(p.val)
        discard addToUpdateScript(p.val)
      else:
        echo "would you like to install this package [y/n]: ", p.val
        yn = readLine(stdin)
        if yn == "y":
          discard installPkg(p.val)
          discard addToUpdateScript(p.val)
        else:
          echo yn
          quit(0)
  of "u":
    if yesToAll == "no":
      echo "would you like to update? [y/n]: "
      yn = stdin.readLine()
      if yn == "y":
        for line in lines("to-update"):
          discard installPkg(line)
      else:
        quit(0)
    else:
      for line in lines("to-update"):
        discard installPkg(line)
  of "h":
    echo usageString
  else:
    errorPrompt("invalid option.")
