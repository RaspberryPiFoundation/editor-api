class RenameInvitationsToTeacherInvitations < ActiveRecord::Migration[7.1]
  def change
    rename_table :invitations, :teacher_invitations
  end
end
