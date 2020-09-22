# frozen_string_literal: true

require 'octokit'
require 'yaml'

def main
  target_project = fetch_projects_by(config['PROJECT_NUMBER'])
  target_columns = fetch_columns_by(target_project.id)

  target_columns.each do |column|
    column_cards = github_client.column_cards(column.id)
    check_story_point_in_the_title(column_cards)
  end
end

def check_story_point_in_the_title(column_cards)
  column_cards.each do |card|
    issue = fetch_issue_by(card)
    next if issue.title.match(/\[\d+\]/)

    github_client.add_comment(repository, issue.number, "@#{card.creator.login} #{config['MESSAGE']}")
    sleep 0.5 # to avoid rate limit
  end
end

def fetch_projects_by(project_number)
  projects = github_client.projects(repository)
  projects.find { |p| p.number == project_number }
end

def fetch_columns_by(project_id)
  columns = github_client.project_columns(project_id)
  columns.select { |c| config['COLUMN_NAMES'].include?(c.name) }
end

def fetch_issue_by(card)
  issue_number = card.content_url[%r{issues\/(\d+)}, 1]
  github_client.issue(repository, issue_number)
end

def github_client
  @github_client ||= Octokit::Client.new(access_token: config['GITHUB_ACCESS_TOKEN'])
end

def repository
  config['REPOSITORY']
end

def config
  @config ||= YAML.load_file('config.yml')
end

main
