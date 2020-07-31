# ScratchOrgButler
> A guided bash script to help building salesforce scratch orgs using SFDX and unlocked packages

[![License](http://img.shields.io/:license-mit-blue.svg)](http://doge.mit-license.org)


Table of contents
=================

<!--ts-->
   * [Table of contents](#table-of-contents)
   * [Installation](#installation)
   * [Usage](#usage)
   * [Examples](#examples)
   * [Coming Features](#coming-features)
   * [Known Issues](#known-issues)
   * [Contacts](#contacts)
<!--te-->

Installation
============
This script requires jq to run (https://stedolan.github.io/jq/download/).

- To install jq on mac
```shell
$ brew update
$ brew install jq
```

- To install jq on ubuntu
```shell
sudo apt-get install jq
```

- Download place ScratchOrgButler.sh in your saleforce DX project root
- Make it executable with 
```shell
$ chmode +x ScratchOrgButler.sh
```
Usage
============
The butler at the moment can do 3 things:

- Create a Scratch org and install Managed and Unlocked Packages
- Push packages or onlocked packages to an existing Scratch org
- Push your code on a scratch org

To get inline help you can launch

```shell
$ ./ScratchOrgButler.sh -h
```

These are the parameters you can use

* -s: This is the name of the target scratch org for cretion or installation of the packages
* -d: This is the name of devhub that will be used to retrieve the available package list and versions (you can point to another random org)
* -c: If this flag is specified the scratch org gest created
* -p: If this flag is specified the source code is pushed to the scratch org

Examples
============

This command will allow you to install packages that are installed on **DevHub** on a prexisting **TestButler** scratch org
```shell
$ ./ScratchOrgButler.sh -s TestButler -d DevHub
```

This command will create a **TestButler** scratch org allow and install packages that are installed on **DevHub**
```shell
$ ./ScratchOrgButler.sh -s TestButler -d DevHub -c
```

This command will create a **TestButler** scratch org allow and install packages that are installed on **DevHub**, and push your code on it
```shell
$ ./ScratchOrgButler.sh -s TestButler -d DevHub -c -p
```

Coming Features
============
- Customer cloning (takes an account from an org and clones it to the scracth org)
- Scratch org mass deletion
- Package uninstall

Known Issues
============
* No error management

Contacts
============
