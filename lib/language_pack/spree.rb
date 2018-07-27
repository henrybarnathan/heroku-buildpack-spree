require 'securerandom'
require 'language_pack'
require 'language_pack/rails5'

class LanguagePack::Spree < LanguagePack::Rails5
  def self.use?
    File.exists?('spree.gemspec')
  end

  def compile
    run_command 'git init -q'
    run_command 'gem install --user-install --no-ri --no-rdoc railties'
    run_command 'gem install --user-install --no-ri --no-rdoc bundler'

    rails_path = `ruby -e "gem 'railties'; puts Gem.bin_path('railties', 'rails')"`.strip
    run_command "#{rails_path} new sandbox --skip-bundle --database=postgresql"

    run_command "cp -rf sandbox/* ."
    run_command "rm -rf sandbox"

    File.open("Gemfile", 'a') do |f|
      f.puts <<-GEMFILE
gem 'spree', :path => '.'
gem 'spree_auth_devise', github: 'spree/spree_auth_devise', branch: 'master'
      GEMFILE
    end

    raise(ENV['AWS_ACCESS_KEY_ID']+ENV['AWS_SECRET_ACCESS_KEY']+ENV['AWS_REGION']+ENV['AWS_BUCKET'])

  File.open('config/storage.yml', 'a') { |f|
    f << "<% aws_access_key_id = ENV['AWS_ACCESS_KEY_ID'] %>\n"
    f << "<% aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY'] %>\n"
    f << "<% aws_region = ENV['AWS_REGION'] %>\n"
    f << "<% aws_bucket = ENV['AWS_BUCKET'] %>\n"
    f << "amazon:\n"
    f << "  service: S3\n"
    f << "  access_key_id: <% aws_access_key_id %>\n"
    f << "  secret_access_key: <% aws_secret_access_key %>\n"
    f << "  region: <% aws_region %>\n"
    f << "  bucket: <% aws_bucket %>\n"
  }

 File.write("config/initializers/devise.rb", <<RUBY)
Devise.secret_key = #{SecureRandom.hex(50).inspect }
RUBY

    super
  end

  def install_plugins
    # do not install plugins, do not call super, do not warn
  end

  private

  def run_assets_precompile_rake_task
    run_command "bundle exec rails g spree:install --auto-accept --user_class=Spree::User --enforce_available_locales=true --migrate=false --sample=false --seed=false --copy_views=false"
    run_command "bundle exec rails g spree:auth:install --migrate=false"
    super
  end

  def run_command(cmd)
    system(cmd) || raise("#{cmd} failed.")
  end
end
