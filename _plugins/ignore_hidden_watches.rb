# frozen_string_literal: true

require "jekyll-watch"

module IgnoreHiddenWatches
  def listen_ignore_paths(options)
    super + [%r{(?:\A|/)\.[^/]+(?:/|\z)}]
  end
end

Jekyll::Watcher.singleton_class.prepend(IgnoreHiddenWatches)
