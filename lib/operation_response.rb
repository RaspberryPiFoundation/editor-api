# frozen_string_literal: true

class OperationResponse < Hash
  def success?
    return false unless self[:error].nil?

    true
  end

  def failure?
    !success?
  end
end
