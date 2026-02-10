#!/usr/bin/env ruby

# Script to add ScreenshotTests.swift to Xcode project

pbxproj = 'CoffeeJournal.xcodeproj/project.pbxproj'
content = File.read(pbxproj)

# Generate UUIDs
build_file_uuid = 'SS900001SS900001'
file_ref_uuid1 = 'SS900011SS900011'
file_ref_uuid2 = 'SS900012SS900012'

# Add PBXBuildFile entry
build_file_entry = "\t\t#{build_file_uuid} /* ScreenshotTests.swift in Sources */ = {isa = PBXBuildFile; fileRef = #{file_ref_uuid1} /* ScreenshotTests.swift */; };"
content.sub!(/1A442BA4A492458B09FD4FA3 \/\* BeanUITests.swift in Sources.*\n/) do |match|
  match + build_file_entry + "\n"
end

# Add PBXFileReference entries
file_ref_entry1 = "\t\t#{file_ref_uuid1} /* ScreenshotTests.swift */ = {isa = PBXFileReference; includeInIndex = 1; lastKnownFileType = sourcecode.swift; name = ScreenshotTests.swift; path = CoffeeJournalUITests/ScreenshotTests.swift; sourceTree = SOURCE_ROOT; };"
content.sub!(/497F6B19F37851A703F30F99 \/\* BeanUITests.swift.*SOURCE_ROOT.*\n/) do |match|
  match + file_ref_entry1 + "\n"
end

file_ref_entry2 = "\t\t#{file_ref_uuid2} /* ScreenshotTests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ScreenshotTests.swift; sourceTree = \"<group>\"; };"
content.sub!(/BB900014BB900014 \/\* BeanUITests.swift.*<group>.*\n/) do |match|
  match + file_ref_entry2 + "\n"
end

# Add to group
group_entry = "\t\t\t\t#{file_ref_uuid2} /* ScreenshotTests.swift */,"
content.sub!(/BB900014BB900014 \/\* BeanUITests.swift \*\/,\n/) do |match|
  match + group_entry + "\n"
end

group_entry2 = "\t\t\t\t#{file_ref_uuid1} /* ScreenshotTests.swift */,"
content.sub!(/497F6B19F37851A703F30F99 \/\* BeanUITests.swift \*\/,\n/) do |match|
  match + group_entry2 + "\n"
end

# Add to Sources build phase
sources_entry = "\t\t\t\t#{build_file_uuid} /* ScreenshotTests.swift in Sources */,"
content.sub!(/1A442BA4A492458B09FD4FA3 \/\* BeanUITests.swift in Sources \*\/,\n/) do |match|
  match + sources_entry + "\n"
end

File.write(pbxproj, content)
puts '✅ Added ScreenshotTests.swift to Xcode project'
