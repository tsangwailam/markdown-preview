#!/usr/bin/env ruby
# frozen_string_literal: true

require 'xcodeproj'
require 'fileutils'

project_path = File.expand_path('../MarkdownPreview.xcodeproj', __dir__)
FileUtils.rm_rf(project_path)
project = Xcodeproj::Project.new(project_path)

app_target = project.new_target(:application, 'MarkdownPreviewApp', :osx, '13.0')
ext_target = project.new_target(:app_extension, 'MarkdownPreviewExtension', :osx, '13.0')

project.root_object.attributes['LastUpgradeCheck'] = '2620'

project.build_configurations.each do |config|
  config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '13.0'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['CLANG_ENABLE_MODULES'] = 'YES'
  config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'YES'
end

app_target.build_configurations.each do |config|
  config.build_settings['INFOPLIST_FILE'] = 'src/Config/MarkdownPreviewApp-Info.plist'
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'src/Config/MarkdownPreviewApp.entitlements'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.local.MarkdownPreviewApp'
  config.build_settings['DEVELOPMENT_TEAM'] = 'ZVKZS6XN7Q'
  config.build_settings['CODE_SIGN_STYLE'] = 'Manual'
  config.build_settings['CODE_SIGN_IDENTITY'] = 'Apple Development'
  config.build_settings['CODE_SIGN_IDENTITY[sdk=macosx*]'] = 'Apple Development'
  config.build_settings['MARKETING_VERSION'] = '1.0'
  config.build_settings['CURRENT_PROJECT_VERSION'] = '1'
  config.build_settings['SWIFT_EMIT_LOC_STRINGS'] = 'YES'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/../Frameworks']
end

ext_target.build_configurations.each do |config|
  config.build_settings['INFOPLIST_FILE'] = 'src/Config/MarkdownPreviewExtension-Info.plist'
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'src/Config/MarkdownPreviewExtension.entitlements'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.local.MarkdownPreviewApp.MarkdownPreviewExtension'
  config.build_settings['DEVELOPMENT_TEAM'] = 'ZVKZS6XN7Q'
  config.build_settings['CODE_SIGN_STYLE'] = 'Manual'
  config.build_settings['CODE_SIGN_IDENTITY'] = 'Apple Development'
  config.build_settings['CODE_SIGN_IDENTITY[sdk=macosx*]'] = 'Apple Development'
  config.build_settings['MARKETING_VERSION'] = '1.0'
  config.build_settings['CURRENT_PROJECT_VERSION'] = '1'
  config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/../Frameworks', '@executable_path/../../Frameworks']
  config.build_settings['SKIP_INSTALL'] = 'YES'
end

src_group = project.main_group.find_subpath('src', true)
src_group.set_source_tree('<group>')

app_group = src_group.find_subpath('MarkdownPreviewApp', true)
ext_group = src_group.find_subpath('MarkdownPreviewExtension', true)

app_sources = [
  'src/MarkdownPreviewApp/MarkdownPreviewApp.swift',
  'src/MarkdownPreviewApp/ContentView.swift'
]
app_resources = [
  'src/MarkdownPreviewApp/Assets.xcassets'
]
ext_sources = [
  'src/MarkdownPreviewExtension/PreviewViewController.swift'
]
ext_resources = [
  'src/MarkdownPreviewExtension/Resources/HighlightJS/highlight.min.js',
  'src/MarkdownPreviewExtension/Resources/Prettier/standalone.js',
  'src/MarkdownPreviewExtension/Resources/Prettier/parser-babel.js',
  'src/MarkdownPreviewExtension/Resources/Prettier/parser-estree.js',
  'src/MarkdownPreviewExtension/Resources/Prettier/parser-html.js',
  'src/MarkdownPreviewExtension/Resources/Prettier/parser-yaml.js'
]

app_refs = app_sources.map { |path| project.main_group.new_file(path) }
app_resource_refs = app_resources.map { |path| project.main_group.new_file(path) }
ext_refs = ext_sources.map { |path| project.main_group.new_file(path) }
ext_resource_refs = ext_resources.map { |path| project.main_group.new_file(path) }

app_target.add_file_references(app_refs)
ext_target.add_file_references(ext_refs)
app_resource_refs.each do |resource_ref|
  app_target.resources_build_phase.add_file_reference(resource_ref)
end
ext_resource_refs.each do |resource_ref|
  ext_target.resources_build_phase.add_file_reference(resource_ref)
end

package_ref = project.new(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
package_ref.relative_path = 'src/CoreMarkdownPreview'
project.root_object.package_references << package_ref

product_dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
product_dep.product_name = 'CoreMarkdownPreview'
product_dep.package = package_ref
ext_target.package_product_dependencies << product_dep

framework_build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
framework_build_file.product_ref = product_dep
ext_target.frameworks_build_phase.files << framework_build_file

app_target.add_dependency(ext_target)
embed_phase = app_target.copy_files_build_phases.find { |phase| phase.name == 'Embed App Extensions' } || app_target.new_copy_files_build_phase('Embed App Extensions')
embed_phase.symbol_dst_subfolder_spec = :plug_ins
embed_phase.dst_path = ''
embed_phase.add_file_reference(ext_target.product_reference)

project.save
puts "Created #{project_path}"
