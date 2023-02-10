

class ProjectImporter
    attr_reader :name, :identifier, :images, :components, :type

    components = [
      {
        filename: "index"
        extension: "html"
        contents: "<html></html>"
        default: true
    },
    {
      filename: "styles"
      extension: "css"
      contents: "html { color: pink } "
      default: false
    }]

    images = {
      [
        filename: "foo.png"
        contents: # binary
      ]
    }

    def initialize(name:, identifier:, type:, components:, images: [])
      @name = name
      @identifier = identifier
      @components = components
      @images = images
      @type = type
    end

    def import!
      Project.transaction do
      delete_components

      components.each do |component|
        project_component = Component.new(*component)
        project.components << project_component
      end

      delete_removed_images
      project_images.each do |image_name|
        attach_image_if_needed(project, image_name, dir)
      end

      project.save!
      end
    end

    private

    def project
      @project ||= Project.find_or_initialze_by(identifier:)
    end

    def delete_components
      project.components.each(&:destroy)
    end

    def delete_removed_images
      existing_images = project.images.map { |x| x.blob.filename.to_s }
      diff = existing_images - images.map{|x| x[:filename]}
      return if diff.empty?

      diff.each do |filename|
        img = project.images.find { |i| i.blob.filename == filename }
        img.purge!
      end
    end

    def attach_images_if_needed
      existing_image = project.images.find { |i| i.blob.filename == image_name }

      if existing_image
        return if existing_image.blob.checksum == image_checksum(image_name)

        existing_image.purge!
      end

      project.images.attach!(io: image.io,
                            filename: image.filename)
    end


    def image_checksum(io)
      OpenSSL::Digest.new('MD5').tap do |checksum|
        while (chunk = io.read(5.megabytes))
          checksum << chunk
        end

        io.rewind
      end.base64digest
    end
  end
