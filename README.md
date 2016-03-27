# Vizardry

                ________________ _______ _______ ______  _______
        |\     /\__   __/ ___   (  ___  (  ____ (  __  \(  ____ |\     /|
        | )   ( |  ) (  \/   )  | (   ) | (    )| (  \  | (    )( \   / )
        | |   | |  | |      /   | (___) | (____)| |   ) | (____)|\ (_) /
        ( (   ) )  | |     /   /|  ___  |     __| |   | |     __) \   /
         \ \_/ /   | |    /   / | (   ) | (\ (  | |   ) | (\ (     ) (
          \   / ___) (___/   (_/| )   ( | ) \ \_| (__/  | ) \ \__  | |
           \_/  \_______(_______|/     \|/   \__(______/|/   \__/  \_/

                    A vim plugin manager for lazy people

## Table of contents

0. [Announce](#announce)
1. [Release notes](#release-notes)
2. [Introduction](#introduction)
    1. [Why This Fork ?](#why-this-fork)
    2. [Requirements](#requirements)
    3. [Installation](#installation)
    4. [License](#license)
3. [Submodules](#how-to-use-vizardry-with-submodules)
4. [Commands](#commands)
    1. [Scry](#scry)
        1. [Number of results](#number-of-results)
        2. [Queries](#queries)
        3. [Search Options](#search-options)
    2. [Invoke](#invoke)
        1. [Display readme on Invoke](#display-readme-on-invoke)
    3. [Banish](#banish)
    4. [Unbanish](#unbanish)
    5. [Vanish](#vanish)
    6. [Evolve](#evolve)
        1. [Display readme on evolve](#display-readme-on-evolve)
        2. [Evolve from vim.org](#evolve-from-vim.org)
    7. [Vizardry](#vizardry-cmd)
    8. [Grimoire](#grimoire)
5. [Magic](#magic)
    1. [Configuration](#magic-configuration)
    2. [Commands](#magic-commands)
        1. [:Magic](#magic-cmd)
        2. [:Magicedit](#magicedit)
        3. [:Magicsplit](#magicsplit)
        4. [:Magicvsplit](#magicvsplit)
        5. [:MagicCommit](#magiccommit)
6. [Get involved](#get-involved)

## Announce

**Help wanted:** I need help in writing small piece of code to make vizardry
2.0 able to install bundles from any provider (github, bitbucket, gitlabs,
...) see [issue#3](https://github.com/dbeniamine/vizardry/issues/3).


## Release notes

Current Version: 2.0

*   v2.0 comes with several improvements:
    * Grimoires abstraction to install bundles from any provider (Grimoires
    currently available: github, bitbuckets, gitlab), see [Grimoire](#grimoire).
    * Re enabling of `:Magic` family commands with support for submodule
    mode, see [Magic](#magic)).
    * A major refactor including, several minor bug fix, and removing
    dependencies to external commands (`sed`, `grep` etc.).
    * A new documentation for developers to help Vizardry enthusiasts improve
    it.

    **Important informations**: Helps and Readme are not read from stdin anymore
    but from temporary file thus the Reader syntax have changed see:
    [here](#display-readme-on-evolve).
*   v1.4 provides several bug fix and the capability of seeing help files from
 Invoke and Evolve prompt.
*   v1.3 allow to Invoke directly from Scry, to do so, I had to modify the input
  method (using `:input()`, instead of `:getchar()`), for the user the result
  is that it is now necessary to hit 'enter' after answering a prompt from
  Vizardry
* Since v1.1, `VizardrySortScryResults` is replaced by `VizardrySearchOptions`

## Introduction

Remember back in the dark ages of 2013? When you had to search for vim plugins like a wild animal, using your browser?

In 2014, you can just type ":Invoke &lt;keyword&gt;" and Vizardry will automatically search github for the plugin you want and install it for you.

In 2015 you can even upgrade plugins from any git repo or vim.org using [:Evolve](#evolve).

As each year seems to come with a new improvement, in 2016 you are not
limited to github anymore it is possible to install plugins from bitbucket,
gitlab or virtually any others, see [Grimoire](#grimoire).


### Why this fork ?

This plugin is a fork from [Ardagnir original Vizardry
plugin](https://github.com/ardagnir/Vizardry) which adds several pretty cool
features including:

* `Grimoire` abstraction to install bundle from any providers.
+ `Vanish` command to actually remove a plugin.
+ `Evolve` command to upgrade one or every plugins see [Evolve](#evolve).
+ Complete submodule handling for people having their vim config in a git repo
(see [submodules](#how-to-use-vizardry-with-submodules)).
+ Dislay README.md file inside vim while using `:Invoke`.
+ Navigate through search results with `:Invoke`
+ Set the length of `Scry` results list.
+ Go directly from `Scry`  to `Invoke`
+ Search script written by specific user with `:Scry` and `:Invoke`
+ Automatically call `:Helptags` every time a plugin is Invoked.
+ ...


### Requirements

+ Vizardry requires [pathogen](https://github.com/tpope/vim-pathogen). But you
  already have pathogen installed, don't you?

+ It also needs git, curl, and basic \*nix commands.

+ You will probably have issues if you use a Windows OS.

### Installation

Use pathogen.

    cd ~/.vim/bundle
    git clone https://github.com/dbeniamine/vizardry

### License

Vizardry: A vim plugin manager for lazy people
Copyright (C) 2015,2016 David Beniamine. All rights reserved.
Copyright (C) 2013, James Kolb. All rights reserved.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.


## How to use Vizardry with submodules ?

Set the following variables in your vimrc:

    let g:VizardryGitMethod="submodule add"
    let g:VizardryGitBaseDir="/path/to/your/git/repo"

The second variable **must be** the root of the repo containing your vim
files.

Optionally you can set the vim commit messages (the name of the modified
plugin will always be happened in the end of the message, the proposed values
are the defaults):

    let g:VizardryCommitMsgs={'Invoke': "[Vizardry] Invoked vim submodule:",
          \'Banish': "[Vizardry] Banished vim submodule:",
          \'Vanish': "[Vizardry] Vanished vim submodule:",
          \'Evolve': "[Vizardry] Evolved vim submodule:",
          \}

Each time you `:Invoke`, `:Bannish` or `:Vanish` a module, the submodule will be correctly
updated and a minimal commit will be created.

### Note:

+ Commits created by Vizardry are not automatically pushed.
+ The `.gitmodule` is included in each commit, do not use `:Invoke`, `:Bannish`
or `:Vanish` if it contains some bad modifications.


## Commands

### Scry

`:Scry [<query>]`

+ If no <query> is given, list all invoked and banished plugins.
+ If a <query> is specified (see below), search for a script matching
<query> in title or readme and list N first results.  After the search, ̀`Scry`
will prompt you to `Invoke` a script, hit `q` to exit, or a number to `Invoke`
the corresponding script.

#### Number of results

The number of results displayed can be configured by adding the following to
your vimrc:

    let g:VizardryNbScryResults = 25

Default is 10.

#### Queries

A `<query>` can be:

+ One or several keywords
+ A query matching the github [search
api](https://developer.github.com/v3/search/#search-repositories)
+ A mix of keywords and github search fields

Additionally, Vizardry adds the following parameters that can be used alone or
in combination with a query
    + `-u <user>` (search every repositories of <user> matching 'vim')
    + `-q <grimoire>` to search on a different grimoire

#### Search options

It is possible to set some github search option in your vimrc, default
options are show forked repositories and sort by pertinence. These options
can be overwritten. For instance adding the following to your vimrc will
make vizardry show results sorted by number of stars hidding forked
repositries.

    let g:VizardrySortOptions="fork:false+sort:stars"

Any combination of github option can be used, a `+` must appear between
each options. For the sort option, available parameters are `stars`,
`forks`, `updated`, by default, it show the best match.

### Invoke

`:Invoke [<query>|N]`

+   If no arguments is specified, reload your plugins.
+   If the argument is a number, ask to install the plugin with that
    number from the last `:Scry` or Invoke.
+   If the argument is a `<query>`, search github for a plugin matching
`<query>` (see above)  and ask for install, the sort criteria for search
results can be configured (see above).

Suppose you're in the middle of vimming and you have a sudden need to surround
random words in "scare quotes". You can't remember who made the surround
plugin, or whether it's called surround.vim, vim-surround or
vim-surround-plugin. Most importantly, you're lazy.


Just type:

    :Invoke surround

Vizardry will pop up a prompt saying:

    Result 1/20: tpope/vim-surround
    (surround.vim: quoting/parenthesizing made simple)

    Clone as "surround"? (Yes/Rename/Displayreadme/displayHelp/Next/Previous/Abort)

Press Y and you can immediately start surrounding things.  You can also take a
look at the README.md directly in vim by hitting `d` or at the help using `h`,
Go to the next or previous script with `n` and `p` or abort `a`. It's that
easy.

Even plugins with vague or silly names can be found with Vizardry. Imagine
you're running multiple instances of vim and need a package to sync registers.

Type:

    :Invoke sync registers

Vizardry will prompt you with:

    Result 1/3: ardagnir/united-front
    (Automatically syncs registers between vim instances)

    Clone as "syncregisters"? (Yes/Rename/DisplayMore/Next/Previous/Abort)

Just as easy.

#### Display readme on Invoke

To view the readme, an other instance of vim is called, the command line can
be configured:

    let g:VizardryReadmeReader='view -c "set ft=markdown"'

The help file reader is also configurable, there is the default:

    let g:VizardryHelpReader='view -c "set ft=help"'

**Note:** since v2.0, the `-` in the end of the reader line is not required
anymore, please update your configuration accordingly.

Finally if readme or help is missing, Vizardry will try to search for the
other one, if you dont like this behavior, you can prevent it:

    let g:VizardryReadmeHelpFallback = 0

### Banish

`:Banish <keyword>`

Banish a plugin, this only forbid pathogen to load it and does not remove
the files. You need to restart vim to see the effects.

### UnBanish

`:Unbanish <keyword>`

Reverse a banish.

### Vanish

`:Vanish <keyword>`

Remove definitively a plugin's files.

### Evolve

`:Evolve  [<keyword> [<branch>]]`

Upgrade the plugin matching &lt;keyword&gt; using remote branche
&lt;branch&gt; if specified. If no &lt;keyword&gt; is given, upgrade
all possible plugins.

Git plugins are upgraded by doing `git pull origin branch`. Where  `branch` the
one specified in argument if any or the current branch of the local repository.
If `branch` is different from the current branch, Vizardry will first create
or checkout a local branch with the same name as the remote branch requested.

#### Display Readme On Evolve

Sometimes it can be a good idea to take a quick look at a plugin's README,
help or git log when updating, to do so, add the following to your vimrc:

    let g:VizardryViewReadmeOnEvolve=1

`:Evolve` will then ask you to display readme help or log each time a plugin is
upgraded.

#### Evolve from vim.org

**Evolving directly from vim.org is deprecated.**
To install plugin found at vim.org from github use:

    :Invoke -u vim-scripts <plugin-name>

Were &lt;plugin-name&gt; is the actual name of the plugin at vim.org

You can also search a plugin by vim.org id:

    :Invoke -u vim-scripts in:readme script_id=<id>

### <a name="vizardry-cmd">Vizardry</a>

    :Vizardry

Show a basic usage and Vizardry version.

### Grimoire

    :Grimoire [provider]

List Grimoires or select the `Grimoire` from which you want to `Scry` and
`Invoke` bundles. A grimoire is a website from which you can search for
bundles such as github or bitbucket.

It is also possible to set the default grimoire in your vimrc

    let g:VizardryDefaultGrimoire='github'

For Bitbucket and gitlab, an instance url can be supplied, here are the
defaults:

    let g:VizardryGitlabInstanceUrl='gitlab.com'
    let g:VizardryBitbucketInstanceUrl='bitbucket.org'

**Note:**

*   Bitbucket does not allow to do any filters while searching for public
repository, thus every github parameters (such as `fork:true`) but `user:name`
and `language:lang` are ignored, when using Bitbucket grimoire. For the same
reason, Bitbuckets queries does not respect `g:VizardryNbScryResults`.
*   Gitlab API is even worse, neither `user` nor ̀`language` or any other github
search options works.

# Magic

Vizardry Magic is a simple way to handle plugin specific configurations files,
these files will be Banished, Unbanished and Vanished with the bundle they
belong to.

## Magic Configuration

By default, these files are stored in `bunde/vizardry/plugin/magic`, this path
ensure that removing Vizardry will remove the magic files. As it is not always
a good idea to keep modified files in a subdirectory of an existing bundle,
this pas can be modified (and must be modified for submodule mode
[Submodules](#how-to-use-vizardry-with-submodules)). A good idea can be to
keep them in `~/.vim/plugin/magic`:

    let g:VizardryMagicDir='~/.vim/plugin/magic'


## Magic Commands

### <a name="magic-cmd">:Magic</a>

    :Magic <bundle> <command>


Adds &lt;command&gt; to &lt;bundle&gt; magic file and execute it.

### :Magicedit

    :Magicedit <bundle>

Edits magic file for &lt;bundle&gt;.

### :Magicsplit

    :Magicsplit <bundle>

Edits magic file for &lt;bundle&gt;, spliting the current window.

### :Magicvsplit

    :Magicvsplit <bundle>

Edits magic file for &lt;bundle&gt;, vspliting the current window.

### :MagicCommit

    :MagicCommit <file>

For submodule (see [Submodules](#how-to-use-vizardry-with-submodules)) mode
only: Commit the changes to the given magic file.

Does nothing in clone mode

# Get involved

## Spread the word

If you like Vizardry and you are also a vimscript developper, an easy way to
spread the word is to add a Vizardry install section to your plugins README
for instance:

If you have installed [Vizardry](https://github.com/dbeniamine/vizardry) just
run the following from vim:

    :Invoke -u <your_username> <your_plugin_name>

## Write Grimoires

Currently only github and bitbucket are available, but it is very easy to add a
new Grimoire, see [issue#3](https://github.com/dbeniamine/vizardry/issues/3)
and `:help Vizardry-Dev-grimoires`.

## Develop inside Vizardry

If you like Vizardry and want to help, you can look add `vizardry/todo.txt`
see what I improvement I'm planning to add to Vizardry.
If you are going to modify Vizardry code, please take a look at |Vizardry-Dev|
before writing any code.
Feel free to open pull requests when you are done :).
