class AddIndexToSupportUserDfESignInUid < ActiveRecord::Migration[6.0]
  def change
    remove_index :support_users, :dfe_sign_in_uid
    add_index :support_users, :dfe_sign_in_uid, unique: true
  end
end
