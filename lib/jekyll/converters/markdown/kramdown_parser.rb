module Jekyll
  module Converters
    class Markdown
      class KramdownParser
        CoderayDefaults = {
          "bold_every" => 10,
          "css" => "style".freeze,
          "line_numbers" => "inline".freeze,
          "line_number_start" => 1,
          "wrap" => "div".freeze,
          "tab_width" => 4
        }.freeze

        def initialize(config)
          setup config
        end

        # Setup and normalize the configuration:
        #   * Create Kramdown if it doesn't exist.
        #   * Set syntax_highlighter, detecting enable_coderay and merging highlighter if none.
        #   * Merge kramdown[coderay] into syntax_highlighter_opts stripping coderay_.
        #   * Make sure `syntax_highlighter_opts` exists.

        def setup(config)
          @jekyll_config = config
          @jekyll_config["kramdown"] ||= {}
          @config = @jekyll_config["kramdown".freeze].dup
          @config["syntax_highlighter".freeze] ||= highlighter
          @config["syntax_highlighter_opts".freeze] ||= {}
          @config["coderay".freeze] ||= {} # XXX: Legacy.
          load_kramdown

          if highlighter == "coderay".freeze
            configs = @config["syntax_highlighter_opts".freeze]
            coderay = Jekyll::Utils.deep_merge_hashes(CoderayDefaults, @config["coderay"]) # XXX: Legacy
            coderay = Jekyll::Utils.deep_merge_hashes(configs, coderay) if @config.has_key?("coderay".freeze)
            @config["syntax_highlighter_opts"] = coderay
          end

          @config["syntax_highlighter_opts".freeze] = strip_coderay(@config[ \
            "syntax_highlighter_opts".freeze])
        end

        def convert(content)
          Kramdown::Document.new(content, @config).to_html
        end

        private
        def load_kramdown
          require "kramdown".freeze
        rescue LoadError
          Jekyll.logger.error  "You need to install Kramdown"
          raise Errors::FatalException.new("Missing kramdown")
        end

        # config[kramdown][syntax_higlighter] > config[kramdown][enable_coderay] > config[highlighter]
        # Where `enable_coderay` is now deprecated because Kramdown supports Rouge now too.

        private
        def highlighter
          @highlighter ||= begin
            if out = @config["syntax_highlighter".freeze] then out
            elsif @config.has_key?("enable_coderay".freeze) && @config["enable_coderay".freeze]
              Jekyll.logger.warn "You are using enable_coderay, use syntax_highlighter: coderay." \
                "In the future enable_coderay will be removed entirely."
              "coderay".freeze
            else
              @jekyll_config["highlighter".freeze] || \
                "rogue".freeze
            end
          end
        end

        private
        def strip_coderay(hash)
          hash.inject({}) do |hash_, (key, val)|
            cleaned_key = key.gsub(/\Acoderay_/, "")
            if hash.has_key?(key)
              Jekyll.logger.warn "You are an old CodeRay key: '#{key}'." \
                "It is being normalized to #{cleaned_key}."
            end

            hash_.update(
              cleaned_key => val
            )
          end
        end
      end
    end
  end
end
