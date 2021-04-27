# Prosopite ![CI](https://github.com/charkost/prosopite/actions/workflows/ci.yml/badge.svg) [![Gem Version](https://badge.fury.io/rb/prosopite.svg)](https://badge.fury.io/rb/prosopite)

Prosopite is able to auto-detect Rails N+1 queries with zero false positives / false negatives.

```
N+1 queries detected:
  SELECT `users`.* FROM `users` WHERE `users`.`id` = 20 LIMIT 1
  SELECT `users`.* FROM `users` WHERE `users`.`id` = 21 LIMIT 1
  SELECT `users`.* FROM `users` WHERE `users`.`id` = 22 LIMIT 1
  SELECT `users`.* FROM `users` WHERE `users`.`id` = 23 LIMIT 1
  SELECT `users`.* FROM `users` WHERE `users`.`id` = 24 LIMIT 1
Call stack:
  app/controllers/thank_you_controller.rb:4:in `block in index'
  app/controllers/thank_you_controller.rb:3:in `each'
  app/controllers/thank_you_controller.rb:3:in `index':
  app/controllers/application_controller.rb:8:in `block in <class:ApplicationController>'
```

The need for prosopite emerged after dealing with various false positives / negatives using the
[bullet](https://github.com/flyerhzm/bullet) gem.

## Compared to Bullet

Prosopite can auto-detect the following extra cases of N+1 queries:

#### N+1 queries after record creations (usually in tests)

```ruby
FactoryBot.create_list(:leg, 10)

Leg.last(10).each do |l|
  l.chair
end
```

#### Not triggered by ActiveRecord associations

```ruby
Leg.last(4).each do |l|
  Chair.find(l.chair_id)
end
```

#### First/last/pluck of collection associations

```ruby
Chair.last(20).each do |c|
  c.legs.first
  c.legs.last
  c.legs.pluck(:id)
end
```

#### Changing the ActiveRecord class with #becomes

```ruby
Chair.last(20).map{ |c| c.becomes(ArmChair) }.each do |ac|
  ac.legs.map(&:id)
end
```

#### Mongoid models calling ActiveRecord

```ruby
class Leg::Design
  include Mongoid::Document
  ...
  field :cid, as: :chair_id, type: Integer
  ...
  def chair
    @chair ||= Chair.where(id: chair_id).first!
  end
end

Leg::Design.last(20) do |l|
  l.chair
end
```

## Why a new gem

Creating a new gem makes more sense since bullet's core mechanism is completely
different from prosopite's.

## How it works

Prosopite monitors all SQL queries using the Active Support instrumentation
and looks for the following pattern which is present in all N+1 query cases:

More than one queries have the same call stack and the same query fingerprint.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'prosopite'
```

If you're **not** using MySQL/MariaDB, you should also add:

```ruby
gem 'pg_query'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install prosopite

## Development Environment Usage

Prosopite auto-detection can be enabled on all controllers:

```ruby
class ApplicationController < ActionController::Base
  unless Rails.env.production?
    around_action do
      Prosopite.scan! do
        yield
      end
    end
  end
end
```

## Test Environment Usage
And each test can be scanned with:

```ruby
# spec/spec_helper.rb
config.around(:each) do |example|
  Prosopite.scan! do
    example.run
  end
end
```

or with custom code using scan report

```ruby
# spec/your_spec.rb
it 'has no N+1 queries' do
  n_ones = Prosopite.scan do
    MyAction.perform(arguments)
  end
  
  expect(n_ones.size).to eq(0)
end
```

## Whitelisting

Ignore notifications for call stacks containing one or more substrings:

```ruby
  Prosopite.scan!(whitelist: 'myapp/lib/known_n_plus_ones/') do
    example.run
  end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/charkost/prosopite.

## License

Prosopite is licensed under the Apache License, Version 2.0. See LICENSE.txt for the full license text.
