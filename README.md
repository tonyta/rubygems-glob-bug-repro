# RubyGems Glob Bug

**TL;DR:** The implementation of `Gem::Util.glob_files_in_dir` method will unexpectedly return _relative_ paths, instead of _absolute_ paths. This causes `Gem.find_files` to return filepaths will raise an error when passed to `Kernel#require`.

## Minimum Repro

Running `minimum_repro.rb` in this repo will output the unrequireable filename:
```ruby
# minimum_repro.rb
fail unless RUBY_VERSION >= "2.5"
$LOAD_PATH.unshift "test"
puts Gem.find_files("minitest/*_plugin.rb")
```
```
$ bundle exec ruby minimum_repro.rb
test/minitest/noop_plugin.rb
/Users/tonyta/.rbenv/versions/2.5.1/lib/ruby/gems/2.5.0/gems/minitest-5.11.3/lib/minitest/pride_plugin.rb
```

## Realistic Repro

This problem can manifest when using the following:
- RubyGems 3.0 (since it contains a change introduced in [rubygems PR#2336](https://github.com/rubygems/rubygems/pull/2336))
- Ruby 2.5 or above (since the behavior [switches on `RUBY_VERSION`](https://github.com/rubygems/rubygems/blob/v3.0.0/lib/rubygems/util.rb#L124-L128))
- Minitest testing framework and its default behavior to `load_plugins`
- Test Rake task (`Rails::TestTask`) provided by Rails 4.2 as defined in the `railties` gem
- User-defined Minitest plugin in the project's `test/` directory

Below is an explanation of how it works (or, er... doesn't work):

1. `Rails::TestTask` will [add the relative path `test`](https://github.com/rails/rails/blob/v4.2.11/railties/lib/rails/test_unit/sub_test_task.rb#L103) to the [$LOAD_PATH without expanding it](https://github.com/rails/rails/blob/v4.2.11/railties/lib/rails/test_unit/sub_test_task.rb#L112). This causes `$LOAD_PATH` to contain relative paths.

2. When Minitest is invoked, it will attempt to [find all minitest plugins and require them](https://github.com/seattlerb/minitest/blob/master/lib/minitest.rb#L92-L100) via `Gem.find_files`.

3. If the user has defined a Minitest plugin from within directory in `$LOAD_PATH` that is a relative path (e.g. the `test/` directory in a Rails project), its non-expanded path will be returned by `Gem.find_files`.

4. Minitest will attempt to `require` all found plugins, but will fail since the relative path for the user-defined plugin is prepended with its parent directory, making it unrequireable.


## Live Example

This repo contains a live example of this bug which you can replay commit-by-commit. You can reproduce the error by running the following command:

```
$ bundle exec rake
```

