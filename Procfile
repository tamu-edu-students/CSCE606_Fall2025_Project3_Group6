release: bundle exec rails db:migrate
web: bundle exec puma -C config/puma.rb
# For manual asset builds (Heroku runs assets:precompile during slug compile)
assets: bundle exec rails assets:precompile
worker: bundle exec solid_queue:start
