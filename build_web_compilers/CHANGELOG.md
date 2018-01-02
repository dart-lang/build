# 0.2.0-dev

- Renamed `ddc_bootstrap` builder to `web_entrypoint`, the exposed class also
  changed from `DevCompilerBootstrapBuilder` to `WebEntrypointBuilder`.

# 0.1.1

- Mark `ddc_bootstrap` builder with `build_to: cache`.
- Publish as `build_web_compilers`

# 0.1.0

- Add builder factories.
- Fixed temp dir cleanup bug on windows.
- Enabled support for running tests in --precompiled mode.

# 0.0.1

- Initial release with support for building analyzer summaries and DDC modules.
