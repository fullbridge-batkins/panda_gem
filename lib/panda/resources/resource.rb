module Panda
  class Resource < Base
    include Panda::Builders
    include Panda::Associations
    include Panda::CloudConnection

    def initialize(attributes={})
      super(attributes)
      @attributes['cloud_id'] ||= Panda.cloud.id
    end

    class << self
      include Panda::Finders::FindMany
      include Panda::CloudConnection

      def cloud
        Panda.cloud
      end
    end

    def cloud
      Panda.clouds[cloud_id]
    end

    def create
      raise "Can't create attribute. Already have an id=#{attributes['id']}" if attributes['id']
      response = connection.post(object_url_map(self.class.many_path), attributes)
      load_response(response) ? (@changed_attributes = {}; true) : false
    end

    def create!
      create || errors.last.raise!
    end

    def reload
      perform_reload("cloud_id" => cloud_id)
      self
    end

  end
end
