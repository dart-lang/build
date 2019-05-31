# Using build_runner with Travis for incremental CI builds

One of the nice advantages of build_runner is that you can use it in your CI
environments too! This gives you faster turnaround times by leveraging the power
of incremental builds in the cloud.

While this doc is tailored to Travis, the concepts are generally applicable to
any CI service.

## Setting up basic caching between builds

The key part when integrating with travis, is to set up your build cache so that
the `.dart_tool/build` directory is cached between your CI builds. This allows
build_runner to re-use all the parts of the previous build that are still up to
date.

You can set this up in your `.travis.yml` file, like this:

```yaml
cache:
  directories:
    - .dart_tool/build
```

Travis will archive this directory after each task is completed, and it will
download those cached archives whenever a new task starts up and extract them
to the same directory.

See the [docs](https://docs.travis-ci.com/user/caching) for more information
about the specifics of caching on travis, but by default it will pretty much
just work how you want it to. It will use previous caches from the same branch
if available, and otherwise use a cache from the branch that the current branch
is based off of (usually master, if a pull request).

**Note:** These caches are keyed based off of the environment variables set in
the job, so jobs with different environment variables _will not_ share a
cache.

## Use a custom test job instead of the `test` job from `dart_task`

If your current `.travis.yml` looks something like this:

```yaml
dart_task:
  - test
```

Then you will need to update it to be a normal `script` job, which invokes the
`build_runner test` command instead, something like this:

```yaml
script:
  - pub run build_runner test
```

**Note:** If you are running out of memory due to large builds, you can use the
`--low-resources-mode` option. This will remove all file caching which is slower
but more reliable in low memory environments.

## Using build stages to share a cache across multiple jobs

If you have a lot of tests you might be sharding those tests across multiple
jobs. You can share a single build across all of these jobs, by leveraging the
[build stages](https://docs.travis-ci.com/user/build-stages/) feature of travis.

You will need to separate your build into at least two stages, a _build_ stage
and a _test_ stage. The main thing to keep in mind here, is that as mentioned
previously the cache will only be shared between the stages if the environment
variables are _identical_ across the jobs.

**Note:** Build stages are not compatible with the `dart_task` built in jobs.
You will want to use custom `script` jobs instead (but don't worry, its easy!).

This will look something like the following:

```yaml
jobs:
  include:
    # This stage builds the entire `test` directory
    - stage: build
      script:
        - pub run build_runner build test
    # Set up several jobs in the next stage, using the built in sharding
    # feature from the `test` package.
    #
    # Since a build already happened in the previous stage, these tasks will
    # perform no-op builds which are fast (assuming you set up your cache
    # properly above!).
    - stage: unit_test
      script:
        - pub run build_runner test -- --total-shards 4 --shard-index 0
    - stage: unit_test
      script:
        - pub run build_runner test -- --total-shards 4 --shard-index 1
    - stage: unit_test
      script:
        - pub run build_runner test -- --total-shards 4 --shard-index 2
    - stage: unit_test
      script:
        - pub run build_runner test -- --total-shards 4 --shard-index 3

# Specify the ordering of your stages
stages:
  - build
  - unit_test
```

In practice, you probably want to add an additional stage before both of these,
which runs the dartanalyzer and dartfmt checks.

## Complete example

That might have been a lot to digest, so here is a full example `.travis.yml`
file, which includes all the basics:

```yaml
language: dart

# Optional, the dart sdk release channel to use.
dart:
  - dev

# Optional, required for web tests.
sudo: required
addons:
  chrome: stable

# Defines the stages we want to run.
jobs:
  include:
    # First, check that everything analyzes properly and is formatted.
    - stage: analyze_and_format
      script:
        - dartanalyzer --fatal-warnings .
        - dartfmt -n --set-exit-if-changed .
    # Next, build the entire `test` directory
    - stage: build
      script:
        - pub run build_runner build test
    # Set up several jobs in the next stage, using the built in sharding
    # feature from the `test` package.
    #
    # Since a build already happened in the previous stage, these tasks will
    # perform no-op builds which are fast (assuming you set up your cache
    # properly above!).
    - stage: unit_test
      script:
        - pub run build_runner test -- --total-shards 4 --shard-index 0
    - stage: unit_test
      script:
        - pub run build_runner test -- --total-shards 4 --shard-index 1
    - stage: unit_test
      script:
        - pub run build_runner test -- --total-shards 4 --shard-index 2
    - stage: unit_test
      script:
        - pub run build_runner test -- --total-shards 4 --shard-index 3

# Specify the ordering of your stages
stages:
  - analyze_and_format
  - build
  - unit_test

cache:
  directories:
    - $HOME/.pub-cache
    - .dart_tool/build
```
