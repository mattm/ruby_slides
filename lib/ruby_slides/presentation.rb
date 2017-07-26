require 'zip/filesystem'
require 'fileutils'
require 'tmpdir'

module RubySlides
  class Presentation
    include RubySlides::Util

    attr_reader :slides

    def initialize
      @slides = []
    end

    def introduction_slide(title, subtitle)
      @slides << RubySlides::Slide::Introduction.new(title: title, subtitle: subtitle)
    end

    def save(path)
      Dir.mktmpdir do |dir|
        extract_path = "#{dir}/extract_#{Time.now.strftime("%Y-%m-%d-%H%M%S")}"

        # Copy template to temp path
        FileUtils.copy_entry(TEMPLATE_PATH, extract_path)

        # Remove keep files
        Dir.glob("#{extract_path}/**/.keep").each do |keep_file|
          FileUtils.rm_rf(keep_file)
        end

        # Render/save generic stuff
        render_view('content_type.xml.erb', "#{extract_path}/[Content_Types].xml")
        render_view('presentation.xml.rel.erb', "#{extract_path}/ppt/_rels/presentation.xml.rels")
        render_view('presentation.xml.erb', "#{extract_path}/ppt/presentation.xml")
        render_view('app.xml.erb', "#{extract_path}/docProps/app.xml")

        # Save slides
        slides.each_with_index do |slide, index|
          slide.save(extract_path, index + 1)
        end

        # Create .pptx file
        File.delete(path) if File.exist?(path)
        RubySlides.compress_pptx(extract_path, path)
      end
      path
    end

    def file_types
      slides.map {|slide|
        slide.file_type if slide.respond_to? :file_type
      }.compact.uniq
    end
  end
end