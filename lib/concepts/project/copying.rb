# frozen_string_literal: true

class Project
  class Copying
    class << self
      def copy_project(source_project, attributes: {}, media: %i[images])
        source_project.dup.tap do |project_copy|
          project_copy.identifier = nil
          project_copy.assign_attributes(attributes)

          copy_components(source_project, project_copy)
          copy_scratch_component(source_project, project_copy)
          copy_media(source_project, project_copy, media)
        end
      end

      def copy_media(source_project, project_copy, media)
        media.each do |collection|
          source_project.public_send(collection).each do |attachment|
            project_copy.public_send(collection).attach(attachment.blob)
          end
        end
      end

      private

      def copy_components(source_project, project_copy)
        source_project.components.each do |component|
          project_copy.components.build(component.attributes.slice('name', 'extension', 'content'))
        end
      end

      def copy_scratch_component(source_project, project_copy)
        return unless source_project.scratch_project? && source_project.scratch_component

        project_copy.build_scratch_component(content: source_project.scratch_component.content.deep_dup)
      end
    end
  end
end
