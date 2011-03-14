module HTTParty
  module Icebox
    def self.included(receiver)
      receiver.extend(ClassMethods)

      receiver.class_eval do
        def self.get_without_caching(path, options = {})
          perform_request(Net::HTTP::Get, path, options)
        end

        def self.get_with_caching(path, options = {})
          key = path.downcase << options[:query].to_s if options[:query]

          if cache.exists?(key) and not cache.stale?(key)
            if options[:logger]
              Cache.logger.debug("CACHE -- GET #{path}#{options[:query]}")
            end

            return cache.get(key)
          else
            if options[:logger]
              Cache.logger.debug("/!\\ NETWORK -- GET #{path}#{options[:query]}")
            end

            response = get_without_caching(path, options)
            cache.set(key, response) if response.code.to_s == "200"

            response
          end
        end

        def self.get(path, options = {})
          self.get_with_caching(path, options)
        end
      end
    end

    module ClassMethods
      def cache(options = {})
        options[:store] ||= 'memory'
        options[:timeout] ||= 60
        logger = options[:logger]

        @cache ||= Cache.new(options.delete(:store), options)
      end
    end

    module Store
      class AbstractStore
        def initialize(options = {})
          @timeout = options[:timeout]
          message = "Cache: Using #{self.class.to_s.split('::').last} " <<
            "in location: #{options[:location]} " if options[:location] << 
            "with timeout #{options[:timeout]} sec"

          Cache.logger.info(message) unless options[:logger].nil?

          self
        end
      end
    end
  end
end
