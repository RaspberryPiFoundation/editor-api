# frozen_string_literal: true

class ScratchComponent < ApplicationRecord
  belongs_to :project

  def content_with_stage_first
    content_hash = content.to_h
    targets = content_hash['targets']
    return content_hash unless targets.is_a?(Array)

    # Scratch's SB3 schema expects the stage target at targets[0].
    stage_targets, other_targets = targets.partition do |target|
      target.is_a?(Hash) && (target['isStage'] || target[:isStage])
    end
    return content_hash if stage_targets.empty?

    content_hash.merge('targets' => stage_targets + other_targets)
  end
end
