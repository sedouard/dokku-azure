class CreateReservations < ActiveRecord::Migration
  def change
    create_table :reservations do |t|
      t.string :name
      t.string :phone_number
      t.text :date_time
      t.integer :party_size

      t.timestamps null: false
    end
  end
end
