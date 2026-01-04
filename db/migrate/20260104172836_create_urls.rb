class CreateUrls < ActiveRecord::Migration[7.1]
  def change
    create_table :urls do |t|
      t.string :original_url, null: false
      t.string :short_code, null: false

      t.timestamps
    end
    add_index :urls, :short_code, unique: true
    add_index :urls, :original_url
  end
end
