class CreateTasks < ActiveRecord::Migration[6.0]
  def change
    create_table :tasks do |t|
      t.references :support_user, null: false, foreign_key: true
      t.text :code, null: false
      t.string :status, null: false

      t.timestamps
    end
  end
end
