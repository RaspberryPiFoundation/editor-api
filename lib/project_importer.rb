# frozen_string_literal: true

class ProjectImporter
  attr_reader :name, :identifier, :images, :components, :type

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
        project_component = Component.new(**component)
        project.components << project_component
      end

      delete_removed_images
      attach_images_if_needed

      project.save!
    end
  end

  private

  def project
    @project ||= Project.find_or_initialize_by(identifier:)
  end

  def delete_components
    project.components.each(&:destroy)
  end

  def delete_removed_images
    existing_images = project.images.map { |x| x.blob.filename.to_s }
    diff = existing_images - images.pluck(:filename)
    return if diff.empty?

    diff.each do |filename|
      img = project.images.find { |i| i.blob.filename == filename }
      img.purge!
    end
  end

  def attach_images_if_needed
    images.each do |image|
      existing_image = project.images.find { |i| i.blob.filename == image[:filename] }

      if existing_image
        return if existing_image.blob.checksum == image_checksum(image[:io])

        existing_image.purge!
      end

      project.images.attach!(*image)
    end
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
