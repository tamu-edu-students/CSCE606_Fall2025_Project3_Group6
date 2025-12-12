# Technical Documentation

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture Diagrams](#architecture-diagrams)
   - [System Architecture](#system-architecture)
   - [Class Diagram](#class-diagram)
   - [Database Schema](#database-schema)
3. [Getting Started from Zero](#getting-started-from-zero)
4. [Development Setup](#development-setup)
5. [Production Deployment](#production-deployment)
6. [Configuration](#configuration)
7. [Dependencies](#dependencies)

---

## System Overview

**Cinematico** is a Rails 8.0.3 web application for movie tracking, reviews, and social interaction. The application integrates with The Movie Database (TMDb) API to fetch movie metadata and provides features for users to:

- Track watched movies with watchlists and watch history
- Write and manage movie reviews
- Follow other users and view activity feeds
- View personalized statistics and recommendations
- Earn achievements and XP through gamification

### Technology Stack

- **Framework**: Ruby on Rails 8.0.3
- **Database**: PostgreSQL
- **Web Server**: Puma with Thruster
- **Frontend**: Tailwind CSS
- **Deployment**: Heroku
- **External API**: The Movie Database (TMDb) API v3
- **Authentication**: Devise
- **Background Jobs**: Solid Queue
- **Caching**: Solid Cache (PostgreSQL-backed)

---

## Architecture Diagrams

### System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Browser                            │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ HTTPS
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                    Kamal Proxy (SSL/TLS)                        │
│                    (Let's Encrypt)                               │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                    Rails Application Container                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Puma Web Server (with Thruster)                          │  │
│  │  - Handles HTTP requests                                  │  │
│  │  - Serves static assets                                   │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Rails Application                                        │  │
│  │  - Controllers (MVC)                                      │  │
│  │  - Services (TmdbService, StatsService)                  │  │
│  │  - Background Jobs (Solid Queue)                          │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                ┌────────────┼────────────┐
                │            │            │
┌───────────────▼──┐  ┌──────▼──────┐  ┌─▼──────────────────┐
│   PostgreSQL     │  │   Redis     │  │   TMDb API         │
│   - Primary DB   │  │   (Optional)│  │   (External)       │
│   - Cache        │  │             │  │                    │
│   - Queue        │  │             │  │                    │
│   - Cable        │  │             │  │                    │
└──────────────────┘  └─────────────┘  └────────────────────┘
```

### Class Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         Application Layer                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Controllers:                                                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ MoviesCtrl   │  │ UsersCtrl    │  │ ReviewsCtrl  │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                 │                 │                  │
│  ┌──────▼───────┐  ┌──────▼───────┐  ┌──────▼───────┐          │
│  │ Watchlists   │  │ StatsCtrl    │  │ Notifications│          │
│  │ Controller   │  │              │  │ Controller   │          │
│  └─────────────┘  └──────────────┘  └──────────────┘          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ uses
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Service Layer                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────┐         ┌──────────────────┐              │
│  │  TmdbService     │         │  StatsService    │              │
│  │                  │         │                  │              │
│  │  +search_movies  │         │  +calculate_    │              │
│  │  +movie_details  │         │    overview     │              │
│  │  +similar_movies │         │  +calculate_top_│              │
│  │  +trending_movies│         │    contributors │              │
│  │  +genres         │         │  +calculate_    │              │
│  └──────────────────┘         │    trend_data    │              │
│                               └──────────────────┘              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ uses
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Model Layer                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────┐      ┌──────────┐      ┌──────────┐              │
│  │   User   │      │  Movie   │      │  Review  │              │
│  │          │      │          │      │          │              │
│  │ -email   │      │ -tmdb_id │      │ -body    │              │
│  │ -username│      │ -title   │      │ -rating  │              │
│  │ -xp      │      │ -overview│      │          │              │
│  └────┬─────┘      └────┬─────┘      └────┬─────┘              │
│       │                │                  │                    │
│       │ has_many       │ has_many         │ belongs_to         │
│       │                │                  │                    │
│  ┌────▼─────────────────▼──────────────────▼─────┐            │
│  │  Watchlist  │  WatchLog  │  Log  │  Vote     │            │
│  └─────────────┴─────────────┴───────┴───────────┘            │
│                                                                  │
│  ┌──────────┐      ┌──────────┐      ┌──────────┐              │
│  │  Follow  │      │   List   │      │  Tag     │              │
│  │          │      │          │      │          │              │
│  │ -follower│      │ -name    │      │ -name    │              │
│  │ -followed│      │ -public  │      │          │              │
│  └──────────┘      └──────────┘      └──────────┘              │
│                                                                  │
│  ┌──────────┐      ┌──────────┐      ┌──────────┐              │
│  │ Notification│    │Achievement│    │UserStat  │              │
│  │            │    │          │    │          │              │
│  │ -type     │    │ -code    │    │ -total_  │              │
│  │ -read     │    │ -name    │    │   movies │              │
│  └──────────┘      └──────────┘      └──────────┘              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Database Schema

```
┌─────────────────────────────────────────────────────────────────┐
│                         Core Tables                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  users                    movies                                 │
│  ├─ id (PK)              ├─ id (PK)                             │
│  ├─ email (UNIQUE)       ├─ tmdb_id (UNIQUE)                    │
│  ├─ username (UNIQUE)    ├─ title                               │
│  ├─ encrypted_password    ├─ overview                            │
│  ├─ profile_public        ├─ poster_path                        │
│  ├─ xp                    ├─ release_date                       │
│  └─ banned                ├─ runtime                            │
│                           └─ cached_at                           │
│                                                                  │
│  reviews                  watchlists                            │
│  ├─ id (PK)              ├─ id (PK)                             │
│  ├─ user_id (FK)         ├─ user_id (FK)                        │
│  ├─ movie_id (FK)        └─ ...                                 │
│  ├─ body                 │                                       │
│  ├─ rating               watchlist_items                        │
│  ├─ reported             ├─ id (PK)                             │
│  └─ cached_score         ├─ watchlist_id (FK)                  │
│                           ├─ movie_id (FK)                      │
│  votes                    └─ UNIQUE(watchlist_id, movie_id)     │
│  ├─ id (PK)              │                                       │
│  ├─ user_id (FK)         watch_histories                        │
│  ├─ review_id (FK)       ├─ id (PK)                             │
│  └─ value                ├─ user_id (FK, UNIQUE)                  │
│                          └─ ...                                 │
│                          │                                       │
│                          watch_logs                             │
│                          ├─ id (PK)                             │
│                          ├─ user_id (FK)                        │
│                          ├─ movie_id (FK)                       │
│                          ├─ watched_on                         │
│                          └─ watch_history_id (FK)               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Social & Community Tables                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  follows                  lists                                 │
│  ├─ id (PK)              ├─ id (PK)                             │
│  ├─ follower_id (FK)     ├─ user_id (FK)                        │
│  ├─ followed_id (FK)     ├─ name                                │
│  └─ UNIQUE(follower,      ├─ description                         │
│      followed)           └─ public                              │
│                           │                                       │
│  notifications            list_items                            │
│  ├─ id (PK)              ├─ id (PK)                             │
│  ├─ user_id (FK)         ├─ list_id (FK)                        │
│  ├─ actor_id (FK)        ├─ movie_id (FK)                       │
│  ├─ notification_type     └─ position                            │
│  ├─ notifiable_type                                             │
│  ├─ notifiable_id                                              │
│  ├─ read                                                         │
│  └─ body                                                        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Metadata & Stats Tables                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  genres                  people                                 │
│  ├─ id (PK)              ├─ id (PK)                             │
│  ├─ name                 ├─ tmdb_id                            │
│  └─ tmdb_id              ├─ name                                │
│                          └─ profile_path                         │
│  movie_genres            movie_people                           │
│  ├─ id (PK)              ├─ id (PK)                             │
│  ├─ movie_id (FK)        ├─ movie_id (FK)                       │
│  └─ genre_id (FK)        ├─ person_id (FK)                      │
│                           ├─ role                                │
│  tags                    └─ character                           │
│  ├─ id (PK)              │                                       │
│  └─ name                 logs                                   │
│                          ├─ id (PK)                             │
│  log_tags                ├─ user_id (FK)                        │
│  ├─ id (PK)              ├─ movie_id (FK)                       │
│  ├─ log_id (FK)          ├─ watched_on                          │
│  └─ tag_id (FK)          ├─ rating                              │
│                          ├─ review_text                         │
│                          └─ rewatch                             │
│                                                                  │
│  user_stats              achievements                           │
│  ├─ id (PK)              ├─ id (PK)                             │
│  ├─ user_id (FK)         ├─ code                                │
│  ├─ total_movies         ├─ name                                │
│  ├─ total_hours          ├─ description                         │
│  ├─ total_reviews        └─ icon_url                            │
│  ├─ total_rewatches                                             │
│  ├─ top_genres_json      user_achievements                      │
│  ├─ top_actors_json      ├─ id (PK)                             │
│  ├─ top_directors_json   ├─ user_id (FK)                        │
│  └─ heatmap_json         ├─ achievement_id (FK)                  │
│                          └─ earned_at                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Getting Started from Zero

This section provides step-by-step instructions to get the application running from a fresh clone/fork.

### Prerequisites

Before starting, ensure you have the following installed:

- **Ruby 3.4.1** (check with `ruby -v`)
- **PostgreSQL 9.3+** (check with `psql --version`)
- **redis-server** (check with `redis-server -v`)

### Step 1: Clone the Repository

```bash
# Clone the repository
git clone https://github.com/tamu-edu-students/CSCE606_Fall2025_Project3_Group6.git
cd CSCE606_Fall2025_Project3_Group6

# Or if forking:
# git clone https://github.com/YOUR_USERNAME/CSCE606_Fall2025_Project3_Group6.git
```

### Step 2: Install Ruby Dependencies

```bash
# Install Bundler if not already installed
gem install bundler

# Install all Ruby gems
bundle install
```

### Step 3: Set Up PostgreSQL Database

```bash
# Create PostgreSQL user and database (if not exists)
# On macOS with Homebrew:
createuser -s cinematico
createdb cinematico_development
createdb cinematico_test

# Or using psql:
psql postgres
CREATE USER cinematico WITH PASSWORD 'cinematico';
CREATE DATABASE cinematico_development OWNER cinematico;
CREATE DATABASE cinematico_test OWNER cinematico;
\q
```

### Step 4: Configure Environment Variables

```bash
# Copy the example environment file (if exists) or create .env file
# Create .env file in the root directory
touch .env

# Add the following to .env:
SENDGRID_API_KEY=<sendgrid-api>
TMDB_ACCESS_TOKEN=<tmdb-access-token>
```

**To get a TMDb Access Token:**
1. Visit https://www.themoviedb.org/
2. Create an account
3. Setup an api key and obtain the TMDb access token
4. Set TMDB_ACCESS_TOKEN in .env as the access token obtained

**To get Sendgrid API KEY:**
1. Visit https://www.twilio.com/en-us/products/email-api
2. Create an account
3. Create an API Key and get the API key secret
4. Set SENDGRID_API_KEY .env as the secret obtained


### Step 5: Set Up the Database

```bash
# Create database tables
rails db:create

# Run migrations
rails db:migrate

# (Optional) Seed the database with initial data
rails db:seed
```


### Step 6: Precompile Assets (Development)

```bash
# Precompile assets for development
rails assets:precompile
```

### Step 7: Start the Development Server

```bash
# Use bin/dev to start the server, this will compile the tailwind css before running the server
bin/dev
```

The application should now be available at `http://localhost:3000`

---

## Development Setup

### Confirming an account without confirmation email
#### Using confirmation email provided in console
On creation of a user the contents of the confirmation email should be pasted in the console containing the confirmation link.

#### Through console
```bash
# Open rails console
rails c

# Get the user object of the user you want to confirm
user = User.find_by(usename: "<username>")

# Confrim the user
user.confirm
```

### Running Tests

```bash
# Run all RSpec tests
bundle exec rspec

# Run rspec test on specific test file
bundle exec rspec <specific-file.rb>

# Run Cucumber acceptance tests
bundle exec cucumber

# Run Cucumber test on a speciifc file
bundle exec cucumber<specific-file.rb>
```

### Database Management

```bash
# Create a new migration
rails generate migration MigrationName

# Rollback last migration
rails db:rollback

# Reset database (WARNING: deletes all data)
rails db:reset

# Open database console
rails dbconsole
```

### Code Quality

```bash
# Run RuboCop (code style checker)
rubocop -A

# Run Brakeman (security scanner)
bundle exec brakeman
```

### Development Tools

```bash
# Open Rails console
rails console

# View routes
rails routes

# Check environment
rails about
```

---

## Production Deployment

This application is currentlly deployed using heroku at https://cinematico.app/ with the following addons:
Heroku-Postgres
Redis Cloud
---

## Configuration

### Environment Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `TMDB_ACCESS_TOKEN` | TMDb API access token | Yes | - |
| `RAILS_MASTER_KEY` | Rails master key for credentials | Yes | - |
| `DATABASE_URL` | PostgreSQL connection string | Production | - |
| `RAILS_ENV` | Rails environment | No | `development` |
| `RAILS_LOG_LEVEL` | Log level | No | `info` |
| `SOLID_QUEUE_IN_PUMA` | Run jobs in Puma process | No | `true` |

### Database Configuration

Database settings are in `config/database.yml`:

- **Development**: Uses local PostgreSQL with user `cinematico`
- **Test**: Uses separate test database
- **Production**: Uses `DATABASE_URL` environment variable

### TMDb API Configuration

The application caches TMDb API responses to reduce API calls:

- Search results: 1 hour cache
- Movie details: 24 hours cache
- Similar movies: 24 hours cache
- Trending movies: 2 hours cache

Cache is stored in PostgreSQL (Solid Cache) in production, or in-memory in development.

### Email Configuration

Email is configured via Action Mailer. Update `config/environments/production.rb` for SMTP settings:

```ruby
config.action_mailer.smtp_settings = {
  address: 'smtp.example.com',
  port: 587,
  user_name: ENV['SMTP_USERNAME'],
  password: ENV['SMTP_PASSWORD'],
  authentication: 'plain',
  enable_starttls_auto: true
}
```

---

## Dependencies

### Core Gems

- **rails** (~> 8.0.3): Web framework
- **pg** (~> 1.1): PostgreSQL adapter
- **puma** (>= 5.0): Web server
- **devise**: Authentication
- **faraday**: HTTP client for TMDb API
- **redis**: Caching (optional)

### Development/Test Gems

- **rspec-rails**: Testing framework
- **factory_bot_rails**: Test data factories
- **cucumber-rails**: Acceptance testing
- **capybara**: Integration testing
- **simplecov**: Code coverage
- **rubocop-rails-omakase**: Code style
- **brakeman**: Security scanner

### Deployment

- **kamal**: Docker-based deployment
- **thruster**: HTTP acceleration for Puma

### Frontend

- **tailwindcss-rails**: CSS framework
- **stimulus-rails**: JavaScript framework
- **turbo-rails**: SPA-like page acceleration
- **importmap-rails**: JavaScript module management

---

## Additional Resources

### API Documentation

- TMDb API: https://developer.themoviedb.org/docs
- TMDb API v3 Reference: https://developer.themoviedb.org/reference/intro/getting-started

### Rails Documentation

- Rails Guides: https://guides.rubyonrails.org/
- Rails API: https://api.rubyonrails.org/

### Deployment Documentation

- Kamal Documentation: https://kamal-deploy.org/
- Docker Documentation: https://docs.docker.com/

---

## Support

For issues or questions:

1. Check existing GitHub issues
2. Review application logs: `kamal app logs`
3. Check Rails logs: `tail -f log/production.log` (on server)
4. Open a new GitHub issue with:
   - Error messages
   - Steps to reproduce
   - Environment details

---

**Last Updated**: December 2025
**Version**: 1.0.0
