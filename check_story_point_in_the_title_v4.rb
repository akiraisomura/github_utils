# frozen_string_literal: true

require 'octokit'
require 'yaml'
require 'active_support/all'
require 'faraday'
require 'faraday_middleware'
require 'dotenv/load'
Dir[File.dirname(__FILE__) + '/mention_rules/*.rb'].each {|file| require file }

def main
  issues = fetch_issues

  issues.each do |issue|
    next unless target_column?(issue)

    check_story_point_in_the_title(issue)
  end
end

def check_story_point_in_the_title(issue)
  return if issue.title.match(/\[\d+\]/)

  mention_target = decide_mention_target(issue)
  github_client.add_comment(repository, issue[:content][:number], "@#{mention_target} #{config['MESSAGE']}")
  sleep 0.5 # to avoid rate limit
end

def decide_mention_target(issue)
  creator = issue[:creator][:login]
  return creator unless mention_rule_class

  mention_rule_class.decide_mention_target(creator)
end

def mention_rule_class
  mention_rules = config['MENTION_RULES']
  return unless mention_rules
  return unless mention_rules['CLASS']

  @mention_rule_class ||= mention_rules['CLASS'].constantize.new
end

def target_column?(issue)
  column_name = issue[:content][:projectItems][:nodes][0][:fieldValues][:nodes].last[:name]
  config['COLUMN_NAMES'].include?(column_name)
end

def fetch_issues
  body = {
    query: query
  }
  github_connection.post("/graphql", body)
end

def query
  <<~GRAPHQL
    query {
      node(id: "#{config['PROJECT_ID']}") {
        ... on ProjectV2 {
          title
          url
          closed
          items(first: 100) {
            totalCount
            pageInfo {
              endCursor
              hasNextPage
              hasPreviousPage
              startCursor
            }
            nodes {
              type
              creator {
                login
              }
              content {
                ... on Issue {
                  url
                  title
                  state
                  updatedAt
                  closed
                  number
                  repository{
                      name
                  }
                  assignees(first: 1) {
                    nodes{
                      login
                    }
                  }
                  labels(first: 5) {
                    nodes{
                      name
                    }
                  }
                  projectItems(first: 100, includeArchived: false){
                    totalCount
                    nodes{
                      fieldValues(first: 8) {
                        totalCount
                        nodes{
                          ... on ProjectV2ItemFieldSingleSelectValue{
                            name
                          }
                          ... on ProjectV2ItemFieldLabelValue{
                            labels{
                              nodes{
                                name
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
                ... on PullRequest {
                  title
                  baseRefName
                  closed
                  headRefName
                  url
                }
              }
            }
          }
        }
      }
    }
  GRAPHQL
end

def github_client
  @github_client ||= Octokit::Client.new(access_token: ENV['ACCESS_TOKEN'])
end

def github_connection
  graphql_url = 'https://api.github.com'
  @github_connection ||= Faraday.new(graphql_url) do |builder|
    access_token = ENV['ACCESS_TOKEN']
    builder.headers = {
      "Authorization": "Bearer #{access_token}",
      "Accept": "application/vnd.github.starfox-preview+json"
    }
    builder.response(:json, parser_options: { symbolize_names: true })
    builder.response(:raise_error)
    builder.request(:json)
    builder.request(:retry, { methods: %i[get post] })
  end
end

def repository
  config['REPOSITORY']
end

def config
  @config ||= YAML.load_file('config.yml')
end

main
