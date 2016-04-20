class Stamps < ActiveRecord::Migration
  def change
    create_table :stamps do |t|
      t.integer :user_id
      t.string :action
      t.datetime :stamp_at
      t.timestamps null: false
    end
  end
end
