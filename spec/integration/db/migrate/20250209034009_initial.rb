class Initial < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :role, default: :user  # admin, user, etc.
      t.boolean :active, default: true

      t.timestamps
    end

    create_table :api_tokens do |t|
      t.string :token, null: false, index: {unique: true}
      t.belongs_to :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
