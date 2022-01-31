#Import necessary libraries
import os, strformat, strutils, parseopt


#Declare variables
var
  p = initOptParser()
  yesToAll = false
  yn: char
  multiplePkgs = false
  allPkgs: seq[string]
  usageString = """
  -h: return help
  -u: update packages in to-update file
  -i: install package  (value required) (can install multiple if separated by a comma, example: obs,telegram-desktop,linux-lqx)
  -y: answer yes to all prompts
  tip: use the flags that requite a value like -flag:value, not -flag value
"""


#Create the required procedures
proc errorPrompt(err: string) = 
  echo fmt"KABOOM! plane crash: {err}"
  quit(1)

proc pacmanInstall(pkg: string): int = 
  if execShellCmd(fmt"sudo pacman -S {pkg}") != 0:
    return 1

proc mkfiles() = 
  discard execShellCmd("touch to-update")

proc clonePkg(pkg: string) =
  discard execShellCmd(fmt"git clone https://aur.archlinux.org/{pkg}")

proc makePkg(pkg: string) =
  discard execShellCmd(fmt"(cd {pkg} && makepkg PKGBUILD)")

proc cleanUp(pkg: string) =
  discard execShellCmd(fmt"rm -rf {pkg}")

proc addToUpdateScript(pkg: string) =
  discard execShellCmd(fmt"tee -a {pkg} to-update")
 
proc installPkg(pkg: string) =
  if pacmanInstall(pkg) != 0:
    clonePkg(pkg)
    makePkg(pkg)
    cleanUp(pkg)
  else:
    echo "pacman has successfully installed the package."


#Create required files
mkfiles()


#Check if there are parameters
if paramCount() == 0:
  errorPrompt("no option specified")


#Parse options and execute
while true:
  p.next
  case p.key
  of "t":
    putEnv("MAKEFLAGS", fmt"-j{p.val}"
  of "y":
    yesToAll = true
  of "i":
    for i in p.val:
      if i == ',':
        echo "multiple packages detected! attempting parse"
        multiplePkgs = true
        allPkgs = p.val.split(",")
    if multiplePkgs:
      if yesToAll:
        for i in allPkgs:
          installPkg(i)
          addToUpdateScript(i)
      else:
        echo "would you like to install multiple packages? [y/n]: "
        yn = stdin.readChar()
        if yn == 'y':
          for i in allPkgs:
            installPkg(i)
            addToUpdateScript(i)
        else:
          echo yn
          quit(0)
    else:
      if yesToAll:
        installPkg(p.val)
        addToUpdateScript(p.val)
      else:
        echo fmt"would you like to install {p.val}? [y/n]: "
        yn = stdin.readChar()
        if yn == 'y':
          installPkg(p.val)
          addToUpdateScript(p.val)
        else:
          echo yn
          quit(0)
  of "u":
    if not yesToAll:
      echo "would you like to update? [y/n]: "
      yn = stdin.readChar()
      if yn == 'y':
        for line in lines("to-update"):
          installPkg(line)
      else:
        quit(0)
    else:
      for line in lines("to-update"):
        installPkg(line)
  of "h":
    echo usageString
  else:
    errorPrompt("invalid option.") 