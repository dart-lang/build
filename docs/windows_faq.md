When running on windows there are a few quick tips that we recommend to help
your file I/O performance.

## Exclude your package directory from Windows Defender

The build system does a lot of file I/O, especially when using the `-o` option
or running tests.

You can exclude your package entirely from windows defender by following
[these instructions](https://support.microsoft.com/en-us/help/4028485/windows-10-add-an-exclusion-to-windows-defender-antivirus).

You can also just exclude the `.dart_tool/build` and any output directories
explicitly if you prefer.

## Hide your output directories and the `.dart_tool` directory from your IDE

It is common for IDEs to run file watchers on your entire package in order to
update the file tree view among other things. Explicitly telling them to ignore
the `.dart_tool` directory and any directories that you commonly use with `-o`
can give a decent performance improvement.

In `VsCode` you can do this using the `files.exclude` option in your
preferences.

In `Intellij` you can right click on a directory, select `Mark Directory as`,
and choose `Excluded`.
