# frozen_string_literal: true

require "cgi"
require "fileutils"
require "open3"
require "uri"

module Jekyll
  class GeneratedPostCardFile < StaticFile
    def initialize(site, base, dir, name, destination_dir)
      super(site, base, dir, name)
      @destination_dir = destination_dir
    end

    def url
      File.join("/", @destination_dir, @name)
    end
  end

  class AutoPostTitleCardsGenerator < Generator
    safe true
    priority :highest

    CARD_WIDTH = 1200
    CARD_HEIGHT = 630
    CACHE_DIR = ".jekyll-cache/auto-post-title-cards"
    DESTINATION_DIR = "assets/images/generated/posts"
    BRAND_LABEL = "MOUAAD AALLAM"
    SERIF_FONT_FAMILY = "'Iowan Old Style', 'Palatino Linotype', Palatino, Georgia, serif"
    SANS_FONT_FAMILY = "-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif"
    TITLE_COLOR = "#111111"
    META_COLOR = "#8E8E8E"
    SUBTITLE_COLOR = "#5A5A5A"
    HAIRLINE_COLOR = "#E6E3DC"
    META_X = 100
    META_Y = 112
    ORNAMENT_Y = 144
    FOOTER_LINE_Y = 560
    FOOTER_Y = 594
    # Subtitle copy fits in 2 lines of 60 chars each, so the hard cap is ~120 chars.
    SUBTITLE_FONT_SIZE = 21
    SUBTITLE_LINE_HEIGHT = 32
    SUBTITLE_MAX_LINES = 2
    SUBTITLE_MAX_CHARS = 60
    TITLE_LAYOUTS = [
      { :max_lines => 1, :max_chars => 13, :font_size => 112, :line_height => 112, :first_line_y => 340, :subtitle_gap => 108 },
      { :max_lines => 2, :max_chars => 16, :font_size => 98, :line_height => 96, :first_line_y => 300, :subtitle_gap => 74 },
      { :max_lines => 3, :max_chars => 18, :font_size => 80, :line_height => 78, :first_line_y => 250, :subtitle_gap => 58 },
    ].freeze
    MONTH_NAMES = %w[
      JANUARY FEBRUARY MARCH APRIL MAY JUNE
      JULY AUGUST SEPTEMBER OCTOBER NOVEMBER DECEMBER
    ].freeze

    def generate(site)
      rasterizer = find_rasterizer!
      cache_dir = site.in_source_dir(CACHE_DIR)
      FileUtils.mkdir_p(cache_dir)

      site.posts.docs.each do |post|
        next if explicit_front_matter_image?(post.path)

        filename = "#{File.basename(post.path, File.extname(post.path))}.png"
        png_path = File.join(cache_dir, filename)
        svg_path = File.join(cache_dir, "#{File.basename(filename, ".png")}.svg")

        File.write(
          svg_path,
          svg_markup(
            site,
            post,
            site_url_label(site)
          )
        )
        generate_png(rasterizer, svg_path, png_path)

        site.static_files << GeneratedPostCardFile.new(
          site,
          site.source,
          CACHE_DIR,
          filename,
          DESTINATION_DIR
        )
        post.data["image"] = "/#{DESTINATION_DIR}/#{filename}"
      end
    end

    private

    def explicit_front_matter_image?(post_path)
      front_matter = File.read(post_path, encoding: "UTF-8")[/\A---\s*\n(.*?)\n---\s*\n/m, 1]
      front_matter&.match?(/^\s*image\s*:/)
    end

    def find_rasterizer!
      executable = ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).find do |dir|
        File.executable?(File.join(dir, "rsvg-convert"))
      end

      return File.join(executable, "rsvg-convert") if executable

      raise Errors::FatalException, "rsvg-convert is required to generate default post social cards"
    end

    def generate_png(rasterizer, svg_path, png_path)
      _stdout, stderr, status = Open3.capture3(
        rasterizer,
        svg_path,
        "-w", CARD_WIDTH.to_s,
        "-h", CARD_HEIGHT.to_s,
        "-o", png_path
      )

      return if status.success?

      raise Errors::FatalException, "failed to generate social card for #{svg_path}: #{stderr}"
    end

    def site_url_label(site)
      url = site.config["url"].to_s
      URI(url).host || url
    rescue URI::InvalidURIError
      url.sub(%r!\Ahttps?://!, "")
    end

    def svg_markup(site, post, site_label)
      title = post.data["title"].to_s
      description = post.data["description"].to_s
      title_lines, layout = wrapped_title_lines(title)
      title_markup = title_lines.each_with_index.map do |line, index|
        y = layout[:first_line_y] + (index * layout[:line_height])
        %(<text x="100" y="#{y}" font-family="#{SERIF_FONT_FAMILY}" font-size="#{layout[:font_size]}" font-weight="500" fill="#{TITLE_COLOR}" letter-spacing="-0.028em">#{escape(line)}</text>)
      end.join("\n      ")
      subtitle_markup = subtitle_block(description, layout, title_lines.length)
      read_time_markup = read_time_block(site, post)
      accessibility_description = [title, description].map(&:strip).reject(&:empty?).join(". ")

      <<~SVG
        <svg xmlns="http://www.w3.org/2000/svg" width="#{CARD_WIDTH}" height="#{CARD_HEIGHT}" viewBox="0 0 #{CARD_WIDTH} #{CARD_HEIGHT}" role="img" aria-labelledby="title desc">
          <title id="title">#{escape(title)}</title>
          <desc id="desc">#{escape(accessibility_description)}</desc>
          <rect width="#{CARD_WIDTH}" height="#{CARD_HEIGHT}" fill="#FFFFFF" />
          <text x="#{META_X}" y="#{META_Y}" font-family="#{SANS_FONT_FAMILY}" font-size="12" fill="#{META_COLOR}" letter-spacing="0.28em" font-weight="500">
            #{escape(meta_label(post))}
          </text>
          <rect x="#{META_X}" y="#{ORNAMENT_Y}" width="28" height="2" fill="#{TITLE_COLOR}" />
          #{title_markup}
          #{subtitle_markup}
          <line x1="#{META_X}" y1="#{FOOTER_LINE_Y}" x2="1100" y2="#{FOOTER_LINE_Y}" stroke="#{HAIRLINE_COLOR}" stroke-width="1" />
          <text x="#{META_X}" y="#{FOOTER_Y}" font-family="#{SANS_FONT_FAMILY}" font-size="15" fill="#{TITLE_COLOR}" font-weight="500">
            #{escape(site_label)}
          </text>
          #{read_time_markup}
        </svg>
      SVG
    end

    def wrapped_title_lines(title)
      normalized = title.gsub(/\s+/, " ").strip
      TITLE_LAYOUTS.each do |layout|
        lines = wrap_words(normalized, layout[:max_lines], layout[:max_chars])
        return [lines, layout] if lines
      end

      [
        wrap_words(normalized, 3, 18, :truncate => true),
        { :font_size => 76, :line_height => 74, :first_line_y => 252, :subtitle_gap => 54 }
      ]
    end

    def subtitle_block(description, layout, title_line_count)
      normalized = description.gsub(/\s+/, " ").strip
      return "" if normalized.empty? || title_line_count > 2

      lines = wrap_words(normalized, SUBTITLE_MAX_LINES, SUBTITLE_MAX_CHARS, :truncate => true)
      start_y = layout[:first_line_y] + ((title_line_count - 1) * layout[:line_height]) + layout[:subtitle_gap]

      lines.each_with_index.map do |line, index|
        y = start_y + (index * SUBTITLE_LINE_HEIGHT)
        %(<text x="100" y="#{y}" font-family="#{SANS_FONT_FAMILY}" font-size="#{SUBTITLE_FONT_SIZE}" fill="#{SUBTITLE_COLOR}" font-weight="400">#{escape(line)}</text>)
      end.join("\n      ")
    end

    def meta_label(post)
      "#{BRAND_LABEL} · #{date_label(post)}"
    end

    def date_label(post)
      date = post.date.to_time
      "#{MONTH_NAMES[date.month - 1]} #{date.year}"
    end

    def read_time_block(site, post)
      return "" unless site.config["read-time"]

      <<~SVG.chomp
        <text x="1100" y="#{FOOTER_Y}" font-family="#{SANS_FONT_FAMILY}" font-size="14" fill="#{META_COLOR}" font-weight="400" text-anchor="end">
          #{escape(read_time_label(post))}
        </text>
      SVG
    end

    def read_time_label(post)
      minutes = estimated_read_minutes(post)
      "#{minutes} min read"
    end

    def estimated_read_minutes(post)
      word_count = plain_text_word_count(post.content.to_s)
      return 1 if word_count < 360

      word_count / 180
    end

    def plain_text_word_count(content)
      stripped = content.dup
      stripped.gsub!(/```.*?```/m, " ")
      stripped.gsub!(/`[^`]*`/, " ")
      stripped.gsub!(/!\[[^\]]*\]\([^)]+\)/, " ")
      stripped.gsub!(/\[([^\]]+)\]\([^)]+\)/, '\1')
      stripped.gsub!(/<[^>]+>/, " ")
      stripped.scan(/\b[\p{L}\p{N}_'-]+\b/u).count
    end

    def wrap_words(title, max_lines, max_chars, truncate: false)
      words = title.split(" ")
      lines = []
      current = +""

      until words.empty?
        word = words.first
        candidate = current.empty? ? word : "#{current} #{word}"

        if candidate.length <= max_chars
          current = candidate
          words.shift
          next
        end

        if current.empty?
          current = truncate ? ellipsize(word, max_chars) : word
          words.shift
        end

        lines << current
        current = +""

        if truncate && lines.length == max_lines
          lines[-1] = ellipsize("#{lines[-1]} #{words.join(" ")}".strip, max_chars)
          return lines
        end
        return nil if lines.length >= max_lines
      end

      lines << current unless current.empty?
      return lines if lines.length <= max_lines
      return nil unless truncate

      lines = lines.first(max_lines)
      lines[-1] = ellipsize(lines[-1], max_chars)
      lines
    end

    def ellipsize(text, max_chars)
      return text if text.length <= max_chars
      return text[0, max_chars] if max_chars <= 1

      "#{text[0, max_chars - 1].rstrip}…"
    end

    def escape(text)
      CGI.escapeHTML(text.to_s)
    end
  end
end
