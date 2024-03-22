# frozen_string_literal: true

require 'google_drive'
require 'yaml'

class DecideTargetBySubjectsAndMonth
  def decide_mention_target(creator)
    return creator unless creator.in?(config['CREATORS'])

    ws = spreadsheet.worksheets[0]
    target_date = Time.now.strftime("%Y/%m")
    target_row = ws.rows.find { |month, _t| month == target_date }
    target_row[1]
  end

  def session
    @session ||= GoogleDrive::Session.from_config("config.json")
  end

  def spreadsheet
    @spreadsheet ||= session.spreadsheet_by_key(config['SPREADSHEET_KEY'])
  end

  def config
    @config ||= YAML.load_file('config.yml')
  end
end
