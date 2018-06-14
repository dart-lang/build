When running on windows there are a few quick tips that can help your file I/O
performance.

## Exclude your package directory from Windows Defender

You can exclude your package entirely from windows defender by following
[these instructions](https://support.microsoft.com/en-us/help/4028485/windows-10-add-an-exclusion-to-windows-defender-antivirus).

This gives significant speed improvements (~2x in some light testing), but
also comes with some obvious security considerations.

### Security Considerations

By opting into this you are potentially opening yourself up to vulnerabilities.
Any `Builder` which is being applied to your package will no longer have its
outputs checked by Windows Defender. If you don't trust your (even transitive!)
dependencies then you should be wary of this option.

Note that the original package dependency sources are not in your package
directory but instead in your pub cache, so they will still be processed by
windows defender.

## Hide your output directories and the `.dart_tool` directory from your IDE

It is common for IDEs to run file watchers on your entire package in order to
update the file tree view among other things. Explicitly telling them to ignore
the `.dart_tool` directory and any directories that you commonly use with `-o`
can give a decent performance improvement.

In `VsCode` you can do this using the `files.exclude` option in your
preferences.

In `Intellij` you can right click on a directory, select `Mark Directory as`,
and choose `Excluded`.
