#!/usr/bin/env ruby
require 'xcodeproj'

project = Xcodeproj::Project.open('CoffeeJournal.xcodeproj')
target = project.targets.first

# Add the correct files
files_to_add = [
  'CoffeeJournal/Views/MainTabView.swift',
  'CoffeeJournal/Views/Setup/SetupWizardView.swift'
]

files_to_add.each do |file_path|
  # Check if already in project
  exists = target.source_build_phase.files.any? do |bf|
    bf.file_ref && bf.file_ref.real_path.to_s.end_with?(file_path)
  end

  unless exists
    file_ref = project.new_file(file_path)
    target.add_file_references([file_ref])
    puts "✓ Added #{file_path}"
  else
    puts "- #{file_path} already in project"
  end
end

project.save
puts "\n✓ Project saved"
