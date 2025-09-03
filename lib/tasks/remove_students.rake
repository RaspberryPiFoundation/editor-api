# frozen_string_literal: true

require_relative '../../app/services/student_removal_service'
require 'csv'

namespace :remove_students do
  desc 'Remove students listed in a CSV file'
  task run: :environment do
    Rails.logger.level = Logger::WARN

    students = []
    school_id = ENV.fetch('SCHOOL_ID', nil)
    remove_from_profile = ENV.fetch('REMOVE_FROM_PROFILE', 'false') == 'true'
    token = ENV.fetch('TOKEN', nil)

    school = School.find_by(id: school_id)
    if school.nil?
      Rails.logger.error 'Please provide a valid school ID with SCHOOL_ID=your_school_id'
      exit 1
    end

    if ENV['CSV']
      csv_path = ENV['CSV']
      unless File.exist?(csv_path)
        Rails.logger.error 'Please provide a valid CSV file path with CSV=/path/to/file.csv'
        exit 1
      end
      CSV.foreach(csv_path, headers: true) do |row|
        students << row['user_id']
      end
    elsif ENV['STUDENTS']
      students = ENV['STUDENTS'].split(',').map(&:strip)
    else
      Rails.logger.error 'Please provide students via a list of user_ids like this STUDENTS=comma,separated,list or in a CSV=/path/to/file.csv (with a single column called `user_id`)'
      exit 1
    end

    puts "\n===================="
    puts "Student removal options summary\n"
    puts "SCHOOL: #{school.name} (#{school.id})"
    puts "REMOVE_FROM_PROFILE: #{remove_from_profile}"
    puts "Students to remove: #{students.size}"
    puts "====================\n\n"
    puts "Please confirm deletion of #{students.size} user(s), and that recent Postgres backups have been captured for all services affected (https://devcenter.heroku.com/articles/heroku-postgres-backups#manual-backups)"
    puts 'Are you sure you want to continue? (yes/no): '
    confirmation = $stdin.gets.strip.downcase
    unless confirmation == 'yes'
      puts 'Aborted. No students were removed.'
      exit 0
    end

    service = StudentRemovalService.new(
      school: school,
      remove_from_profile: remove_from_profile,
      token: token,
      raise_on_noop: true
    )

    results = []
    students.each do |student_id|
      service.remove_student(student_id)
      results << "Student: #{student_id} | Removed successfully"
    rescue StandardError => e
      results << "Student: #{student_id} | Error: #{e.message}"
    end

    puts "\n===================="
    puts "Results\n"
    puts "Students processed: #{results.size}"
    puts '===================='
    results.each { |result| puts result }
    puts "====================\n\n"
  end
end
