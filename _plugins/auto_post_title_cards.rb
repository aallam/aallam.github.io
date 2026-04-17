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
    TITLE_LAYOUTS = [
      { :max_lines => 1, :max_chars => 18, :font_size => 88, :start_y => 176 },
      { :max_lines => 2, :max_chars => 24, :font_size => 74, :start_y => 144 },
      { :max_lines => 3, :max_chars => 22, :font_size => 60, :start_y => 122 },
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

        File.write(svg_path, svg_markup(post.data["title"].to_s, site_url_label(site)))
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

    def svg_markup(title, site_label)
      lines, layout = wrapped_lines(title)
      line_height = (layout[:font_size] * 1.14).round
      title_tspans = lines.each_with_index.map do |line, index|
        dy = index.zero? ? "0" : line_height.to_s
        %(<tspan x="0" dy="#{dy}">#{escape(line)}</tspan>)
      end.join

      <<~SVG
        <svg xmlns="http://www.w3.org/2000/svg" width="#{CARD_WIDTH}" height="#{CARD_HEIGHT}" viewBox="0 0 #{CARD_WIDTH} #{CARD_HEIGHT}" role="img" aria-labelledby="title desc">
          <title id="title">#{escape(title)}</title>
          <desc id="desc">Auto-generated social sharing card for the post "#{escape(title)}".</desc>

          <defs>
            <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stop-color="#f7f7fb" />
              <stop offset="100%" stop-color="#efe7ff" />
            </linearGradient>
            <linearGradient id="accent" x1="0%" y1="0%" x2="100%" y2="0%">
              <stop offset="0%" stop-color="#6a3fd4" />
              <stop offset="100%" stop-color="#1b8c7a" />
            </linearGradient>
          </defs>

          <rect width="#{CARD_WIDTH}" height="#{CARD_HEIGHT}" fill="url(#bg)" rx="36" />
          <circle cx="1025" cy="112" r="96" fill="#ffffff" opacity="0.65" />
          <circle cx="1110" cy="510" r="140" fill="#ffffff" opacity="0.45" />
          <circle cx="160" cy="540" r="180" fill="#ffffff" opacity="0.55" />
          <rect x="84" y="84" width="1032" height="462" rx="32" fill="#ffffff" opacity="0.88" />
          <rect x="84" y="84" width="1032" height="12" rx="6" fill="url(#accent)" />

          <g transform="translate(136 170)">
            <text x="0" y="0" fill="#6a3fd4" font-family="Helvetica Neue, Helvetica, Arial, sans-serif" font-size="24" font-weight="700" letter-spacing="2">
              #{BRAND_LABEL}
            </text>
            <text x="0" y="#{layout[:start_y]}" fill="#1d1d27" font-family="Helvetica Neue, Helvetica, Arial, sans-serif" font-size="#{layout[:font_size]}" font-weight="700">
              #{title_tspans}
            </text>
            <text x="0" y="308" fill="#4b4b5a" font-family="Helvetica Neue, Helvetica, Arial, sans-serif" font-size="38" letter-spacing="1">
              #{escape(site_label)}
            </text>
          </g>
        </svg>
      SVG
    end

    def wrapped_lines(title)
      normalized = title.gsub(/\s+/, " ").strip
      TITLE_LAYOUTS.each do |layout|
        lines = wrap_words(normalized, layout[:max_lines], layout[:max_chars])
        return [lines, layout] if lines
      end

      [wrap_words(normalized, 3, 22, :truncate => true), { :font_size => 58, :start_y => 122 }]
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
