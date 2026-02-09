#!/usr/bin/env ruby
require 'xcodeproj'

project = Xcodeproj::Project.open('CoffeeJournal.xcodeproj')
target = project.targets.first

# Files to remove
files_to_remove = [
  'CoffeeJournal/MainTabView.swift',
  'CoffeeJournal/SetupWizardView.swift'
]

files_to_remove.each do |file_path|
  # Find and remove build files
  build_files = target.source_build_phase.files.select do |bf|
    bf.file_ref && (bf.file_ref.real_path.to_s.end_with?(file_path) || bf.file_ref.path&.end_with?(file_path))
  end

  build_files.each do |bf|
    puts "Removing build file: #{bf.file_ref.path}"
    bf.remove_from_project
  end

  # Find and remove file references
  project.main_group.recursive_children.each do |child|
    if child.is_a?(Xcodeproj::Project::Object::PBXFileReference)
      if child.real_path.to_s.end_with?(file_path) || child.path&.end_with?(file_path)
        puts "Removing file reference: #{child.path}"
        child.remove_from_project
      end
    end
  end
end

project.save
puts "\n✓ Removed stub file references from project"
