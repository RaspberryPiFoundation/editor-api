# frozen_string_literal: true

class OperationResponse < Hash
  def success?
    fetch(:error, nil).nil?
  end

  def failure?
    !success?
  end
end
