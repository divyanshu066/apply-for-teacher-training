class AddForceOpenToCourses < ActiveRecord::Migration[6.0]
  def change
    add_column :courses, :force_open, :boolean, null: false, default: false
  end
end
