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
      @slides << RubySlides::Slide::Introduction.new(title: title,
                                                     subtitle: subtitle)
    end

    def textual_slide(title, content = [])
      @slides << RubySlides::Slide::Textual.new(presentation: self,
                                                title: title,
                                                content: content)
    end

    def pictorial_slide(title, image_path, coords = {})
      @slides << RubySlides::Slide::Pictorial.new(presentation: self,
                                                  title: title,
                                                  image_path: image_path,
                                                  coords: coords)
    end

    def text_picture_slide(title, image_path, content = [])
      @slides << RubySlides::Slide::TextPicSplit.new(presentation: self,
                                                     title: title,
                                                     image_path: image_path,
                                                     content: content)
    end

    def picture_description_slide(title, image_path, content = [])
      @slides << RubySlides::Slide::DescriptionPic.new(presentation: self,
                                                       title: title,
                                                       image_path: image_path,
                                                       content: content)
    end

    def table_slide(title, content = [])
      @slides << RubySlides::Slide::Table.new(presentation: self,
                                              title: title,
                                              content: content)
    end

    def chart_slide(title, series = [{}])
      @slides << RubySlides::Slide::Chart.new(presentation: self,
                                              title: title,
                                              series: series)
    end

    def save(path, widescreen: false)
      Dir.mktmpdir do |dir|
        extract_path = "#{dir}/extract_#{Time.now.strftime("%Y-%m-%d-%H%M%S")}"

        # Copy template to temp path
        FileUtils.copy_entry(TEMPLATE_PATH, extract_path)

        # Remove keep files
        Dir.glob("#{extract_path}/**/.keep").each do |keep_file|
          FileUtils.rm_rf(keep_file)
        end

        # Render/save generic stuff
        render_view('content_type.xml.erb',
                    "#{extract_path}/[Content_Types].xml")
        render_view('presentation.xml.rel.erb',
                    "#{extract_path}/ppt/_rels/presentation.xml.rels", widescreen: widescreen)
        render_view('presentation.xml.erb',
                    "#{extract_path}/ppt/presentation.xml", widescreen: widescreen)
        render_view('app.xml.erb',
                    "#{extract_path}/docProps/app.xml")

        # We dynamically generate the slide master because we need to adjust the
        # width of the title depending on whether the slide is widescreen or standard
        render_view('slideMaster1.xml.erb',
          "#{extract_path}/ppt/slideMasters/slideMaster1.xml", widescreen: widescreen)

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

    def charts
      slides.map {|slide|
        slide.class == RubySlides::Slide::Chart
      }.count
    end
  end
end
