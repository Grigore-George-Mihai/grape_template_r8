# frozen_string_literal: true

namespace :setup do
  desc "Ask for new app name and update known files"
  task rename_app: :environment do
    print "Enter the new app name (Title Case, e.g. My New App): "
    new_title = $stdin.gets&.strip.to_s
    abort("❌ App name cannot be empty!") if new_title.empty?

    old_title       = Rails.application.name.titleize
    old_title_camel = old_title.delete(" ")
    old_title_snake = old_title.parameterize(separator: "_")

    new_title       = new_title.titleize
    new_title_camel = new_title.delete(" ")
    new_title_snake = new_title.parameterize(separator: "_")

    puts "Using:\n  Title : #{new_title}\n  snake : #{new_title_snake}\n  Camel : #{new_title_camel}"

    replace_patterns = [
      # Title Case (strict word boundaries)
      [/\b#{Regexp.escape(old_title)}\b/, new_title],

      # CamelCase
      [/#{Regexp.escape(old_title_camel)}/, new_title_camel],

      # snake_case
      [/#{Regexp.escape(old_title_snake)}/, new_title_snake],

      # SCREAMING_SNAKE_CASE (env var names, e.g. APP_DATABASE_PASSWORD)
      [/#{Regexp.escape(old_title_snake.upcase)}/, new_title_snake.upcase]
    ]

    files = %w[
      .ruby-gemset
      .env.development.template
      config/application.rb
      config/cable.yml
      config/database.yml
      config/environments/production.rb
      config/initializers/swagger.rb
      config/scout_apm.yml
      config/deploy.yml
      docker-compose.yml
      Dockerfile
      README.md
    ]

    changed = 0
    files.each do |file|
      path = Rails.root.join(file)
      next unless File.exist?(path)

      text = File.read(path)
      updated = replace_patterns.reduce(text) { |acc, (from, to)| acc.gsub(from, to) }
      next if updated == text

      File.write(path, updated)
      puts "Updated: #{file}"
      changed += 1
    end

    puts "✅ Done. Files updated: #{changed}"
  end
end
