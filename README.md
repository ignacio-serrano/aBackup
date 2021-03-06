aBackup
=======

A quick and dirty backup tool for Windows

TODO:
-----
  * Make configuranble how many backups must be kept in a repository before
    removing the oldest one.
  * `restore` command always asks to choose one backup (unless there is only
    one in the repository). Add a parameter to allow choosing one beforehand.
    This way, user interaction can be optional.
  * `restore` command doesn't have into account that there can be files already
    existing in the target directory which may have to deleted. Add parameters
    to handle that.
  * Repositories only allow to backup one directory. Enable several different
    directories.
  * Investigate how to make a simple installer/uninsitaller.
    * Take a look at [IEXPRESS](https://ss64.com/nt/iexpress.html).
  * Find a way to schedule execution of a bat file (see SchTasks.exe).
  * Add an -L option to display licenses.
  * \[DONE\] Implement command `restore`.
    * \[DONE\] Offer the user the possibility to choose between all the backups.
  * \[DONE\] Make aBackup.bat to allow to do custom on-demand backups.
  * \[DONE\] :findoutInstall seems unable to identify the installation directory
    in the PATH when the program is invoked without extension. Fix it.
  * \[DONE: Or so it seems, in rinse-n-repeat.bat\] Find out how to get a timestamp for the zip filename.
  * \[DONE\] Find a command which can zip what I want to.
  * \[DONE\] Create this repository.

Project layout
--------------
  * `src`: Here it is where source code is.
    * `main`: Here it is where source code meant to be part of the application
              lives. It is here just in case I want to add a `test` directory
              some day.
  * `cmd`: Useful executables for development.
  * `dependencies`: Contains third party libraries and installers required by
                    `aBackup` for easier installation.

Technical notes
---------------
In order to simplify user commands, it could be interesting to keep some
configuration files in a global or user dependant path. I'm thinking in wherever
`%USERPROFILE%` points to.

---
Below, a markdown cheatsheet.

Heading
=======
Sub-heading
-----------
### Another deeper heading

---

Paragraphs are separated
by a blank line.

Two spaces at the end of a line leave a  
line break.

Text attributes _italic_, *italic*, __bold__, **bold**, `monospace`.

Bullet list:

  * apples
  * oranges
  * pears

Numbered list:

  1. apples
  2. oranges
  3. pears

A [link](http://example.com).

```javascript
function {
  //Javascript highlighted code block.
}
```

    {
    Code block without highlighting.
    }
