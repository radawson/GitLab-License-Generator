#!/usr/bin/env ruby
# encoding: utf-8

require 'json'
require 'optparse'

features_file = nil
EXPORT_JSON_FILE = nil

OptionParser.new do |opts|
    opts.banner = "Usage: scan.features.rb [options]"

    opts.on("-s", "--src-dir PATH", "") do |v|
        # Keeping this for compatibility
    end

    opts.on("-f", "--features-file PATH", "Input features file path") do |v|
        features_file = File.expand_path(v)
    end

    opts.on("-o", "--output PATH", "Output to json file (required)") do |v|
        EXPORT_JSON_FILE = File.expand_path(v)
    end

    opts.on("-h", "--help", "Prints this help") do
        puts opts
        exit
    end
end.parse!

if features_file.nil? || !File.exist?(features_file)
    puts "[!] features file not found"
    exit 1
end

if EXPORT_JSON_FILE.nil?
    puts "[!] output file path required"
    exit 1
end

# Read and parse the features file
content = File.read(features_file)
output_dir = File.dirname(EXPORT_JSON_FILE)
File.write(File.join(output_dir, 'features.rb'), content)

puts "[DEBUG] Features file size: #{content.size} bytes"

# Look for the first feature list to verify content
first_list = content.match(/GLOBAL_FEATURES\s*=\s*%i\[(.*?)\]/m)
if first_list
    puts "[DEBUG] Found GLOBAL_FEATURES list"
    puts "[DEBUG] First few features: #{first_list[1].split(/\s+/)[0..5].join(', ')}"
else
    puts "[DEBUG] Could not find GLOBAL_FEATURES list"
    puts "[DEBUG] First 100 chars of content: #{content[0..100]}"
end

features = []

# Extract features from constant arrays with more flexible pattern
content.scan(/[A-Z_]+_FEATURES\s*=\s*%i\[(.*?)\]/m).each do |match|
    feature_list = match[0].strip.split(/\s+/)
    puts "[DEBUG] Found feature list with #{feature_list.size} features"
    puts "[DEBUG] Sample features: #{feature_list[0..2].join(', ')}" if feature_list.any?
    features.concat(feature_list)
end

features.uniq!
puts "[DEBUG] Total unique features found: #{features.size}"

# Write the features to the output JSON file
File.open(EXPORT_JSON_FILE, 'w') do |file|
    file.write(JSON.pretty_generate(features))
end
