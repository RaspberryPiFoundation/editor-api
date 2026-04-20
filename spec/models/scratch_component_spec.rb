# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ScratchComponent do
  describe '#content_with_stage_first' do
    it 'returns the stage target first' do
      component = build(
        :scratch_component,
        content: {
          targets: [
            { name: 'Sprite1', isStage: false },
            { name: 'Stage', isStage: true },
            { name: 'Sprite2', isStage: false }
          ],
          monitors: [],
          extensions: [],
          meta: {}
        }
      )

      expect(component.content_with_stage_first.fetch('targets').pluck('name')).to eq(%w[Stage Sprite1 Sprite2])
    end

    it 'returns the content unchanged when targets is not an array' do
      component = build(:scratch_component, content: { targets: 'invalid' })

      expect(component.content_with_stage_first).to eq(component.content.to_h)
    end

    it 'returns the content unchanged when there is no stage target' do
      component = build(
        :scratch_component,
        content: {
          targets: [
            { name: 'Sprite1', isStage: false },
            { name: 'Sprite2', isStage: false }
          ]
        }
      )

      expect(component.content_with_stage_first).to eq(component.content.to_h)
    end
  end
end
