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

Settings from database will be available only after rails app initialization.
Everything else can be used in initializers.

## Rails Credentials Handling

BlueprintConfig integrates with Rails credentials system. When Rails is available, it uses `Rails.application.credentials` which automatically handles both global and environment-specific credentials.

### Environment-Specific Credentials (Rails 6+)

Rails 6+ supports environment-specific credentials that are automatically merged:
- Global: `config/credentials.yml.enc` (with `config/master.key`)
- Environment-specific: `config/credentials/[environment].yml.enc` (with `config/credentials/[environment].key`)

Example structure:
```
config/
├── credentials.yml.enc              # Global credentials
├── master.key                       # Global key (not committed)
└── credentials/
    ├── development.yml.enc          # Development-only credentials
    ├── development.key              # Development key (not committed)
    ├── production.yml.enc           # Production-only credentials
    └── production.key               # Production key (not committed)
```

When both exist, Rails merges them with environment-specific values taking precedence. BlueprintConfig automatically receives the merged result through `Rails.application.credentials`.

Example:
```ruby
# In config/credentials.yml.enc (global):
aws:
  region: us-east-1
  bucket: myapp

# In config/credentials/production.yml.enc:
aws:
  access_key_id: PROD_KEY_123
  secret_access_key: PROD_SECRET_456

# Result in production:
AppConfig.aws.region              # => "us-east-1" (from global)
AppConfig.aws.bucket              # => "myapp" (from global)
AppConfig.aws.access_key_id       # => "PROD_KEY_123" (from production)
AppConfig.aws.secret_access_key   # => "PROD_SECRET_456" (from production)
```

## Configuration Recommendations

### Where to Put Your Settings

Different types of configuration should be stored in different places based on their nature:

#### 1. **Credentials** → Use Rails Credentials
Sensitive data like API keys, passwords, and tokens:
```yaml
# config/credentials.yml.enc
stripe:
  secret_key: sk_live_xxxxx
  webhook_secret: whsec_xxxxx
database:
  password: super_secret_password
external_api:
  token: bearer_token_xxxxx
```

#### 2. **Application Configuration** → Use `config/app.yml`
Rarely changed settings that configure application behavior:
```yaml
# config/app.yml
smtp:
  server: smtp.example.com
  port: 587
  domain: example.com
app:
  host: app.example.com
  name: My Application
  support_email: support@example.com
features:
  signup_enabled: true
  maintenance_mode: false
```

#### 3. **Dynamic Settings** → Use Database
Settings that need to change without redeployment:
```ruby
# Stored in settings table, managed via admin interface
BlueprintConfig::Setting.create(key: 'feature_flags.new_ui', value: 'true')
BlueprintConfig::Setting.create(key: 'rate_limits.api_calls', value: '1000')
BlueprintConfig::Setting.create(key: 'maintenance.message', value: 'Back at 3pm')
```

> **Automatic Reloading**: Database settings are automatically reloaded when changed. The system checks for updates every second and refreshes configuration if database records are newer than the cached values. This means changes take effect immediately without restarting the application.

#### 4. **Local Overrides** → Use `config/app.local.yml`
Development-specific overrides (never commit this file):
```yaml
# config/app.local.yml
smtp:
  server: localhost
  port: 1025  # Local MailCatcher
app:
  host: localhost:3000
debug:
  verbose_logging: true
```

### Configuration Precedence

Settings are loaded in this order (later sources override earlier ones):
1. `config/app.yml` - Base configuration
2. Rails credentials - Secure/sensitive data
3. ENV variables - Deployment-specific overrides
4. Database settings - Runtime-configurable values
5. `config/app.local.yml` - Local development overrides

## Accessing Configuration Variables

The recommended access style is using dot notation (member access syntax):

```ruby
# Recommended approach
AppConfig.action_mailer.smtp_settings.address
AppConfig.stripe.secret_key
AppConfig.features.signup_enabled

# This provides clean, readable code that mirrors your configuration structure
```

You can access configuration variables in any of following ways:

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

If nil is suitable as a default value you can use safe navigation operator

```ruby
irb(main):001> AppConfig.some&.var
=> nil

```



Optionally you can use bang methods to always raise exception when variable is not defined

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

Note: Because question mark methods return Boolean you cannot chain them.

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

Dig permits to safely get value in nested structures (including arrays)

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

## Testing with Memory Backend

In test environments, BlueprintConfig automatically includes a memory backend that allows you to temporarily set configuration values for testing purposes. The memory backend has the highest priority and will override all other configuration sources.

### Setting Values in Tests

You can use `AppConfig.set` to temporarily override configuration values:

```ruby
# Set a single value
AppConfig.set('smtp.server', 'test.localhost')

# Set multiple values with a hash
AppConfig.set(
  smtp: {
    server: 'localhost',
    port: 1025
  },
  features: {
    new_ui: true
  }
)

# Set deeply nested values
AppConfig.set('app.mail.settings', { 
  from: 'test@example.com',
  reply_to: 'noreply@example.com'
})
```

### RSpec Usage Pattern

```ruby
RSpec.describe 'MyFeature' do
  context 'with feature enabled' do
    before do
      AppConfig.set('features.new_ui', true)
    end

    after do
      AppConfig.clear_memory!
    end

    it 'behaves differently' do
      expect(AppConfig.features.new_ui).to be true
      # test your feature
    end
  end
end
```

### Shared Examples and Contexts

```ruby
RSpec.shared_context 'with premium features' do
  before do
    AppConfig.set(
      features: {
        premium: true,
        advanced_analytics: true,
        api_limit: 10000
      }
    )
  end

  after do
    AppConfig.clear_memory!
  end
end

# Use in your specs
RSpec.describe PremiumService do
  include_context 'with premium features'
  
  it 'allows advanced operations' do
    expect(AppConfig.features.premium).to be true
    # test premium functionality
  end
end
```

