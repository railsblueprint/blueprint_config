# Blueprint Config

Blueprint Config is a gem which allows you to easily configure your Ruby applications
in a multitude of ways.

It was highly inspired by other solutions, Econfig in first place. 

## Installation

Add this to your Gemfile:

``` ruby
gem "blueprint_config"
```

## Using with Ruby on Rails app

In Rails, you'll want to add this in `config/application.rb`:

``` ruby
module MyApp
  class Application < Rails::Application
    BlueprintConfig.configure_rails(config)
  end
end
```

This will create module "AppConfig" for accessing configuration options,
and load configuration in following order:
- config/app.yml
- credentials
- ENV variables 
- settings in database
- config/app.local.yml

Settings form database will be available only after rails app initialization.
Everything else can be used in initializers.

## Accessing configuration variables.

You can access configuration variables in any of followining ways:

### Member access syntax:

```ruby
irb(main):001> AppConfig.action_mailer.smtp_settings.address
=> "127.0.0.1"
```

If at some level variable is not defined and you try to access nested variable, 
you'll gen an exception 

```ruby
irb(main):001> AppConfig.some.var
(irb):1:in `<main>': undefined method `var' for nil:NilClass (NoMethodError)

AppConfig.some.var
              ^^^^
```

If nil is suitable as a default value tyou can use safe navigation operator

```ruby
irb(main):001> AppConfig.some&.var
=> nil

```



Optionaly you use bang methods to allways raise exception when variable is not defined

```ruby
irb(main):001> AppConfig.some
=> nil
irb(main):002> AppConfig.some!
(irb):2:in `<main>': Configuration key 'some' is not set (KeyError)
irb(main):003> AppConfig.some!.var!
(irb):3:in `<main>': Configuration key 'some' is not set (KeyError)
```

Or use question mark to check if variable is defined

```ruby
irb(main):001> AppConfig.some?
=> false
irb(main):002> AppConfig.host?
=> true
```

Note: Because question mark methods return Boolean you cannot chain em.

### Hash access syntax
You can use both symbols or strings as keys

```ruby
irb(main):001> AppConfig[:action_mailer][:delivery_method]
=> :letter_opener
irb(main):002> AppConfig['action_mailer']['delivery_method']
=> :letter_opener

```
Again, if some level is missing you'll get an exception
```ruby
irb(main):001> AppConfig[:some][:var]
(irb):1:in `<main>': undefined method `[]' for nil:NilClass (NoMethodError)

AppConfig[:some][:var]
                ^^^^^^
```

### Fetch

You can use hash-style fetch method, but it works only for one level 
(but you can chain it). Default values as second parameter or block are 
supported. Without default value missing key will raise exception.

```ruby
irb(main):001> AppConfig.fetch(:host)
=> "localhost"
irb(main):002> AppConfig.fetch(:var)
(irb):2:in `<main>': Configuration key 'var' is not set (KeyError)
irb(main):003> AppConfig.fetch(:var, 123)
=> 123
irb(main):004> AppConfig.fetch(:var){123}
=> 123
```

### Dig

Dig permits to sefely get value in nested structures (including arrays)

```ruby
irb(main):001> AppConfig.dig(:action_mailer, :smtp_settings, :address)
=> "127.0.0.1"
irb(main):002> AppConfig.dig(:action_mailer, :smtp_settings, :unknown)
=> nil
```
Bang version will raise exception when key at any level is missing
```ruby
irb(main):001> AppConfig.dig!(:action_mailer, :smtp_settings, :unknown)
(irb):1:in `<main>': Configuration key 'action_mailer.smtp_settings.unknown' is not set (KeyError)
irb(main):002> AppConfig.dig!(:action, :smtp_settings, :address)
(irb):2:in `<main>': Configuration key 'action' is not set (KeyError)
```

Whenever possible exception message specifies which key is missing.


## License

MIT, see separate LICENSE.txt file
