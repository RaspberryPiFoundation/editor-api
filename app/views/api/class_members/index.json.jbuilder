# frozen_string_literal: true

json.array!(@class_members) do |class_member|
  if class_member.respond_to?(:student_id)
    json.partial! 'class_member', class_member:
  else
    # Teachers are not modelled as ClassMembers
    json.set! :teacher do
      json.call(
        class_member,
        :id,
        :name,
        :email
      )
    end
  end
end
