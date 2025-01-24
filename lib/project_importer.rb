# frozen_string_literal: true

class ProjectImporter
  attr_reader :name, :identifier, :images, :videos, :audio_files, :media, :components, :type, :locale

  def initialize(**kwargs)
    @name = kwargs[:name]
    @identifier = kwargs[:identifier]
    @components = kwargs[:components]
    @images = kwargs[:images]
    @videos = kwargs[:videos]
    @audio_files = kwargs[:audio_files]
    @media = images + videos + audio_files
    @type = kwargs[:type]
    @locale = kwargs[:locale]
  end

  def import!
    Project.transaction do
      setup_project
      delete_components
      create_components
      delete_removed_media
      attach_media_if_needed

      project.save!
    end
  end

  private

  def project
    @project ||= Project.find_or_initialize_by(identifier:, locale:)
  end

  def setup_project
    project.name = name
    project.project_type = type
  end

  def delete_components
    project.components.each(&:destroy)
  end

  def create_components
    components.each do |component|
      project_component = Component.new(**component)
      project.components << project_component
    end
  end

  def delete_removed_media
    return if removed_media_names.empty?

    removed_media_names.each do |filename|
      media_file = project.media.find { |i| i.blob.filename == filename }
      media_file.purge
    end
  end

  def removed_media_names
    existing_media = project.media.map { |x| x.blob.filename.to_s }
    existing_media - media.pluck(:filename)
  end

  def attach_media_if_needed
    media.each do |media_file|
      existing_media_file = find_existing_media_file(media_file[:filename])
      if existing_media_file
        next if existing_media_file.blob.checksum == media_checksum(media_file[:io])

        existing_media.purge
      end
      if images.include?(media_file)
        project.images.attach(**media_file)
      elsif videos.include?(media_file)
        project.videos.attach(**media_file)
      elsif audio_files.include?(media_file)
        project.audio_files.attach(**media_file)
      else
        raise "Unsupported media file: #{media_file[:filename]}"
      end
    end
  end

  def find_existing_media_file(filename)
    project.media.find { |i| i.blob.filename == filename }
  end

  def media_checksum(io)
    OpenSSL::Digest.new('MD5').tap do |checksum|
      while (chunk = io.read(5.megabytes))
        checksum << chunk
      end

      io.rewind
    end.base64digest
  end
end