### Clearing Memory

Use `AppConfig.clear_memory!` to clear all memory-stored values:

```ruby
# In RSpec configuration
RSpec.configure do |config|
  config.after(:each) do
    AppConfig.clear_memory! if defined?(AppConfig)
  end
end

# Or manually in specific tests
AppConfig.clear_memory!
```

### Important Notes

1. The memory backend is only available in test environment (`Rails.env.test?`)
2. Memory values have the highest priority and override all other sources
3. Values are stored in memory only and are not persisted
4. Remember to clear memory between tests to avoid test pollution
5. The `set` method will raise an error if used outside test environment

## Debugging and Inspection

### Viewing Configuration Sources

BlueprintConfig tracks where each configuration value comes from. You can use the `source` method to see which backend provided a specific value:

```ruby
# Get the source of a specific configuration value
AppConfig.config.source(:smtp, :server)
# => "BlueprintConfig::Backend::YAML(config/app.yml) smtp.server"

AppConfig.config.source(:database, :password)
# => "BlueprintConfig::Backend::Credentials(global + production) database.password"

# In test environment with memory backend
AppConfig.set('feature.enabled', true)
AppConfig.config.source(:feature, :enabled)
# => "BlueprintConfig::Backend::Memory feature.enabled"

# For environment variables with specific configuration
AppConfig.config.source(:api, :key)
# => "BlueprintConfig::Backend::ENV(whitelist_prefixes: API_, APP_) api.key"

# For local overrides
AppConfig.config.source(:debug, :verbose)
# => "BlueprintConfig::Backend::YAML(config/app.local.yml) debug.verbose"

# For database settings
AppConfig.config.source(:rate_limit, :max_requests)
# => "BlueprintConfig::Backend::ActiveRecord(settings table) rate_limit.max_requests"
```

### Inspecting All Configuration

To view all configuration values as a hash:

```ruby
# Get all configuration as a Ruby hash
AppConfig.to_h
# or
AppConfig.config.to_h
# => {
#   smtp: {
#     server: "smtp.gmail.com",
#     port: 587,
#     domain: "example.com"
#   },
#   database: {
#     pool: 5,
#     timeout: 5000
#   },
#   features: {
#     signup_enabled: true,
#     beta_features: false
#   }
# }

# Pretty print configuration in console
require 'pp'
pp AppConfig.to_h

# Convert to YAML for easier reading
require 'yaml'
puts AppConfig.to_h.to_yaml
# ---
# :smtp:
#   :server: smtp.gmail.com
#   :port: 587
#   :domain: example.com
# :database:
#   :pool: 5
#   :timeout: 5000
# :features:
#   :signup_enabled: true
#   :beta_features: false
```

### Viewing Configuration with Sources

To see both values and their sources:

```ruby
# Get configuration with source information
AppConfig.with_sources
# or
AppConfig.config.with_sources
# => {
#   smtp: {
#     server: {
#       value: "smtp.gmail.com",
#       source: "BlueprintConfig::Backend::YAML(config/app.yml)"
#     },
#     port: {
#       value: 587,
#       source: "BlueprintConfig::Backend::YAML(config/app.yml)"
#     },
#     username: {
#       value: "user@example.com",
#       source: "BlueprintConfig::Backend::Credentials(production)"
#     }
#   },
#   features: {
#     beta_enabled: {
#       value: true,
#       source: "BlueprintConfig::Backend::Memory"
#     }
#   },
#   debug: {
#     verbose: {
#       value: true,
#       source: "BlueprintConfig::Backend::YAML(config/app.local.yml)"
#     }
#   }
# }

# Pretty print with sources
require 'pp'
pp AppConfig.config.with_sources

# Convert to YAML for easier reading
require 'yaml'
puts AppConfig.config.with_sources.to_yaml
```

### Checking Available Backends

To see which backends are currently loaded:

```ruby
# List all backends with their configuration
AppConfig.backends.each do |backend|
  puts backend.source
end
# Output:
# BlueprintConfig::Backend::YAML(config/app.yml)
# BlueprintConfig::Backend::Credentials(global + production)
# BlueprintConfig::Backend::ENV(whitelist_prefixes: API_, APP_)
# BlueprintConfig::Backend::ActiveRecord(settings table)
# BlueprintConfig::Backend::YAML(config/app.local.yml)
# BlueprintConfig::Backend::Memory

# Check specific backend
AppConfig.backends[:memory]  # => BlueprintConfig::Backend::Memory instance or nil
AppConfig.backends[:app]     # => BlueprintConfig::Backend::YAML instance
```

### Configuration Load Order

The default configuration load order (later sources override earlier ones):

1. `app` - YAML file (config/app.yml)
2. `credentials` - Rails credentials
3. `env` - Environment variables
4. `db` - Database settings (after Rails initialization)
5. `app_local` - Local YAML overrides (config/app.local.yml)
6. `memory` - Test-only memory backend (highest priority in test environment)

### Source Tracking Details

BlueprintConfig provides detailed source information for debugging:

- **YAML files**: Shows the file path (e.g., `config/app.yml`)
- **Credentials**: Shows whether using global only or merged with environment-specific (e.g., `global + production`)
- **Environment variables**: Shows any whitelist configuration
- **Database**: Indicates if connected to settings table
- **Memory**: Simple indicator for test values

Note: While YAML line numbers are not currently tracked, the file path information helps identify which YAML file contains specific values. For credentials, Rails automatically merges global and environment-specific files, and the source indicates which files are in use.

## License

MIT, see separate LICENSE.txt file
