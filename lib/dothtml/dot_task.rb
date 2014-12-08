require 'rake'
require 'rake/tasklib'
require_relative 'dot_helper'

module Dothtml
  class DotTask < Rake::TaskLib
    attr_accessor :template
    attr_accessor :style
    attr_accessor :behavior
    attr_accessor :cdn
    attr_accessor :d3js

    attr_accessor :dot_folder
    attr_accessor :html_folder

    def initialize(name = :dot)
      templates = File.expand_path(File.join(File.dirname(__FILE__), "..", "..","templates"))
      @name     = name
      @style    = File.join(templates, 'style.css')
      @behavior = File.join(templates, 'behavior.js')
      @template = File.join(templates, 'index.html.erb')
      self.cdn  = true
      yield self if block_given?
      define
    end

    def cdn=(val)
      @d3js = val ? "//cdnjs.cloudflare.com/ajax/libs/d3/3.4.13/d3.min.js" : "d3.v3.js"
    end

    def define
      desc "convert dot file into an svg file"
      task :dot_svg, [:src, :target] do |t, params|
        source = params[:src]
        target = params[:target]
        puts "#{source} -> #{target}"
        puts `dot -Tsvg #{source} -o #{target}`
      end

      # would be nice if there were no intermediary steps
      rule ".svg" => ".dot" do |t|
        Rake::Task["dot_svg"].execute(:target => t.name, :src => t.source)
      end

      desc "convert svg file into a html file"
      task :svg_html, [:src, :target] do |t, params|
        source = params[:src]
        target = params[:target]

        puts "#{source} -> #{target}"

        doc = DotHelper.new(source)#.embed_images
        doc.write target, @template,
                  title:    doc.extractTitle,
                  body:     doc.to_xml,
                  style:    File.read(style),
                  behavior: File.read(behavior),
                  d3js:     d3js
      end

      rule '.html' => [".svg", style, template] do |t|
        Rake::Task["svg_html"].execute(:target => t.name, :src => t.source)
        Rake::Task["refresh_browser"].invoke
      end

      #TODO find proper tab, offer non chrome options
      desc "use applescript to refresh front most window in chrome"
      task :refresh_browser do
        puts "refreshing browser"
        `osascript -e 'tell application "Google Chrome" to tell the active tab of its first window to reload'` 
      end
    end
  end
end